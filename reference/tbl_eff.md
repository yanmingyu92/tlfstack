# Summary of a BDS parameter by visit

Descriptive statistics of `value_col` per visit and treatment. For
change from baseline (`value_col = "CHG"`) the baseline visit, defined
as the lowest `AVISITN`, is omitted.

## Usage

``` r
tbl_eff(
  adx,
  trt_var = "TRT01A",
  paramcd = NULL,
  value_col = "CHG",
  config = NULL
)
```

## Arguments

- adx:

  A BDS dataset (`AVISIT`, optionally `AVISITN` and `PARAMCD`).

- trt_var:

  Treatment variable (resolved with
  [`tlf_resolve_trt()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_trt.md)).

- paramcd:

  Optional `PARAMCD` filter.

- value_col:

  `"AVAL"` or `"CHG"`.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

## Value

A `tlf_table`.

## See also

Other table builders:
[`tbl_ae()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae.md),
[`tbl_ae_severity()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae_severity.md),
[`tbl_demographics()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_demographics.md),
[`tbl_disposition()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_disposition.md),
[`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md),
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_eff(ex_adlb, paramcd = "ALT", value_col = "CHG")
#> <tlf_table> 8 row(s) x 6 column(s)
#>  Visit   Statistic       Drug 10 mg (N=20) Drug 20 mg (N=20) Placebo (N=20)  
#>  Week 8  n               20                20                20              
#>          Mean (SD)       5.2 (3.0)         6.3 (4.6)         -0.5 (4.8)      
#>          Median (Q1, Q3) 5.0 (4.0, 6.4)    5.0 (3.9, 9.5)    -1.6 (-2.5, 2.4)
#>          Min, Max        -0.1, 11.2        -1.6, 15.9        -8.4, 11.6      
#>  Week 12 n               20                20                20              
#>          Mean (SD)       4.4 (2.9)         12.5 (3.5)        1.5 (4.9)       
#>          Median (Q1, Q3) 3.9 (2.4, 6.7)    13.5 (9.4, 15.1)  0.8 (-0.7, 4.2) 
#>          Min, Max        -0.5, 9.9         4.7, 18.0         -6.6, 11.4      
#>  Total (N=60)   
#>  60             
#>  3.7 (5.1)      
#>  4.2 (0.3, 6.7) 
#>  -8.4, 15.9     
#>  60             
#>  6.2 (6.0)      
#>  5.3 (1.7, 11.1)
#>  -6.6, 18.0     
#> Note: Change from baseline of ALT, summarized by visit.
```
