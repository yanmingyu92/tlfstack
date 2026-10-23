# Add footnotes to a title block

Appends footnotes after the existing ones and drops exact duplicates,
keeping the first occurrence. Renderers use this to place
builder-derived notes (for example a hazard ratio) after the
table-of-contents footnotes.

## Usage

``` r
tlf_titles_add_footnotes(titles, footnotes)
```

## Arguments

- titles:

  A
  [`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md)
  object.

- footnotes:

  Character vector to append.

## Value

A new `tlf_titles`.

## Examples

``` r
t <- tlf_titles("Overall Survival", type = "Figure", number = "14.2.1")
tlf_titles_add_footnotes(t, "Log-rank p-value: 0.032")$footnotes
#> [1] "Log-rank p-value: 0.032"
```
