# Time-to-event summary

Kaplan-Meier median time with 95% CI per arm. With two or more arms it
adds Cox hazard ratios versus the first arm and the log-rank p-value as
footnotes. ADaM ADTTE conventions apply: `AVAL` is the time and
`CNSR == 1` means censored. Requires the survival package.

## Usage

``` r
tbl_tte(adx, trt_var = "TRT01A", paramcd = NULL, config = NULL)
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
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md)

## Examples

``` r
if (requireNamespace("survival", quietly = TRUE)) tbl_tte(ex_adtte)
#> <tlf_table> 3 row(s) x 4 column(s)
#>  Statistic            Drug 10 mg (N=20) Drug 20 mg (N=20)   Placebo (N=20)     
#>  Subjects, n          20                20                  20                 
#>  Events, n (%)        7 (35.0%)         9 (45.0%)           13 (65.0%)         
#>  Median time (95% CI) NE (309.00, NE)   311.00 (118.00, NE) 291.00 (207.00, NE)
#> Note: Hazard ratio (95% CI), Drug 20 mg vs Drug 10 mg: 1.60 (0.60, 4.31)
#> Note: Hazard ratio (95% CI), Placebo vs Drug 10 mg: 1.89 (0.75, 4.74)
#> Note: Log-rank p-value: 0.387
```
