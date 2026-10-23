# Individual-subject lines with an optional mean overlay

Individual-subject lines with an optional mean overlay

## Usage

``` r
fig_spaghetti(
  df,
  ctx = fig_ctx(),
  value_col = "AVAL",
  mean_overlay = TRUE,
  line_alpha = 0.25,
  ci = 0.95,
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

- mean_overlay:

  Overlay the mean with a CI ribbon?

- line_alpha:

  Transparency of subject lines.

- ci:

  Confidence level.

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
[`fig_waterfall()`](https://yanmingyu92.github.io/tlfstack/reference/fig_waterfall.md)

## Examples

``` r
p <- fig_spaghetti(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
