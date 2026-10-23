# Register a builder

Adds a table/listing or figure type to the dispatcher, or replaces an
existing one. This lets an organization add study-specific outputs that
run through the same renderers.

## Usage

``` r
tlf_register_table(
  type,
  fun,
  label = type,
  class = c("Table", "Listing"),
  domains = character()
)

tlf_register_figure(type, fun, label = type)

tlf_unregister(type, kind = c("table", "figure"))
```

## Arguments

- type:

  Type key, for example `"vitals"`.

- fun:

  For tables: `function(data, opts, config)`, where `data` is a named
  list of data frames; it must return a
  [`tlf_table_result()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_table_result.md).
  For figures: `function(df, ctx, opts, config)`; it must return a
  ggplot.

- label:

  Human-readable label, for example for a selection menu.

- class:

  For tables: `"Table"` or `"Listing"`.

- domains:

  Names of the `data` elements the builder reads.

- kind:

  Which registry to remove `type` from.

## Value

`type`, invisibly.

## Examples

``` r
tlf_register_table("n_by_arm", function(data, opts, config) {
  n <- stat_big_n(data$adsl, "TRT01A")
  tlf_table_result(data.frame(Group = names(n), N = as.character(n)))
}, label = "Subjects by arm", domains = "adsl")
tlf_build_table("n_by_arm", list(adsl = ex_adsl))
#> <tlf_table> 4 row(s) x 2 column(s)
#>  Group      N 
#>  Drug 10 mg 20
#>  Drug 20 mg 20
#>  Placebo    20
#>  Total      60
tlf_unregister("n_by_arm")
```
