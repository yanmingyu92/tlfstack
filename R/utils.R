#' @importFrom rlang .data
#' @keywords internal
"_PACKAGE"

# Return `default` when `x` is NULL or zero-length. Unlike some ad hoc helpers,
# a length-one NA is a real value and is returned as-is.
or_default <- function(x, default) {
  if (is.null(x) || length(x) == 0L) default else x
}

# TRUE for NULL, NA, or an all-whitespace string.
is_blank <- function(x) {
  is.null(x) || length(x) == 0L || (length(x) == 1L && (is.na(x) || !nzchar(trimws(x))))
}

tlf_abort <- function(..., class = NULL) {
  rlang::abort(paste0(...), class = c(class, "tlfstack_error"))
}

tlf_warn <- function(..., class = NULL) {
  rlang::warn(paste0(...), class = c(class, "tlfstack_warning"))
}

check_df <- function(x, arg = "data") {
  if (!is.data.frame(x)) tlf_abort("`", arg, "` must be a data frame.")
  if (!nrow(x)) tlf_abort("`", arg, "` has no rows.")
  invisible(x)
}

check_cols <- function(df, cols, what = "data") {
  miss <- setdiff(cols, names(df))
  if (length(miss)) {
    tlf_abort(what, " is missing required column(s): ", paste(miss, collapse = ", "), ".")
  }
  invisible(df)
}

# Format "n (pct%)" with the zero convention: a zero count prints as "0".
fmt_npct <- function(n, denom, digits = 1L) {
  out <- character(length(n))
  zero <- n == 0L | is.na(denom) | denom == 0L
  out[zero] <- "0"
  out[!zero] <- sprintf("%d (%s%%)", as.integer(n[!zero]),
                        formatC(100 * n[!zero] / denom[!zero], format = "f", digits = digits))
  out
}

# Display order of treatment groups: factor levels (those present) when the
# column is a factor, otherwise sorted values.
arm_levels <- function(x) {
  if (is.factor(x)) return(levels(droplevels(x[!is.na(x)])))
  sort(unique(as.character(x[!is.na(x)])))
}

# Visit order: AVISIT ordered by AVISITN when both are present.
visit_levels <- function(df, visit_col = "AVISIT", visitn_col = "AVISITN") {
  if (visit_col == "AVISIT" && all(c(visit_col, visitn_col) %in% names(df))) {
    uv <- unique(df[!is.na(df[[visit_col]]), c(visitn_col, visit_col), drop = FALSE])
    uv <- uv[order(uv[[visitn_col]]), , drop = FALSE]
    return(unique(as.character(uv[[visit_col]])))
  }
  sort(unique(as.character(stats::na.omit(df[[visit_col]]))))
}

# Single unit label from AVALU, or NULL when absent / ambiguous.
single_unit <- function(df, col = "AVALU") {
  if (!col %in% names(df)) return(NULL)
  u <- unique(df[[col]][!is.na(df[[col]]) & nzchar(df[[col]])])
  if (length(u) == 1L) u else NULL
}
