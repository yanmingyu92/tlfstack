# Subgroup forest plot

Treatment effect, comparator versus reference, overall and within each
level of `subgroup_var`. With time-to-event data (`CNSR` present) the
effect is a Cox hazard ratio on a log scale, and the survival package is
required. Otherwise it is a difference in means (Welch t-test) at the
last visit. Subgroups that cannot be estimated are dropped and listed in
the `tlf_dropped` attribute.

## Usage

``` r
fig_forest(
  df,
  ctx = fig_ctx(),
  subgroup_var = NULL,
  ref_arm = NULL,
  comp_arm = NULL,
  ci = 0.95,
  point_labels = TRUE,
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

- subgroup_var:

  Subgroup column. `NULL` uses the first of `SEX`, `AGEGR1`, `RACE`,
  `REGION` present.

- ref_arm, comp_arm:

  Reference and comparator arms (default: first and last arm in sort
  order).

- ci:

  Confidence level.

- point_labels:

  Print the estimate and CI next to each row?

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
[`fig_km()`](https://yanmingyu92.github.io/tlfstack/reference/fig_km.md),
[`fig_lsmeans()`](https://yanmingyu92.github.io/tlfstack/reference/fig_lsmeans.md),
[`fig_meanci()`](https://yanmingyu92.github.io/tlfstack/reference/fig_meanci.md),
[`fig_shift()`](https://yanmingyu92.github.io/tlfstack/reference/fig_shift.md),
[`fig_spaghetti()`](https://yanmingyu92.github.io/tlfstack/reference/fig_spaghetti.md),
[`fig_waterfall()`](https://yanmingyu92.github.io/tlfstack/reference/fig_waterfall.md)

## Examples

``` r
p <- fig_forest(ex_adlb[ex_adlb$PARAMCD == "ALT", ], subgroup_var = "SEX")
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
