# Run a function with crash isolation and bounded retries

The general mechanism behind
[`tlf_rtf_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_figure.md).
With `isolate = TRUE`, `fun` runs in a fresh R process through
[`callr::r()`](https://callr.r-lib.org/reference/r.html), so `fun` must
be self-contained: it may only use its arguments and `pkg::fun` calls. A
crash, error or timeout in the child counts as a failed attempt. After
`retries + 1` failed attempts an error is raised that names the attempt
count and the last error message. Nothing fails silently.

## Usage

``` r
tlf_run_isolated(
  fun,
  args = list(),
  isolate = TRUE,
  retries = 2L,
  timeout = 90,
  log_file = NULL,
  target = ""
)
```

## Arguments

- fun:

  Function to run.

- args:

  List of arguments for `fun`.

- isolate:

  Run in a child process? With `FALSE`, `fun` runs in-process once and
  is not retried.

- retries:

  Extra attempts after a failure.

- timeout:

  Per-attempt timeout in seconds.

- log_file:

  Optional CSV path; one row is appended per attempt.

- target:

  Label written to the log, for example the output file name.

## Value

The value returned by `fun`.

## Details

The current policy has no backoff between attempts and no detection of
deterministic crashes.

## Examples

``` r
tlf_run_isolated(function(x) x + 1, list(x = 1), isolate = FALSE)
#> [1] 2
```
