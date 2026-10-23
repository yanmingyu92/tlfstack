# Builder result

The fixed shape every table and listing builder returns, so a renderer
can be written once against it.

## Usage

``` r
tlf_table_result(
  df,
  col_rel_width = NULL,
  text_justification = "l",
  footnotes = character(),
  meta = list()
)
```

## Arguments

- df:

  Data frame whose character cells are printed as-is.

- col_rel_width:

  Relative column widths (one per column).

- text_justification:

  Body justification, recycled across columns.

- footnotes:

  Builder-derived footnotes, appended after the title-block footnotes at
  render time.

- meta:

  A list of provenance notes, such as the resolved treatment variable or
  skipped variables.

## Value

An object of class `tlf_table`.

## Examples

``` r
tlf_table_result(data.frame(a = "1"))
#> <tlf_table> 1 row(s) x 1 column(s)
#>  a
#>  1
```
