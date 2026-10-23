# Example table of contents

A canonical TOC table (see
[`toc_read()`](https://yanmingyu92.github.io/tlfstack/reference/toc_read.md))
with six outputs. The two `t_eff` rows share a program and are selected
by `number`. Some titles use a `{param}` placeholder. Rows with a blank
`study` apply to every study.

## Usage

``` r
ex_toc
```

## Format

A data frame with list columns `title`, `subtitle` and `footnotes`.

## Source

Simulated.

## Examples

``` r
ex_toc[, c("program", "number", "study")]
#>    program number   study
#> 1   t_demo 14.1.1 STUDY01
#> 2     t_ae 14.3.1 STUDY01
#> 3    t_eff 14.2.1 STUDY01
#> 4    t_eff 14.2.2 STUDY01
#> 5 f_meanci 14.2.3    <NA>
#> 6     l_ae 16.2.7    <NA>
```
