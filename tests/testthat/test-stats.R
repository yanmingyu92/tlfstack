test_that("p-values are formatted adaptively", {
  expect_identical(format_pvalue(c(0.0321, 0.0004, NA, Inf, 0.001)),
                   c("0.032", "<0.001", "", "", "0.001"))
})

test_that("big N counts distinct subjects per arm and in total", {
  n <- stat_big_n(ex_adsl, "TRT01A")
  expect_equal(unname(n["Total"]), 60L)
  expect_equal(sum(n[names(n) != "Total"]), 60L)
  n2 <- stat_big_n(ex_adae, "TRT01A")
  expect_lte(n2[["Total"]], 60L)
})

test_that("descriptive statistics match base R (SAS-default quartiles)", {
  d <- data.frame(USUBJID = 1:5, TRT = "A", X = c(1, 2, 3, 4, 10))
  s <- stat_desc(d, "X", "TRT", total = FALSE)
  expect_identical(s$A, c("5", "4.0 (3.5)", "3.0 (2.0, 4.0)", "1.0, 10.0"))
})

test_that("a single value gives SD 'NE' and an empty group gives n = 0", {
  d <- data.frame(USUBJID = 1:2, TRT = c("A", "B"), X = c(5, NA))
  s <- stat_desc(d, "X", "TRT", total = FALSE)
  expect_identical(s$A[2], "5.0 (NE)")
  expect_identical(s$B[1], "0")
})

test_that("frequencies use subject denominators and the zero convention", {
  d <- data.frame(USUBJID = 1:4, TRT = c("A", "A", "B", "B"), SEX = c("F", "F", "F", "M"))
  f <- stat_freq(d, "SEX", "TRT")
  expect_identical(f$A, c("2 (100.0%)", "0"))
  expect_identical(f$Total, c("3 (75.0%)", "1 (25.0%)"))
})

test_that("group order follows factor levels", {
  d <- ex_adsl
  d$TRT01A <- factor(d$TRT01A, levels = c("Placebo", "Drug 10 mg", "Drug 20 mg"))
  expect_identical(names(stat_big_n(d, "TRT01A"))[1], "Placebo")
  expect_identical(names(stat_desc(d, "AGE", "TRT01A"))[4], "Placebo")
})
