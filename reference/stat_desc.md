# Descriptive statistics for a continuous variable

Returns n, Mean (SD), Median (Q1, Q3) and Min, Max per group. Quartiles
use `stats::quantile(type = 2)`, which is the analogue of the SAS
default percentile definition (PCTLDEF=5).

## Usage

``` r
stat_desc(
  df,
  var,
  trt_var,
  label = var,
  digits = 1L,
  total = TRUE,
  total_label = "Total"
)
```

## Arguments

- df:

  Data frame.

- var:

  Analysis column.

- trt_var:

  Treatment/grouping column.

- label:

  Row label for the block.

- digits:

  Decimals for the mean, SD, median and quartiles.

- total:

  Add a total column?

- total_label:

  Name of the total column.

## Value

Data frame with columns `param`, `label`, `stat` and one column per
group.

## Examples

``` r
stat_desc(ex_adsl, "AGE", "TRT01A", label = "Age (years)")
#>         param       label            stat        Drug 10 mg        Drug 20 mg
#> 1 Age (years) Age (years)               n                20                20
#> 2 Age (years) Age (years)       Mean (SD)        58.2 (8.4)        59.6 (9.5)
#> 3 Age (years) Age (years) Median (Q1, Q3) 58.0 (53.0, 64.5) 57.0 (54.0, 64.0)
#> 4 Age (years) Age (years)        Min, Max        41.0, 72.0        48.0, 88.0
#>             Placebo             Total
#> 1                20                60
#> 2       54.4 (10.8)        57.4 (9.7)
#> 3 54.0 (46.0, 59.5) 56.5 (51.5, 63.5)
#> 4        31.0, 77.0        31.0, 88.0
```
