# Render a table or listing to RTF

Applies the configured page geometry, running header, title block, body
fonts, footnotes and source line, and writes an RTF file. Footnotes
carried by a `tlf_table` result (for example a hazard ratio) are
appended after the title-block footnotes. An empty table renders as a
single `"No data to report."` row rather than failing.

## Usage

``` r
tlf_rtf_table(
  x,
  file,
  titles = NULL,
  config = NULL,
  colheader = NULL,
  col_rel_width = NULL,
  text_justification = NULL
)

tlf_rtf_listing(
  x,
  file,
  titles = NULL,
  config = NULL,
  colheader = NULL,
  col_rel_width = NULL
)
```

## Arguments

- x:

  A `tlf_table` result from a builder, a pre-formatted data frame whose
  cells are printed as-is, a gtsummary table, or a cards `card` object;
  anything
  [`as_tlf_table()`](https://yanmingyu92.github.io/tlfstack/reference/as_tlf_table.md)
  can convert.

- file:

  Output `.rtf` path.

- titles:

  A
  [`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md)
  object (for example from
  [`tlf_resolve_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_titles.md)),
  a character vector of title lines, or `NULL`.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

- colheader:

  Column header string in r2rtf `" | "` format. The default uses the
  column names.

- col_rel_width:

  Relative column widths. The default is the builder's widths, or equal
  widths.

- text_justification:

  Body justification per column (`"l"`, `"c"`, `"r"`), recycled.

## Value

`file`, invisibly.

## Details

Tables and listings need no graphics device and render in-process.

## Examples

``` r
res <- tbl_demographics(ex_adsl)
f <- tempfile(fileext = ".rtf")
tlf_rtf_table(res, f, titles = tlf_titles("Demographics", number = "14.1.1"))
unlink(f)
```
