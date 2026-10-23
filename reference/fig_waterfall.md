# Waterfall plot of best percent change

One bar per subject: the minimum post-baseline percent change, from
`PCHG` or computed from `AVAL` and `BASE`.

## Usage

``` r
fig_waterfall(
  df,
  ctx = fig_ctx(),
  ref_lines = NULL,
  base_size = NULL,
  config = NULL
)
```

## Arguments

- df:

  Analysis data (BDS).

- ctx:

  A
  [`fig_ctx()`](https://yanmingyu92.github.io/tlfstack/reference/fig_ctx.md)
  list.

- ref_lines:

  Optional horizontal reference lines (for example `c(-30, 20)`).

- base_size:

  Font size; `NULL` uses the configuration.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

## Value

A ggplot.

## See also

Other figure builders:
[`fig_boxplot()`](https://yanmingyu92.github.io/tlfstack/reference/fig_boxplot.md),
[`fig_edish()`](https://yanmingyu92.github.io/tlfstack/reference/fig_edish.md),
[`fig_forest()`](https://yanmingyu92.github.io/tlfstack/reference/fig_forest.md),
[`fig_km()`](https://yanmingyu92.github.io/tlfstack/reference/fig_km.md),
[`fig_lsmeans()`](https://yanmingyu92.github.io/tlfstack/reference/fig_lsmeans.md),
[`fig_meanci()`](https://yanmingyu92.github.io/tlfstack/reference/fig_meanci.md),
[`fig_shift()`](https://yanmingyu92.github.io/tlfstack/reference/fig_shift.md),
[`fig_spaghetti()`](https://yanmingyu92.github.io/tlfstack/reference/fig_spaghetti.md)

## Examples

``` r
p <- fig_waterfall(ex_adlb[ex_adlb$PARAMCD == "ALT", ], ref_lines = c(-30, 20))
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
