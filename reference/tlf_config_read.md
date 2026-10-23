# Read a configuration file

Reads a YAML file with optional top-level keys `page`, `fonts`,
`header_left`, `header_right`, `palette`, `trt_candidates` and `render`.
The `page`, `fonts` and `render` keys hold the arguments of
[`tlf_page()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_page.md),
[`tlf_fonts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_fonts.md)
and
[`tlf_render_opts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_render_opts.md).
This function requires the yaml package.

## Usage

``` r
tlf_config_read(path)
```

## Arguments

- path:

  Path to a YAML file.

## Value

A `tlf_config`.

## Examples

``` r
f <- tempfile(fileext = ".yml")
writeLines(c("header_left: Example Organization", "fonts:", "  text_size: 8"), f)
tlf_config_read(f)
#> <tlf_config>
#>   page    : landscape 11x8.5 in, margins 0.5/0.5/0.5/0.5/0.5/0.5; figure body 9x6 in
#>   text    : Courier New 8 (source 8)
#>   figure  : Arial 10 (allowed 9-10)
#>   header  : left='Example Organization' right='Page \pagenumber of \pagefield'
#>   render  : isolate=TRUE retries=2 timeout=90s dpi=300
unlink(f)
```
