# Figure context

Names the visit and treatment columns a figure builder should use.

## Usage

``` r
fig_ctx(visit_col = "AVISIT", trt_col = "TRT01A")
```

## Arguments

- visit_col:

  Visit column (ordered by `AVISITN` when it is `"AVISIT"`).

- trt_col:

  Treatment column. `NULL` means no grouping. A column missing from the
  data falls back to the configured candidates, and then to no grouping.

## Value

A list.

## Examples

``` r
fig_ctx(trt_col = "TRTA")
#> $visit_col
#> [1] "AVISIT"
#> 
#> $trt_col
#> [1] "TRTA"
#> 
```
