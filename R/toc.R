# Table-of-contents (TOC) metadata: sources, the canonical TOC table, the
# interchange file format, and three-mode title resolution.
#
# Canonical TOC table (what every source is normalized to): one row per output,
# with columns program, type, number, title, subtitle, footnotes (list columns
# of character vectors), output_file_name, plus one character column per scope
# key (for example study, milestone).

toc_core <- c("program", "type", "number", "title", "subtitle", "footnotes", "output_file_name")
toc_lines <- c("title", "subtitle", "footnotes")
toc_format_version <- 1L

#' Column mapping for tabular TOC sources
#'
#' Describes how a TOC stored as a flat table (a database table, CSV or RDS
#' file, or data frame) maps onto the canonical TOC fields. Column names are
#' matched case-insensitively. Multi-line cells are split on `delim`.
#'
#' @param program Column(s) holding the program name. When several are given,
#'   the first non-blank value in each row wins.
#' @param type,number,title,subtitle,footnotes,output_file_name Columns holding
#'   each field. Use `NA` for a field the source does not have.
#' @param scope Columns that scope a row, for example to a study or
#'   milestone. A named vector renames them: `c(study = "study_id")` exposes
#'   column `study_id` as scope key `study`.
#' @param delim Line delimiter inside multi-line cells.
#' @return An object of class `toc_schema`.
#' @examples
#' toc_schema(program = c("r_program", "program_name"), scope = c(study = "study_id"))
#' @export
toc_schema <- function(program = "program_name", type = "output_type",
                       number = "output_number", title = "output_title",
                       subtitle = "output_subtitle", footnotes = "output_footnotes",
                       output_file_name = "output_file_name",
                       scope = c("study", "milestone"), delim = "\\") {
  if (!is.character(program) || !length(program)) tlf_abort("`program` must name at least one column.")
  if (!is.character(delim) || length(delim) != 1L || !nzchar(delim)) tlf_abort("`delim` must be a non-empty string.")
  if (is.null(names(scope))) names(scope) <- scope
  names(scope)[!nzchar(names(scope))] <- scope[!nzchar(names(scope))]
  clash <- intersect(names(scope), toc_core)
  if (length(clash)) tlf_abort("Scope key(s) clash with core TOC fields: ", paste(clash, collapse = ", "), ".")
  structure(list(program = program, type = type, number = number, title = title,
                 subtitle = subtitle, footnotes = footnotes,
                 output_file_name = output_file_name, scope = scope, delim = delim),
            class = "toc_schema")
}

# ---- sources ------------------------------------------------------------------

new_toc_source <- function(reader, mode, label) {
  structure(list(reader = reader, mode = mode, label = label), class = "toc_source")
}

#' TOC sources
#'
#' Sources are passed, in priority order, to [tlf_resolve_titles()] and
#' [toc_read()].
#'
#' * `toc_source_db()`: a live database table read through DBI (mode
#'   `"live"`).
#' * `toc_source_file()`: a snapshot file (mode `"snapshot"`). `.json`,
#'   `.yml`/`.yaml` (the tlfstack interchange format, see [toc_write()]),
#'   `.csv` and `.rds` are supported.
#' * `toc_source_dir()`: finds a snapshot in a directory by trying
#'   `<stem>.json`, `<stem>.yml`, `<stem>.yaml`, `<stem>.csv` and
#'   `<stem>.rds`, in that order.
#' * `toc_source_data()`: an in-memory data frame (mode `"snapshot"`).
#'
#' @section Credentials:
#' tlfstack never reads credentials or builds connection strings. Pass either
#' an open DBI connection, which you own and close, or a function with no
#' arguments that returns one. tlfstack calls the function for each read and
#' disconnects afterwards. Keep secrets in your own secret store (for example
#' a keyring, an ODBC DSN, or environment variables read inside your function).
#'
#' @param conn A `DBIConnection`, or a function with no arguments returning
#'   one.
#' @param table Table name, or a `DBI::Id()` for schema-qualified names. The
#'   name is quoted by DBI, never pasted into SQL.
#' @param schema A [toc_schema()] mapping for tabular sources.
#' @param label Short description recorded in the provenance of resolved
#'   titles.
#' @param path File path.
#' @param dir Directory to search.
#' @param stem File name without extension.
#' @param data A data frame in the layout described by `schema`.
#' @return An object of class `toc_source`.
#' @examples
#' f <- tempfile(fileext = ".yml")
#' toc_write(ex_toc, f)
#' src <- toc_source_file(f)
#' nrow(toc_read(src))
#' unlink(f)
#' @name toc_sources
NULL

#' @rdname toc_sources
#' @export
toc_source_db <- function(conn, table, schema = toc_schema(), label = "database") {
  rlang::check_installed("DBI", reason = "to read a TOC from a database.")
  if (!is.function(conn) && !methods::is(conn, "DBIConnection")) {
    tlf_abort("`conn` must be a DBIConnection or a function returning one.")
  }
  check_schema(schema)
  reader <- function() {
    owned <- is.function(conn)
    con <- if (owned) conn() else conn
    if (owned) on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)
    toc_normalize(DBI::dbReadTable(con, table), schema)
  }
  new_toc_source(reader, "live", label)
}

#' @rdname toc_sources
#' @export
toc_source_file <- function(path, schema = toc_schema(), label = basename(path)) {
  if (!is.character(path) || length(path) != 1L) tlf_abort("`path` must be a single file path.")
  check_schema(schema)
  new_toc_source(function() read_toc_file(path, schema), "snapshot", label)
}

#' @rdname toc_sources
#' @export
toc_source_dir <- function(dir, stem = "toc_snapshot", schema = toc_schema()) {
  check_schema(schema)
  reader <- function() {
    cand <- file.path(dir, paste0(stem, c(".json", ".yml", ".yaml", ".csv", ".rds")))
    hit <- cand[file.exists(cand)]
    if (!length(hit)) tlf_abort("No TOC snapshot named '", stem, ".{json,yml,yaml,csv,rds}' in ", dir, ".")
    read_toc_file(hit[1], schema)
  }
  new_toc_source(reader, "snapshot", file.path(dir, paste0(stem, ".*")))
}

#' @rdname toc_sources
#' @export
toc_source_data <- function(data, schema = toc_schema(), label = "data frame") {
  if (!is.data.frame(data)) tlf_abort("`data` must be a data frame.")
  check_schema(schema)
  new_toc_source(function() {
    if (is_canonical_toc(data)) data else toc_normalize(data, schema)
  }, "snapshot", label)
}

check_schema <- function(schema) {
  if (!inherits(schema, "toc_schema")) tlf_abort("`schema` must be created with toc_schema().")
  invisible(schema)
}

read_toc_file <- function(path, schema) {
  if (!file.exists(path)) tlf_abort("TOC file not found: ", path)
  ext <- tolower(tools::file_ext(path))
  toc <- switch(ext,
    json = toc_from_list(read_json_file(path), path),
    yml = , yaml = {
      rlang::check_installed("yaml", reason = "to read YAML TOC files.")
      toc_from_list(yaml::read_yaml(path), path)
    },
    csv = toc_normalize(utils::read.csv(path, colClasses = "character", check.names = FALSE,
                                        na.strings = "", encoding = "UTF-8"), schema),
    rds = {
      obj <- readRDS(path)
      if (!is.data.frame(obj)) tlf_abort("RDS TOC file must contain a data frame: ", path)
      if (is_canonical_toc(obj)) obj else toc_normalize(obj, schema)
    },
    tlf_abort("Unsupported TOC file type '.", ext, "': ", path)
  )
  meta <- or_default(attr(toc, "toc_meta"), list())
  if (is.null(meta$generated_at)) meta$generated_at <- format(file.mtime(path), "%Y-%m-%dT%H:%M:%S%z")
  attr(toc, "toc_meta") <- meta
  toc
}

read_json_file <- function(path) {
  rlang::check_installed("jsonlite", reason = "to read JSON TOC files.")
  jsonlite::read_json(path, simplifyVector = FALSE)
}

# ---- normalization ------------------------------------------------------------

split_lines <- function(x, delim) {
  if (is_blank(x)) return(character())
  parts <- trimws(strsplit(as.character(x), delim, fixed = TRUE)[[1]])
  parts[nzchar(parts)]
}

pick_col <- function(df, col) {
  if (is.na(col) || is.null(col)) return(NULL)
  i <- match(tolower(col), tolower(names(df)))
  if (is.na(i)) NULL else df[[i]]
}

# Flat table -> canonical TOC table.
toc_normalize <- function(df, schema) {
  if (!is.data.frame(df)) tlf_abort("TOC source did not return a data frame.")
  n <- nrow(df)
  chr <- function(v) if (is.null(v)) rep(NA_character_, n) else trimws(as.character(v))
  prog_cols <- lapply(schema$program, function(cl) chr(pick_col(df, cl)))
  if (all(vapply(prog_cols, function(v) all(is.na(v)), logical(1)))) {
    tlf_abort("TOC source has none of the program column(s): ", paste(schema$program, collapse = ", "), ".")
  }
  program <- Reduce(function(a, b) ifelse(is.na(a) | !nzchar(a), b, a), prog_cols)
  out <- data.frame(program = program, type = chr(pick_col(df, schema$type)),
                    number = chr(pick_col(df, schema$number)), stringsAsFactors = FALSE)
  for (f in toc_lines) {
    v <- chr(pick_col(df, schema[[f]]))
    out[[f]] <- lapply(v, split_lines, delim = schema$delim)
  }
  out$output_file_name <- chr(pick_col(df, schema$output_file_name))
  for (k in names(schema$scope)) out[[k]] <- chr(pick_col(df, schema$scope[[k]]))
  rownames(out) <- NULL
  out
}

is_canonical_toc <- function(x) {
  is.data.frame(x) && all(toc_core %in% names(x)) && all(vapply(x[toc_lines], is.list, logical(1)))
}

# Interchange list (parsed JSON/YAML) -> canonical TOC table.
toc_from_list <- function(x, path = "TOC file") {
  if (!is.list(x) || is.null(x$tlfstack_toc)) {
    tlf_abort(path, " is not a tlfstack TOC file (missing the `tlfstack_toc` version key).")
  }
  if (as.integer(x$tlfstack_toc) > toc_format_version) {
    tlf_abort(path, " uses TOC format version ", x$tlfstack_toc,
              "; this tlfstack reads up to version ", toc_format_version, ".")
  }
  outs <- or_default(x$outputs, list())
  str1 <- function(v) if (is.null(v)) NA_character_ else as.character(v)[1]
  vec <- function(v) as.character(unlist(v))
  scope_keys <- unique(unlist(lapply(outs, function(o) names(o$scope))))
  rows <- lapply(seq_along(outs), function(i) {
    o <- outs[[i]]
    if (is_blank(o$program)) tlf_abort(path, ": output ", i, " has no `program`.")
    if (!length(vec(o$title))) tlf_abort(path, ": output ", i, " (", o$program, ") has no `title`.")
    o
  })
  toc <- data.frame(
    program = vapply(rows, function(o) str1(o$program), ""),
    type = vapply(rows, function(o) str1(o$type), ""),
    number = vapply(rows, function(o) str1(o$number), ""),
    stringsAsFactors = FALSE)
  for (f in toc_lines) toc[[f]] <- lapply(rows, function(o) vec(o[[f]]))
  toc$output_file_name <- vapply(rows, function(o) str1(o$output_file_name), "")
  for (k in scope_keys) toc[[k]] <- vapply(rows, function(o) str1(o$scope[[k]]), "")
  attr(toc, "toc_meta") <- list(generated_at = x$generated_at, source = x$source)
  toc
}

# ---- read / write -------------------------------------------------------------

#' Read a TOC source into the canonical table
#'
#' @param source A `toc_source` (see [toc_sources]).
#' @return A data frame with one row per output. It has character columns
#'   `program`, `type`, `number`, `output_file_name` and one per scope key, and
#'   list columns `title`, `subtitle` and `footnotes`. Attribute `toc_meta`
#'   holds the snapshot header (`generated_at`, `source`) when known.
#' @examples
#' toc <- toc_read(toc_source_data(ex_toc))
#' toc$title[[1]]
#' @export
toc_read <- function(source) {
  if (!inherits(source, "toc_source")) tlf_abort("`source` must be a toc_source.")
  source$reader()
}

#' Write a TOC snapshot
#'
#' Writes a canonical TOC table to a file. Use it to dump a live database TOC
#' for offline work, to version-control title metadata, or to hand it to
#' another language.
#'
#' The JSON and YAML formats share one structure:
#'
#' ```yaml
#' tlfstack_toc: 1                 # format version
#' generated_at: 2026-10-22T09:00:00+0000
#' source: database                # where the snapshot came from
#' outputs:
#'   - program: t_demo
#'     scope: {study: STUDY01}
#'     type: Table
#'     number: "14.1.1"
#'     title: [Summary of Demographic and Baseline Characteristics]
#'     subtitle: [Safety Population]
#'     footnotes: [Percentages are based on N in each column.]
#'     output_file_name: t-14-01-01-demog.rtf
#' ```
#'
#' Multi-line fields are arrays, so no delimiter convention is needed and
#' output numbers stay strings. A JSON Schema for the format ships with the
#' package: `system.file("schema", "tlfstack-toc-v1.schema.json", package =
#' "tlfstack")`. CSV output joins multi-line fields with the schema delimiter,
#' for tools that need a flat file.
#'
#' @param toc A canonical TOC table (from [toc_read()]) or a data frame in the
#'   layout described by `schema`.
#' @param path Output file. The format is taken from the extension: `.json`,
#'   `.yml`, `.yaml` or `.csv`.
#' @param source Text recorded in the `source` header field.
#' @param schema A [toc_schema()]. It is used to normalize a flat `toc`, and
#'   for the CSV column names and delimiter.
#' @return `path`, invisibly.
#' @examples
#' f <- tempfile(fileext = ".json")
#' toc_write(ex_toc, f, source = "example")
#' identical(toc_read(toc_source_file(f))$number, ex_toc$number)
#' unlink(f)
#' @export
toc_write <- function(toc, path, source = or_default(attr(toc, "toc_meta")$source, "tlfstack"),
                      schema = toc_schema()) {
  check_schema(schema)
  if (!is_canonical_toc(toc)) toc <- toc_normalize(toc, schema)
  ext <- tolower(tools::file_ext(path))
  scope_keys <- setdiff(names(toc), toc_core)
  if (ext == "csv") {
    flat <- data.frame(row.names = seq_len(nrow(toc)))
    target <- c(program = schema$program[1], type = schema$type, number = schema$number,
                title = schema$title, subtitle = schema$subtitle, footnotes = schema$footnotes,
                output_file_name = schema$output_file_name)
    for (f in names(target)) {
      if (is.na(target[[f]])) next
      flat[[target[[f]]]] <- if (f %in% toc_lines) {
        vapply(toc[[f]], paste, "", collapse = schema$delim)
      } else toc[[f]]
    }
    for (k in scope_keys) flat[[or_default(schema$scope[k][[1]], k)]] <- toc[[k]]
    utils::write.csv(flat, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
    return(invisible(path))
  }
  na_null <- function(v) if (length(v) == 1L && is.na(v)) NULL else v
  outputs <- lapply(seq_len(nrow(toc)), function(i) {
    o <- list(program = toc$program[i])
    sc <- lapply(scope_keys, function(k) toc[[k]][i])
    names(sc) <- scope_keys
    sc <- Filter(function(v) !is.na(v), sc)
    if (length(sc)) o$scope <- sc
    o$type <- na_null(toc$type[i])
    o$number <- na_null(toc$number[i])
    for (f in toc_lines) o[[f]] <- I(toc[[f]][[i]])
    o$output_file_name <- na_null(toc$output_file_name[i])
    o
  })
  doc <- list(tlfstack_toc = toc_format_version,
              generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
              source = source, outputs = outputs)
  switch(ext,
    json = {
      rlang::check_installed("jsonlite", reason = "to write JSON TOC files.")
      jsonlite::write_json(doc, path, auto_unbox = TRUE, pretty = TRUE)
    },
    yml = , yaml = {
      rlang::check_installed("yaml", reason = "to write YAML TOC files.")
      for (i in seq_along(doc$outputs)) {
        for (f in toc_lines) doc$outputs[[i]][[f]] <- as.list(unclass(doc$outputs[[i]][[f]]))
      }
      yaml::write_yaml(doc, path)
    },
    tlf_abort("Unsupported TOC file type '.", ext, "'. Use .json, .yml, .yaml or .csv.")
  )
  invisible(path)
}

# ---- resolution ---------------------------------------------------------------

normalize_program <- function(x) sub("\\.(r|sas)$", "", tolower(trimws(x)))

# Rows of `toc` for `program`, ranked by scope specificity. A blank scope cell
# is a wildcard. A non-blank cell must equal the requested value.
toc_match <- function(toc, program, scope, number = NULL) {
  hit <- which(!is.na(toc$program) & normalize_program(toc$program) == normalize_program(program))
  if (!is.null(number)) hit <- hit[!is.na(toc$number[hit]) & toc$number[hit] == number]
  if (!length(hit)) return(integer())
  # Rank: more exact matches on requested scope keys first; then, for scope
  # columns the caller did not specify, general (blank) rows before specific ones.
  score <- integer(length(hit))
  specific <- integer(length(hit))
  keep <- rep(TRUE, length(hit))
  for (k in setdiff(names(toc), toc_core)) {
    have <- tolower(trimws(toc[[k]][hit]))
    wild <- is.na(have) | !nzchar(have)
    if (k %in% names(scope)) {
      want <- tolower(as.character(scope[[k]]))
      keep <- keep & (wild | have == want)
      score <- score + as.integer(!wild & have == want)
    } else {
      specific <- specific + as.integer(!wild)
    }
  }
  hit <- hit[keep]
  if (!length(hit)) return(integer())
  rank <- score[keep] * 1000L - specific[keep]
  hit[rank == max(rank)]
}

#' Resolve the title block of an output
#'
#' Looks up the titles and footnotes of `program` in a table of contents and
#' returns a [tlf_titles()] object. There are three modes:
#'
#' 1. **Live/snapshot.** `sources` are tried in order. The first one that
#'    reads successfully and has rows is used, and later sources are not
#'    consulted, so a reachable live source is authoritative.
#' 2. **Fallback.** If no source can be read, or the program has no row, the
#'    result is a placeholder title block (`"Table x.y.z"` plus a
#'    `"TODO: <program> title from TOC"` line) and a warning is issued. The
#'    program still runs, so a dry run is never blocked by missing metadata,
#'    but a placeholder can never pass for a resolved title.
#'
#' Matching: rows are matched on the program name (case-insensitive,
#' ignoring a `.R`/`.sas` extension). A row whose scope cell is blank applies
#' to every scope. Otherwise it must equal the requested `scope` value, and
#' the most specific match wins. For scope columns not given in `scope`,
#' general (blank) rows are preferred over specific ones. If several rows
#' still tie, `number` selects one; a remaining tie is an error.
#'
#' @param program Program name, for example `"t_demo"`.
#' @param type Output type used for the banner when the TOC row has none.
#' @param sources A list of `toc_source` objects, in priority order.
#' @param scope Named list of scope values, for example
#'   `list(study = "STUDY01")`.
#' @param number Optional output number to pick one of several outputs
#'   produced by the same program.
#' @param pre_title,source Passed to [tlf_titles()]. They come from the
#'   environment, not the TOC (for example a data cut-off line and the
#'   program path).
#' @param vars Named list of placeholder values (see [tlf_titles()]).
#' @param on_resolve Optional function `function(titles)` called after
#'   resolution, for example to write an audit record. Errors in it become
#'   warnings.
#' @return A [tlf_titles()] object. `$provenance` records `mode` (`"live"`,
#'   `"snapshot"` or `"fallback"`), the source label, the snapshot's
#'   `generated_at` when known, `resolved_at`, and why a fallback happened.
#' @examples
#' t <- tlf_resolve_titles("t_demo", sources = list(toc_source_data(ex_toc)),
#'                         scope = list(study = "STUDY01"))
#' t
#' t$provenance$mode
#' @export
tlf_resolve_titles <- function(program, type = c("Table", "Figure", "Listing"),
                               sources = list(), scope = list(), number = NULL,
                               pre_title = character(), source = "", vars = list(),
                               on_resolve = NULL) {
  if (!is.character(program) || length(program) != 1L || !nzchar(program)) {
    tlf_abort("`program` must be a single non-empty string.")
  }
  type <- match.arg(type)
  if (inherits(sources, "toc_source")) sources <- list(sources)
  if (!is.list(sources) || !all(vapply(sources, inherits, logical(1), "toc_source"))) {
    tlf_abort("`sources` must be a list of toc_source objects.")
  }
  if (length(scope) && is.null(names(scope))) tlf_abort("`scope` must be a named list.")

  read <- read_first_source(sources)
  prov <- list(mode = "fallback", source = read$label, generated_at = read$generated_at,
               resolved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
               program = program, scope = scope, reason = read$reason)

  idx <- if (is.null(read$toc)) integer() else toc_match(read$toc, program, scope, number)
  if (length(idx) > 1L) {
    tlf_abort(sprintf("%d TOC rows match program '%s' (numbers: %s). Pass `number` or a more specific `scope`.",
                      length(idx), program, paste(read$toc$number[idx], collapse = ", ")),
              class = "tlfstack_ambiguous_toc")
  }
  if (!length(idx)) {
    if (!is.null(read$toc)) prov$reason <- sprintf("no row for program '%s' in %s", program, read$label)
    tlf_warn("TOC: ", prov$reason, ". Using a TODO placeholder title.", class = "tlfstack_toc_fallback")
    out <- tlf_titles(title = paste0("TODO: ", program, " title from TOC"), type = type,
                      number = "x.y.z", pre_title = pre_title, source = source,
                      output_file_name = paste0(program, ".rtf"), vars = vars, provenance = prov)
  } else {
    row <- read$toc[idx, , drop = FALSE]
    prov$mode <- read$mode
    prov$reason <- NULL
    prov$row <- idx
    row_type <- row$type
    if (!is_blank(row_type) && !row_type %in% c("Table", "Figure", "Listing")) {
      row_type <- switch(toupper(substr(row_type, 1, 1)), T = "Table", F = "Figure", L = "Listing", type)
    }
    out <- tlf_titles(
      title = if (length(row$title[[1]])) row$title[[1]] else " ",
      type = if (is_blank(row_type)) type else row_type,
      number = row$number, subtitle = row$subtitle[[1]], footnotes = row$footnotes[[1]],
      pre_title = pre_title, source = source,
      output_file_name = if (is_blank(row$output_file_name)) paste0(program, ".rtf") else row$output_file_name,
      vars = vars, provenance = prov)
  }
  if (is.function(on_resolve)) {
    tryCatch(on_resolve(out), error = function(e) {
      tlf_warn("`on_resolve` failed: ", conditionMessage(e))
    })
  }
  out
}

read_first_source <- function(sources) {
  if (!length(sources)) return(list(toc = NULL, label = "none", reason = "no TOC source configured"))
  errors <- character()
  for (s in sources) {
    toc <- tryCatch(s$reader(), error = function(e) {
      errors[[length(errors) + 1L]] <<- sprintf("%s: %s", s$label, conditionMessage(e))
      NULL
    })
    if (!is.null(toc) && nrow(toc)) {
      return(list(toc = toc, mode = s$mode, label = s$label,
                  generated_at = attr(toc, "toc_meta")$generated_at))
    }
    if (!is.null(toc)) errors[[length(errors) + 1L]] <- sprintf("%s: no rows", s$label)
  }
  list(toc = NULL, label = "none", reason = paste("no readable TOC source:", paste(errors, collapse = "; ")))
}
