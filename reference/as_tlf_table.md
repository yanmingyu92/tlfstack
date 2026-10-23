# Convert a table body to a tlfstack table

Renderers call `as_tlf_table()` on their input, so anything with a
method can be rendered under tlfstack conventions:

## Usage

``` r
as_tlf_table(x, ...)
```

## Arguments

- x:

  Object to convert.

- ...:

  Passed to methods. For `card` objects: `by`, the name of the grouping
  variable for
  [`gtsummary::tbl_ard_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_ard_summary.html).
  It is inferred when the ARD has a single grouping variable.

## Value

A `tlf_table` (see
[`tlf_table_result()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_table_result.md)).

## Details

- `tlf_table`: returned unchanged.

- `data.frame`: cells printed as-is.

- `gtsummary` objects (for example from
  [`tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
  or
  [`tbl_hierarchical()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_hierarchical.html)):
  the visible columns with their header labels and row indentation.
  gtsummary footnotes, abbreviations and source notes become builder
  footnotes, placed after the title-block footnotes. The Analysis
  Results Data behind the table is kept in `meta$ard` for QC.

- `card` objects (Analysis Results Data from cards/cardx): formatted
  through
  [`gtsummary::tbl_ard_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_ard_summary.html).

Markdown emphasis in gtsummary labels (`**bold**`, `_italic_`) is
removed, because the RTF text layer uses one font convention. A header
line break before `N = xx` becomes `(N = xx)`.

## Examples

``` r
as_tlf_table(data.frame(Parameter = "Age", Value = "42"))
#> <tlf_table> 1 row(s) x 2 column(s)
#>  Parameter Value
#>  Age       42   
if (requireNamespace("gtsummary", quietly = TRUE)) {
  gt <- gtsummary::tbl_summary(ex_adsl, by = TRT01A, include = c(AGE, SEX))
  tb <- as_tlf_table(gt)
  tb$footnotes
}
#> [1] "Median (Q1, Q3); n (%)"
```
