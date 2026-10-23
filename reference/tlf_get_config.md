# Resolve the active configuration

Every function that takes a `config` argument resolves it through
`tlf_get_config()`. The first available source wins:

## Usage

``` r
tlf_get_config(config = NULL)
```

## Arguments

- config:

  `NULL` or a `tlf_config`.

## Value

A `tlf_config`.

## Details

1.  The `config` argument itself.

2.  The session option `tlfstack.config`. This is the hook a site
    profile or environment-setup function uses to apply organization
    conventions once per session.

3.  A YAML file named by the environment variable `TLFSTACK_CONFIG`.

4.  The package defaults,
    [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md).

## Examples

``` r
tlf_get_config()
#> <tlf_config>
#>   page    : landscape 11x8.5 in, margins 0.5/0.5/0.5/0.5/0.5/0.5; figure body 9x6 in
#>   text    : Courier New 9 (source 8)
#>   figure  : Arial 10 (allowed 9-10)
#>   header  : left='' right='Page \pagenumber of \pagefield'
#>   render  : isolate=TRUE retries=2 timeout=90s dpi=300
old <- options(tlfstack.config = tlf_config(header_left = "Example Organization"))
tlf_get_config()$header_left
#> [1] "Example Organization"
options(old)
```
