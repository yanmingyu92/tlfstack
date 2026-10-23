# Resolve the title block of an output

Looks up the titles and footnotes of `program` in a table of contents
and returns a
[`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md)
object. There are three modes:

## Usage

``` r
tlf_resolve_titles(
  program,
  type = c("Table", "Figure", "Listing"),
  sources = list(),
  scope = list(),
  number = NULL,
  pre_title = character(),
  source = "",
  vars = list(),
  on_resolve = NULL
)
```

## Arguments

- program:

  Program name, for example `"t_demo"`.

- type:

  Output type used for the banner when the TOC row has none.

- sources:

  A list of `toc_source` objects, in priority order.

- scope:

  Named list of scope values, for example `list(study = "STUDY01")`.

- number:

  Optional output number to pick one of several outputs produced by the
  same program.

- pre_title, source:

  Passed to
  [`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md).
  They come from the environment, not the TOC (for example a data
  cut-off line and the program path).

- vars:

  Named list of placeholder values (see
  [`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md)).

- on_resolve:

  Optional function `function(titles)` called after resolution, for
  example to write an audit record. Errors in it become warnings.

## Value

A
[`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md)
object. `$provenance` records `mode` (`"live"`, `"snapshot"` or
`"fallback"`), the source label, the snapshot's `generated_at` when
known, `resolved_at`, and why a fallback happened.

## Details

1.  **Live/snapshot.** `sources` are tried in order. The first one that
    reads successfully and has rows is used, and later sources are not
    consulted, so a reachable live source is authoritative.

2.  **Fallback.** If no source can be read, or the program has no row,
    the result is a placeholder title block (`"Table x.y.z"` plus a
    `"TODO: <program> title from TOC"` line) and a warning is issued.
    The program still runs, so a dry run is never blocked by missing
    metadata, but a placeholder can never pass for a resolved title.

Matching: rows are matched on the program name (case-insensitive,
ignoring a `.R`/`.sas` extension). A row whose scope cell is blank
applies to every scope. Otherwise it must equal the requested `scope`
value, and the most specific match wins. For scope columns not given in
`scope`, general (blank) rows are preferred over specific ones. If
several rows still tie, `number` selects one; a remaining tie is an
error.

## Examples

``` r
t <- tlf_resolve_titles("t_demo", sources = list(toc_source_data(ex_toc)),
                        scope = list(study = "STUDY01"))
t
#> <tlf_titles> mode: snapshot
#>   banner:   Table 14.1.1
#>   title:    Summary of Demographic and Baseline Characteristics
#>   subtitle: Safety Population
#>   footnote: Percentages are based on the number of subjects in each column.
#>   file:     t-14-01-01-demog.rtf
t$provenance$mode
#> [1] "snapshot"
```
