# Crash isolation with a stub child that dies abruptly with exit status 139
# (the status of a SIGSEGV). To the parent this is identical to a native crash:
# the child never returns a value and no R condition reaches the parent.

crash_twice <- function(state) {
  n <- if (file.exists(state)) as.integer(readLines(state)) else 0L
  writeLines(as.character(n + 1L), state)
  if (n < 2L) quit(save = "no", status = 139L, runLast = FALSE)
  "rendered"
}

test_that("a crashing child becomes a retriable error; the third attempt succeeds", {
  skip_on_cran()
  state <- withr::local_tempfile()
  log <- withr::local_tempfile(fileext = ".csv")
  out <- tlf_run_isolated(crash_twice, list(state = state), retries = 2L, timeout = 60,
                          log_file = log, target = "stub.rtf")
  expect_identical(out, "rendered")
  lg <- utils::read.csv(log)
  expect_identical(lg$attempt, 1:3)
  expect_identical(lg$status, c("error", "error", "success"))
  expect_true(all(lg$target == "stub.rtf"))
})

test_that("exhausted retries raise a loud, classed error naming the attempt count", {
  skip_on_cran()
  state <- withr::local_tempfile()
  expect_error(tlf_run_isolated(crash_twice, list(state = state), retries = 1L, timeout = 60),
               "after 2 attempt", class = "tlfstack_render_failed")
})

test_that("a hung child counts as a failed attempt via the timeout", {
  skip_on_cran()
  expect_error(tlf_run_isolated(function() Sys.sleep(30), retries = 0L, timeout = 2),
               class = "tlfstack_render_failed")
})

test_that("in-process mode runs once and propagates errors", {
  expect_identical(tlf_run_isolated(function(x) x * 2, list(x = 2), isolate = FALSE), 4)
  expect_error(tlf_run_isolated(function() stop("boom"), isolate = FALSE), "boom")
  expect_error(tlf_run_isolated("nope"), "function")
})
