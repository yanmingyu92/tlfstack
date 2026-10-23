# gtsummary / cards (ARD) interoperability: the body layer comes from the
# pharmaverse table packages, the convention layer from tlfstack.

test_that("data frames and tlf_tables convert; other objects fail clearly", {
  tb <- as_tlf_table(data.frame(a = "1", b = "2"))
  expect_s3_class(tb, "tlf_table")
  expect_identical(as_tlf_table(tb), tb)
  expect_error(as_tlf_table(1:3), "Cannot convert")
})

test_that("gtsummary tables keep labels, indentation and footnotes", {
  skip_if_not_installed("gtsummary")
  gt <- gtsummary::tbl_summary(ex_adsl, by = TRT01A, include = c(AGE, SEX))
  tb <- as_tlf_table(gt)
  expect_identical(names(tb$df)[1], "Characteristic")
  expect_true(all(grepl("\\(N = \\d+\\)$", names(tb$df)[-1])))
  expect_false(any(grepl("\\*\\*", names(tb$df))))
  expect_true("SEX" %in% tb$df[[1]])
  expect_true(any(startsWith(tb$df[[1]], "    ")))   # levels indented
  expect_match(tb$footnotes, "Median \\(Q1, Q3\\); n \\(%\\)")
  expect_identical(tb$meta$source, "gtsummary")
  expect_false(is.null(tb$meta$ard))
})

test_that("hierarchical AE tables keep their nesting", {
  skip_if_not_installed("gtsummary")
  gt <- gtsummary::tbl_hierarchical(ex_adae, variables = c(AESOC, AEDECOD), by = TRT01A,
                                    id = USUBJID, denominator = ex_adsl)
  tb <- as_tlf_table(gt)
  first <- tb$df[[1]]
  expect_true(any(!startsWith(first, " ")) && any(startsWith(first, " ")))
})

test_that("gtsummary tables render under tlfstack conventions with TOC titles", {
  skip_if_not_installed("gtsummary")
  gt <- gtsummary::tbl_summary(ex_adsl, by = TRT01A, include = c(AGE, SEX))
  t <- tlf_resolve_titles("t_demo", sources = toc_source_data(ex_toc), scope = list(study = "STUDY01"))
  f <- withr::local_tempfile(fileext = ".rtf")
  tlf_rtf_table(gt, f, titles = t, config = tlf_config(header_left = "Example Organization"))
  txt <- rtf_text(f)
  expect_match(txt, "Table 14.1.1", fixed = TRUE)
  expect_match(txt, "Example Organization", fixed = TRUE)
  expect_match(txt, "Median (Q1, Q3); n (%)", fixed = TRUE)
  # TOC footnote comes before the gtsummary footnote
  expect_lt(regexpr("Percentages are based", txt, fixed = TRUE),
            regexpr("Median (Q1, Q3); n (%)", txt, fixed = TRUE))
})

test_that("registered builders may return gtsummary tables", {
  skip_if_not_installed("gtsummary")
  tlf_register_table("demog_gts", function(data, opts, config) {
    gtsummary::tbl_summary(data$adsl, by = TRT01A, include = c(AGE, SEX))
  }, domains = "adsl")
  withr::defer(tlf_unregister("demog_gts"))
  tb <- tlf_build_table("demog_gts", list(adsl = ex_adsl))
  expect_s3_class(tb, "tlf_table")
  expect_identical(tb$meta$source, "gtsummary")
})

test_that("cards ARD formats through gtsummary and renders", {
  skip_if_not_installed("gtsummary")
  skip_if_not_installed("cards")
  ard <- cards::ard_stack(ex_adsl, .by = TRT01A,
                          cards::ard_continuous(variables = AGE),
                          cards::ard_categorical(variables = SEX))
  tb <- as_tlf_table(ard, by = "TRT01A")
  expect_s3_class(tb, "tlf_table")
  expect_identical(tb$meta$source, "card")
  expect_s3_class(tlf_ard(tb), "card")
  f <- withr::local_tempfile(fileext = ".rtf")
  tlf_rtf_table(ard, f, titles = "Demographics from ARD")
  expect_match(rtf_text(f), "Demographics from ARD", fixed = TRUE)
})

test_that("ARD export flattens one row per statistic for QC", {
  skip_if_not_installed("cards")
  ard <- cards::ard_continuous(ex_adsl, by = TRT01A, variables = AGE)
  f <- withr::local_tempfile(fileext = ".csv")
  tlf_write_ard(ard, f)
  out <- utils::read.csv(f)
  mean_placebo <- out$stat[out$stat_name == "mean" & out$group1_level == "Placebo"]
  expect_equal(mean_placebo, mean(ex_adsl$AGE[ex_adsl$TRT01A == "Placebo"]))
  skip_if_not_installed("gtsummary")
  gt <- gtsummary::tbl_summary(ex_adsl, by = TRT01A, include = AGE) |> gtsummary::add_overall()
  f2 <- withr::local_tempfile(fileext = ".csv")
  tlf_write_ard(gt, f2)
  expect_true(all(c("tbl_summary", "add_overall") %in% utils::read.csv(f2)$component))
  expect_error(tlf_write_ard(tlf_table_result(data.frame(a = "1")), f2), "No Analysis Results Data")
  expect_error(tlf_write_ard(ard, withr::local_tempfile(fileext = ".txt")), "Unsupported")
})

test_that("markdown is stripped from gtsummary text", {
  expect_identical(tlfstack:::strip_md("**Drug A**  \nN = 20"), "Drug A (N = 20)")
  expect_identical(tlfstack:::strip_md("_Placebo_ arm"), "Placebo arm")
  expect_identical(tlfstack:::strip_md("snake_case_name"), "snake_case_name")
})
