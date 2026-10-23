# Interoperability with the pharmaverse table layer. gtsummary (and the cards
# Analysis Results Data it is built on) can produce the table body; tlfstack
# then applies page conventions, TOC titles and RTF rendering. The body layer
# and the convention layer stay separate.

#' Convert a table body to a tlfstack table
#'
#' Renderers call `as_tlf_table()` on their input, so anything with a method
#' can be rendered under tlfstack conventions:
#'
#' * `tlf_table`: returned unchanged.
#' * `data.frame`: cells printed as-is.
#' * `gtsummary` objects (for example from `tbl_summary()` or
#'   `tbl_hierarchical()`): the visible columns with their header labels and
#'   row indentation. gtsummary footnotes, abbreviations and source notes become
#'   builder footnotes, placed after the title-block footnotes. The Analysis
#'   Results Data behind the table is kept in `meta$ard` for QC.
#' * `card` objects (Analysis Results Data from cards/cardx): formatted
#'   through `gtsummary::tbl_ard_summary()`.
#'
#' Markdown emphasis in gtsummary labels (`**bold**`, `_italic_`) is removed,
#' because the RTF text layer uses one font convention. A header line break
#' before `N = xx` becomes `(N = xx)`.
#'
#' @param x Object to convert.
#' @param ... Passed to methods. For `card` objects: `by`, the name of the
#'   grouping variable for `gtsummary::tbl_ard_summary()`. It is inferred when
#'   the ARD has a single grouping variable.
#' @return A `tlf_table` (see [tlf_table_result()]).
#' @examples
#' as_tlf_table(data.frame(Parameter = "Age", Value = "42"))
#' if (requireNamespace("gtsummary", quietly = TRUE)) {
#'   gt <- gtsummary::tbl_summary(ex_adsl, by = TRT01A, include = c(AGE, SEX))
#'   tb <- as_tlf_table(gt)
#'   tb$footnotes
#' }
#' @export
as_tlf_table <- function(x, ...) UseMethod("as_tlf_table")

#' @export
as_tlf_table.tlf_table <- function(x, ...) x

#' @export
as_tlf_table.data.frame <- function(x, ...) {
  tlf_table_result(as.data.frame(x, stringsAsFactors = FALSE), text_justification = "l")
}

#' @export
as_tlf_table.default <- function(x, ...) {
  tlf_abort("Cannot convert an object of class '", paste(class(x), collapse = "/"),
            "' to a tlf_table. Supported: tlf_table, data.frame, gtsummary, card.")
}

# Remove gtsummary markdown and turn header line breaks into plain text.
strip_md <- function(x) {
  x <- gsub("\\*\\*|__", "", x)
  x <- gsub("(^|[^A-Za-z0-9])_([^_]+)_($|[^A-Za-z0-9])", "\\1\\2\\3", x)
  x <- gsub("\\s*\n\\s*(N = [0-9,]+)\\s*$", " (\\1)", x)
  x <- gsub("\\s*\n\\s*", " ", x)
  trimws(gsub(" {2,}", " ", x))
}

# Number of leading spaces per row of `column`, from gtsummary's indent rules.
gts_indent <- function(x, column) {
  body <- x$table_body
  out <- integer(nrow(body))
  ind <- x$table_styling$indent
  if (is.null(ind) || !nrow(ind)) return(out)
  for (i in seq_len(nrow(ind))) {
    if (!identical(ind$column[i], column)) next
    rows <- rlang::eval_tidy(ind$rows[[i]], data = body)
    rows <- if (isTRUE(rows) && length(rows) == 1L) rep(TRUE, nrow(body)) else rows %in% TRUE
    out[rows] <- ind$n_spaces[i]
  }
  out
}

gts_notes <- function(x) {
  st <- x$table_styling
  pick <- function(tbl, col) {
    if (is.null(tbl) || !nrow(tbl) || !col %in% names(tbl)) return(character())
    keep <- if ("remove" %in% names(tbl)) !tbl$remove %in% TRUE else rep(TRUE, nrow(tbl))
    v <- tbl[[col]][keep]
    v[!is.na(v) & nzchar(v)]
  }
  notes <- c(pick(st$footnote_header, "footnote"), pick(st$footnote_spanning_header, "footnote"),
             pick(st$footnote_body, "footnote"))
  abbr <- pick(st$abbreviation, "abbreviation")
  if (length(abbr)) notes <- c(notes, paste0("Abbreviations: ", paste(unique(abbr), collapse = ", ")))
  notes <- c(notes, pick(st$source_note, "source_note"))
  unique(strip_md(notes))
}

#' @export
as_tlf_table.gtsummary <- function(x, ...) {
  rlang::check_installed("gtsummary", reason = "to render gtsummary tables.")
  body <- as.data.frame(gtsummary::as_tibble(x, col_labels = FALSE), stringsAsFactors = FALSE)
  labels <- names(gtsummary::as_tibble(x, col_labels = TRUE))
  if (nrow(body) != nrow(x$table_body)) {
    tlf_abort("Unexpected gtsummary layout: visible rows do not match the table body.")
  }
  for (col in names(body)) {
    n <- gts_indent(x, col)
    v <- ifelse(is.na(body[[col]]), "", as.character(body[[col]]))
    body[[col]] <- ifelse(n > 0 & nzchar(v), paste0(strrep(" ", n), v), v)
  }
  names(body) <- make.unique(strip_md(labels))
  ard <- tryCatch(gtsummary::gather_ard(x), error = function(e) NULL)
  tlf_table_result(body,
    col_rel_width = c(2.5, rep(1, ncol(body) - 1L)),
    text_justification = c("l", rep("c", ncol(body) - 1L)),
    footnotes = gts_notes(x),
    meta = list(source = "gtsummary", gtsummary_class = class(x)[1], ard = ard))
}

#' @export
as_tlf_table.card <- function(x, ..., by = NULL) {
  rlang::check_installed("gtsummary", reason = "to format Analysis Results Data.")
  if (is.null(by) && "group1" %in% names(x)) {
    g <- unique(stats::na.omit(as.character(x$group1)))
    if (length(g) == 1L) by <- g
  }
  args <- list(cards = x)
  if (!is.null(by)) args$by <- rlang::sym(by)
  tbl <- do.call(gtsummary::tbl_ard_summary, args)
  out <- as_tlf_table(tbl)
  out$meta$source <- "card"
  out$meta$ard <- x
  out
}

#' Analysis Results Data behind a table
#'
#' Returns the Analysis Results Data (ARD) behind a table, for QC and for
#' numeric comparison with an independently produced result, such as a SAS
#' dataset.
#'
#' * `tlf_ard()` returns the ARD: a cards `card` object, or a named list of
#'   them for a gtsummary table built in several steps.
#' * `tlf_write_ard()` flattens it to one row per statistic and writes CSV
#'   (or JSON, by file extension).
#'
#' @param x A `card`, a gtsummary table, or a `tlf_table` converted from
#'   either.
#' @param path Output file, `.csv` or `.json`.
#' @return `tlf_ard()`: the ARD, or `NULL` when there is none.
#'   `tlf_write_ard()`: `path`, invisibly.
#' @examples
#' if (requireNamespace("cards", quietly = TRUE)) {
#'   ard <- cards::ard_continuous(ex_adsl, by = TRT01A, variables = AGE)
#'   f <- tempfile(fileext = ".csv")
#'   tlf_write_ard(ard, f)
#'   head(read.csv(f))
#'   unlink(f)
#' }
#' @export
tlf_ard <- function(x) {
  if (inherits(x, "card")) return(x)
  if (inherits(x, "gtsummary")) {
    rlang::check_installed("gtsummary")
    return(gtsummary::gather_ard(x))
  }
  if (inherits(x, "tlf_table")) return(x$meta$ard)
  tlf_abort("`x` must be a card, a gtsummary table or a tlf_table.")
}

#' @rdname tlf_ard
#' @export
tlf_write_ard <- function(x, path) {
  rlang::check_installed("cards", reason = "to flatten Analysis Results Data.")
  ard <- tlf_ard(x)
  if (is.null(ard)) tlf_abort("No Analysis Results Data available for this object.")
  parts <- if (inherits(ard, "card")) list(ard = ard) else ard
  if (is.null(names(parts))) names(parts) <- paste0("part", seq_along(parts))
  flat <- lapply(names(parts), function(nm) {
    d <- as.data.frame(cards::unlist_ard_columns(parts[[nm]]), stringsAsFactors = FALSE)
    d <- d[vapply(d, is.atomic, logical(1))]
    d[] <- lapply(d, function(v) if (is.factor(v)) as.character(v) else v)
    cbind(component = nm, d, stringsAsFactors = FALSE)
  })
  cols <- unique(unlist(lapply(flat, names)))
  flat <- lapply(flat, function(d) {
    for (cl in setdiff(cols, names(d))) d[[cl]] <- NA
    d[cols]
  })
  out <- do.call(rbind, flat)
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    utils::write.csv(out, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  } else if (ext == "json") {
    rlang::check_installed("jsonlite", reason = "to write JSON.")
    jsonlite::write_json(out, path, pretty = TRUE, na = "null", digits = NA)
  } else {
    tlf_abort("Unsupported ARD file type '.", ext, "'. Use .csv or .json.")
  }
  invisible(path)
}
