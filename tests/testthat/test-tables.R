test_that("every builder returns the fixed tlf_table shape", {
  data <- list(adsl = ex_adsl, adae = ex_adae, bds = alt(), adtte = ex_adtte)
  types <- tlf_table_types()$type
  if (!requireNamespace("survival", quietly = TRUE)) types <- setdiff(types, "tte")
  for (ty in types) {
    r <- tlf_build_table(ty, data)
    expect_s3_class(r, "tlf_table")
    expect_named(r, c("df", "col_rel_width", "text_justification", "footnotes", "meta"))
    expect_length(r$col_rel_width, ncol(r$df))
    expect_true(all(vapply(r$df, is.character, logical(1))), info = ty)
  }
})

test_that("demographics: big-N headers, skipped variables recorded", {
  r <- tbl_demographics(ex_adsl, cont_vars = list(AGE = "Age", HEIGHT = "Height"))
  expect_true(all(grepl("\\(N=\\d+\\)$", names(r$df)[-(1:2)])))
  expect_identical(r$meta$skipped, "HEIGHT")
  expect_identical(r$df$Characteristic[1], "Age")
})

test_that("treatment variable falls back to configured candidates", {
  expect_message(r <- tbl_demographics(ex_adsl, trt_var = "NOPE"), "TRT01A")
  expect_identical(r$meta$trt_var, "TRT01A")
  bare <- ex_adsl[setdiff(names(ex_adsl), c("TRT01A", "TRT01P"))]
  expect_error(tbl_demographics(bare), "No treatment")
})

test_that("blank treatment values never become a column", {
  d <- ex_adsl
  d$TRT01A[1:3] <- ""
  r <- tbl_demographics(d)
  expect_false(any(startsWith(names(r$df), " (N=")))
  expect_true(any(names(r$df) == "Total (N=57)"))
})

test_that("AE table: totals, ordering, TEAE filter and denominators", {
  r <- tbl_ae(ex_adae, ex_adsl)
  expect_identical(r$df[[1]][1], "Subjects with at least one TEAE")
  expect_true(any(names(r$df) == "Total (N=60)"))
  te <- ex_adae[ex_adae$TRTEMFL == "Y", ]
  n_any <- length(unique(te$USUBJID))
  expect_match(r$df[1, "Total (N=60)"], paste0("^", n_any, " "))
  socs <- r$df[[1]][!startsWith(r$df[[1]], "  ")][-1]
  n_soc <- vapply(socs, function(s) length(unique(te$USUBJID[te$AESOC == s])), integer(1))
  expect_true(all(diff(n_soc) <= 0))
  r_all <- tbl_ae(ex_adae, ex_adsl, teae_flag = NULL)
  expect_gte(as.integer(sub(" .*", "", r_all$df[1, "Total (N=60)"])), n_any)
})

test_that("AE severity counts each subject once at the worst grade", {
  r <- tbl_ae_severity(ex_adae, ex_adsl)
  tot <- sum(as.integer(sub(" .*", "", r$df[-1, "Total (N=60)"])))
  n_any <- as.integer(sub(" .*", "", r$df[1, "Total (N=60)"]))
  expect_equal(tot, n_any)
})

test_that("disposition counts flags and discontinuation reasons", {
  r <- tbl_disposition(ex_adsl)
  expect_true("Discontinued study" %in% r$df$Category)
  n_disc <- sum(ex_adsl$EOSSTT == "DISCONTINUED")
  row <- r$df[r$df$Category == "Discontinued study", "Total (N=60)"]
  expect_match(row, paste0("^", n_disc, " "))
})

test_that("efficacy summary excludes baseline for CHG and fails on no post-baseline data", {
  r <- tbl_eff(ex_adlb, paramcd = "ALT")
  expect_false("Baseline" %in% r$meta$visits)
  r2 <- tbl_eff(ex_adlb, paramcd = "ALT", value_col = "AVAL")
  expect_true("Baseline" %in% r2$meta$visits)
  base_only <- ex_adlb[ex_adlb$AVISITN == 0, ]
  expect_error(tbl_eff(base_only, paramcd = "ALT"), "non-missing|post-baseline")
  expect_error(tbl_eff(ex_adlb, paramcd = "XYZ"), "PARAMCD")
})

test_that("time-to-event table reports medians and HR/log-rank footnotes", {
  skip_if_not_installed("survival")
  r <- tbl_tte(ex_adtte)
  expect_identical(r$df$Statistic, c("Subjects, n", "Events, n (%)", "Median time (95% CI)"))
  expect_length(grep("^Hazard ratio", r$footnotes), 2)
  expect_length(grep("^Log-rank p-value", r$footnotes), 1)
})

test_that("listings select, rename and sort", {
  r <- tbl_listing(ex_adae, listing_cols_ae)
  expect_identical(names(r$df)[1], "Subject")
  expect_false(is.unsorted(r$df$Subject))
  r2 <- tbl_listing(ex_adae, c(listing_cols_ae, NOPE = "Missing"))
  expect_identical(r2$meta$skipped, "NOPE")
  expect_error(tbl_listing(ex_adae, c(NOPE = "x")), "None")
})
