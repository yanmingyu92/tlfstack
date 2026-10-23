# Device-free suite: LS-means.

test_that("baseline-adjusted LS-means: one point per arm and post-baseline visit", {
  p <- fig_lsmeans(alt(), value_col = "AVAL")
  pts <- layer_data_of(p, "GeomPoint")[[1]]
  expect_equal(nrow(pts), 3 * 3) # 3 arms x 3 post-baseline visits
  expect_match(plot_label(p, "y"), "baseline-adjusted")
  expect_match(plot_label(p, "y"), "LS-mean AVAL (U/L)", fixed = TRUE)
})

test_that("CHG variant and both dispatcher keys build", {
  expect_s3_class(fig_lsmeans(alt(), value_col = "CHG"), "ggplot")
  expect_s3_class(tlf_build_figure("lsmeans", alt()), "ggplot")
  expect_s3_class(tlf_build_figure("lsmeans_chg", alt()), "ggplot")
  expect_true(all(c("lsmeans", "lsmeans_chg") %in% tlf_figure_types()$type))
})

test_that("LS-means without BASE falls back to unadjusted means", {
  d <- alt()[setdiff(names(alt()), "BASE")]
  p <- fig_lsmeans(d)
  expect_s3_class(p, "ggplot")
  expect_false(grepl("baseline-adjusted", plot_label(p, "y")))
})

test_that("LS-means guards and the N strip", {
  expect_error(fig_lsmeans(alt(), ctx = fig_ctx(trt_col = NULL)), "treatment")
  p <- fig_lsmeans(alt(), show_n = TRUE)
  expect_gt(length(layer_data_of(p, "GeomText")), 0)
})

test_that("LS-means arm order follows factor levels", {
  d <- alt()
  d$TRT01A <- factor(d$TRT01A, levels = c("Placebo", "Drug 10 mg", "Drug 20 mg"))
  b <- ggplot2::ggplot_build(fig_lsmeans(d))
  expect_equal(b$plot$scales$get_scales("colour")$get_limits()[1], "Placebo")
})
