# Format p-values

Values at or above `10^-digits` are shown with `digits` decimals.
Smaller values are shown as `"<0.001"` (for `digits = 3`). Missing or
non-finite values become `""`.

## Usage

``` r
format_pvalue(p, digits = 3L)
```

## Arguments

- p:

  Numeric vector of p-values.

- digits:

  Number of decimals.

## Value

Character vector the same length as `p`.

## Examples

``` r
format_pvalue(c(0.0321, 0.0004, NA))
#> [1] "0.032"  "<0.001" ""      
```
