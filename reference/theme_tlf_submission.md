# Figure body theme

A ggplot2 theme for submission figures: white background with a thin
black panel border, major gridlines only, black text, legend at the
bottom, and no in-body title or subtitle. The title block is set in the
RTF text layer by
[`tlf_rtf_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_figure.md),
so it stays machine-auditable.

## Usage

``` r
theme_tlf_submission(base_size = NULL, base_family = NULL, config = NULL)
```

## Arguments

- base_size:

  Font size in points. `NULL` uses the configured `figure_size`. Sizes
  outside the configured `figure_size_range` are an error.

- base_family:

  Font family. `NULL` uses the configured `figure_family`.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

## Value

A ggplot2 theme.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tlf_submission()
```
