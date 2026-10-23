# Reporting configuration

`tlf_config()` bundles every organization-level convention: page
geometry, fonts, the running page header, the figure palette,
treatment-variable candidates and the figure render policy. The defaults
are neutral; an organization usually sets its own once per session (see
[`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md)).

## Usage

``` r
tlf_config(
  page = tlf_page(),
  fonts = tlf_fonts(),
  header_left = "",
  header_right = "Page \\pagenumber of \\pagefield",
  palette = tol_bright,
  trt_candidates = c("TRT01A", "TRTA", "TRT01P", "TRTP", "ARM", "ACTARM"),
  render = tlf_render_opts(),
  text_convert = FALSE
)
```

## Arguments

- page:

  A
  [`tlf_page()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_page.md)
  object.

- fonts:

  A
  [`tlf_fonts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_fonts.md)
  object.

- header_left:

  Text of the left cell of the running page header, for example an
  organization name. `""` means no left cell.

- header_right:

  Text of the right cell. r2rtf page fields `\\pagenumber` and
  `\\pagefield` are expanded.

- palette:

  Colours used for treatment groups in figures.

- trt_candidates:

  Treatment/grouping variables tried, in order, when the requested
  treatment variable is absent from the data.

- render:

  A
  [`tlf_render_opts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_render_opts.md)
  object.

- text_convert:

  Let r2rtf convert LaTeX-like markup in text (for example `_` to a
  subscript, `>=` to a symbol)? The default `FALSE` prints all text
  verbatim, so titles stay character-identical to their metadata source
  and program names such as `t_demo.R` are not mangled.

## Value

An object of class `tlf_config`.

## Examples

``` r
cfg <- tlf_config(header_left = "Example Organization")
cfg$fonts$text_family
#> [1] "Courier New"
```
