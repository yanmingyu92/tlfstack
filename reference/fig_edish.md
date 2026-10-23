# eDISH (Hy's Law) plot

Each subject's peak transaminase versus peak total bilirubin, as
multiples of the upper limit of normal (`AVAL / ANRHI`), on log scales,
with reference lines at 3x and 2x ULN.

## Usage

``` r
fig_edish(
  df,
  ctx = fig_ctx(),
  enzyme = c("ALT", "AST"),
  bili_codes = c("BILI", "TBILI", "BILTOT"),
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

- enzyme:

  `"ALT"` or `"AST"`.

- bili_codes:

  `PARAMCD` values accepted for total bilirubin.

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
[`fig_forest()`](https://yanmingyu92.github.io/tlfstack/reference/fig_forest.md),
[`fig_km()`](https://yanmingyu92.github.io/tlfstack/reference/fig_km.md),
[`fig_lsmeans()`](https://yanmingyu92.github.io/tlfstack/reference/fig_lsmeans.md),
[`fig_meanci()`](https://yanmingyu92.github.io/tlfstack/reference/fig_meanci.md),
[`fig_shift()`](https://yanmingyu92.github.io/tlfstack/reference/fig_shift.md),
[`fig_spaghetti()`](https://yanmingyu92.github.io/tlfstack/reference/fig_spaghetti.md),
[`fig_waterfall()`](https://yanmingyu92.github.io/tlfstack/reference/fig_waterfall.md)

## Examples

``` r
p <- fig_edish(ex_adlb)
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
