# Demographics and baseline characteristics

Stacks continuous blocks
([`stat_desc()`](https://yanmingyu92.github.io/tlfstack/reference/stat_desc.md))
and categorical blocks
([`stat_freq()`](https://yanmingyu92.github.io/tlfstack/reference/stat_freq.md))
with big-N column headers. Requested variables missing from the data are
skipped and recorded in `meta$skipped`.

## Usage

``` r
tbl_demographics(
  adsl,
  trt_var = "TRT01A",
  cont_vars = list(AGE = "Age (years)"),
  cat_vars = list(SEX = "Sex", RACE = "Race", ETHNIC = "Ethnicity", AGEGR1 = "Age group"),
  config = NULL
)
```

## Arguments

- adsl:

  Subject-level data.

- trt_var:

  Treatment variable (resolved with
  [`tlf_resolve_trt()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_trt.md)).

- cont_vars:

  Named list: continuous variable = row label.

- cat_vars:

  Named list: categorical variable = row label.

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
[`tbl_disposition()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_disposition.md),
[`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md),
[`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md),
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_demographics(ex_adsl)
#> <tlf_table> 13 row(s) x 6 column(s)
#>  Characteristic Statistic                 Drug 10 mg (N=20) Drug 20 mg (N=20)
#>  Age (years)    n                         20                20               
#>                 Mean (SD)                 58.2 (8.4)        59.6 (9.5)       
#>                 Median (Q1, Q3)           58.0 (53.0, 64.5) 57.0 (54.0, 64.0)
#>                 Min, Max                  41.0, 72.0        48.0, 88.0       
#>  Sex            F                         12 (60.0%)        13 (65.0%)       
#>                 M                         8 (40.0%)         7 (35.0%)        
#>  Race           ASIAN                     6 (30.0%)         4 (20.0%)        
#>                 BLACK OR AFRICAN AMERICAN 3 (15.0%)         5 (25.0%)        
#>                 WHITE                     11 (55.0%)        11 (55.0%)       
#>  Ethnicity      HISPANIC OR LATINO        3 (15.0%)         2 (10.0%)        
#>                 NOT HISPANIC OR LATINO    17 (85.0%)        18 (90.0%)       
#>  Age group      <65                       15 (75.0%)        16 (80.0%)       
#>                 >=65                      5 (25.0%)         4 (20.0%)        
#>  Placebo (N=20)    Total (N=60)     
#>  20                60               
#>  54.4 (10.8)       57.4 (9.7)       
#>  54.0 (46.0, 59.5) 56.5 (51.5, 63.5)
#>  31.0, 77.0        31.0, 88.0       
#>  13 (65.0%)        38 (63.3%)       
#>  7 (35.0%)         22 (36.7%)       
#>  4 (20.0%)         14 (23.3%)       
#>  4 (20.0%)         12 (20.0%)       
#>  12 (60.0%)        34 (56.7%)       
#>  8 (40.0%)         13 (21.7%)       
#>  12 (60.0%)        47 (78.3%)       
#>  17 (85.0%)        48 (80.0%)       
#>  3 (15.0%)         12 (20.0%)       
```
