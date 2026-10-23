# Device-free suite: waterfall.

test_that("waterfall: one bar per subject, sorted descending", {
  p <- fig_waterfall(alt())
  bars <- layer_data_of(p, "GeomCol")[[1]]
  expect_equal(nrow(bars), length(unique(alt()$USUBJID)))
  ord <- bars$y[order(bars$x)]
  expect_true(all(diff(ord) <= 1e-9))
  expect_length(unique(bars$fill), 3)
})

test_that("waterfall labels and reference lines", {
  p <- fig_waterfall(alt(), ref_lines = c(-30, 20))
  expect_match(plot_label(p, "y"), "Best % change", fixed = TRUE)
  expect_match(plot_label(p, "x"), "ordered by best response")
  hl <- layer_data_of(p, "GeomHline")
  yi <- unlist(lapply(hl, `[[`, "yintercept"))
  expect_true(all(c(0, -30, 20) %in% yi))
})

test_that("waterfall prefers PCHG over AVAL/BASE", {
  d <- alt()
  d$PCHG <- ifelse(d$AVISITN > 0, -99, NA)
  bars <- layer_data_of(fig_waterfall(d), "GeomCol")[[1]]
  expect_true(all(abs(bars$y + 99) < 1e-6))
})

test_that("waterfall computes percent change when PCHG is absent", {
  d <- alt()[setdiff(names(alt()), "PCHG")]
  expect_s3_class(fig_waterfall(d), "ggplot")
})

test_that("waterfall guards and dispatch", {
  expect_s3_class(tlf_build_figure("waterfall", alt()), "ggplot")
  expect_s3_class(fig_waterfall(alt(), ctx = fig_ctx(trt_col = NULL)), "ggplot")
  expect_error(fig_waterfall(alt()[setdiff(names(alt()), "USUBJID")]), "USUBJID")
})
