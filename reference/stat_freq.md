# Frequency table for a categorical variable

Returns n (%) per category and group. The denominator is the number of
distinct subjects in each group. A zero count prints as `"0"`.

## Usage

``` r
stat_freq(
  df,
  var,
  trt_var,
  label = var,
  id_var = "USUBJID",
  digits = 1L,
  total = TRUE,
  total_label = "Total",
  levels_order = NULL
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

- id_var:

  Subject identifier column.

- digits:

  Decimals for the mean, SD, median and quartiles.

- total:

  Add a total column?

- total_label:

  Name of the total column.

- levels_order:

  Optional category order. The default is sorted categories.

## Value

Data frame with columns `param`, `label`, `stat` (the category) and one
column per group.

## Examples

``` r
stat_freq(ex_adsl, "SEX", "TRT01A", label = "Sex")
#>   param label stat Drug 10 mg Drug 20 mg    Placebo      Total
#> 1   Sex   Sex    F 12 (60.0%) 13 (65.0%) 13 (65.0%) 38 (63.3%)
#> 2   Sex   Sex    M  8 (40.0%)  7 (35.0%)  7 (35.0%) 22 (36.7%)
```
