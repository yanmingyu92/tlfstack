test_that("mean (CI) figure: one point per arm and visit, no in-body title", {
  p <- fig_meanci(alt())
  pts <- layer_data_of(p, "GeomPoint")[[1]]
  expect_equal(nrow(pts), 3 * 4)
  expect_match(plot_label(p, "y"), "Mean AVAL (U/L) with 95% CI", fixed = TRUE)
  th <- ggplot2::theme_get()
  expect_s3_class(p$theme$plot.title, "element_blank")
  expect_gt(length(layer_data_of(fig_meanci(alt(), point_labels = TRUE, show_n = TRUE), "GeomText")), 1)
})

test_that("ungrouped figures hide the legend", {
  p <- fig_meanci(alt(), ctx = fig_ctx(trt_col = NULL))
  pts <- layer_data_of(p, "GeomPoint")[[1]]
  expect_equal(nrow(pts), 4)
})

test_that("box plot, spaghetti and eDISH build", {
  expect_s3_class(fig_boxplot(alt()), "ggplot")
  expect_s3_class(fig_boxplot(alt(), jitter = FALSE), "ggplot")
  sp <- fig_spaghetti(alt())
  expect_length(layer_data_of(sp, "GeomRibbon"), 1)
  expect_length(layer_data_of(fig_spaghetti(alt(), mean_overlay = FALSE), "GeomRibbon"), 0)
  ed <- fig_edish(ex_adlb)
  pts <- layer_data_of(ed, "GeomPoint")[[1]]
  expect_equal(nrow(pts), length(unique(ex_adlb$USUBJID)))
  expect_match(plot_label(ed, "x"), "Peak ALT")
  expect_error(fig_edish(alt()), "bilirubin")
})

test_that("figure palette and fonts follow the configuration", {
  cfg <- tlf_config(palette = c("#000000", "#555555", "#999999"), fonts = tlf_fonts(figure_size = 9))
  p <- fig_meanci(alt(), config = cfg)
  cols <- unique(layer_data_of(p, "GeomPoint")[[1]]$colour)
  expect_setequal(cols, c("#000000", "#555555", "#999999"))
  expect_equal(p$theme$text$size, 9)
})

test_that("every registered figure type builds on example data", {
  for (ty in tlf_figure_types()$type) {
    if (ty == "km") skip_if_not_installed("survival")
    df <- switch(ty, km = ex_adtte, edish = ex_adlb, alt())
    expect_s3_class(ggplot2::ggplot_build(tlf_build_figure(ty, df))$plot, "ggplot")
  }
})
