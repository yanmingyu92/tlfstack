# Device-free suite: Kaplan-Meier.

test_that("example ADTTE follows the AVAL/CNSR convention", {
  expect_true(all(c("AVAL", "CNSR") %in% names(ex_adtte)))
  expect_true(all(ex_adtte$CNSR %in% c(0, 1)))
  expect_true(any(ex_adtte$CNSR == 0) && any(ex_adtte$CNSR == 1))
  expect_equal(nrow(ex_adtte), length(unique(ex_adtte$USUBJID)))
})

test_that("KM builds one step curve per arm, starting at 1, bounded in [0, 1]", {
  skip_if_not_installed("survival")
  p <- fig_km(ex_adtte)
  expect_s3_class(p, "ggplot")
  stp <- layer_data_of(p, "GeomStep")[[1]]
  expect_gt(nrow(stp), 0)
  expect_length(unique(stp$group), 3)
  expect_true(all(stp$y >= 0 & stp$y <= 1))
  expect_equal(max(stp$y), 1)
})

test_that("KM axes are labelled from the unit", {
  skip_if_not_installed("survival")
  p <- fig_km(ex_adtte)
  expect_equal(plot_label(p, "x"), "Time (DAYS)")
  expect_equal(plot_label(p, "y"), "Survival probability")
})

test_that("KM censor marks can be switched off", {
  skip_if_not_installed("survival")
  expect_length(layer_data_of(fig_km(ex_adtte), "GeomPoint"), 1)
  expect_length(layer_data_of(fig_km(ex_adtte, censor_marks = FALSE), "GeomPoint"), 0)
})

test_that("KM without a treatment column draws a single curve", {
  skip_if_not_installed("survival")
  d <- ex_adtte[setdiff(names(ex_adtte), "TRT01A")]
  stp <- layer_data_of(fig_km(d), "GeomStep")[[1]]
  expect_length(unique(stp$group), 1)
})

test_that("KM routes through the dispatcher and guards bad input", {
  skip_if_not_installed("survival")
  expect_s3_class(tlf_build_figure("km", ex_adtte), "ggplot")
  expect_error(fig_km(ex_adtte[setdiff(names(ex_adtte), "CNSR")]), "CNSR")
  bad <- ex_adtte
  bad$AVAL <- NA
  expect_error(fig_km(bad), "time-to-event")
})
