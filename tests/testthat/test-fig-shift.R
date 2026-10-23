# Device-free suite: shift plot (and the shared pairing used by tbl_shift).

test_that("example lab data carries two-sided reference ranges", {
  expect_true(all(c("ANRLO", "ANRHI") %in% names(ex_adlb)))
  expect_true(all(alt()$ANRLO < alt()$ANRHI))
})

test_that("shift plot builds a tile grid with count labels", {
  p <- fig_shift(alt())
  expect_s3_class(p, "ggplot")
  tiles <- layer_data_of(p, "GeomTile")[[1]]
  expect_gt(nrow(tiles), 0)
  txt <- layer_data_of(p, "GeomText")[[1]]
  expect_true("label" %in% names(txt))
})

test_that("shift counts are conserved: each subject counted once", {
  b <- ggplot2::ggplot_build(fig_shift(alt()))
  total <- sum(as.integer(b$data[[2]]$label))
  expect_equal(total, length(unique(alt()$USUBJID)))
})

test_that("shift plot labels and facets", {
  p <- fig_shift(alt())
  expect_match(plot_label(p, "x"), "Baseline category")
  expect_match(plot_label(p, "y"), "Endpoint category")
  expect_equal(nrow(ggplot2::ggplot_build(p)$layout$layout), 3)
  pn <- fig_shift(alt(), ctx = fig_ctx(trt_col = NULL))
  expect_equal(nrow(ggplot2::ggplot_build(pn)$layout$layout), 1)
})

test_that("shift guards and dispatch", {
  d <- alt()
  d$ANRLO <- NA
  d$ANRHI <- NA
  d$AVAL <- NA
  expect_error(fig_shift(d), "ANRLO|categorized")
  expect_s3_class(tlf_build_figure("shift", alt()), "ggplot")
})

test_that("tbl_shift agrees with the figure", {
  tb <- tbl_shift(alt())
  cnt <- as.integer(unlist(tb$df[, 3:5]))
  expect_equal(sum(cnt), length(unique(alt()$USUBJID)))
})
