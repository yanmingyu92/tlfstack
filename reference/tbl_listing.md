# Subject-level listing

Selects, renames and sorts columns, one row per record. Configured
columns missing from the data are skipped and recorded in `meta`.

## Usage

``` r
tbl_listing(
  df,
  cols,
  sort_by = c("USUBJID", "AVISITN", "PARAMCD", "ASTDT", "AESTDTC")
)
```

## Arguments

- df:

  Data frame.

- cols:

  Named character vector: data column = display header. See
  [listing_cols_ae](https://yanmingyu92.github.io/tlfstack/reference/listing_cols.md)
  and
  [listing_cols_lab](https://yanmingyu92.github.io/tlfstack/reference/listing_cols.md)
  for defaults.

- sort_by:

  Data columns to sort by (those present are used).

## Value

A `tlf_table`.

## See also

Other table builders:
[`tbl_ae()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae.md),
[`tbl_ae_severity()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae_severity.md),
[`tbl_demographics()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_demographics.md),
[`tbl_disposition()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_disposition.md),
[`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md),
[`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md),
[`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md)

## Examples

``` r
tbl_listing(ex_adae, listing_cols_ae)
#> <tlf_table> 120 row(s) x 7 column(s)
#>  Subject     System Organ Class                     Preferred Term  Severity
#>  STUDY01-001 INFECTIONS AND INFESTATIONS            NASOPHARYNGITIS MODERATE
#>  STUDY01-002 GASTROINTESTINAL DISORDERS             DIARRHOEA       SEVERE  
#>  STUDY01-002 INFECTIONS AND INFESTATIONS            NASOPHARYNGITIS MILD    
#>  STUDY01-002 NERVOUS SYSTEM DISORDERS               DIZZINESS       MODERATE
#>  STUDY01-002 INFECTIONS AND INFESTATIONS            NASOPHARYNGITIS MILD    
#>  STUDY01-002 NERVOUS SYSTEM DISORDERS               HEADACHE        MILD    
#>  STUDY01-005 GASTROINTESTINAL DISORDERS             NAUSEA          MODERATE
#>  STUDY01-006 NERVOUS SYSTEM DISORDERS               HEADACHE        MODERATE
#>  STUDY01-006 GASTROINTESTINAL DISORDERS             NAUSEA          MODERATE
#>  STUDY01-006 GASTROINTESTINAL DISORDERS             NAUSEA          MILD    
#>  STUDY01-007 NERVOUS SYSTEM DISORDERS               DIZZINESS       MILD    
#>  STUDY01-008 GASTROINTESTINAL DISORDERS             NAUSEA          MILD    
#>  STUDY01-009 SKIN AND SUBCUTANEOUS TISSUE DISORDERS RASH            MODERATE
#>  STUDY01-009 NERVOUS SYSTEM DISORDERS               HEADACHE        MILD    
#>  STUDY01-009 GASTROINTESTINAL DISORDERS             NAUSEA          MILD    
#>  STUDY01-010 INFECTIONS AND INFESTATIONS            NASOPHARYNGITIS MILD    
#>  STUDY01-010 NERVOUS SYSTEM DISORDERS               DIZZINESS       SEVERE  
#>  STUDY01-010 INFECTIONS AND INFESTATIONS            NASOPHARYNGITIS MILD    
#>  STUDY01-012 GASTROINTESTINAL DISORDERS             DIARRHOEA       MILD    
#>  STUDY01-013 NERVOUS SYSTEM DISORDERS               HEADACHE        MILD    
#>  Onset Date Outcome                    Relationship
#>  2026-02-27 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-01-30 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-03-14 RECOVERED/RESOLVED         RELATED     
#>  2026-04-04 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-04-13 RECOVERED/RESOLVED         RELATED     
#>  2026-05-07 NOT RECOVERED/NOT RESOLVED RELATED     
#>  2026-03-15 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-01-29 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-02-01 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-03-30 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-05-02 NOT RECOVERED/NOT RESOLVED NOT RELATED 
#>  2026-05-10 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-04-03 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-04-18 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-04-26 NOT RECOVERED/NOT RESOLVED RELATED     
#>  2026-02-05 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-02-28 RECOVERED/RESOLVED         NOT RELATED 
#>  2026-03-11 NOT RECOVERED/NOT RESOLVED NOT RELATED 
#>  2026-04-19 RECOVERED/RESOLVED         RELATED     
#>  2026-02-02 RECOVERED/RESOLVED         NOT RELATED 
#> ...
```
