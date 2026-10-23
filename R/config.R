# Organization-configuration layer. Every convention a team might change lives
# here as data; the mechanism layer (builders, renderers, resolver) only reads it.

#' Page geometry
#'
#' Describes the physical page and the figure body rectangle used by every
#' renderer.
#'
#' @param orientation `"landscape"` or `"portrait"`.
#' @param paper Paper size in inches as `c(short, long)`; for example
#'   `c(8.5, 11)` for US Letter or `c(8.27, 11.69)` for A4.
#' @param margin Six margins in inches, in r2rtf order: left, right, top,
#'   bottom, header, footer.
#' @param fig_width,fig_height Size of the figure body in inches. `NULL`
#'   means 9 x 6 in, shrunk to fit the printable area if needed.
#' @return An object of class `tlf_page`.
#' @examples
#' tlf_page()
#' tlf_page("portrait", fig_width = 6.5, fig_height = 8)
#' @export
tlf_page <- function(orientation = c("landscape", "portrait"),
                     paper = c(8.5, 11),
                     margin = rep(0.5, 6),
                     fig_width = NULL, fig_height = NULL) {
  orientation <- match.arg(orientation)
  if (!is.numeric(paper) || length(paper) != 2L || any(paper <= 0)) {
    tlf_abort("`paper` must be two positive numbers: c(short, long) in inches.")
  }
  if (!is.numeric(margin) || length(margin) != 6L || any(margin < 0)) {
    tlf_abort("`margin` must be six non-negative numbers (left, right, top, bottom, header, footer).")
  }
  paper <- sort(paper)
  dims <- if (orientation == "landscape") rev(paper) else paper
  body_w <- dims[1] - margin[1] - margin[2]
  body_h <- dims[2] - margin[3] - margin[4]
  if (body_w <= 0 || body_h <= 0) tlf_abort("Margins leave no printable area.")
  fig_width <- or_default(fig_width, min(9, body_w))
  fig_height <- or_default(fig_height, min(6, body_h))
  if (fig_width > body_w || fig_height > body_h) {
    tlf_abort(sprintf("Figure body %gx%g in does not fit inside the %gx%g in printable area.",
                      fig_width, fig_height, body_w, body_h))
  }
  structure(list(orientation = orientation, width = dims[1], height = dims[2],
                 margin = margin, fig_width = fig_width, fig_height = fig_height),
            class = "tlf_page")
}

#' @rdname tlf_page
#' @export
tlf_page_letter_landscape <- function() tlf_page("landscape", paper = c(8.5, 11))

#' @rdname tlf_page
#' @export
tlf_page_a4_landscape <- function() tlf_page("landscape", paper = c(8.27, 11.69))

#' Font conventions
#'
#' @param text_family Font family of the RTF text layer (titles, headers,
#'   table and listing bodies, footnotes). It must be one of the fonts r2rtf
#'   knows about.
#' @param text_size Point size of the text layer.
#' @param source_size Point size of the source line.
#' @param figure_family Font family of the figure body (axes, legend, ticks).
#' @param figure_size Default point size of the figure body.
#' @param figure_size_range Allowed range for figure body sizes. Requests
#'   outside it are an error, so a convention cannot be bent silently.
#' @return An object of class `tlf_fonts`.
#' @examples
#' tlf_fonts(text_size = 8)
#' @export
tlf_fonts <- function(text_family = "Courier New", text_size = 9, source_size = 8,
                      figure_family = "Arial", figure_size = 10,
                      figure_size_range = c(9, 10)) {
  if (!is.character(text_family) || length(text_family) != 1L) tlf_abort("`text_family` must be a single string.")
  if (!is.character(figure_family) || length(figure_family) != 1L) tlf_abort("`figure_family` must be a single string.")
  for (nm in c("text_size", "source_size", "figure_size")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1L || v <= 0) tlf_abort("`", nm, "` must be a single positive number.")
  }
  if (!is.numeric(figure_size_range) || length(figure_size_range) != 2L) {
    tlf_abort("`figure_size_range` must be c(min, max).")
  }
  figure_size_range <- sort(figure_size_range)
  check_figure_size(figure_size, figure_size_range)
  structure(list(text_family = text_family, text_size = text_size,
                 source_size = source_size, figure_family = figure_family,
                 figure_size = figure_size, figure_size_range = figure_size_range),
            class = "tlf_fonts")
}

check_figure_size <- function(size, range) {
  if (size < range[1] || size > range[2]) {
    tlf_abort(sprintf("Figure font size %g is outside the configured range [%g, %g].",
                      size, range[1], range[2]))
  }
  invisible(size)
}

#' Figure render policy
#'
#' @param isolate Render figures in a child R process (via callr), so a native
#'   crash in the graphics stack cannot kill the calling session.
#' @param retries Extra attempts after a failed isolated render. The default of
#'   2 means up to three attempts in total.
#' @param timeout Per-attempt timeout in seconds. A hung render counts as a
#'   failed attempt.
#' @param dpi Resolution of the embedded PNG.
#' @param log_file Optional CSV path. When set, one row is appended per render
#'   attempt.
#' @return An object of class `tlf_render_opts`.
#' @examples
#' tlf_render_opts(retries = 0)
#' @export
tlf_render_opts <- function(isolate = TRUE, retries = 2L, timeout = 90, dpi = 300,
                            log_file = NULL) {
  if (!is.logical(isolate) || length(isolate) != 1L || is.na(isolate)) tlf_abort("`isolate` must be TRUE or FALSE.")
  retries <- as.integer(retries)
  if (length(retries) != 1L || is.na(retries) || retries < 0L) tlf_abort("`retries` must be a non-negative integer.")
  if (!is.numeric(timeout) || length(timeout) != 1L || timeout <= 0) tlf_abort("`timeout` must be a positive number of seconds.")
  if (!is.numeric(dpi) || length(dpi) != 1L || dpi < 72) tlf_abort("`dpi` must be a number >= 72.")
  if (!is.null(log_file) && (!is.character(log_file) || length(log_file) != 1L)) {
    tlf_abort("`log_file` must be NULL or a single file path.")
  }
  structure(list(isolate = isolate, retries = retries, timeout = timeout, dpi = dpi,
                 log_file = log_file),
            class = "tlf_render_opts")
}

# Paul Tol "bright" qualitative palette: colour-blind safe and public domain.
tol_bright <- c("#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#BBBBBB")

#' Reporting configuration
#'
#' `tlf_config()` bundles every organization-level convention: page geometry,
#' fonts, the running page header, the figure palette, treatment-variable
#' candidates and the figure render policy. The defaults are neutral; an
#' organization usually sets its own once per session (see [tlf_get_config()]).
#'
#' @param page A [tlf_page()] object.
#' @param fonts A [tlf_fonts()] object.
#' @param header_left Text of the left cell of the running page header, for
#'   example an organization name. `""` means no left cell.
#' @param header_right Text of the right cell. r2rtf page fields
#'   `\\pagenumber` and `\\pagefield` are expanded.
#' @param palette Colours used for treatment groups in figures.
#' @param trt_candidates Treatment/grouping variables tried, in order, when the
#'   requested treatment variable is absent from the data.
#' @param render A [tlf_render_opts()] object.
#' @param text_convert Let r2rtf convert LaTeX-like markup in text (for
#'   example `_` to a subscript, `>=` to a symbol)? The default `FALSE`
#'   prints all text verbatim, so titles stay character-identical to their
#'   metadata source and program names such as `t_demo.R` are not mangled.
#' @return An object of class `tlf_config`.
#' @examples
#' cfg <- tlf_config(header_left = "Example Organization")
#' cfg$fonts$text_family
#' @export
tlf_config <- function(page = tlf_page(), fonts = tlf_fonts(),
                       header_left = "", header_right = "Page \\pagenumber of \\pagefield",
                       palette = tol_bright,
                       trt_candidates = c("TRT01A", "TRTA", "TRT01P", "TRTP", "ARM", "ACTARM"),
                       render = tlf_render_opts(), text_convert = FALSE) {
  if (!inherits(page, "tlf_page")) tlf_abort("`page` must be created with tlf_page().")
  if (!inherits(fonts, "tlf_fonts")) tlf_abort("`fonts` must be created with tlf_fonts().")
  if (!inherits(render, "tlf_render_opts")) tlf_abort("`render` must be created with tlf_render_opts().")
  for (nm in c("header_left", "header_right")) {
    v <- get(nm)
    if (!is.character(v) || length(v) != 1L) tlf_abort("`", nm, "` must be a single string.")
  }
  if (!is.character(palette) || !length(palette)) tlf_abort("`palette` must be a non-empty character vector of colours.")
  if (!is.character(trt_candidates)) tlf_abort("`trt_candidates` must be a character vector.")
  if (!is.logical(text_convert) || length(text_convert) != 1L || is.na(text_convert)) {
    tlf_abort("`text_convert` must be TRUE or FALSE.")
  }
  structure(list(page = page, fonts = fonts, header_left = header_left,
                 header_right = header_right, palette = unname(palette),
                 trt_candidates = trt_candidates, render = render,
                 text_convert = text_convert),
            class = "tlf_config")
}

#' @export
print.tlf_config <- function(x, ...) {
  cat("<tlf_config>\n")
  cat(sprintf("  page    : %s %gx%g in, margins %s; figure body %gx%g in\n",
              x$page$orientation, x$page$width, x$page$height,
              paste(x$page$margin, collapse = "/"), x$page$fig_width, x$page$fig_height))
  cat(sprintf("  text    : %s %g (source %g)\n", x$fonts$text_family, x$fonts$text_size, x$fonts$source_size))
  cat(sprintf("  figure  : %s %g (allowed %g-%g)\n", x$fonts$figure_family, x$fonts$figure_size,
              x$fonts$figure_size_range[1], x$fonts$figure_size_range[2]))
  cat(sprintf("  header  : left='%s' right='%s'\n", x$header_left, x$header_right))
  cat(sprintf("  render  : isolate=%s retries=%d timeout=%gs dpi=%g\n", x$render$isolate,
              x$render$retries, x$render$timeout, x$render$dpi))
  invisible(x)
}

#' Modify a configuration
#'
#' Returns a modified copy; the input is left unchanged.
#'
#' @param config A [tlf_config()] object.
#' @param ... Named fields of [tlf_config()] to replace.
#' @return A new `tlf_config`.
#' @examples
#' cfg <- tlf_config_update(tlf_config(), header_left = "Example Organization")
#' @export
tlf_config_update <- function(config, ...) {
  if (!inherits(config, "tlf_config")) tlf_abort("`config` must be a tlf_config object.")
  changes <- list(...)
  if (!length(changes)) return(config)
  bad <-setdiff(names(changes), names(formals(tlf_config)))
  if (length(bad) || is.null(names(changes)) || any(!nzchar(names(changes)))) {
    tlf_abort("Unknown or unnamed configuration field(s): ", paste(bad, collapse = ", "), ".")
  }
  args <- unclass(config)
  args[names(changes)] <- changes
  do.call(tlf_config, args)
}

#' Read a configuration file
#'
#' Reads a YAML file with optional top-level keys `page`, `fonts`,
#' `header_left`, `header_right`, `palette`, `trt_candidates` and `render`.
#' The `page`, `fonts` and `render` keys hold the arguments of [tlf_page()],
#' [tlf_fonts()] and [tlf_render_opts()]. This function requires the yaml
#' package.
#'
#' @param path Path to a YAML file.
#' @return A `tlf_config`.
#' @examples
#' f <- tempfile(fileext = ".yml")
#' writeLines(c("header_left: Example Organization", "fonts:", "  text_size: 8"), f)
#' tlf_config_read(f)
#' unlink(f)
#' @export
tlf_config_read <- function(path) {
  rlang::check_installed("yaml", reason = "to read configuration files.")
  if (!file.exists(path)) tlf_abort("Configuration file not found: ", path)
  y <- yaml::read_yaml(path)
  if (is.null(y)) y <- list()
  known <- names(formals(tlf_config))
  bad <- setdiff(names(y), known)
  if (length(bad)) tlf_abort("Unknown key(s) in ", basename(path), ": ", paste(bad, collapse = ", "), ".")
  args <- y
  if (!is.null(y$page)) {
    if (!is.null(y$page$paper)) y$page$paper <- unlist(y$page$paper)
    if (!is.null(y$page$margin)) y$page$margin <- unlist(y$page$margin)
    args$page <- do.call(tlf_page, y$page)
  }
  if (!is.null(y$fonts)) {
    if (!is.null(y$fonts$figure_size_range)) y$fonts$figure_size_range <- unlist(y$fonts$figure_size_range)
    args$fonts <- do.call(tlf_fonts, y$fonts)
  }
  if (!is.null(y$render)) args$render <- do.call(tlf_render_opts, y$render)
  if (!is.null(y$palette)) args$palette <- unlist(y$palette)
  if (!is.null(y$trt_candidates)) args$trt_candidates <- unlist(y$trt_candidates)
  do.call(tlf_config, args)
}

#' Resolve the active configuration
#'
#' Every function that takes a `config` argument resolves it through
#' `tlf_get_config()`. The first available source wins:
#'
#' 1. The `config` argument itself.
#' 2. The session option `tlfstack.config`. This is the hook a site profile or
#'    environment-setup function uses to apply organization conventions once
#'    per session.
#' 3. A YAML file named by the environment variable `TLFSTACK_CONFIG`.
#' 4. The package defaults, [tlf_config()].
#'
#' @param config `NULL` or a `tlf_config`.
#' @return A `tlf_config`.
#' @examples
#' tlf_get_config()
#' old <- options(tlfstack.config = tlf_config(header_left = "Example Organization"))
#' tlf_get_config()$header_left
#' options(old)
#' @export
tlf_get_config <- function(config = NULL) {
  if (!is.null(config)) {
    if (!inherits(config, "tlf_config")) tlf_abort("`config` must be a tlf_config object.")
    return(config)
  }
  opt <- getOption("tlfstack.config")
  if (!is.null(opt)) {
    if (!inherits(opt, "tlf_config")) tlf_abort("Option `tlfstack.config` must hold a tlf_config object.")
    return(opt)
  }
  path <- Sys.getenv("TLFSTACK_CONFIG", "")
  if (nzchar(path)) return(tlf_config_read(path))
  tlf_config()
}
