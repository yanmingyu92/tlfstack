# Render a figure to RTF

Draws a ggplot to a PNG (through ragg when installed, otherwise the
cairo [`png()`](https://rdrr.io/r/grDevices/png.html) device with a
warning), embeds it in an RTF file, and applies the same page, header,
title block, footnotes and source line as
[`tlf_rtf_table()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_table.md).

## Usage

``` r
tlf_rtf_figure(plot, file, titles = NULL, config = NULL, render = NULL)
```

## Arguments

- plot:

  A ggplot, typically from
  [`tlf_build_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_build_table.md).

- file:

  Output `.rtf` path.

- titles:

  A
  [`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md)
  object, a character vector, or `NULL`.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

- render:

  A
  [`tlf_render_opts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_render_opts.md)
  overriding the configured policy.

## Value

`file`, invisibly.

## Details

By default the render runs in an isolated child process with bounded
retries (see
[`tlf_run_isolated()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_run_isolated.md)
and
[`tlf_render_opts()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_render_opts.md)).
A native crash in the graphics stack then cannot kill the calling
session. Isolation contains most crashes, but not all of them: font
operations in the parent process can still fault on an affected host.

## Examples

``` r
# \donttest{
p <- fig_meanci(ex_adlb[ex_adlb$PARAMCD == "ALT", ])
f <- tempfile(fileext = ".rtf")
tlf_rtf_figure(p, f, titles = tlf_titles("Mean ALT by Visit", type = "Figure",
                                         number = "14.3.1"),
               render = tlf_render_opts(isolate = FALSE))
unlink(f)
# }
```
