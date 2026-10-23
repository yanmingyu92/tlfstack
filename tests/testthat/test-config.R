test_that("default configuration is neutral and valid", {
  cfg <- tlf_config()
  expect_s3_class(cfg, "tlf_config")
  expect_identical(cfg$header_left, "")
  expect_equal(c(cfg$page$width, cfg$page$height), c(11, 8.5))
  expect_equal(cfg$page$margin, rep(0.5, 6))
  expect_output(print(cfg), "Courier New 9")
})

test_that("page geometry is oriented and validated", {
  pg <- tlf_page("portrait")
  expect_equal(c(pg$width, pg$height), c(8.5, 11))
  expect_lte(pg$fig_width, 8.5 - 1)
  expect_equal(c(tlf_page_a4_landscape()$width, tlf_page_a4_landscape()$height), c(11.69, 8.27))
  expect_error(tlf_page(margin = c(1, 1)), "six")
  expect_error(tlf_page(fig_width = 20), "does not fit")
})

test_that("font conventions enforce the figure size range", {
  expect_error(tlf_fonts(figure_size = 12), "outside the configured range")
  expect_error(theme_tlf_submission(base_size = 8), "outside")
  expect_s3_class(theme_tlf_submission(base_size = 9), "theme")
})

test_that("config update returns a modified copy", {
  a <- tlf_config()
  b <- tlf_config_update(a, header_left = "Org")
  expect_identical(a$header_left, "")
  expect_identical(b$header_left, "Org")
  expect_identical(tlf_config_update(a), a)
  expect_error(tlf_config_update(a, nope = 1), "Unknown")
})

test_that("precedence: argument > option > env file > defaults", {
  skip_if_not_installed("yaml")
  f <- withr::local_tempfile(fileext = ".yml")
  writeLines(c("header_left: From file", "fonts:", "  text_size: 8"), f)
  withr::local_envvar(TLFSTACK_CONFIG = f)
  withr::local_options(tlfstack.config = NULL)
  expect_identical(tlf_get_config()$header_left, "From file")
  expect_equal(tlf_get_config()$fonts$text_size, 8)
  withr::local_options(tlfstack.config = tlf_config(header_left = "From option"))
  expect_identical(tlf_get_config()$header_left, "From option")
  expect_identical(tlf_get_config(tlf_config(header_left = "Arg"))$header_left, "Arg")
})

test_that("config files reject unknown keys", {
  skip_if_not_installed("yaml")
  f <- withr::local_tempfile(fileext = ".yml")
  writeLines("colour_scheme: red", f)
  expect_error(tlf_config_read(f), "Unknown key")
  writeLines(c("page:", "  orientation: portrait", "render:", "  retries: 0"), f)
  cfg <- tlf_config_read(f)
  expect_equal(cfg$page$orientation, "portrait")
  expect_equal(cfg$render$retries, 0L)
})

test_that("render options are validated", {
  expect_error(tlf_render_opts(retries = -1), "non-negative")
  expect_error(tlf_render_opts(timeout = 0), "positive")
  expect_error(tlf_render_opts(isolate = NA), "TRUE or FALSE")
})
