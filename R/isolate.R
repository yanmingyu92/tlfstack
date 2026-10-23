# Crash isolation. A native crash (for example a segfault in a graphics
# device) is an operating-system signal, not an R condition, so tryCatch()
# cannot catch it. Running the work in a short-lived callr child turns a crash
# into an ordinary error in the parent, which a bounded retry loop can count.
# This is a documented workaround built on callr, not a new technique.

.tlf_env <- new.env(parent = emptyenv())

log_attempt <- function(log_file, target, attempt, status, msg = "") {
  if (is.null(log_file)) return(invisible(NULL))
  row <- data.frame(timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
                    target = target, attempt = attempt, status = status,
                    error = gsub("[\r\n]+", " ", msg), stringsAsFactors = FALSE)
  exists <- file.exists(log_file)
  utils::write.table(row, log_file, sep = ",", row.names = FALSE, col.names = !exists,
                     append = exists, qmethod = "double")
  invisible(NULL)
}

#' Run a function with crash isolation and bounded retries
#'
#' The general mechanism behind [tlf_rtf_figure()]. With `isolate = TRUE`,
#' `fun` runs in a fresh R process through [callr::r()], so `fun` must be
#' self-contained: it may only use its arguments and `pkg::fun` calls. A
#' crash, error or timeout in the child counts as a failed attempt. After
#' `retries + 1` failed attempts an error is raised that names the attempt
#' count and the last error message. Nothing fails silently.
#'
#' The current policy has no backoff between attempts and no detection of
#' deterministic crashes.
#'
#' @param fun Function to run.
#' @param args List of arguments for `fun`.
#' @param isolate Run in a child process? With `FALSE`, `fun` runs in-process
#'   once and is not retried.
#' @param retries Extra attempts after a failure.
#' @param timeout Per-attempt timeout in seconds.
#' @param log_file Optional CSV path; one row is appended per attempt.
#' @param target Label written to the log, for example the output file name.
#' @return The value returned by `fun`.
#' @examples
#' tlf_run_isolated(function(x) x + 1, list(x = 1), isolate = FALSE)
#' @export
tlf_run_isolated <- function(fun, args = list(), isolate = TRUE, retries = 2L,
                             timeout = 90, log_file = NULL, target = "") {
  if (!is.function(fun)) tlf_abort("`fun` must be a function.")
  if (!isTRUE(isolate)) {
    out <- tryCatch(do.call(fun, args), error = function(e) {
      log_attempt(log_file, target, 1L, "error", conditionMessage(e))
      stop(e)
    })
    log_attempt(log_file, target, 1L, "success")
    return(out)
  }
  attempts <- max(1L, as.integer(retries) + 1L)
  last_msg <- "unknown error"
  for (i in seq_len(attempts)) {
    res <- tryCatch(callr::r(fun, args = args, timeout = timeout, spinner = FALSE),
                    error = function(e) e)
    if (!inherits(res, "condition")) {
      log_attempt(log_file, target, i, "success")
      return(res)
    }
    last_msg <- conditionMessage(res)
    log_attempt(log_file, target, i, "error", last_msg)
  }
  tlf_abort(sprintf("Isolated render failed after %d attempt(s): %s", attempts, last_msg),
            class = "tlfstack_render_failed")
}
