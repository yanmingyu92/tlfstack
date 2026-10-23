# Adverse events by system organ class and preferred term

Counts subjects with at least one event. SOCs and PTs are sorted by
decreasing frequency, with ties broken alphabetically. Denominators come
from `adsl` when given, otherwise from `adae`.

## Usage

``` r
tbl_ae(
  adae,
  adsl = NULL,
  trt_var = "TRT01A",
  soc_var = "AESOC",
  pt_var = "AEDECOD",
  teae_flag = "TRTEMFL",
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

- soc_var, pt_var:

  SOC and PT columns.

- teae_flag:

  Treatment-emergent flag column (`"Y"` rows are kept); `NULL` keeps all
  events.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

## Value

A `tlf_table`.

## See also

Other table builders:
[`tbl_ae_severity()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae_severity.md),
[`tbl_demographics()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_demographics.md),
[`tbl_disposition()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_disposition.md),
[`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md),
[`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md),
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_ae(ex_adae, ex_adsl)
#> <tlf_table> 11 row(s) x 5 column(s)
#>  System Organ Class / Preferred Term    Drug 10 mg (N=20) Drug 20 mg (N=20)
#>  Subjects with at least one TEAE        16 (80.0%)        17 (85.0%)       
#>  NERVOUS SYSTEM DISORDERS               9 (45.0%)         11 (55.0%)       
#>    DIZZINESS                            6 (30.0%)         7 (35.0%)        
#>    HEADACHE                             6 (30.0%)         7 (35.0%)        
#>  GASTROINTESTINAL DISORDERS             8 (40.0%)         12 (60.0%)       
#>    DIARRHOEA                            4 (20.0%)         6 (30.0%)        
#>    NAUSEA                               4 (20.0%)         6 (30.0%)        
#>  INFECTIONS AND INFESTATIONS            6 (30.0%)         4 (20.0%)        
#>    NASOPHARYNGITIS                      6 (30.0%)         4 (20.0%)        
#>  SKIN AND SUBCUTANEOUS TISSUE DISORDERS 2 (10.0%)         2 (10.0%)        
#>    RASH                                 2 (10.0%)         2 (10.0%)        
#>  Placebo (N=20) Total (N=60)
#>  17 (85.0%)     50 (83.3%)  
#>  11 (55.0%)     31 (51.7%)  
#>  8 (40.0%)      21 (35.0%)  
#>  5 (25.0%)      18 (30.0%)  
#>  6 (30.0%)      26 (43.3%)  
#>  5 (25.0%)      15 (25.0%)  
#>  3 (15.0%)      13 (21.7%)  
#>  6 (30.0%)      16 (26.7%)  
#>  6 (30.0%)      16 (26.7%)  
#>  4 (20.0%)      8 (13.3%)   
#>  4 (20.0%)      8 (13.3%)   
#> Note: Subjects are counted once per SOC and once per preferred term.
```
