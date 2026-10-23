# Adverse events by maximum severity

Each subject is counted once, at the worst severity recorded.

## Usage

``` r
tbl_ae_severity(
  adae,
  adsl = NULL,
  trt_var = "TRT01A",
  sev_var = "AESEV",
  teae_flag = "TRTEMFL",
  levels = c("MILD", "MODERATE", "SEVERE"),
  config = NULL
)
```

## Arguments

- adae:

  Adverse-event data.

- adsl:

  Optional subject-level data for denominators.

- trt_var:

  Treatment variable (resolved with
  [`tlf_resolve_trt()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_trt.md)).

- sev_var:

  Severity column.

- teae_flag:

  Treatment-emergent flag column (`"Y"` rows are kept); `NULL` keeps all
  events.

- levels:

  Severity levels from mildest to worst (matched case-insensitively).

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
[`tbl_demographics()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_demographics.md),
[`tbl_disposition()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_disposition.md),
[`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md),
[`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md),
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_ae_severity(ex_adae, ex_adsl)
#> <tlf_table> 4 row(s) x 5 column(s)
#>  Maximum severity                Drug 10 mg (N=20) Drug 20 mg (N=20)
#>  Subjects with at least one TEAE 16 (80.0%)        17 (85.0%)       
#>    Mild                          5 (25.0%)         6 (30.0%)        
#>    Moderate                      6 (30.0%)         8 (40.0%)        
#>    Severe                        5 (25.0%)         3 (15.0%)        
#>  Placebo (N=20) Total (N=60)
#>  17 (85.0%)     50 (83.3%)  
#>  7 (35.0%)      18 (30.0%)  
#>  8 (40.0%)      22 (36.7%)  
#>  2 (10.0%)      10 (16.7%)  
#> Note: Subjects are counted once, at the maximum severity reported.
```
