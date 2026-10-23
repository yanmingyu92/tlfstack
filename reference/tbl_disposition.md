# Subject disposition

n (%) for population flags (`"Y"` = yes), subjects discontinued from the
study, and the discontinuation reasons.

## Usage

``` r
tbl_disposition(
  adsl,
  trt_var = "TRT01A",
  flags = list(RANDFL = "Randomized", SAFFL = "Safety population", COMPLFL =
    "Completed study"),
  eos_var = "EOSSTT",
  discontinued = "DISCONTINUED",
  reason_var = "DCSREAS",
  config = NULL
)
```

## Arguments

- adsl:

  Subject-level data.

- trt_var:

  Treatment variable (resolved with
  [`tlf_resolve_trt()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_trt.md)).

- flags:

  Named list: flag column = row label. Flags missing from the data are
  skipped.

- eos_var:

  End-of-study status column.

- discontinued:

  Values of `eos_var` meaning discontinued (matched case-insensitively).

- reason_var:

  Discontinuation reason column.

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
[`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md),
[`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md),
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_disposition(ex_adsl)
#> <tlf_table> 7 row(s) x 5 column(s)
#>  Category                Drug 10 mg (N=20) Drug 20 mg (N=20) Placebo (N=20)
#>  Randomized              20 (100.0%)       20 (100.0%)       20 (100.0%)   
#>  Safety population       20 (100.0%)       20 (100.0%)       20 (100.0%)   
#>  Completed study         19 (95.0%)        17 (85.0%)        17 (85.0%)    
#>  Discontinued study      1 (5.0%)          3 (15.0%)         3 (15.0%)     
#>    ADVERSE EVENT         1 (5.0%)          1 (5.0%)          1 (5.0%)      
#>    LOST TO FOLLOW-UP     0                 2 (10.0%)         1 (5.0%)      
#>    WITHDRAWAL BY SUBJECT 0                 0                 1 (5.0%)      
#>  Total (N=60)
#>  60 (100.0%) 
#>  60 (100.0%) 
#>  53 (88.3%)  
#>  7 (11.7%)   
#>  3 (5.0%)    
#>  3 (5.0%)    
#>  1 (1.7%)    
```
