# Page geometry

Describes the physical page and the figure body rectangle used by every
renderer.

## Usage

``` r
tlf_page(
  orientation = c("landscape", "portrait"),
  paper = c(8.5, 11),
  margin = rep(0.5, 6),
  fig_width = NULL,
  fig_height = NULL
)

tlf_page_letter_landscape()

tlf_page_a4_landscape()
```

## Arguments

- orientation:

  `"landscape"` or `"portrait"`.

- paper:

  Paper size in inches as `c(short, long)`; for example `c(8.5, 11)` for
  US Letter or `c(8.27, 11.69)` for A4.

- margin:

  Six margins in inches, in r2rtf order: left, right, top, bottom,
  header, footer.

- fig_width, fig_height:

  Size of the figure body in inches. `NULL` means 9 x 6 in, shrunk to
  fit the printable area if needed.

## Value

An object of class `tlf_page`.

## Examples

``` r
tlf_page()
#> $orientation
#> [1] "landscape"
#> 
#> $width
#> [1] 11
#> 
#> $height
#> [1] 8.5
#> 
#> $margin
#> [1] 0.5 0.5 0.5 0.5 0.5 0.5
#> 
#> $fig_width
#> [1] 9
#> 
#> $fig_height
#> [1] 6
#> 
#> attr(,"class")
#> [1] "tlf_page"
tlf_page("portrait", fig_width = 6.5, fig_height = 8)
#> $orientation
#> [1] "portrait"
#> 
#> $width
#> [1] 8.5
#> 
#> $height
#> [1] 11
#> 
#> $margin
#> [1] 0.5 0.5 0.5 0.5 0.5 0.5
#> 
#> $fig_width
#> [1] 6.5
#> 
#> $fig_height
#> [1] 8
#> 
#> attr(,"class")
#> [1] "tlf_page"
```
