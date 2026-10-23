# Modify a configuration

Returns a modified copy; the input is left unchanged.

## Usage

``` r
tlf_config_update(config, ...)
```

## Arguments

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md)
  object.

- ...:

  Named fields of
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md)
  to replace.

## Value

A new `tlf_config`.

## Examples

``` r
cfg <- tlf_config_update(tlf_config(), header_left = "Example Organization")
```
