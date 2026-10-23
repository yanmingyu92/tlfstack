# Table and listing builders. The contract: a builder takes already-read data
# frames and returns a tlf_table result. It never reads data, writes files,
# touches the TOC or opens a graphics device, so the same call serves batch
# programs, interactive previews and device-free tests.

#' Builder result
#'
#' The fixed shape every table and listing builder returns, so a renderer can
#' be written once against it.
#'
#' @param df Data frame whose character cells are printed as-is.
#' @param col_rel_width Relative column widths (one per column).
#' @param text_justification Body justification, recycled across columns.
#' @param footnotes Builder-derived footnotes, appended after the title-block
#'   footnotes at render time.
#' @param meta A list of provenance notes, such as the resolved treatment
#'   variable or skipped variables.
#' @return An object of class `tlf_table`.
#' @examples
#' tlf_table_result(data.frame(a = "1"))
#' @export
tlf_table_result <- function(df, col_rel_width = NULL, text_justification = "l",
                             footnotes = character(), meta = list()) {
  if (!is.data.frame(df)) tlf_abort("`df` must be a data frame.")
  col_rel_width <- or_default(col_rel_width, rep(1, ncol(df)))
  if (length(col_rel_width) != ncol(df)) tlf_abort("`col_rel_width` must have one value per column.")
  structure(list(df = df, col_rel_width = col_rel_width,
                 text_justification = text_justification, footnotes = footnotes,
                 meta = meta),
            class = "tlf_table")
}

#' @export
print.tlf_table <- function(x, ...) {
  cat(sprintf("<tlf_table> %d row(s) x %d column(s)\n", nrow(x$df), ncol(x$df)))
  print(utils::head(x$df, 20L), row.names = FALSE, right = FALSE)
  if (nrow(x$df) > 20L) cat("...\n")
  if (length(x$footnotes)) cat(paste0("Note: ", x$footnotes, "\n"), sep = "")
  invisible(x)
}

#' Resolve the treatment variable
#'
#' Returns `trt_var` when it is a column of `df`. Otherwise it returns the
#' first configured candidate (see [tlf_config()]) present in the data, with a
#' message. It errors when there is none.
#'
#' @param df Data frame.
#' @param trt_var Requested treatment/grouping column.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @return A column name.
#' @examples
#' tlf_resolve_trt(ex_adsl, "TRTXX")
#' @export
tlf_resolve_trt <- function(df, trt_var = "TRT01A", config = NULL) {
  if (!is.null(trt_var) && !is.na(trt_var) && trt_var %in% names(df)) return(trt_var)
  alt <- intersect(tlf_get_config(config)$trt_candidates, names(df))
  if (!length(alt)) tlf_abort("No treatment/grouping variable found in the data.")
  message("Using '", alt[1], "' as the treatment variable ('", trt_var, "' not found).")
  alt[1]
}

# Drop rows whose treatment value is missing or blank: a blank group is never a
# valid output column.
drop_blank_trt <- function(df, trt_var) {
  v <- as.character(df[[trt_var]])
  df[!is.na(v) & nzchar(trimws(v)), , drop = FALSE]
}

prepare_trt <- function(df, trt_var, config, what) {
  check_df(df, what)
  trt_var <- tlf_resolve_trt(df, trt_var, config)
  df <- drop_blank_trt(df, trt_var)
  if (!nrow(df)) tlf_abort("No rows with a non-blank '", trt_var, "' value in ", what, ".")
  list(df = df, trt_var = trt_var)
}

filter_param <- function(df, paramcd) {
  if (is_blank(paramcd)) return(df)
  check_cols(df, "PARAMCD")
  out <- df[!is.na(df$PARAMCD) & df$PARAMCD == paramcd, , drop = FALSE]
  if (!nrow(out)) tlf_abort("No rows with PARAMCD == '", paramcd, "'.")
  out
}

# Distinct-subject denominators per group plus Total.
denominators <- function(pop, trt_var, id_var = "USUBJID") {
  stat_big_n(pop, trt_var, id_var = id_var, total = TRUE, total_label = "Total")
}

# One n (%) row: distinct subjects in `sub` per group, over `denom`.
npct_row <- function(sub, trt_var, denom, id_var = "USUBJID") {
  grp <- as.character(sub[[trt_var]])
  n <- vapply(names(denom), function(g) {
    ids <- if (g == "Total") sub[[id_var]] else sub[[id_var]][!is.na(grp) & grp == g]
    length(unique(ids))
  }, integer(1))
  fmt_npct(n, denom)
}

label_with_n <- function(groups, denom) sprintf("%s (N=%d)", groups, denom[groups])

# Stack long summaries (param | label | stat | groups) into a display frame.
stack_blocks <- function(blocks, first_col, df, trt_var) {
  tbl <- do.call(rbind, blocks)
  grp_cols <- setdiff(names(tbl), c("param", "label", "stat"))
  disp <- data.frame(ifelse(!duplicated(tbl$param), tbl$label, ""), tbl$stat,
                     tbl[grp_cols], check.names = FALSE, stringsAsFactors = FALSE)
  names(disp)[1:2] <- c(first_col, "Statistic")
  big_n <- denominators(df, trt_var)
  names(disp)[-(1:2)] <- label_with_n(grp_cols, big_n)
  disp
}

#' Demographics and baseline characteristics
#'
#' Stacks continuous blocks ([stat_desc()]) and categorical blocks
#' ([stat_freq()]) with big-N column headers. Requested variables missing
#' from the data are skipped and recorded in `meta$skipped`.
#'
#' @param adsl Subject-level data.
#' @param trt_var Treatment variable (resolved with [tlf_resolve_trt()]).
#' @param cont_vars Named list: continuous variable = row label.
#' @param cat_vars Named list: categorical variable = row label.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_demographics(ex_adsl)
#' @export
tbl_demographics <- function(adsl, trt_var = "TRT01A",
                             cont_vars = list(AGE = "Age (years)"),
                             cat_vars = list(SEX = "Sex", RACE = "Race", ETHNIC = "Ethnicity",
                                             AGEGR1 = "Age group"),
                             config = NULL) {
  p <- prepare_trt(adsl, trt_var, config, "adsl")
  d <- p$df
  present <- function(v) intersect(names(v), names(d))
  skipped <- setdiff(c(names(cont_vars), names(cat_vars)), names(d))
  blocks <- c(
    lapply(present(cont_vars), function(v) stat_desc(d, v, p$trt_var, label = cont_vars[[v]])),
    lapply(present(cat_vars), function(v) stat_freq(d, v, p$trt_var, label = cat_vars[[v]]))
  )
  if (!length(blocks)) tlf_abort("None of the requested analysis variables are in adsl.")
  disp <- stack_blocks(blocks, "Characteristic", d, p$trt_var)
  tlf_table_result(disp,
    col_rel_width = c(2.2, 1.6, rep(1, ncol(disp) - 2)),
    text_justification = c("l", "l", rep("c", ncol(disp) - 2)),
    meta = list(trt_var = p$trt_var, skipped = skipped))
}

ae_population <- function(adae, adsl, trt_var) {
  if (!is.null(adsl) && trt_var %in% names(adsl)) drop_blank_trt(adsl, trt_var) else adae
}

teae_filter <- function(adae, teae_flag) {
  if (is.null(teae_flag) || !teae_flag %in% names(adae)) return(adae)
  out <- adae[!is.na(adae[[teae_flag]]) & adae[[teae_flag]] == "Y", , drop = FALSE]
  if (!nrow(out)) tlf_abort("No treatment-emergent AE rows (", teae_flag, " == 'Y').")
  out
}

# Names of `x` ordered by decreasing distinct-subject count, ties alphabetical.
order_by_subjects <- function(ids, x) {
  n <- tapply(ids, x, function(v) length(unique(v)))
  names(n)[order(-n, names(n))]
}

#' Adverse events by system organ class and preferred term
#'
#' Counts subjects with at least one event. SOCs and PTs are sorted by
#' decreasing frequency, with ties broken alphabetically. Denominators come
#' from `adsl` when given, otherwise from `adae`.
#'
#' @param adae Adverse-event data.
#' @param adsl Optional subject-level data for denominators.
#' @param soc_var,pt_var SOC and PT columns.
#' @param teae_flag Treatment-emergent flag column (`"Y"` rows are kept);
#'   `NULL` keeps all events.
#' @inheritParams tbl_demographics
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_ae(ex_adae, ex_adsl)
#' @export
tbl_ae <- function(adae, adsl = NULL, trt_var = "TRT01A", soc_var = "AESOC",
                   pt_var = "AEDECOD", teae_flag = "TRTEMFL", config = NULL) {
  p <- prepare_trt(adae, trt_var, config, "adae")
  check_cols(p$df, c("USUBJID", soc_var, pt_var), "adae")
  ae <- teae_filter(p$df, teae_flag)
  denom <- denominators(ae_population(ae, adsl, p$trt_var), p$trt_var)
  rows <- list(c("Subjects with at least one TEAE", npct_row(ae, p$trt_var, denom)))
  socs <- order_by_subjects(ae$USUBJID, ae[[soc_var]])
  for (soc in socs) {
    s <- ae[ae[[soc_var]] == soc, , drop = FALSE]
    rows[[length(rows) + 1L]] <- c(soc, npct_row(s, p$trt_var, denom))
    for (pt in order_by_subjects(s$USUBJID, s[[pt_var]])) {
      rows[[length(rows) + 1L]] <- c(paste0("  ", pt),
                                     npct_row(s[s[[pt_var]] == pt, , drop = FALSE], p$trt_var, denom))
    }
  }
  disp <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(disp) <- c("System Organ Class / Preferred Term", label_with_n(names(denom), denom))
  tlf_table_result(disp,
    col_rel_width = c(3.4, rep(1, ncol(disp) - 1)),
    text_justification = c("l", rep("c", ncol(disp) - 1)),
    footnotes = "Subjects are counted once per SOC and once per preferred term.",
    meta = list(trt_var = p$trt_var, n_soc = length(socs)))
}

#' Adverse events by maximum severity
#'
#' Each subject is counted once, at the worst severity recorded.
#'
#' @inheritParams tbl_ae
#' @param sev_var Severity column.
#' @param levels Severity levels from mildest to worst (matched
#'   case-insensitively).
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_ae_severity(ex_adae, ex_adsl)
#' @export
tbl_ae_severity <- function(adae, adsl = NULL, trt_var = "TRT01A", sev_var = "AESEV",
                            teae_flag = "TRTEMFL", levels = c("MILD", "MODERATE", "SEVERE"),
                            config = NULL) {
  p <- prepare_trt(adae, trt_var, config, "adae")
  check_cols(p$df, c("USUBJID", sev_var), "adae")
  ae <- teae_filter(p$df, teae_flag)
  denom <- denominators(ae_population(ae, adsl, p$trt_var), p$trt_var)
  rank <- match(toupper(trimws(as.character(ae[[sev_var]]))), toupper(levels))
  ae$.rank <- rank
  ranked <- ae[!is.na(rank), , drop = FALSE]
  if (!nrow(ranked)) tlf_abort("No events with a severity in: ", paste(levels, collapse = ", "), ".")
  worst <- stats::aggregate(.rank ~ USUBJID, data = ranked, FUN = max)
  per <- unique(ranked[, c("USUBJID", p$trt_var)])
  per <- merge(per[!duplicated(per$USUBJID), , drop = FALSE], worst, by = "USUBJID")
  rows <- list(c("Subjects with at least one TEAE", npct_row(ae, p$trt_var, denom)))
  for (i in seq_along(levels)) {
    lab <- paste0("  ", tools::toTitleCase(tolower(levels[i])))
    rows[[length(rows) + 1L]] <- c(lab, npct_row(per[per$.rank == i, , drop = FALSE], p$trt_var, denom))
  }
  disp <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(disp) <- c("Maximum severity", label_with_n(names(denom), denom))
  notes <- "Subjects are counted once, at the maximum severity reported."
  if (anyNA(rank)) notes <- c(notes, sprintf("%d event(s) with missing or unrecognized severity are excluded from the severity rows.", sum(is.na(rank))))
  tlf_table_result(disp,
    col_rel_width = c(3, rep(1, ncol(disp) - 1)),
    text_justification = c("l", rep("c", ncol(disp) - 1)),
    footnotes = notes, meta = list(trt_var = p$trt_var))
}

#' Subject disposition
#'
#' n (%) for population flags (`"Y"` = yes), subjects discontinued from the
#' study, and the discontinuation reasons.
#'
#' @inheritParams tbl_demographics
#' @param flags Named list: flag column = row label. Flags missing from the
#'   data are skipped.
#' @param eos_var End-of-study status column.
#' @param discontinued Values of `eos_var` meaning discontinued (matched
#'   case-insensitively).
#' @param reason_var Discontinuation reason column.
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_disposition(ex_adsl)
#' @export
tbl_disposition <- function(adsl, trt_var = "TRT01A",
                            flags = list(RANDFL = "Randomized", SAFFL = "Safety population",
                                         COMPLFL = "Completed study"),
                            eos_var = "EOSSTT", discontinued = "DISCONTINUED",
                            reason_var = "DCSREAS", config = NULL) {
  p <- prepare_trt(adsl, trt_var, config, "adsl")
  d <- p$df
  check_cols(d, "USUBJID", "adsl")
  denom <- denominators(d, p$trt_var)
  rows <- list()
  for (fl in intersect(names(flags), names(d))) {
    rows[[length(rows) + 1L]] <- c(flags[[fl]], npct_row(d[!is.na(d[[fl]]) & d[[fl]] == "Y", , drop = FALSE], p$trt_var, denom))
  }
  if (eos_var %in% names(d)) {
    disc <- toupper(trimws(as.character(d[[eos_var]]))) %in% toupper(discontinued)
    rows[[length(rows) + 1L]] <- c("Discontinued study", npct_row(d[disc, , drop = FALSE], p$trt_var, denom))
    if (reason_var %in% names(d)) {
      rs <- trimws(as.character(d[[reason_var]]))
      for (r in sort(unique(rs[disc & !is.na(rs) & nzchar(rs)]))) {
        rows[[length(rows) + 1L]] <- c(paste0("  ", r), npct_row(d[disc & rs %in% r, , drop = FALSE], p$trt_var, denom))
      }
    }
  }
  if (!length(rows)) tlf_abort("No disposition variables found in adsl.")
  disp <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(disp) <- c("Category", label_with_n(names(denom), denom))
  tlf_table_result(disp,
    col_rel_width = c(3, rep(1, ncol(disp) - 1)),
    text_justification = c("l", rep("c", ncol(disp) - 1)),
    meta = list(trt_var = p$trt_var))
}

#' Summary of a BDS parameter by visit
#'
#' Descriptive statistics of `value_col` per visit and treatment. For change
#' from baseline (`value_col = "CHG"`) the baseline visit, defined as the
#' lowest `AVISITN`, is omitted.
#'
#' @param adx A BDS dataset (`AVISIT`, optionally `AVISITN` and `PARAMCD`).
#' @param paramcd Optional `PARAMCD` filter.
#' @param value_col `"AVAL"` or `"CHG"`.
#' @inheritParams tbl_demographics
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_eff(ex_adlb, paramcd = "ALT", value_col = "CHG")
#' @export
tbl_eff <- function(adx, trt_var = "TRT01A", paramcd = NULL, value_col = "CHG", config = NULL) {
  p <- prepare_trt(adx, trt_var, config, "adx")
  d <- filter_param(p$df, paramcd)
  check_cols(d, c(value_col, "AVISIT"), "adx")
  d <- d[!is.na(d[[value_col]]) & !is.na(d$AVISIT), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No rows with a non-missing ", value_col, " value.")
  visits <- visit_levels(d)
  if (value_col == "CHG" && "AVISITN" %in% names(d)) {
    base_visit <- unique(d$AVISIT[d$AVISITN == min(d$AVISITN, na.rm = TRUE)])
    visits <- setdiff(visits, base_visit)
  }
  if (!length(visits)) tlf_abort("No post-baseline visits to summarize.")
  blocks <- lapply(visits, function(v) stat_desc(d[d$AVISIT == v, , drop = FALSE], value_col, p$trt_var, label = v))
  disp <- stack_blocks(blocks, "Visit", d, p$trt_var)
  what <- if (value_col == "CHG") "Change from baseline" else "Observed values"
  tlf_table_result(disp,
    col_rel_width = c(2, 1.8, rep(1, ncol(disp) - 2)),
    text_justification = c("l", "l", rep("c", ncol(disp) - 2)),
    footnotes = sprintf("%s of %s, summarized by visit.", what, or_default(paramcd, "the analysis parameter")),
    meta = list(trt_var = p$trt_var, value_col = value_col, visits = visits))
}

shift_levels <- c("Low", "Normal", "High")

# Reference-range category of each value: Low / Normal / High.
range_category <- function(av, lo, hi) {
  out <- rep(NA_character_, length(av))
  fin <- is.finite(av)
  out[fin] <- "Normal"
  out[fin & is.finite(lo) & av < lo] <- "Low"
  out[fin & is.finite(hi) & av > hi] <- "High"
  factor(out, levels = shift_levels)
}

# Per-subject baseline and endpoint (last post-baseline) category.
shift_pairs <- function(d, trt_var) {
  num <- function(col) if (col %in% names(d)) suppressWarnings(as.numeric(d[[col]])) else rep(NA_real_, nrow(d))
  d$.cat <- range_category(num("AVAL"), num("ANRLO"), num("ANRHI"))
  d <- d[!is.na(d$.cat) & !is.na(d$AVISITN), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No rows can be categorized against ANRLO/ANRHI.")
  bl <- min(d$AVISITN)
  d <- d[order(d$USUBJID, d$AVISITN), , drop = FALSE]
  base <- d[d$AVISITN == bl, , drop = FALSE]
  base <- base[!duplicated(base$USUBJID), c("USUBJID", trt_var, ".cat")]
  names(base) <- c("USUBJID", "trt", "base_cat")
  post <- d[d$AVISITN > bl, , drop = FALSE]
  post <- post[!duplicated(post$USUBJID, fromLast = TRUE), c("USUBJID", ".cat")]
  names(post) <- c("USUBJID", "end_cat")
  per <- merge(base, post, by = "USUBJID")
  if (!nrow(per)) tlf_abort("No subjects with both a baseline and a post-baseline category.")
  per$trt <- factor(as.character(per$trt), levels = arm_levels(d[[trt_var]]))
  per
}

#' Shift table: baseline vs endpoint reference-range category
#'
#' Cross-tabulates each subject's baseline category (at the lowest `AVISITN`)
#' against the category at the last post-baseline visit, by treatment.
#'
#' @inheritParams tbl_eff
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_shift(ex_adlb, paramcd = "ALT")
#' @export
tbl_shift <- function(adx, trt_var = "TRT01A", paramcd = NULL, config = NULL) {
  p <- prepare_trt(adx, trt_var, config, "adx")
  d <- filter_param(p$df, paramcd)
  check_cols(d, c("USUBJID", "AVAL", "AVISITN"), "adx")
  per <- shift_pairs(d, p$trt_var)
  rows <- list()
  for (a in arm_levels(per$trt)) for (bc in shift_levels) {
    sub <- per[per$trt == a & per$base_cat == bc, , drop = FALSE]
    cnt <- table(factor(as.character(sub$end_cat), levels = shift_levels))
    rows[[length(rows) + 1L]] <- c(if (bc == shift_levels[1]) a else "", bc, as.character(as.integer(cnt)))
  }
  disp <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(disp) <- c("Treatment", "Baseline", paste("Endpoint:", shift_levels))
  tlf_table_result(disp,
    col_rel_width = c(1.6, 1.2, 1, 1, 1),
    text_justification = c("l", "l", "c", "c", "c"),
    footnotes = "Categories are relative to the reference range (ANRLO/ANRHI). Endpoint is the last post-baseline visit.",
    meta = list(trt_var = p$trt_var, n_subjects = nrow(per)))
}

#' Time-to-event summary
#'
#' Kaplan-Meier median time with 95% CI per arm. With two or more arms it
#' adds Cox hazard ratios versus the first arm and the log-rank p-value as
#' footnotes. ADaM ADTTE conventions apply: `AVAL` is the time and
#' `CNSR == 1` means censored. Requires the survival package.
#'
#' @inheritParams tbl_eff
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' if (requireNamespace("survival", quietly = TRUE)) tbl_tte(ex_adtte)
#' @export
tbl_tte <- function(adx, trt_var = "TRT01A", paramcd = NULL, config = NULL) {
  rlang::check_installed("survival", reason = "for time-to-event tables.")
  p <- prepare_trt(adx, trt_var, config, "adx")
  d0 <- filter_param(p$df, paramcd)
  check_cols(d0, c("AVAL", "CNSR"), "adx")
  d <- data.frame(time = suppressWarnings(as.numeric(d0$AVAL)),
                  event = 1 - suppressWarnings(as.numeric(d0$CNSR)),
                  trt = factor(as.character(d0[[p$trt_var]]), levels = arm_levels(d0[[p$trt_var]])))
  d <- d[is.finite(d$time) & d$event %in% c(0, 1), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No analyzable time-to-event records.")
  d$trt <- droplevels(d$trt)
  arms <- levels(d$trt)
  f2 <- function(x) ifelse(is.finite(x), formatC(x, format = "f", digits = 2), "NE")
  ci <- function(est, lo, hi) sprintf("%s (%s, %s)", f2(est), f2(lo), f2(hi))
  fit <- survival::survfit(survival::Surv(time, event) ~ trt, data = d)
  tab <- summary(fit)$table
  if (is.null(dim(tab))) tab <- matrix(tab, nrow = 1L, dimnames = list(paste0("trt=", arms), names(tab)))
  rownames(tab) <- sub("^trt=", "", rownames(tab))
  body <- data.frame(Statistic = c("Subjects, n", "Events, n (%)", "Median time (95% CI)"),
                     stringsAsFactors = FALSE)
  for (a in arms) {
    r <- tab[a, ]
    body[[a]] <- c(as.character(r[["records"]]),
                   fmt_npct(as.integer(r[["events"]]), r[["records"]]),
                   ci(r[["median"]], r[["0.95LCL"]], r[["0.95UCL"]]))
  }
  notes <- character()
  if (length(arms) >= 2L) {
    cox <- tryCatch(survival::coxph(survival::Surv(time, event) ~ trt, data = d), error = function(e) NULL)
    if (!is.null(cox)) {
      sc <- summary(cox)$conf.int
      notes <- sprintf("Hazard ratio (95%% CI), %s vs %s: %s", sub("^trt", "", rownames(sc)), arms[1],
                       ci(sc[, "exp(coef)"], sc[, "lower .95"], sc[, "upper .95"]))
    }
    lr <- tryCatch(survival::survdiff(survival::Surv(time, event) ~ trt, data = d), error = function(e) NULL)
    if (!is.null(lr)) {
      pv <- stats::pchisq(lr$chisq, df = length(arms) - 1L, lower.tail = FALSE)
      notes <- c(notes, paste0("Log-rank p-value: ", format_pvalue(pv)))
    }
  }
  names(body)[-1] <- label_with_n(arms, stats::setNames(as.integer(tab[arms, "records"]), arms))
  tlf_table_result(body,
    col_rel_width = c(2.4, rep(1, ncol(body) - 1)),
    text_justification = c("l", rep("c", ncol(body) - 1)),
    footnotes = notes, meta = list(trt_var = p$trt_var, arms = arms))
}

#' Subject-level listing
#'
#' Selects, renames and sorts columns, one row per record. Configured
#' columns missing from the data are skipped and recorded in `meta`.
#'
#' @param df Data frame.
#' @param cols Named character vector: data column = display header. See
#'   [listing_cols_ae] and [listing_cols_lab] for defaults.
#' @param sort_by Data columns to sort by (those present are used).
#' @return A `tlf_table`.
#' @family table builders
#' @examples
#' tbl_listing(ex_adae, listing_cols_ae)
#' @export
tbl_listing <- function(df, cols, sort_by = c("USUBJID", "AVISITN", "PARAMCD", "ASTDT", "AESTDTC")) {
  if (!is.data.frame(df)) tlf_abort("`df` must be a data frame.")
  if (!is.character(cols) || is.null(names(cols))) tlf_abort("`cols` must be a named character vector.")
  present <- cols[names(cols) %in% names(df)]
  if (!length(present)) tlf_abort("None of the listing columns are in the data.")
  keys <- intersect(sort_by, names(df))
  if (length(keys)) df <- df[do.call(order, unname(as.list(df[keys]))), , drop = FALSE]
  disp <- df[names(present)]
  disp[] <- lapply(disp, function(x) ifelse(is.na(x), "", as.character(x)))
  names(disp) <- unname(present)
  rownames(disp) <- NULL
  tlf_table_result(disp, text_justification = "l",
    meta = list(n_records = nrow(disp), skipped = setdiff(names(cols), names(df))))
}

#' Default listing columns
#'
#' Named character vectors (data column = display header) for
#' [tbl_listing()].
#'
#' @format Named character vectors.
#' @examples
#' listing_cols_ae
#' @name listing_cols
NULL

#' @rdname listing_cols
#' @export
listing_cols_ae <- c(USUBJID = "Subject", AESOC = "System Organ Class",
                     AEDECOD = "Preferred Term", AESEV = "Severity", AESTDTC = "Onset Date",
                     AEOUT = "Outcome", AEREL = "Relationship")

#' @rdname listing_cols
#' @export
listing_cols_lab <- c(USUBJID = "Subject", PARAM = "Parameter", AVISIT = "Visit",
                      AVAL = "Result", AVALU = "Unit", ANRLO = "Ref Low", ANRHI = "Ref High",
                      ANRIND = "Flag")
