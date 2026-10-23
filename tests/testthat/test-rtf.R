test_that("font indices are resolved by name from r2rtf's public output", {
  expect_identical(tlfstack:::rtf_font_index("Courier New"), 9L)
  expect_identical(tlfstack:::rtf_font_index("arial"), 4L)
  expect_error(tlfstack:::rtf_font_index("Comic Sans"), "not in the r2rtf font table")
})

test_that("table RTF carries the conventions and the title block", {
  f <- withr::local_tempfile(fileext = ".rtf")
  t <- tlf_titles("Summary of Demographics", number = "14.1.1", subtitle = "Safety Population",
                  footnotes = "Percentages use N per column.", source = "Program: t_demo.R")
  cfg <- tlf_config(header_left = "Example Organization")
  tlf_rtf_table(tbl_demographics(ex_adsl), f, titles = t, config = cfg)
  txt <- rtf_text(f)
  expect_match(txt, "\\paperw15840\\paperh12240\\landscape", fixed = TRUE) # 11 x 8.5 in
  expect_match(txt, "Table 14.1.1", fixed = TRUE)
  expect_match(txt, "Summary of Demographics", fixed = TRUE)
  expect_match(txt, "Safety Population", fixed = TRUE)
  expect_match(txt, "Percentages use N per column.", fixed = TRUE)
  expect_match(txt, "Program: t_demo.R", fixed = TRUE)
  expect_match(txt, "Example Organization", fixed = TRUE)
  expect_match(txt, "\\f8", fixed = TRUE) # Courier New (0-based in the RTF font table)
})

test_that("REGRESSION: text is rendered verbatim, not as markup", {
  # r2rtf's default markup conversion turns `t_demo.R` into t + subscript and
  # `>=` into a symbol, which breaks character-identical title blocks.
  f <- withr::local_tempfile(fileext = ".rtf")
  t <- tlf_titles("Values >= 1 for {group}", footnotes = "x_y \\ z", source = "Program: t_demo.R",
                  vars = list())
  suppressWarnings(tlf_rtf_table(data.frame(Term = "a_b >= 2"), f, titles = t))
  txt <- rtf_text(f)
  expect_match(txt, "Program: t_demo.R", fixed = TRUE)
  expect_match(txt, "a_b >= 2", fixed = TRUE)
  expect_match(txt, "Values >= 1 for \\{group\\}", fixed = TRUE)
  expect_match(txt, "x_y \\\\ z", fixed = TRUE)
  expect_false(grepl("\\sub", txt, fixed = TRUE))
})

test_that("non-ASCII text is written as RTF Unicode escapes", {
  expect_identical(tlfstack:::rtf_escape("µg ≥ 1"), "\\u181?g \\u8805? 1")
  expect_identical(tlfstack:::rtf_escape("\U0001F600"), "\\u-10179?\\u-8704?")
  expect_identical(tlfstack:::rtf_escape(c("a{b}", NA)), c("a\\{b\\}", ""))
})

test_that("page-field tokens expand in the header and nowhere else", {
  f <- withr::local_tempfile(fileext = ".rtf")
  tlf_rtf_table(data.frame(a = "\\pagenumber"), f, config = tlf_config(header_left = "Org"))
  txt <- rtf_text(f)
  expect_match(txt, "Page \\chpgn  of {\\field{\\*\\fldinst NUMPAGES }}", fixed = TRUE)
  expect_match(txt, "\\\\pagenumber", fixed = TRUE) # body cell stays literal text
})

test_that("r2rtf markup conversion can be opted into", {
  f <- withr::local_tempfile(fileext = ".rtf")
  tlf_rtf_table(data.frame(a = "x"), f, titles = "Program: t_demo.R",
                config = tlf_config(text_convert = TRUE))
  expect_match(rtf_text(f), "\\sub", fixed = TRUE)
})

test_that("builder footnotes are rendered after title-block footnotes", {
  skip_if_not_installed("survival")
  f <- withr::local_tempfile(fileext = ".rtf")
  tlf_rtf_table(tbl_tte(ex_adtte), f, titles = tlf_titles("TTE", footnotes = "TOC note."))
  txt <- rtf_text(f)
  expect_lt(regexpr("TOC note.", txt, fixed = TRUE), regexpr("Log-rank p-value", txt, fixed = TRUE))
})

test_that("portrait pages get portrait dimensions in tables too", {
  f <- withr::local_tempfile(fileext = ".rtf")
  cfg <- tlf_config(page = tlf_page("portrait"))
  tlf_rtf_table(data.frame(a = "1"), f, config = cfg)
  txt <- rtf_text(f)
  expect_match(txt, "\\paperw12240", fixed = TRUE) # 8.5 in
  expect_false(grepl("\\landscape", txt, fixed = TRUE))
})

test_that("empty tables render a no-data row; bad widths and headers fail", {
  f <- withr::local_tempfile(fileext = ".rtf")
  tlf_rtf_listing(data.frame(Subject = character(), Term = character()), f)
  expect_match(rtf_text(f), "No data to report.", fixed = TRUE)
  expect_error(tlf_rtf_table(data.frame(a = 1, b = 2), f, col_rel_width = 1), "col_rel_width")
  expect_error(tlf_rtf_table(data.frame(`a|b` = 1, check.names = FALSE), f), "colheader")
  expect_error(tlf_rtf_table(list(1), f), "tlf_table")
})

test_that("figure RTF renders in-process with the same text layer", {
  skip_on_cran()
  f <- withr::local_tempfile(fileext = ".rtf")
  p <- fig_meanci(alt())
  t <- tlf_titles("Mean ALT by Visit", type = "Figure", number = "14.2.3")
  suppressWarnings(tlf_rtf_figure(p, f, titles = t, render = tlf_render_opts(isolate = FALSE)))
  txt <- rtf_text(f)
  expect_match(txt, "Figure 14.2.3", fixed = TRUE)
  expect_match(txt, "\\pngblip", fixed = TRUE)
  expect_error(tlf_rtf_figure("not a plot", f), "ggplot")
})

test_that("figure RTF renders crash-isolated in a child process", {
  skip_on_cran()
  f <- withr::local_tempfile(fileext = ".rtf")
  log <- withr::local_tempfile(fileext = ".csv")
  suppressWarnings(tlf_rtf_figure(fig_boxplot(alt()), f, titles = "Box plot",
                                  render = tlf_render_opts(retries = 1, log_file = log)))
  expect_true(file.exists(f))
  lg <- utils::read.csv(log)
  expect_identical(lg$status, "success")
  expect_identical(lg$attempt, 1L)
})
