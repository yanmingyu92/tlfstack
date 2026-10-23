# tlfstack

tlfstack is a *convention stack* for clinical tables, listings and
figures (TLFs) in R: the reporting conventions a SAS shop keeps in ODS
templates and a macro library, written as R code and metadata.

It rests on two design principles:

1.  **One code path, two modes.** Builders are pure functions: data in,
    a table object or ggplot out. They never read data, write files or
    touch metadata. A scheduled batch program and an interactive Shiny
    preview make the same call and get the same RTF content. The two
    modes differ only at the data entry point and the output exit point.
2.  **Metadata shared across languages.** Titles, footnotes and output
    file names come from one table of contents (TOC). This can be the
    same database table your SAS programs read, a snapshot of it, or a
    version-controlled JSON/YAML file. Because both sides read one
    source string, the title blocks match by construction.

## What is in the stack

| Layer | Functions |
|----|----|
| Configuration | [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md), [`tlf_page()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_page.md), [`tlf_fonts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_fonts.md), [`tlf_render_opts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_render_opts.md), [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md) (argument \> [`options()`](https://rdrr.io/r/base/options.html) \> `TLFSTACK_CONFIG` file \> defaults) |
| Builders | [`tbl_demographics()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_demographics.md), [`tbl_ae()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae.md), [`tbl_ae_severity()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_ae_severity.md), [`tbl_disposition()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_disposition.md), [`tbl_eff()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_eff.md), [`tbl_shift()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_shift.md), [`tbl_tte()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_tte.md), [`tbl_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tbl_listing.md); [`fig_meanci()`](https://yanmingyu92.github.io/tlfstack/reference/fig_meanci.md), [`fig_boxplot()`](https://yanmingyu92.github.io/tlfstack/reference/fig_boxplot.md), [`fig_spaghetti()`](https://yanmingyu92.github.io/tlfstack/reference/fig_spaghetti.md), [`fig_lsmeans()`](https://yanmingyu92.github.io/tlfstack/reference/fig_lsmeans.md), [`fig_km()`](https://yanmingyu92.github.io/tlfstack/reference/fig_km.md), [`fig_forest()`](https://yanmingyu92.github.io/tlfstack/reference/fig_forest.md), [`fig_waterfall()`](https://yanmingyu92.github.io/tlfstack/reference/fig_waterfall.md), [`fig_edish()`](https://yanmingyu92.github.io/tlfstack/reference/fig_edish.md), [`fig_shift()`](https://yanmingyu92.github.io/tlfstack/reference/fig_shift.md) |
| Dispatcher | [`tlf_build_table()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_build_table.md), [`tlf_build_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_build_table.md), [`tlf_register_table()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_register_table.md), [`tlf_register_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_register_table.md) |
| Titles and TOC | [`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md), [`tlf_resolve_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_titles.md) (live, then snapshot, then fallback), [`toc_source_db()`](https://yanmingyu92.github.io/tlfstack/reference/toc_sources.md), [`toc_source_file()`](https://yanmingyu92.github.io/tlfstack/reference/toc_sources.md), [`toc_source_dir()`](https://yanmingyu92.github.io/tlfstack/reference/toc_sources.md), [`toc_read()`](https://yanmingyu92.github.io/tlfstack/reference/toc_read.md), [`toc_write()`](https://yanmingyu92.github.io/tlfstack/reference/toc_write.md) |
| Convention engine | [`theme_tlf_submission()`](https://yanmingyu92.github.io/tlfstack/reference/theme_tlf_submission.md), [`tlf_rtf_table()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_table.md), [`tlf_rtf_listing()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_table.md), [`tlf_rtf_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_figure.md) |
| Crash isolation | [`tlf_run_isolated()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_run_isolated.md): figure rendering in a callr child process with bounded retries and an attempt log |

## Example

``` r

library(tlfstack)

# Organization conventions, set once per session (for example in a site profile).
options(tlfstack.config = tlf_config(header_left = "Example Organization"))

# Titles from a TOC: a live DBI source first, then a snapshot file.
titles <- tlf_resolve_titles(
  "t_demo",
  sources = list(toc_source_dir("metadata")),   # or toc_source_db(connector, "toc")
  scope = list(study = "STUDY01")
)

# The same call a Shiny app makes.
res <- tlf_build_table("demographics", list(adsl = ex_adsl))
tlf_rtf_table(res, file.path(tempdir(), titles$output_file_name), titles = titles)
```

## Title metadata as a file

[`toc_write()`](https://yanmingyu92.github.io/tlfstack/reference/toc_write.md)
dumps any TOC, including a live database table, to JSON or YAML for
offline work, code review and other languages:

``` yaml
tlfstack_toc: 1
generated_at: 2026-10-22T09:00:00+0000
source: database
outputs:
  - program: t_demo
    scope: {study: STUDY01}
    type: Table
    number: "14.1.1"
    title: [Summary of Demographic and Baseline Characteristics]
    subtitle: [Safety Population]
    footnotes: [Percentages are based on the number of subjects in each column.]
    output_file_name: t-14-01-01-demog.rtf
```

The format has a published JSON Schema:
`system.file("schema", "tlfstack-toc-v1.schema.json", package = "tlfstack")`.

## Where tlfstack sits

tlfstack does not replace the table-construction or interactive-review
packages. Its scope is what sits *around* them:

- **rtables, gtsummary, Tplyr** build table bodies. tlfstack renders
  pre-formatted data frames, so a body from any of them can go through
  its renderers.
- **tfrmt** expresses a table’s layout as metadata for review before
  database lock. tlfstack adds page and figure conventions and
  TOC-driven titles for locked output. The two are complementary.
- **teal** is interactive exploration. tlfstack’s interactive mode is a
  preview of the production output.
- **chevron** generates standard TLF programs. tlfstack is a shared
  runtime layer that both batch and interactive code call.
- **r2rtf** is the RTF engine tlfstack builds on.

No single feature here is new. The contribution is the combination: one
code path for batch and interactive work, conventions as code, one
metadata source shared with SAS, and crash-tolerant figure rendering.

## Installation

tlfstack is not yet on CRAN.

## Status

This is an early release. Planned work is tracked in `NEWS.md` and the
issue tracker.
