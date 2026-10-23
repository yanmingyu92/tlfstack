# Font conventions

Font conventions

## Usage

``` r
tlf_fonts(
  text_family = "Courier New",
  text_size = 9,
  source_size = 8,
  figure_family = "Arial",
  figure_size = 10,
  figure_size_range = c(9, 10)
)
```

## Arguments

- text_family:

  Font family of the RTF text layer (titles, headers, table and listing
  bodies, footnotes). It must be one of the fonts r2rtf knows about.

- text_size:

  Point size of the text layer.

- source_size:

  Point size of the source line.

- figure_family:

  Font family of the figure body (axes, legend, ticks).

- figure_size:

  Default point size of the figure body.

- figure_size_range:

  Allowed range for figure body sizes. Requests outside it are an error,
  so a convention cannot be bent silently.

## Value

An object of class `tlf_fonts`.

## Examples

``` r
tlf_fonts(text_size = 8)
#> $text_family
#> [1] "Courier New"
#> 
#> $text_size
#> [1] 8
#> 
#> $source_size
#> [1] 8
#> 
#> $figure_family
#> [1] "Arial"
#> 
#> $figure_size
#> [1] 10
#> 
#> $figure_size_range
#> [1]  9 10
#> 
#> attr(,"class")
#> [1] "tlf_fonts"
```
