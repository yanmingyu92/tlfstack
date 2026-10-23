# Convention engine: RTF renderers. Every renderer reads page geometry, fonts
# and the page header from the configuration, and the title block from a
# tlf_titles object, so two programs cannot disagree on any of them.

# r2rtf addresses fonts by a 1-based index into its font table, and that table
# is not part of its exported API. Read it from the public encoder output
# (the RTF \fonttbl group) and resolve the family by name, so a future r2rtf
# release that renumbers its table cannot silently change the font.
rtf_font_index <- function(family) {
  tbl <- .tlf_env$font_table
  if (is.null(tbl)) {
    enc <- r2rtf::rtf_encode(r2rtf::rtf_body(data.frame(x = "")))
    entries <- regmatches(enc$start, gregexpr("\\{\\\\f[0-9]+[^;{}]*;\\}", enc$start))[[1]]
    idx <- as.integer(sub("^\\{\\\\f([0-9]+).*$", "\\1", entries)) + 1L
    nm <- trimws(sub("^\\{\\\\f[0-9]+(\\\\[A-Za-z]+-?[0-9]*)*\\s*", "", sub(";\\}$", "", entries)))
    tbl <- stats::setNames(idx, nm)
    .tlf_env$font_table <- tbl
  }
  i <- tbl[tolower(names(tbl)) == tolower(family)]
  if (!length(i)) {
    tlf_abort("Font '", family, "' is not in the r2rtf font table. Available: ",
              paste(names(tbl), collapse = ", "), ".")
  }
  unname(i[1])
}

# ---- verbatim text encoding ----------------------------------------------------
# With text_convert = FALSE r2rtf passes text through untouched: it neither
# escapes RTF control characters nor encodes non-ASCII characters, and it does
# not expand page fields. So we encode text ourselves: escape \ { }, write
# non-ASCII characters as RTF Unicode (\uN?), and expand only the two
# documented page-field tokens. The rendered text is then exactly the input.

rtf_codepoint <- function(cp) {
  if (cp < 128L) return(intToUtf8(cp))
  u16 <- function(v) sprintf("\\u%d?", if (v > 32767L) v - 65536L else v)
  if (cp <= 0xFFFF) return(u16(cp))
  v <- cp - 0x10000
  paste0(u16(0xD800 + v %/% 1024L), u16(0xDC00 + v %% 1024L))
}

rtf_escape <- function(x, page_fields = FALSE) {
  x <- enc2utf8(as.character(x))
  if (page_fields) {
    x <- gsub("\\pagenumber", "\001", x, fixed = TRUE)
    x <- gsub("\\pagefield", "\002", x, fixed = TRUE)
  }
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("{", "\\{", x, fixed = TRUE)
  x <- gsub("}", "\\}", x, fixed = TRUE)
  out <- vapply(x, function(s) {
    if (is.na(s)) return("")
    cp <- utf8ToInt(s)
    if (!length(cp) || all(cp < 128L)) return(s)
    paste(vapply(cp, rtf_codepoint, ""), collapse = "")
  }, "", USE.NAMES = FALSE)
  if (page_fields) {
    out <- gsub("\001", "\\chpgn ", out, fixed = TRUE)
    out <- gsub("\002", "{\\field{\\*\\fldinst NUMPAGES }}", out, fixed = TRUE)
  }
  out
}

# Text as handed to r2rtf: verbatim-encoded, or raw when the user opted into
# r2rtf's own markup conversion.
rtf_txt <- function(x, cfg, page_fields = FALSE) {
  if (isTRUE(cfg$text_convert)) x else rtf_escape(x, page_fields = page_fields)
}

# Header cells (left, right), or NULL when both are blank.
header_cells <- function(cfg) {
  cells <- c(cfg$header_left, cfg$header_right)
  if (!any(nzchar(cells))) NULL else rtf_txt(cells, cfg, page_fields = TRUE)
}

# Shared r2rtf text layer: page, header, title block, footnotes, source.
apply_text_layer <- function(doc, titles, cfg, font) {
  pg <- cfg$page
  doc <- r2rtf::rtf_page(doc, orientation = pg$orientation, width = pg$width,
                         height = pg$height, margin = pg$margin)
  hdr <- header_cells(cfg)
  if (!is.null(hdr)) {
    doc <- r2rtf::rtf_page_header(doc, text = hdr, text_justification = c("l", "r"),
                                  text_font = font, text_font_size = cfg$fonts$text_size,
                                  text_convert = cfg$text_convert)
  }
  lines <- title_block_lines(titles)
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines)) {
    doc <- r2rtf::rtf_title(doc, title = rtf_txt(lines, cfg), text_font = font,
                            text_font_size = cfg$fonts$text_size, text_convert = cfg$text_convert)
  }
  doc
}

apply_footer <- function(doc, titles, cfg, font) {
  if (length(titles$footnotes)) {
    doc <- r2rtf::rtf_footnote(doc, footnote = rtf_txt(titles$footnotes, cfg), text_font = font,
                               text_font_size = cfg$fonts$text_size,
                               text_justification = "l", as_table = FALSE,
                               text_convert = cfg$text_convert)
  }
  if (nzchar(titles$source)) {
    doc <- r2rtf::rtf_source(doc, source = rtf_txt(titles$source, cfg), text_font = font,
                             text_font_size = cfg$fonts$source_size, text_justification = "l",
                             text_convert = cfg$text_convert)
  }
  doc
}

# Accept a tlf_table result or a pre-formatted data frame.
table_parts <- function(x, col_rel_width, text_justification) {
  x <- as_tlf_table(x)
  df <- x$df
  col_rel_width <- or_default(col_rel_width, x$col_rel_width)
  text_justification <- or_default(text_justification, x$text_justification)
  notes <- x$footnotes
  if (!ncol(df)) tlf_abort("Table has no columns.")
  df[] <- lapply(df, function(v) ifelse(is.na(v), "", as.character(v)))
  if (!nrow(df)) {
    df <- df[NA_integer_, , drop = FALSE]
    df[] <- ""
    df[[1]] <- "No data to report."
  }
  col_rel_width <- or_default(col_rel_width, rep(1, ncol(df)))
  if (length(col_rel_width) != ncol(df)) {
    tlf_abort(sprintf("`col_rel_width` has %d value(s) for %d column(s).", length(col_rel_width), ncol(df)))
  }
  text_justification <- rep_len(or_default(text_justification, "l"), ncol(df))
  rownames(df) <- NULL
  list(df = df, col_rel_width = col_rel_width, text_justification = text_justification,
       footnotes = notes)
}

#' Render a table or listing to RTF
#'
#' Applies the configured page geometry, running header, title block, body
#' fonts, footnotes and source line, and writes an RTF file. Footnotes carried
#' by a `tlf_table` result (for example a hazard ratio) are appended after the
#' title-block footnotes. An empty table renders as a single
#' `"No data to report."` row rather than failing.
#'
#' Tables and listings need no graphics device and render in-process.
#'
#' @param x A `tlf_table` result from a builder, a pre-formatted data frame
#'   whose cells are printed as-is, a gtsummary table, or a cards `card` object;
#'   anything [as_tlf_table()] can convert.
#' @param file Output `.rtf` path.
#' @param titles A [tlf_titles()] object (for example from
#'   [tlf_resolve_titles()]), a character vector of title lines, or `NULL`.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @param colheader Column header string in r2rtf `" | "` format. The default
#'   uses the column names.
#' @param col_rel_width Relative column widths. The default is the builder's
#'   widths, or equal widths.
#' @param text_justification Body justification per column (`"l"`, `"c"`,
#'   `"r"`), recycled.
#' @return `file`, invisibly.
#' @examples
#' res <- tbl_demographics(ex_adsl)
#' f <- tempfile(fileext = ".rtf")
#' tlf_rtf_table(res, f, titles = tlf_titles("Demographics", number = "14.1.1"))
#' unlink(f)
#' @export
tlf_rtf_table <- function(x, file, titles = NULL, config = NULL, colheader = NULL,
                          col_rel_width = NULL, text_justification = NULL) {
  cfg <- tlf_get_config(config)
  parts <- table_parts(x, col_rel_width, text_justification)
  titles <- tlf_titles_add_footnotes(as_titles(titles, "Table"), parts$footnotes)
  if (is.null(colheader)) {
    if (any(grepl("|", names(parts$df), fixed = TRUE))) {
      tlf_abort("Column names contain '|', which r2rtf uses as the header separator; supply `colheader`.")
    }
    colheader <- paste(rtf_txt(names(parts$df), cfg), collapse = " | ")
  } else {
    colheader <- paste(rtf_txt(strsplit(colheader, "|", fixed = TRUE)[[1]], cfg), collapse = "|")
  }
  parts$df[] <- lapply(parts$df, rtf_txt, cfg = cfg)
  font <- rtf_font_index(cfg$fonts$text_family)
  doc <- apply_text_layer(parts$df, titles, cfg, font)
  doc <- r2rtf::rtf_colheader(doc, colheader = colheader, col_rel_width = parts$col_rel_width,
                              text_font = font, text_font_size = cfg$fonts$text_size,
                              text_convert = cfg$text_convert)
  doc <- r2rtf::rtf_body(doc, col_rel_width = parts$col_rel_width,
                         text_justification = parts$text_justification,
                         text_font = font, text_font_size = cfg$fonts$text_size,
                         text_convert = cfg$text_convert)
  doc <- apply_footer(doc, titles, cfg, font)
  r2rtf::write_rtf(r2rtf::rtf_encode(doc), file = file)
  invisible(file)
}

#' @rdname tlf_rtf_table
#' @export
tlf_rtf_listing <- function(x, file, titles = NULL, config = NULL, colheader = NULL,
                            col_rel_width = NULL) {
  tlf_rtf_table(x, file, titles = as_titles(titles, "Listing"), config = config,
                colheader = colheader, col_rel_width = col_rel_width,
                text_justification = "l")
}

# Self-contained figure render core: it uses only its arguments and pkg::
# calls, so callr can run it in a fresh child process.
render_figure_core <- function(plot, file, title, footnotes, source, header, font,
                               text_size, source_size, fig_width, fig_height, dpi,
                               orientation, page_w, page_h, margin, text_convert) {
  # Load ggplot2 so the plot's print method is registered in a fresh child.
  requireNamespace("ggplot2", quietly = TRUE)
  img <- tempfile(fileext = ".png")
  on.exit(unlink(img), add = TRUE)
  if (requireNamespace("ragg", quietly = TRUE)) {
    ragg::agg_png(img, width = fig_width, height = fig_height, units = "in", res = dpi,
                  background = "white")
  } else {
    grDevices::png(img, width = fig_width, height = fig_height, units = "in", res = dpi,
                   bg = "white", type = "cairo")
  }
  ok <- FALSE
  on.exit(if (!ok) try(grDevices::dev.off(), silent = TRUE), add = TRUE, after = FALSE)
  print(plot)
  grDevices::dev.off()
  ok <- TRUE
  doc <- r2rtf::rtf_read_figure(img)
  doc <- r2rtf::rtf_page(doc, orientation = orientation, width = page_w, height = page_h,
                         margin = margin)
  if (length(header)) {
    doc <- r2rtf::rtf_page_header(doc, text = header, text_justification = c("l", "r"),
                                  text_font = font, text_font_size = text_size,
                                  text_convert = text_convert)
  }
  if (length(title)) {
    doc <- r2rtf::rtf_title(doc, title = title, text_font = font, text_font_size = text_size,
                            text_convert = text_convert)
  }
  if (length(footnotes)) {
    doc <- r2rtf::rtf_footnote(doc, footnote = footnotes, text_font = font, text_font_size = text_size,
                               text_justification = "l", as_table = FALSE, text_convert = text_convert)
  }
  if (nzchar(source)) {
    doc <- r2rtf::rtf_source(doc, source = source, text_font = font, text_font_size = source_size,
                             text_justification = "l", text_convert = text_convert)
  }
  doc <- r2rtf::rtf_figure(doc, fig_width = fig_width, fig_height = fig_height)
  r2rtf::write_rtf(r2rtf::rtf_encode(doc, doc_type = "figure"), file = file)
  file
}

#' Render a figure to RTF
#'
#' Draws a ggplot to a PNG (through ragg when installed, otherwise the cairo
#' `png()` device with a warning), embeds it in an RTF file, and applies the
#' same page, header, title block, footnotes and source line as
#' [tlf_rtf_table()].
#'
#' By default the render runs in an isolated child process with bounded
#' retries (see [tlf_run_isolated()] and [tlf_render_opts()]). A native crash
#' in the graphics stack then cannot kill the calling session. Isolation
#' contains most crashes, but not all of them: font operations in the parent
#' process can still fault on an affected host.
#'
#' @param plot A ggplot, typically from [tlf_build_figure()].
#' @param file Output `.rtf` path.
#' @param titles A [tlf_titles()] object, a character vector, or `NULL`.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @param render A [tlf_render_opts()] overriding the configured policy.
#' @return `file`, invisibly.
#' @examples
#' \donttest{
#' p <- fig_meanci(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
#' f <- tempfile(fileext = ".rtf")
#' tlf_rtf_figure(p, f, titles = tlf_titles("Mean ALT by Visit", type = "Figure",
#'                                          number = "14.3.1"),
#'                render = tlf_render_opts(isolate = FALSE))
#' unlink(f)
#' }
#' @export
tlf_rtf_figure <- function(plot, file, titles = NULL, config = NULL, render = NULL) {
  if (!inherits(plot, "ggplot")) tlf_abort("`plot` must be a ggplot object.")
  cfg <- tlf_get_config(config)
  ro <- or_default(render, cfg$render)
  if (!inherits(ro, "tlf_render_opts")) tlf_abort("`render` must be created with tlf_render_opts().")
  if (!requireNamespace("ragg", quietly = TRUE)) {
    tlf_warn("ragg is not installed; falling back to the cairo png() device. ",
             "Install ragg for consistent font rendering.")
  }
  titles <- as_titles(titles, "Figure")
  lines <- title_block_lines(titles)
  pg <- cfg$page
  args <- list(plot = plot, file = normalizePath(file, mustWork = FALSE),
               title = rtf_txt(lines[nzchar(trimws(lines))], cfg),
               footnotes = rtf_txt(titles$footnotes, cfg),
               source = rtf_txt(titles$source, cfg), header = header_cells(cfg),
               font = rtf_font_index(cfg$fonts$text_family),
               text_size = cfg$fonts$text_size, source_size = cfg$fonts$source_size,
               fig_width = pg$fig_width, fig_height = pg$fig_height, dpi = ro$dpi,
               orientation = pg$orientation, page_w = pg$width, page_h = pg$height,
               margin = pg$margin, text_convert = cfg$text_convert)
  tlf_run_isolated(render_figure_core, args, isolate = ro$isolate, retries = ro$retries,
                   timeout = ro$timeout, log_file = ro$log_file, target = basename(file))
  invisible(file)
}
