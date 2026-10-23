# Figure render policy

Figure render policy

## Usage

``` r
tlf_render_opts(
  isolate = TRUE,
  retries = 2L,
  timeout = 90,
  dpi = 300,
  log_file = NULL
)
```

## Arguments

- isolate:

  Render figures in a child R process (via callr), so a native crash in
  the graphics stack cannot kill the calling session.

- retries:

  Extra attempts after a failed isolated render. The default of 2 means
  up to three attempts in total.

- timeout:

  Per-attempt timeout in seconds. A hung render counts as a failed
  attempt.

- dpi:

  Resolution of the embedded PNG.

- log_file:

  Optional CSV path. When set, one row is appended per render attempt.

## Value

An object of class `tlf_render_opts`.

## Examples

``` r
tlf_render_opts(retries = 0)
#> $isolate
#> [1] TRUE
#> 
#> $retries
#> [1] 0
#> 
#> $timeout
#> [1] 90
#> 
#> $dpi
#> [1] 300
#> 
#> $log_file
#> NULL
#> 
#> attr(,"class")
#> [1] "tlf_render_opts"
```
