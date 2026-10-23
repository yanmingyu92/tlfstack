# Title block of one output

Creates the structured title block that the RTF renderers consume:

## Usage

``` r
tlf_titles(
  title,
  banner = NULL,
  type = c("Table", "Figure", "Listing"),
  number = NULL,
  subtitle = character(),
  footnotes = character(),
  pre_title = character(),
  source = "",
  output_file_name = NULL,
  vars = list(),
  provenance = list(mode = "manual")
)
```

## Arguments

- title:

  Character vector of title lines (at least one).

- banner:

  Output label. `NULL` builds one from `type` and `number`.

- type:

  Output type: `"Table"`, `"Figure"` or `"Listing"`.

- number:

  Output number, for example `"14.1.1"`.

- subtitle:

  Character vector of subtitle lines.

- footnotes:

  Character vector of footnotes, in display order.

- pre_title:

  Character vector of lines placed above the banner.

- source:

  Source line, for example the producing program's path.

- output_file_name:

  File name of the deliverable. `NULL` means the caller decides.

- vars:

  Named list of values substituted for `{name}` placeholders in every
  text field (see Details).

- provenance:

  List describing where the titles came from. It is filled in by
  [`tlf_resolve_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_titles.md);
  manual titles get `mode = "manual"`.

## Value

An object of class `tlf_titles`.

## Details

- `pre_title`: lines printed above the banner, such as a study
  identifier or data cut-off.

- `banner`: the output label, such as `"Table 14.1.1"`.

- `title`, `subtitle`: title lines below the banner.

- `footnotes`, `source`: printed below the body, in that order.

Use `tlf_titles()` directly when no table-of-contents source exists, or
get one from
[`tlf_resolve_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_titles.md).

Placeholders: a field such as `"Summary of {param} by Visit"` is filled
from `vars`. A placeholder with no value is left visible and triggers a
warning, so an unfilled title can never pass for a finished one.

## Examples

``` r
tlf_titles(
  title = "Summary of Demographics",
  type = "Table", number = "14.1.1",
  subtitle = "Safety Population",
  footnotes = "Percentages are based on N in each column."
)
#> <tlf_titles> mode: manual
#>   banner:   Table 14.1.1
#>   title:    Summary of Demographics
#>   subtitle: Safety Population
#>   footnote: Percentages are based on N in each column.
```
