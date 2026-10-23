#' Synthetic example data
#'
#' Small simulated ADaM-like datasets for examples, tests and vignettes. All
#' values are randomly generated and describe no real study.
#'
#' * `ex_adsl`: subject level, 60 subjects, three arms (`TRT01A`).
#' * `ex_adae`: adverse events (`AESOC`, `AEDECOD`, `AESEV`, `TRTEMFL`).
#' * `ex_adlb`: laboratory BDS for `ALT`, `AST` and `BILI` at four visits,
#'   with `BASE`, `CHG`, `PCHG` and reference ranges.
#' * `ex_adtte`: time to event (`AVAL` in days, `CNSR == 1` censored).
#'
#' @format Data frames.
#' @source Simulated; see `data-raw/make_example_data.R` in the package
#'   sources.
#' @name example_data
#' @aliases ex_adsl ex_adae ex_adlb ex_adtte
#' @keywords datasets
NULL

#' Example table of contents
#'
#' A canonical TOC table (see [toc_read()]) with six outputs. The two `t_eff`
#' rows share a program and are selected by `number`. Some titles use a
#' `{param}` placeholder. Rows with a blank `study` apply to every study.
#'
#' @format A data frame with list columns `title`, `subtitle` and
#'   `footnotes`.
#' @source Simulated.
#' @examples
#' ex_toc[, c("program", "number", "study")]
#' @keywords datasets
"ex_toc"
