# Title-block model. A tlf_titles object keeps every part of the title block in
# its own field, so renderers place each part by convention and an auditor can
# diff any field against its metadata source.

#' Title block of one output
#'
#' Creates the structured title block that the RTF renderers consume:
#'
#' * `pre_title`: lines printed above the banner, such as a study identifier or
#'   data cut-off.
#' * `banner`: the output label, such as `"Table 14.1.1"`.
#' * `title`, `subtitle`: title lines below the banner.
#' * `footnotes`, `source`: printed below the body, in that order.
#'
#' Use `tlf_titles()` directly when no table-of-contents source exists, or
#' get one from [tlf_resolve_titles()].
#'
#' @param title Character vector of title lines (at least one).
#' @param banner Output label. `NULL` builds one from `type` and `number`.
#' @param type Output type: `"Table"`, `"Figure"` or `"Listing"`.
#' @param number Output number, for example `"14.1.1"`.
#' @param subtitle Character vector of subtitle lines.
#' @param footnotes Character vector of footnotes, in display order.
#' @param pre_title Character vector of lines placed above the banner.
#' @param source Source line, for example the producing program's path.
#' @param output_file_name File name of the deliverable. `NULL` means the
#'   caller decides.
#' @param vars Named list of values substituted for `{name}` placeholders in
#'   every text field (see Details).
#' @param provenance List describing where the titles came from. It is filled
#'   in by [tlf_resolve_titles()]; manual titles get `mode = "manual"`.
#'
#' @details
#' Placeholders: a field such as `"Summary of {param} by Visit"` is filled from
#' `vars`. A placeholder with no value is left visible and triggers a warning,
#' so an unfilled title can never pass for a finished one.
#'
#' @return An object of class `tlf_titles`.
#' @examples
#' tlf_titles(
#'   title = "Summary of Demographics",
#'   type = "Table", number = "14.1.1",
#'   subtitle = "Safety Population",
#'   footnotes = "Percentages are based on N in each column."
#' )
#' @export
tlf_titles <- function(title, banner = NULL, type = c("Table", "Figure", "Listing"),
                       number = NULL, subtitle = character(), footnotes = character(),
                       pre_title = character(), source = "", output_file_name = NULL,
                       vars = list(), provenance = list(mode = "manual")) {
  type <- match.arg(type)
  check_text(title, "title", min_len = 1L)
  for (nm in c("subtitle", "footnotes", "pre_title")) check_text(get(nm), nm)
  if (!is.character(source) || length(source) > 1L) tlf_abort("`source` must be a single string.")
  if (!is.list(vars) || (length(vars) && is.null(names(vars)))) tlf_abort("`vars` must be a named list.")
  number <- if (is_blank(number)) "" else trimws(as.character(number))
  if (is.null(banner)) banner <- trimws(paste(type, number))
  out <- list(banner = banner, title = title, subtitle = subtitle, footnotes = footnotes,
              pre_title = pre_title, source = or_default(source, ""), type = type,
              number = number, output_file_name = output_file_name,
              provenance = provenance)
  fill_placeholders(structure(out, class = "tlf_titles"), vars)
}

check_text <- function(x, arg, min_len = 0L) {
  if (!is.character(x) || length(x) < min_len || anyNA(x)) {
    tlf_abort("`", arg, "` must be a character vector without NA",
              if (min_len) sprintf(" (at least %d element)", min_len), ".")
  }
  invisible(x)
}

text_fields <- c("banner", "title", "subtitle", "footnotes", "pre_title", "source", "output_file_name")

fill_placeholders <- function(x, vars) {
  sub_one <- function(s) {
    for (nm in names(vars)) s <- gsub(paste0("{", nm, "}"), as.character(vars[[nm]]), s, fixed = TRUE)
    s
  }
  for (f in text_fields) if (!is.null(x[[f]])) x[[f]] <- sub_one(x[[f]])
  left <- unique(unlist(lapply(text_fields, function(f) {
    regmatches(x[[f]], gregexpr("\\{[A-Za-z][A-Za-z0-9_.]*\\}", x[[f]]))
  })))
  if (length(left)) {
    tlf_warn("Unfilled title placeholder(s): ", paste(left, collapse = ", "),
             ". Supply them through `vars`.", class = "tlfstack_unfilled_placeholder")
  }
  x
}

#' @export
print.tlf_titles <- function(x, ...) {
  cat(sprintf("<tlf_titles> mode: %s\n", or_default(x$provenance$mode, "?")))
  show <- function(lab, v) if (length(v) && any(nzchar(v))) cat(sprintf("  %-9s %s\n", lab, v), sep = "")
  show("pre:", x$pre_title)
  show("banner:", x$banner)
  show("title:", x$title)
  show("subtitle:", x$subtitle)
  show("footnote:", x$footnotes)
  show("source:", x$source)
  show("file:", or_default(x$output_file_name, ""))
  invisible(x)
}

#' Add footnotes to a title block
#'
#' Appends footnotes after the existing ones and drops exact duplicates,
#' keeping the first occurrence. Renderers use this to place builder-derived
#' notes (for example a hazard ratio) after the table-of-contents footnotes.
#'
#' @param titles A [tlf_titles()] object.
#' @param footnotes Character vector to append.
#' @return A new `tlf_titles`.
#' @examples
#' t <- tlf_titles("Overall Survival", type = "Figure", number = "14.2.1")
#' tlf_titles_add_footnotes(t, "Log-rank p-value: 0.032")$footnotes
#' @export
tlf_titles_add_footnotes <- function(titles, footnotes) {
  if (!inherits(titles, "tlf_titles")) tlf_abort("`titles` must be a tlf_titles object.")
  check_text(footnotes, "footnotes")
  titles$footnotes <- unique(c(titles$footnotes, footnotes))
  titles
}

# All lines of the title block, top to bottom, as rendered.
title_block_lines <- function(titles) {
  c(titles$pre_title, titles$banner, titles$title, titles$subtitle)
}

as_titles <- function(titles, type) {
  if (is.null(titles)) {
    return(tlf_titles(title = " ", banner = "", type = type,
                      provenance = list(mode = "none")))
  }
  if (inherits(titles, "tlf_titles")) return(titles)
  if (is.character(titles)) return(tlf_titles(title = titles, banner = "", type = type))
  tlf_abort("`titles` must be a tlf_titles object, a character vector, or NULL.")
}
