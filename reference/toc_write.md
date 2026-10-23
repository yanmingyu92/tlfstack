# Write a TOC snapshot

Writes a canonical TOC table to a file. Use it to dump a live database
TOC for offline work, to version-control title metadata, or to hand it
to another language.

## Usage

``` r
toc_write(
  toc,
  path,
  source = or_default(attr(toc, "toc_meta")$source, "tlfstack"),
  schema = toc_schema()
)
```

## Arguments

- toc:

  A canonical TOC table (from
  [`toc_read()`](https://yanmingyu92.github.io/tlfstack/reference/toc_read.md))
  or a data frame in the layout described by `schema`.

- path:

  Output file. The format is taken from the extension: `.json`, `.yml`,
  `.yaml` or `.csv`.

- source:

  Text recorded in the `source` header field.

- schema:

  A
  [`toc_schema()`](https://yanmingyu92.github.io/tlfstack/reference/toc_schema.md).
  It is used to normalize a flat `toc`, and for the CSV column names and
  delimiter.

## Value

`path`, invisibly.

## Details

The JSON and YAML formats share one structure:

    tlfstack_toc: 1                 # format version
    generated_at: 2026-10-22T09:00:00+0000
    source: database                # where the snapshot came from
    outputs:
      - program: t_demo
        scope: {study: STUDY01}
        type: Table
        number: "14.1.1"
        title: [Summary of Demographic and Baseline Characteristics]
        subtitle: [Safety Population]
        footnotes: [Percentages are based on N in each column.]
        output_file_name: t-14-01-01-demog.rtf

Multi-line fields are arrays, so no delimiter convention is needed and
output numbers stay strings. A JSON Schema for the format ships with the
package:
`system.file("schema", "tlfstack-toc-v1.schema.json", package = "tlfstack")`.
CSV output joins multi-line fields with the schema delimiter, for tools
that need a flat file.

## Examples

``` r
f <- tempfile(fileext = ".json")
toc_write(ex_toc, f, source = "example")
identical(toc_read(toc_source_file(f))$number, ex_toc$number)
#> [1] TRUE
unlink(f)
```
