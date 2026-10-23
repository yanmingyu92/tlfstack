# Summary-statistic primitives. They return plain data frames with character
# cells exactly as they print, so several variables can be stacked into one
# table body. The long layout is: param | label | stat | <one column per group>.

#' Format p-values
#'
#' Values at or above `10^-digits` are shown with `digits` decimals. Smaller
#' values are shown as `"<0.001"` (for `digits = 3`). Missing or non-finite
#' values become `""`.
#'
#' @param p Numeric vector of p-values.
#' @param digits Number of decimals.
#' @return Character vector the same length as `p`.
#' @examples
#' format_pvalue(c(0.0321, 0.0004, NA))
#' @export
format_pvalue <- function(p, digits = 3L) {
  thresh <- 10^(-digits)
  out <- formatC(p, format = "f", digits = digits)
  out[!is.na(p) & is.finite(p) & p < thresh] <- paste0("<", format(thresh, scientific = FALSE))
  out[is.na(p) | !is.finite(p)] <- ""
  out
}

#' Population counts per group
#'
#' Counts distinct subjects per treatment group, for "N=xx" column headers.
#'
#' @param df Data frame.
#' @param trt_var Treatment/grouping column. Group order follows factor
#'   levels when it is a factor, otherwise sorted values.
#' @param id_var Subject identifier column.
#' @param total Add a total column?
#' @param total_label Name of the total column.
#' @return Named integer vector, one element per group (plus the total).
#' @examples
#' stat_big_n(ex_adsl, "TRT01A")
#' @export
stat_big_n <- function(df, trt_var, id_var = "USUBJID", total = TRUE, total_label = "Total") {
  check_cols(df, c(trt_var, id_var))
  d <- df[!is.na(df[[trt_var]]), , drop = FALSE]
  grp <- as.character(d[[trt_var]])
  lv <- arm_levels(d[[trt_var]])
  out <- vapply(lv, function(g) length(unique(d[[id_var]][grp == g])), integer(1))
  names(out) <- lv
  if (isTRUE(total)) out[[total_label]] <- length(unique(d[[id_var]]))
  out
}

# Group columns, in display order, for a treatment variable.
group_levels <- function(df, trt_var) {
  arm_levels(df[[trt_var]])
}

#' Descriptive statistics for a continuous variable
#'
#' Returns n, Mean (SD), Median (Q1, Q3) and Min, Max per group. Quartiles
#' use `stats::quantile(type = 2)`, which is the analogue of the SAS default
#' percentile definition (PCTLDEF=5).
#'
#' @param df Data frame.
#' @param var Analysis column.
#' @param trt_var Treatment/grouping column.
#' @param label Row label for the block.
#' @param digits Decimals for the mean, SD, median and quartiles.
#' @param total Add a total column?
#' @param total_label Name of the total column.
#' @return Data frame with columns `param`, `label`, `stat` and one column per
#'   group.
#' @examples
#' stat_desc(ex_adsl, "AGE", "TRT01A", label = "Age (years)")
#' @export
stat_desc <- function(df, var, trt_var, label = var, digits = 1L, total = TRUE,
                      total_label = "Total") {
  check_cols(df, c(var, trt_var))
  fmt <- function(x) formatC(x, format = "f", digits = digits)
  one <- function(x) {
    v <- suppressWarnings(as.numeric(x))
    v <- v[!is.na(v)]
    if (!length(v)) return(c("0", "", "", ""))
    q <- stats::quantile(v, c(0.25, 0.5, 0.75), names = FALSE, type = 2)
    sd_txt <- if (length(v) > 1L) fmt(stats::sd(v)) else "NE"
    c(as.character(length(v)),
      sprintf("%s (%s)", fmt(mean(v)), sd_txt),
      sprintf("%s (%s, %s)", fmt(q[2]), fmt(q[1]), fmt(q[3])),
      sprintf("%s, %s", fmt(min(v)), fmt(max(v))))
  }
  grp <- as.character(df[[trt_var]])
  out <- data.frame(param = label, label = label,
                    stat = c("n", "Mean (SD)", "Median (Q1, Q3)", "Min, Max"),
                    stringsAsFactors = FALSE)
  for (g in group_levels(df, trt_var)) out[[g]] <- one(df[[var]][!is.na(grp) & grp == g])
  if (isTRUE(total)) out[[total_label]] <- one(df[[var]][!is.na(grp)])
  out
}

#' Frequency table for a categorical variable
#'
#' Returns n (%) per category and group. The denominator is the number of
#' distinct subjects in each group. A zero count prints as `"0"`.
#'
#' @inheritParams stat_desc
#' @param id_var Subject identifier column.
#' @param levels_order Optional category order. The default is sorted
#'   categories.
#' @return Data frame with columns `param`, `label`, `stat` (the category) and
#'   one column per group.
#' @examples
#' stat_freq(ex_adsl, "SEX", "TRT01A", label = "Sex")
#' @export
stat_freq <- function(df, var, trt_var, label = var, id_var = "USUBJID", digits = 1L,
                      total = TRUE, total_label = "Total", levels_order = NULL) {
  check_cols(df, c(var, trt_var, id_var))
  denom <- stat_big_n(df, trt_var, id_var = id_var, total = total, total_label = total_label)
  d <- df[!is.na(df[[var]]) & !is.na(df[[trt_var]]), , drop = FALSE]
  lv <- or_default(levels_order, sort(unique(as.character(d[[var]]))))
  grp <- as.character(d[[trt_var]])
  val <- as.character(d[[var]])
  out <- data.frame(param = label, label = label, stat = lv, stringsAsFactors = FALSE)
  for (g in names(denom)) {
    in_g <- if (isTRUE(total) && g == total_label) rep(TRUE, nrow(d)) else grp == g
    n <- vapply(lv, function(l) length(unique(d[[id_var]][in_g & val == l])), integer(1))
    out[[g]] <- fmt_npct(n, rep(denom[[g]], length(n)), digits)
  }
  out
}
