# Box plot by visit

Box plot by visit

## Usage

``` r
fig_boxplot(
  df,
  ctx = fig_ctx(),
  value_col = "AVAL",
  jitter = TRUE,
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

- value_col:

  `"AVAL"` or `"CHG"`.

- jitter:

  Overlay individual points?

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
[`fig_edish()`](https://yanmingyu92.github.io/tlfstack/reference/fig_edish.md),
[`fig_forest()`](https://yanmingyu92.github.io/tlfstack/reference/fig_forest.md),
[`fig_km()`](https://yanmingyu92.github.io/tlfstack/reference/fig_km.md),
[`fig_lsmeans()`](https://yanmingyu92.github.io/tlfstack/reference/fig_lsmeans.md),
[`fig_meanci()`](https://yanmingyu92.github.io/tlfstack/reference/fig_meanci.md),
[`fig_shift()`](https://yanmingyu92.github.io/tlfstack/reference/fig_shift.md),
[`fig_spaghetti()`](https://yanmingyu92.github.io/tlfstack/reference/fig_spaghetti.md),
[`fig_waterfall()`](https://yanmingyu92.github.io/tlfstack/reference/fig_waterfall.md)

## Examples

``` r
p <- fig_boxplot(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
