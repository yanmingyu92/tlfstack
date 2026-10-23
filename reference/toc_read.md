# Read a TOC source into the canonical table

Read a TOC source into the canonical table

## Usage

``` r
toc_read(source)
```

## Arguments

- source:

  A `toc_source` (see
  [toc_sources](https://yanmingyu92.github.io/tlfstack/reference/toc_sources.md)).

## Value

A data frame with one row per output. It has character columns
`program`, `type`, `number`, `output_file_name` and one per scope key,
and list columns `title`, `subtitle` and `footnotes`. Attribute
`toc_meta` holds the snapshot header (`generated_at`, `source`) when
known.

## Examples

``` r
toc <- toc_read(toc_source_data(ex_toc))
toc$title[[1]]
#> [1] "Summary of Demographic and Baseline Characteristics"
```
