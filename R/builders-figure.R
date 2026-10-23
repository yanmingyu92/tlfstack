# Figure builders. Each returns a ggplot carrying theme_tlf_submission() and no
# in-body title; the title block belongs to the RTF text layer. Builders take
# `df` (analysis data) and `ctx`, a list naming the visit and treatment columns.

#' Figure context
#'
#' Names the visit and treatment columns a figure builder should use.
#'
#' @param visit_col Visit column (ordered by `AVISITN` when it is `"AVISIT"`).
#' @param trt_col Treatment column. `NULL` means no grouping. A column missing
#'   from the data falls back to the configured candidates, and then to no
#'   grouping.
#' @return A list.
#' @examples
#' fig_ctx(trt_col = "TRTA")
#' @export
fig_ctx <- function(visit_col = "AVISIT", trt_col = "TRT01A") {
  list(visit_col = visit_col, trt_col = trt_col)
}

# Resolve ctx against the data and add a `.grp` column (constant when ungrouped).
prep_fig <- function(df, ctx, config, need_trt = FALSE) {
  if (!is.data.frame(df) || !nrow(df)) tlf_abort("`df` must be a data frame with rows.")
  ctx <- utils::modifyList(fig_ctx(), as.list(or_default(ctx, list())))
  trt <- ctx$trt_col
  if (!is.null(trt) && !is.na(trt) && !trt %in% names(df)) {
    alt <- intersect(tlf_get_config(config)$trt_candidates, names(df))
    trt <- if (length(alt)) alt[1] else NULL
  }
  if (need_trt && is.null(trt)) tlf_abort("This figure needs a treatment column.")
  df$.grp <- if (is.null(trt) || is.na(trt)) "All" else as.character(df[[trt]])
  lv <- if (is.null(trt) || is.na(trt)) "All" else arm_levels(df[[trt]])
  df <- df[!is.na(df$.grp) & nzchar(trimws(df$.grp)), , drop = FALSE]
  df$.grp <- factor(df$.grp, levels = setdiff(lv, ""))
  if (!nrow(df)) tlf_abort("No rows with a non-blank treatment value.")
  vis <- ctx$visit_col
  if (!is.null(vis) && vis %in% names(df)) df[[vis]] <- factor(as.character(df[[vis]]), levels = visit_levels(df, vis))
  list(df = df, visit_col = vis, grouped = !is.null(trt) && !is.na(trt), trt_col = trt)
}

group_palette <- function(groups, cfg) {
  lv <- arm_levels(groups)
  stats::setNames(rep_len(cfg$palette, length(lv)), lv)
}

colour_scale <- function(groups, cfg, grouped, aesthetics = "colour") {
  ggplot2::scale_colour_manual(values = group_palette(groups, cfg), name = "Treatment",
                               aesthetics = aesthetics,
                               guide = if (grouped) "legend" else "none")
}

pt_to_mm <- function(pt) pt / ggplot2::.pt

# Adaptive precision so large (about 120) and small (about -2.3) values both read cleanly.
fmt_val <- function(v) {
  ifelse(!is.finite(v), "",
         ifelse(abs(v) >= 100, sprintf("%.0f", v),
                ifelse(abs(v) >= 10, sprintf("%.1f", v), sprintf("%.2f", v))))
}

y_label <- function(df, value_col) {
  u <- single_unit(df)
  if (is.null(u)) value_col else sprintf("%s (%s)", value_col, u)
}

# Mean and normal-approximation CI of `value_col` within `by` groups.
mean_ci <- function(df, value_col, by, ci) {
  z <- stats::qnorm(1 - (1 - ci) / 2)
  key <- interaction(df[by], drop = TRUE, lex.order = TRUE)
  parts <- split(df, key)
  rows <- lapply(parts, function(s) {
    v <- suppressWarnings(as.numeric(s[[value_col]]))
    v <- v[!is.na(v)]
    se <- if (length(v) > 1L) stats::sd(v) / sqrt(length(v)) else NA_real_
    m <- if (length(v)) mean(v) else NA_real_
    out <- s[1, by, drop = FALSE]
    out$n <- length(v)
    out$m <- m
    out$lo <- m - z * se
    out$hi <- m + z * se
    out
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out[out$n > 0, , drop = FALSE]
}

# Per-visit N rows under the panel, one colour-matched row per group.
add_n_strip <- function(p, ndat, x_col, pal, base_size) {
  groups <- arm_levels(ndat$.grp)
  layers <- lapply(seq_along(groups), function(i) {
    ggplot2::geom_text(data = ndat[ndat$.grp == groups[i], , drop = FALSE], inherit.aes = FALSE,
                       ggplot2::aes(x = .data[[x_col]], y = -Inf, label = .data$n),
                       vjust = 3.6 + (i - 1) * 1.6, size = pt_to_mm(base_size) * 0.85,
                       colour = pal[[groups[i]]])
  })
  p + layers + ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme(legend.position = "top",
                   plot.margin = ggplot2::margin(6, 8, 16 + length(groups) * 14, 8))
}

#' Mean with confidence interval by visit
#'
#' @param df Analysis data (BDS).
#' @param ctx A [fig_ctx()] list.
#' @param value_col `"AVAL"` or `"CHG"`.
#' @param ci Confidence level.
#' @param point_labels Print the mean above each point?
#' @param show_n Print per-visit N under the panel?
#' @param base_size Font size; `NULL` uses the configuration.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_meanci(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
#' class(p)
#' @export
fig_meanci <- function(df, ctx = fig_ctx(), value_col = "AVAL", ci = 0.95, point_labels = FALSE,
                       show_n = FALSE, base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  base_size <- or_default(base_size, cfg$fonts$figure_size)
  f <- prep_fig(df, ctx, config)
  check_cols(f$df, c(value_col, f$visit_col))
  agg <- mean_ci(f$df, value_col, c(f$visit_col, ".grp"), ci)
  if (!nrow(agg)) tlf_abort("No non-missing ", value_col, " values.")
  pal <- group_palette(agg$.grp, cfg)
  dodge <- ggplot2::position_dodge(width = if (point_labels) 0.6 else 0.35)
  p <- ggplot2::ggplot(agg, ggplot2::aes(x = .data[[f$visit_col]], y = .data$m,
                                         colour = .data$.grp, group = .data$.grp)) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$lo, ymax = .data$hi), width = 0.2,
                           linewidth = 0.4, position = dodge, na.rm = TRUE) +
    ggplot2::geom_line(linewidth = 0.5, position = dodge) +
    ggplot2::geom_point(size = 1.6, position = dodge) +
    colour_scale(agg$.grp, cfg, f$grouped)
  if (point_labels) {
    p <- p + ggplot2::geom_text(ggplot2::aes(y = .data$hi, label = fmt_val(.data$m)),
                                position = dodge, vjust = -0.35, show.legend = FALSE,
                                size = pt_to_mm(base_size) * 0.9, na.rm = TRUE)
  }
  p <- p + ggplot2::labs(x = NULL, y = sprintf("Mean %s with %g%% CI", y_label(f$df, value_col), round(ci * 100))) +
    theme_tlf_submission(base_size, config = cfg)
  if (show_n) p <- add_n_strip(p, agg, f$visit_col, pal, base_size)
  p
}

#' Box plot by visit
#'
#' @inheritParams fig_meanci
#' @param jitter Overlay individual points?
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_boxplot(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
#' class(p)
#' @export
fig_boxplot <- function(df, ctx = fig_ctx(), value_col = "AVAL", jitter = TRUE,
                        base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  f <- prep_fig(df, ctx, config)
  check_cols(f$df, c(value_col, f$visit_col))
  d <- f$df[!is.na(f$df[[value_col]]), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No non-missing ", value_col, " values.")
  dodge <- ggplot2::position_dodge(width = 0.8)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[f$visit_col]], y = .data[[value_col]],
                                       fill = .data$.grp, colour = .data$.grp)) +
    ggplot2::geom_boxplot(alpha = 0.55, width = 0.55, outlier.shape = NA, colour = "black",
                          linewidth = 0.4, position = dodge)
  if (jitter) {
    p <- p + ggplot2::geom_point(alpha = 0.5, size = 0.9,
                                 position = ggplot2::position_jitterdodge(jitter.width = 0.15, dodge.width = 0.8, seed = 1))
  }
  p + colour_scale(d$.grp, cfg, f$grouped, aesthetics = c("colour", "fill")) +
    ggplot2::labs(x = NULL, y = y_label(d, value_col)) + theme_tlf_submission(base_size, config = cfg)
}

#' Individual-subject lines with an optional mean overlay
#'
#' @inheritParams fig_meanci
#' @param mean_overlay Overlay the mean with a CI ribbon?
#' @param line_alpha Transparency of subject lines.
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_spaghetti(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
#' class(p)
#' @export
fig_spaghetti <- function(df, ctx = fig_ctx(), value_col = "AVAL", mean_overlay = TRUE,
                          line_alpha = 0.25, ci = 0.95, base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  f <- prep_fig(df, ctx, config)
  check_cols(f$df, c("USUBJID", value_col, f$visit_col))
  d <- f$df[!is.na(f$df[[value_col]]) & !is.na(f$df[[f$visit_col]]), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No non-missing ", value_col, " values.")
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[f$visit_col]], y = .data[[value_col]],
                                       group = .data$USUBJID, colour = .data$.grp)) +
    ggplot2::geom_line(alpha = line_alpha, linewidth = 0.4)
  if (mean_overlay) {
    agg <- mean_ci(d, value_col, c(f$visit_col, ".grp"), ci)
    p <- p +
      ggplot2::geom_ribbon(data = agg, inherit.aes = FALSE, alpha = 0.18, colour = NA, na.rm = TRUE,
                           ggplot2::aes(x = .data[[f$visit_col]], ymin = .data$lo, ymax = .data$hi,
                                        group = .data$.grp, fill = .data$.grp)) +
      ggplot2::geom_line(data = agg, inherit.aes = FALSE, linewidth = 1.1,
                         ggplot2::aes(x = .data[[f$visit_col]], y = .data$m,
                                      group = .data$.grp, colour = .data$.grp))
  }
  p + colour_scale(d$.grp, cfg, f$grouped, aesthetics = c("colour", "fill")) +
    ggplot2::labs(x = NULL, y = y_label(d, value_col)) + theme_tlf_submission(base_size, config = cfg)
}

# Per-visit ANCOVA LS-means (value ~ BASE + treatment), base R only.
lsmeans_by_visit <- function(d, value_col, vis_col, ci, use_base) {
  rows <- list()
  for (v in levels(droplevels(d[[vis_col]]))) {
    dv <- d[d[[vis_col]] == v, , drop = FALSE]
    dv$.trt <- droplevels(factor(dv$.grp))
    if (nrow(dv) < 3L) next
    adj <- use_base && length(unique(dv$BASE)) > 1L
    fit <- tryCatch(stats::lm(stats::reformulate(c(if (adj) "BASE", if (nlevels(dv$.trt) > 1L) ".trt"), value_col),
                              data = dv), error = function(e) NULL)
    if (is.null(fit) || fit$df.residual < 1L) next
    nd <- data.frame(.trt = factor(levels(dv$.trt), levels = levels(dv$.trt)))
    if (adj) nd$BASE <- mean(dv$BASE)
    pr <- stats::predict(fit, newdata = nd, se.fit = TRUE)
    tq <- stats::qt(1 - (1 - ci) / 2, df = fit$df.residual)
    rows[[length(rows) + 1L]] <- data.frame(visit = v, .grp = levels(dv$.trt), m = unname(pr$fit),
                                            lo = unname(pr$fit - tq * pr$se.fit),
                                            hi = unname(pr$fit + tq * pr$se.fit),
                                            n = as.integer(table(dv$.trt)), stringsAsFactors = FALSE)
  }
  if (!length(rows)) tlf_abort("LS-means could not be estimated at any visit.")
  do.call(rbind, rows)
}

#' LS-means by visit
#'
#' Per-visit ANCOVA of `value_col` on treatment, adjusted for baseline
#' (`BASE`) when it is available. The baseline visit (lowest `AVISITN`) is
#' then excluded. This is a per-visit model, not an MMRM.
#'
#' @inheritParams fig_meanci
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_lsmeans(ex_adlb[ex_adlb$PARAMCD == "ALT", ], value_col = "CHG")
#' class(p)
#' @export
fig_lsmeans <- function(df, ctx = fig_ctx(), value_col = "AVAL", ci = 0.95, point_labels = FALSE,
                        show_n = FALSE, base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  base_size <- or_default(base_size, cfg$fonts$figure_size)
  f <- prep_fig(df, ctx, config, need_trt = TRUE)
  check_cols(f$df, c(value_col, f$visit_col))
  d <- f$df[!is.na(f$df[[value_col]]) & !is.na(f$df[[f$visit_col]]), , drop = FALSE]
  use_base <- "BASE" %in% names(d) && any(!is.na(d$BASE))
  if (use_base) {
    d <- d[!is.na(d$BASE), , drop = FALSE]
    if ("AVISITN" %in% names(d) && length(unique(d$AVISITN)) > 1L) d <- d[d$AVISITN > min(d$AVISITN), , drop = FALSE]
  }
  if (!nrow(d)) tlf_abort("No post-baseline rows for LS-means.")
  res <- lsmeans_by_visit(d, value_col, f$visit_col, ci, use_base)
  res$visit <- factor(res$visit, levels = levels(droplevels(d[[f$visit_col]])))
  res$.grp <- factor(res$.grp, levels = levels(d$.grp))
  pal <- group_palette(res$.grp, cfg)
  dodge <- ggplot2::position_dodge(width = if (point_labels) 0.6 else 0.35)
  p <- ggplot2::ggplot(res, ggplot2::aes(x = .data$visit, y = .data$m, colour = .data$.grp, group = .data$.grp)) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$lo, ymax = .data$hi), width = 0.2, linewidth = 0.4, position = dodge) +
    ggplot2::geom_line(linewidth = 0.5, position = dodge) +
    ggplot2::geom_point(size = 1.6, position = dodge) +
    colour_scale(res$.grp, cfg, TRUE)
  if (point_labels) {
    p <- p + ggplot2::geom_text(ggplot2::aes(y = .data$hi, label = fmt_val(.data$m)), position = dodge,
                                vjust = -0.35, size = pt_to_mm(base_size) * 0.9, show.legend = FALSE)
  }
  ylab <- sprintf("LS-mean %s with %g%% CI%s", y_label(d, value_col), round(ci * 100),
                  if (use_base) " (baseline-adjusted)" else "")
  p <- p + ggplot2::labs(x = NULL, y = ylab) + theme_tlf_submission(base_size, config = cfg)
  if (show_n) p <- add_n_strip(p, res, "visit", pal, base_size)
  p
}

#' Kaplan-Meier curve
#'
#' ADTTE conventions: `AVAL` is the time and `CNSR == 1` means censored.
#' Requires the survival package.
#'
#' @inheritParams fig_meanci
#' @param censor_marks Mark censored observations?
#' @return A ggplot.
#' @family figure builders
#' @examples
#' if (requireNamespace("survival", quietly = TRUE)) p <- fig_km(ex_adtte)
#' @export
fig_km <- function(df, ctx = fig_ctx(), censor_marks = TRUE, base_size = NULL, config = NULL) {
  rlang::check_installed("survival", reason = "for Kaplan-Meier figures.")
  cfg <- tlf_get_config(config)
  f <- prep_fig(df, ctx, config)
  check_cols(f$df, c("AVAL", "CNSR"))
  d <- data.frame(time = suppressWarnings(as.numeric(f$df$AVAL)),
                  event = 1 - suppressWarnings(as.numeric(f$df$CNSR)), grp = f$df$.grp)
  d <- d[is.finite(d$time) & d$time >= 0 & d$event %in% c(0, 1), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No valid time-to-event rows.")
  steps <- lapply(arm_levels(d$grp), function(g) {
    fit <- survival::survfit(survival::Surv(time, event) ~ 1, data = d[d$grp == g, , drop = FALSE])
    data.frame(time = c(0, fit$time), surv = c(1, fit$surv), ncensor = c(0, fit$n.censor), .grp = g)
  })
  st <- do.call(rbind, steps)
  st$.grp <- factor(st$.grp, levels = arm_levels(d$grp))
  cens <- st[st$ncensor > 0, , drop = FALSE]
  u <- single_unit(f$df)
  p <- ggplot2::ggplot(st, ggplot2::aes(x = .data$time, y = .data$surv, colour = .data$.grp, group = .data$.grp)) +
    ggplot2::geom_step(linewidth = 0.6, direction = "hv")
  if (censor_marks && nrow(cens)) p <- p + ggplot2::geom_point(data = cens, shape = 3, size = 1.8)
  p + colour_scale(st$.grp, cfg, f$grouped) +
    ggplot2::scale_y_continuous(limits = c(0, 1), expand = ggplot2::expansion(mult = c(0, 0.02))) +
    ggplot2::labs(x = if (is.null(u)) "Time" else sprintf("Time (%s)", u), y = "Survival probability") +
    theme_tlf_submission(base_size, config = cfg)
}

#' Subgroup forest plot
#'
#' Treatment effect, comparator versus reference, overall and within each
#' level of `subgroup_var`. With time-to-event data (`CNSR` present) the
#' effect is a Cox hazard ratio on a log scale, and the survival package is
#' required. Otherwise it is a difference in means (Welch t-test) at the last
#' visit. Subgroups that cannot be estimated are dropped and listed in the
#' `tlf_dropped` attribute.
#'
#' @inheritParams fig_meanci
#' @param subgroup_var Subgroup column. `NULL` uses the first of `SEX`,
#'   `AGEGR1`, `RACE`, `REGION` present.
#' @param ref_arm,comp_arm Reference and comparator arms (default: first and
#'   last arm in sort order).
#' @param point_labels Print the estimate and CI next to each row?
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_forest(ex_adlb[ex_adlb$PARAMCD == "ALT", ], subgroup_var = "SEX")
#' class(p)
#' @export
fig_forest <- function(df, ctx = fig_ctx(), subgroup_var = NULL, ref_arm = NULL, comp_arm = NULL,
                       ci = 0.95, point_labels = TRUE, base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  base_size <- or_default(base_size, cfg$fonts$figure_size)
  f <- prep_fig(df, ctx, config, need_trt = TRUE)
  arms <- arm_levels(f$df$.grp)
  if (length(arms) < 2L) tlf_abort("A forest plot needs at least two treatment arms.")
  ref_arm <- if (!is.null(ref_arm) && ref_arm %in% arms) ref_arm else arms[1]
  comp_arm <- if (!is.null(comp_arm) && comp_arm %in% setdiff(arms, ref_arm)) comp_arm else utils::tail(setdiff(arms, ref_arm), 1)
  if (is.null(subgroup_var)) subgroup_var <- intersect(c("SEX", "AGEGR1", "RACE", "REGION"), names(f$df))[1]
  if (is.na(subgroup_var) || !subgroup_var %in% names(f$df)) tlf_abort("A forest plot needs a subgroup column.")
  is_tte <- "CNSR" %in% names(f$df) && any(!is.na(f$df$CNSR))
  if (is_tte) rlang::check_installed("survival", reason = "for hazard-ratio forest plots.")
  value_col <- if (is_tte) "AVAL" else if ("CHG" %in% names(f$df) && any(!is.na(f$df$CHG))) "CHG" else "AVAL"
  d <- f$df[f$df$.grp %in% c(ref_arm, comp_arm), , drop = FALSE]
  if (!is_tte && "AVISITN" %in% names(d) && any(!is.na(d$AVISITN))) {
    d <- d[!is.na(d$AVISITN) & d$AVISITN == max(d$AVISITN, na.rm = TRUE), , drop = FALSE]
  }
  estimate <- function(s) {
    if (is_tte) {
      s <- s[is.finite(suppressWarnings(as.numeric(s$AVAL))) & s$CNSR %in% c(0, 1), , drop = FALSE]
      s$.ev <- 1 - as.numeric(s$CNSR)
      s$.trt <- factor(s$.grp, levels = c(ref_arm, comp_arm))
      if (length(unique(s$.trt)) < 2L || sum(s$.ev) < 1L) return(NULL)
      fit <- tryCatch(survival::coxph(survival::Surv(AVAL, .ev) ~ .trt, data = s), error = function(e) NULL)
      if (is.null(fit)) return(NULL)
      b <- unname(stats::coef(fit)[1])
      se <- sqrt(stats::vcov(fit)[1, 1])
      if (!is.finite(b) || !is.finite(se)) return(NULL)
      z <- stats::qnorm(1 - (1 - ci) / 2)
      return(c(exp(b), exp(b - z * se), exp(b + z * se), nrow(s)))
    }
    rv <- s[[value_col]][s$.grp == ref_arm]
    cv <- s[[value_col]][s$.grp == comp_arm]
    rv <- rv[is.finite(rv)]
    cv <- cv[is.finite(cv)]
    if (length(rv) < 2L || length(cv) < 2L) return(NULL)
    tt <- tryCatch(stats::t.test(cv, rv, conf.level = ci), error = function(e) NULL)
    if (is.null(tt)) return(NULL)
    c(mean(cv) - mean(rv), tt$conf.int[1], tt$conf.int[2], length(rv) + length(cv))
  }
  groups <- c(list(Overall = d), split(d, as.character(d[[subgroup_var]])))
  labs <- c("Overall", paste(subgroup_var, "=", names(groups)[-1]))
  est <- lapply(groups, estimate)
  keep <- !vapply(est, is.null, logical(1))
  if (!any(keep)) tlf_abort("Forest plot: the effect is not estimable overall or in any subgroup.")
  res <- data.frame(label = labs[keep], do.call(rbind, est[keep]), stringsAsFactors = FALSE)
  names(res)[2:5] <- c("est", "lo", "hi", "n")
  res$overall <- res$label == "Overall"
  res$label <- factor(res$label, levels = rev(c(intersect("Overall", res$label), sort(setdiff(res$label, "Overall")))))
  xlab <- if (is_tte) {
    sprintf("Hazard ratio (%s vs %s) with %g%% CI", comp_arm, ref_arm, round(ci * 100))
  } else {
    sprintf("Difference in %s (%s - %s) with %g%% CI", y_label(d, value_col), comp_arm, ref_arm, round(ci * 100))
  }
  p <- ggplot2::ggplot(res, ggplot2::aes(x = .data$est, y = .data$label)) +
    ggplot2::geom_vline(xintercept = if (is_tte) 1 else 0, colour = "grey40", linetype = "dashed", linewidth = 0.4) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lo, xmax = .data$hi), orientation = "y", width = 0.18, linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(shape = .data$overall, size = .data$overall), fill = "black") +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 22, `TRUE` = 23), guide = "none") +
    ggplot2::scale_size_manual(values = c(`FALSE` = 2.2, `TRUE` = 3.2), guide = "none")
  if (point_labels) {
    res$txt <- sprintf("%s (%s, %s)", fmt_val(res$est), fmt_val(res$lo), fmt_val(res$hi))
    p <- p + ggplot2::geom_text(data = res, ggplot2::aes(x = .data$hi, label = .data$txt), hjust = -0.12,
                                size = pt_to_mm(base_size) * 0.85)
  }
  expand <- ggplot2::expansion(mult = c(0.05, if (point_labels) 0.35 else 0.08))
  p <- p + (if (is_tte) ggplot2::scale_x_log10(expand = expand) else ggplot2::scale_x_continuous(expand = expand)) +
    ggplot2::labs(x = xlab, y = NULL) + theme_tlf_submission(base_size, config = cfg)
  attr(p, "tlf_dropped") <- labs[!keep]
  p
}

#' Waterfall plot of best percent change
#'
#' One bar per subject: the minimum post-baseline percent change, from `PCHG`
#' or computed from `AVAL` and `BASE`.
#'
#' @inheritParams fig_meanci
#' @param ref_lines Optional horizontal reference lines (for example
#'   `c(-30, 20)`).
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_waterfall(ex_adlb[ex_adlb$PARAMCD == "ALT", ], ref_lines = c(-30, 20))
#' class(p)
#' @export
fig_waterfall <- function(df, ctx = fig_ctx(), ref_lines = NULL, base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  f <- prep_fig(df, ctx, config)
  d <- f$df
  check_cols(d, "USUBJID")
  if ("PCHG" %in% names(d) && any(!is.na(d$PCHG))) {
    d$.pchg <- suppressWarnings(as.numeric(d$PCHG))
  } else {
    check_cols(d, c("AVAL", "BASE"), "Waterfall data (PCHG, or AVAL and BASE)")
    av <- suppressWarnings(as.numeric(d$AVAL))
    bs <- suppressWarnings(as.numeric(d$BASE))
    d$.pchg <- ifelse(is.finite(bs) & bs != 0, (av - bs) / abs(bs) * 100, NA_real_)
  }
  if ("AVISITN" %in% names(d) && any(!is.na(d$AVISITN))) d <- d[is.na(d$AVISITN) | d$AVISITN > min(d$AVISITN, na.rm = TRUE), , drop = FALSE]
  d <- d[is.finite(d$.pchg), , drop = FALSE]
  if (!nrow(d)) tlf_abort("No finite post-baseline percent-change values.")
  best <- stats::aggregate(.pchg ~ USUBJID + .grp, data = d, FUN = min)
  best <- best[order(-best$.pchg, best$USUBJID), , drop = FALSE]
  best$rank <- seq_len(nrow(best))
  ylab <- "Best % change from baseline"
  if ("PARAM" %in% names(d) && length(unique(d$PARAM)) == 1L) ylab <- paste0(ylab, ": ", d$PARAM[1])
  p <- ggplot2::ggplot(best, ggplot2::aes(x = .data$rank, y = .data$.pchg, fill = .data$.grp)) +
    ggplot2::geom_col(width = 0.85) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey30", linewidth = 0.4)
  if (length(ref_lines)) p <- p + ggplot2::geom_hline(yintercept = ref_lines, colour = "grey40", linetype = "dashed", linewidth = 0.35)
  p + colour_scale(best$.grp, cfg, f$grouped, aesthetics = "fill") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0.01)) +
    ggplot2::labs(x = "Subjects (ordered by best response)", y = ylab) +
    theme_tlf_submission(base_size, config = cfg) +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
}

#' eDISH (Hy's Law) plot
#'
#' Each subject's peak transaminase versus peak total bilirubin, as multiples
#' of the upper limit of normal (`AVAL / ANRHI`), on log scales, with
#' reference lines at 3x and 2x ULN.
#'
#' @inheritParams fig_meanci
#' @param enzyme `"ALT"` or `"AST"`.
#' @param bili_codes `PARAMCD` values accepted for total bilirubin.
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_edish(ex_adlb)
#' class(p)
#' @export
fig_edish <- function(df, ctx = fig_ctx(), enzyme = c("ALT", "AST"),
                      bili_codes = c("BILI", "TBILI", "BILTOT"), base_size = NULL, config = NULL) {
  enzyme <- match.arg(enzyme)
  cfg <- tlf_get_config(config)
  base_size <- or_default(base_size, cfg$fonts$figure_size)
  f <- prep_fig(df, ctx, config)
  d <- f$df
  check_cols(d, c("USUBJID", "PARAMCD", "AVAL", "ANRHI"))
  bili <- intersect(bili_codes, unique(d$PARAMCD))[1]
  if (is.na(bili)) tlf_abort("eDISH needs total bilirubin rows (PARAMCD in ", paste(bili_codes, collapse = ", "), ").")
  if (!enzyme %in% d$PARAMCD) tlf_abort("No ", enzyme, " rows in the data.")
  d$xuln <- suppressWarnings(as.numeric(d$AVAL) / as.numeric(d$ANRHI))
  d <- d[is.finite(d$xuln) & d$xuln > 0, , drop = FALSE]
  peak <- function(code, nm) {
    s <- d[d$PARAMCD == code, , drop = FALSE]
    if (!nrow(s)) return(NULL)
    out <- stats::aggregate(xuln ~ USUBJID + .grp, data = s, FUN = max)
    names(out)[3] <- nm
    out
  }
  enz <- peak(enzyme, "x")
  bil <- peak(bili, "y")
  if (is.null(enz) || is.null(bil)) tlf_abort("No subjects with evaluable ", enzyme, " and bilirubin values.")
  w <- merge(enz, bil, by = c("USUBJID", ".grp"))
  if (!nrow(w)) tlf_abort("No subjects with both ", enzyme, " and total bilirubin.")
  x_max <- max(w$x, 4)
  y_max <- max(w$y, 3)
  ggplot2::ggplot(w, ggplot2::aes(x = .data$x, y = .data$y, colour = .data$.grp)) +
    ggplot2::annotate("rect", xmin = 3, xmax = x_max, ymin = 2, ymax = y_max, fill = "grey60", alpha = 0.12) +
    ggplot2::geom_vline(xintercept = 3, colour = "grey30", linetype = "dashed", linewidth = 0.4) +
    ggplot2::geom_hline(yintercept = 2, colour = "grey30", linetype = "dashed", linewidth = 0.4) +
    ggplot2::geom_point(size = 2, alpha = 0.85) +
    ggplot2::annotate("text", x = 3.1, y = y_max, label = "Potential Hy's Law", hjust = 0, vjust = 1,
                      size = pt_to_mm(base_size) * 0.85, fontface = "italic") +
    ggplot2::scale_x_log10() + ggplot2::scale_y_log10() +
    colour_scale(w$.grp, cfg, f$grouped) +
    ggplot2::labs(x = sprintf("Peak %s (x ULN)", enzyme), y = "Peak total bilirubin (x ULN)") +
    theme_tlf_submission(base_size, config = cfg)
}

#' Shift plot: baseline vs endpoint category
#'
#' A tile grid of subject counts by baseline and endpoint reference-range
#' category, faceted by treatment. It uses the same pairing as [tbl_shift()].
#'
#' @inheritParams fig_meanci
#' @return A ggplot.
#' @family figure builders
#' @examples
#' p <- fig_shift(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
#' class(p)
#' @export
fig_shift <- function(df, ctx = fig_ctx(), base_size = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  base_size <- or_default(base_size, cfg$fonts$figure_size)
  f <- prep_fig(df, ctx, config)
  check_cols(f$df, c("USUBJID", "AVAL", "AVISITN"))
  per <- shift_pairs(f$df, ".grp")
  cnt <- as.data.frame(table(base_cat = per$base_cat, end_cat = per$end_cat, trt = per$trt),
                       stringsAsFactors = FALSE)
  names(cnt)[4] <- "n"
  cnt$base_cat <- factor(cnt$base_cat, levels = shift_levels)
  cnt$end_cat <- factor(cnt$end_cat, levels = shift_levels)
  p <- ggplot2::ggplot(cnt, ggplot2::aes(x = .data$base_cat, y = .data$end_cat, fill = .data$n)) +
    ggplot2::geom_tile(colour = "grey80", linewidth = 0.3) +
    ggplot2::geom_text(ggplot2::aes(label = .data$n), size = pt_to_mm(base_size), colour = "grey10") +
    ggplot2::scale_fill_gradient(low = "#EAF0F6", high = cfg$palette[1], name = "Subjects") +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Baseline category", y = "Endpoint category (last post-baseline visit)") +
    theme_tlf_submission(base_size, config = cfg)
  if (f$grouped) p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$trt))
  p
}
