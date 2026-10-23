test_that("manual title blocks keep every part in its own field", {
  t <- tlf_titles("Summary of Demographics", type = "Table", number = "14.1.1",
                  subtitle = "Safety Population", footnotes = "Note A.",
                  pre_title = "Study STUDY01", source = "Program: t_demo.R")
  expect_identical(t$banner, "Table 14.1.1")
  expect_identical(tlfstack:::title_block_lines(t),
                   c("Study STUDY01", "Table 14.1.1", "Summary of Demographics", "Safety Population"))
  expect_identical(t$provenance$mode, "manual")
  expect_output(print(t), "Table 14.1.1")
})

test_that("title blocks are validated", {
  expect_error(tlf_titles(character()), "title")
  expect_error(tlf_titles("x", footnotes = NA_character_), "footnotes")
  expect_error(tlf_titles("x", type = "Graph"))
})

test_that("placeholders are filled, and unfilled ones stay visible with a warning", {
  t <- tlf_titles("Summary of {param} at {visit}", vars = list(param = "ALT", visit = "Week 12"))
  expect_identical(t$title, "Summary of ALT at Week 12")
  expect_warning(t2 <- tlf_titles("Summary of {param}"), class = "tlfstack_unfilled_placeholder")
  expect_identical(t2$title, "Summary of {param}")
})

test_that("builder footnotes are appended after TOC footnotes, de-duplicated", {
  t <- tlf_titles("x", footnotes = c("A.", "B."))
  t2 <- tlf_titles_add_footnotes(t, c("B.", "C."))
  expect_identical(t2$footnotes, c("A.", "B.", "C."))
  expect_identical(t$footnotes, c("A.", "B."))
})
