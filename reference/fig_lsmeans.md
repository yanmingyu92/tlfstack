# LS-means by visit

Per-visit ANCOVA of `value_col` on treatment, adjusted for baseline
(`BASE`) when it is available. The baseline visit (lowest `AVISITN`) is
then excluded. This is a per-visit model, not an MMRM.

## Usage

``` r
fig_lsmeans(
  df,
  ctx = fig_ctx(),
  value_col = "AVAL",
  ci = 0.95,
  point_labels = FALSE,
  show_n = FALSE,
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

- ci:

  Confidence level.

- point_labels:

  Print the mean above each point?

- show_n:

  Print per-visit N under the panel?

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
[`fig_meanci()`](https://yanmingyu92.github.io/tlfstack/reference/fig_meanci.md),
[`fig_shift()`](https://yanmingyu92.github.io/tlfstack/reference/fig_shift.md),
[`fig_spaghetti()`](https://yanmingyu92.github.io/tlfstack/reference/fig_spaghetti.md),
[`fig_waterfall()`](https://yanmingyu92.github.io/tlfstack/reference/fig_waterfall.md)

## Examples

``` r
p <- fig_lsmeans(ex_adlb[ex_adlb$PARAMCD == "ALT", ], value_col = "CHG")
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
