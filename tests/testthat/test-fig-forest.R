# Device-free suite: forest plot (ggplot_build only, no graphics device).

test_that("hazard-ratio forest builds on a log scale with the null line at 1", {
  skip_if_not_installed("survival")
  p <- fig_forest(ex_adtte, subgroup_var = "SEX")
  expect_s3_class(p, "ggplot")
  expect_match(plot_label(p, "x"), "Hazard ratio")
  b <- ggplot2::ggplot_build(p)
  expect_true(inherits(b$layout$panel_scales_x[[1]]$trans, "transform") ||
                grepl("log", b$layout$panel_scales_x[[1]]$trans$name))
  expect_equal(b$data[[1]]$xintercept[1], 0) # log10(1)
  expect_gte(nrow(b$data[[2]]), 3)           # Overall + 2 subgroups
})

test_that("difference forest uses CHG at the last visit with the null line at 0", {
  p <- fig_forest(alt(), subgroup_var = "AGEGR1")
  expect_match(plot_label(p, "x"), "Difference in CHG")
  b <- ggplot2::ggplot_build(p)
  expect_equal(b$data[[1]]$xintercept[1], 0)
})

test_that("forest auto-picks a subgroup, and the dispatcher routes it", {
  expect_s3_class(fig_forest(alt()), "ggplot")
  expect_s3_class(tlf_build_figure("forest", alt()), "ggplot")
  expect_true("forest" %in% tlf_figure_types()$type)
})

test_that("forest honours explicit reference and comparator arms", {
  p <- fig_forest(alt(), subgroup_var = "SEX", ref_arm = "Placebo", comp_arm = "Drug 20 mg")
  expect_match(plot_label(p, "x"), "Drug 20 mg - Placebo", fixed = TRUE)
})

test_that("forest guards fail loudly", {
  one_arm <- alt()[alt()$TRT01A == "Placebo", ]
  expect_error(fig_forest(one_arm, subgroup_var = "SEX"), "two treatment arms")
  expect_error(fig_forest(alt(), ctx = fig_ctx(trt_col = NULL)), "treatment")
  expect_error(fig_forest(alt(), subgroup_var = "NOPE"), "subgroup")
})

test_that("forest omits point labels on request and records dropped subgroups", {
  p <- fig_forest(alt(), subgroup_var = "SEX", point_labels = FALSE)
  expect_false(any(vapply(p$layers, function(l) inherits(l$geom, "GeomText"), logical(1))))
  expect_type(attr(p, "tlf_dropped"), "character")
})
