# Registry + dispatcher. A typed request (type key + data + options) is routed
# to a builder, identically from a batch program or an interactive app.

.registry <- new.env(parent = emptyenv())
.registry$table <- list()
.registry$figure <- list()

#' Register a builder
#'
#' Adds a table/listing or figure type to the dispatcher, or replaces an
#' existing one. This lets an organization add study-specific outputs that
#' run through the same renderers.
#'
#' @param type Type key, for example `"vitals"`.
#' @param fun For tables: `function(data, opts, config)`, where `data` is a
#'   named list of data frames; it must return a [tlf_table_result()], a data
#'   frame, a gtsummary table or a cards `card` (see [as_tlf_table()]). For
#'   figures: `function(df, ctx, opts, config)`; it must return a ggplot.
#' @param label Human-readable label, for example for a selection menu.
#' @param class For tables: `"Table"` or `"Listing"`.
#' @param domains Names of the `data` elements the builder reads.
#' @return `type`, invisibly.
#' @examples
#' tlf_register_table("n_by_arm", function(data, opts, config) {
#'   n <- stat_big_n(data$adsl, "TRT01A")
#'   tlf_table_result(data.frame(Group = names(n), N = as.character(n)))
#' }, label = "Subjects by arm", domains = "adsl")
#' tlf_build_table("n_by_arm", list(adsl = ex_adsl))
#' tlf_unregister("n_by_arm")
#' @export
tlf_register_table <- function(type, fun, label = type, class = c("Table", "Listing"),
                               domains = character()) {
  check_type_key(type)
  if (!is.function(fun)) tlf_abort("`fun` must be a function(data, opts, config).")
  .registry$table[[type]] <- list(fun = fun, label = label, class = match.arg(class),
                                  domains = domains)
  invisible(type)
}

#' @rdname tlf_register_table
#' @export
tlf_register_figure <- function(type, fun, label = type) {
  check_type_key(type)
  if (!is.function(fun)) tlf_abort("`fun` must be a function(df, ctx, opts, config).")
  .registry$figure[[type]] <- list(fun = fun, label = label)
  invisible(type)
}

#' @rdname tlf_register_table
#' @param kind Which registry to remove `type` from.
#' @export
tlf_unregister <- function(type, kind = c("table", "figure")) {
  kind <- match.arg(kind)
  .registry[[kind]][[type]] <- NULL
  invisible(type)
}

check_type_key <- function(type) {
  if (!is.character(type) || length(type) != 1L || !grepl("^[A-Za-z][A-Za-z0-9_]*$", type)) {
    tlf_abort("`type` must be a single identifier, such as 'ae_severity'.")
  }
}

#' Registered types
#'
#' @return A data frame with one row per registered type: `type`, `label`,
#'   and for tables also `class` and `domains`.
#' @examples
#' tlf_table_types()
#' tlf_figure_types()
#' @export
tlf_table_types <- function() {
  r <- .registry$table
  data.frame(type = names(r), label = vapply(r, `[[`, "", "label"),
             class = vapply(r, `[[`, "", "class"),
             domains = vapply(r, function(e) paste(e$domains, collapse = ", "), ""),
             row.names = NULL, stringsAsFactors = FALSE)
}

#' @rdname tlf_table_types
#' @export
tlf_figure_types <- function() {
  r <- .registry$figure
  data.frame(type = names(r), label = vapply(r, `[[`, "", "label"),
             row.names = NULL, stringsAsFactors = FALSE)
}

#' Build a registered table, listing or figure
#'
#' The dispatcher. Batch programs and interactive apps make the same call,
#' so both get the same object, and the same renderer then produces the same
#' RTF content.
#'
#' @param type A registered type key (see [tlf_table_types()] and
#'   [tlf_figure_types()]).
#' @param data Named list of data frames, for example
#'   `list(adsl = adsl, adae = adae)`.
#' @param df Analysis data frame for a figure.
#' @param ctx A [fig_ctx()] list.
#' @param opts Named list of builder options, for example
#'   `list(trt_var = "TRTA", paramcd = "ALT")`.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @return A `tlf_table` (tables) or a ggplot (figures).
#' @examples
#' tlf_build_table("demographics", list(adsl = ex_adsl))
#' p <- tlf_build_figure("meanci", ex_adlb[ex_adlb$PARAMCD == "ALT", ])
#' @export
tlf_build_table <- function(type, data, opts = list(), config = NULL) {
  entry <- .registry$table[[type]]
  if (is.null(entry)) tlf_abort("Unknown table type '", type, "'. See tlf_table_types().")
  if (!is.list(data) || is.data.frame(data)) tlf_abort("`data` must be a named list of data frames.")
  miss <- setdiff(entry$domains[1], names(data))
  if (length(entry$domains) && length(miss)) tlf_abort("Table type '", type, "' needs data$", miss, ".")
  out <- entry$fun(data, opts, config)
  if (!inherits(out, c("tlf_table", "data.frame", "gtsummary", "card"))) {
    tlf_abort("Builder for '", type, "' did not return a tlf_table, data frame, gtsummary table or card.")
  }
  as_tlf_table(out)
}

#' @rdname tlf_build_table
#' @export
tlf_build_figure <- function(type, df, ctx = fig_ctx(), opts = list(), config = NULL) {
  entry <- .registry$figure[[type]]
  if (is.null(entry)) tlf_abort("Unknown figure type '", type, "'. See tlf_figure_types().")
  out <- entry$fun(df, ctx, opts, config)
  if (!inherits(out, "ggplot")) tlf_abort("Builder for '", type, "' did not return a ggplot.")
  out
}

# Call `fun` with the options it accepts.
call_with_opts <- function(fun, fixed, opts) {
  ok <- opts[intersect(names(opts), setdiff(names(formals(fun)), names(fixed)))]
  do.call(fun, c(fixed, ok))
}

register_builtins <- function() {
  reg_tbl <- function(type, label, fun, domains, class = "Table", first = domains[1]) {
    tlf_register_table(type, function(data, opts, config) {
      fixed <- list(data[[first]], config = config)
      if ("adsl" %in% domains && first != "adsl") fixed$adsl <- data$adsl
      call_with_opts(fun, fixed, opts)
    }, label = label, class = class, domains = domains)
  }
  reg_tbl("demographics", "Demographics and baseline characteristics", tbl_demographics, "adsl")
  reg_tbl("disposition", "Subject disposition", tbl_disposition, "adsl")
  reg_tbl("ae", "Adverse events by SOC and PT", tbl_ae, c("adae", "adsl"))
  reg_tbl("ae_severity", "Adverse events by maximum severity", tbl_ae_severity, c("adae", "adsl"))
  reg_tbl("eff", "Summary by visit (observed or change from baseline)", tbl_eff, "bds")
  reg_tbl("shift", "Shift: baseline vs endpoint category", tbl_shift, "bds")
  reg_tbl("tte", "Time to event: KM medians, Cox HR, log-rank", tbl_tte, "adtte")
  listing <- function(type, label, cols, domain) {
    tlf_register_table(type, function(data, opts, config) {
      tbl_listing(data[[domain]], or_default(opts$cols, cols))
    }, label = label, class = "Listing", domains = domain)
  }
  listing("listing_ae", "Listing of adverse events", listing_cols_ae, "adae")
  listing("listing_lab", "Listing of laboratory results", listing_cols_lab, "bds")

  fg <- function(type, label, fun, fixed = list()) {
    tlf_register_figure(type, function(df, ctx, opts, config) {
      call_with_opts(fun, c(list(df, ctx = ctx, config = config), fixed), opts)
    }, label = label)
  }
  fg("meanci", "Mean (CI) by visit", fig_meanci, list(value_col = "AVAL"))
  fg("meanci_chg", "Mean (CI) change from baseline by visit", fig_meanci, list(value_col = "CHG"))
  fg("boxplot", "Box plot by visit", fig_boxplot)
  fg("spaghetti", "Individual subject profiles", fig_spaghetti, list(value_col = "AVAL"))
  fg("spaghetti_chg", "Individual change-from-baseline profiles", fig_spaghetti, list(value_col = "CHG"))
  fg("lsmeans", "LS-means by visit", fig_lsmeans, list(value_col = "AVAL"))
  fg("lsmeans_chg", "LS-means of change from baseline by visit", fig_lsmeans, list(value_col = "CHG"))
  fg("km", "Kaplan-Meier curve", fig_km)
  fg("forest", "Subgroup forest plot", fig_forest)
  fg("waterfall", "Waterfall of best % change", fig_waterfall)
  fg("edish", "eDISH (Hy's Law) plot", fig_edish)
  fg("shift", "Shift plot", fig_shift)
  invisible(NULL)
}

.onLoad <- function(libname, pkgname) {
  register_builtins()
}
