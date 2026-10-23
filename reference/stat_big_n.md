# Population counts per group

Counts distinct subjects per treatment group, for "N=xx" column headers.

## Usage

``` r
stat_big_n(
  df,
  trt_var,
  id_var = "USUBJID",
  total = TRUE,
  total_label = "Total"
)
```

## Arguments

- df:

  Data frame.

- trt_var:

  Treatment/grouping column. Group order follows factor levels when it
  is a factor, otherwise sorted values.

- id_var:

  Subject identifier column.

- total:

  Add a total column?

- total_label:

  Name of the total column.

## Value

Named integer vector, one element per group (plus the total).

## Examples

``` r
stat_big_n(ex_adsl, "TRT01A")
#> Drug 10 mg Drug 20 mg    Placebo      Total 
#>         20         20         20         60 
```
