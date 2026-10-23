# Resolve the treatment variable

Returns `trt_var` when it is a column of `df`. Otherwise it returns the
first configured candidate (see
[`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md))
present in the data, with a message. It errors when there is none.

## Usage

``` r
tlf_resolve_trt(df, trt_var = "TRT01A", config = NULL)
```

## Arguments

- df:

  Data frame.

- trt_var:

  Requested treatment/grouping column.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

## Value

A column name.

## Examples

``` r
tlf_resolve_trt(ex_adsl, "TRTXX")
#> Using 'TRT01A' as the treatment variable ('TRTXX' not found).
#> [1] "TRT01A"
```
