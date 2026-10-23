# Shift table: baseline vs endpoint reference-range category

Cross-tabulates each subject's baseline category (at the lowest
`AVISITN`) against the category at the last post-baseline visit, by
treatment.

## Usage

``` r
tbl_shift(adx, trt_var = "TRT01A", paramcd = NULL, config = NULL)
```

## Arguments

- adx:

  A BDS dataset (`AVISIT`, optionally `AVISITN` and `PARAMCD`).

- trt_var:

  Treatment variable (resolved with
  [`tlf_resolve_trt()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_trt.md)).

- paramcd:

  Optional `PARAMCD` filter.

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
[`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md),
[`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_shift(ex_adlb, paramcd = "ALT")
#> <tlf_table> 9 row(s) x 5 column(s)
#>  Treatment  Baseline Endpoint: Low Endpoint: Normal Endpoint: High
#>  Drug 10 mg Low      0             0                0             
#>             Normal   0             15               4             
#>             High     0             0                1             
#>  Drug 20 mg Low      0             0                0             
#>             Normal   0             7                12            
#>             High     0             0                1             
#>  Placebo    Low      0             0                0             
#>             Normal   0             16               3             
#>             High     0             0                1             
#> Note: Categories are relative to the reference range (ANRLO/ANRHI). Endpoint is the last post-baseline visit.
```
