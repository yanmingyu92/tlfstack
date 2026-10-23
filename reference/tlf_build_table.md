# Build a registered table, listing or figure

The dispatcher. Batch programs and interactive apps make the same call,
so both get the same object, and the same renderer then produces the
same RTF content.

## Usage

``` r
tlf_build_table(type, data, opts = list(), config = NULL)

tlf_build_figure(type, df, ctx = fig_ctx(), opts = list(), config = NULL)
```

## Arguments

- type:

  A registered type key (see
  [`tlf_table_types()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_table_types.md)
  and
  [`tlf_figure_types()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_table_types.md)).

- data:

  Named list of data frames, for example
  `list(adsl = adsl, adae = adae)`.

- opts:

  Named list of builder options, for example
  `list(trt_var = "TRTA", paramcd = "ALT")`.

- config:

  A
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md);
  `NULL` resolves through
  [`tlf_get_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_get_config.md).

- df:

  Analysis data frame for a figure.

- ctx:

  A
  [`fig_ctx()`](https://yanmingyu92.github.io/tlfstack/reference/fig_ctx.md)
  list.

## Value

A `tlf_table` (tables) or a ggplot (figures).

## Examples

``` r
tlf_build_table("demographics", list(adsl = ex_adsl))
#> <tlf_table> 13 row(s) x 6 column(s)
#>  Characteristic Statistic                 Drug 10 mg (N=20) Drug 20 mg (N=20)
#>  Age (years)    n                         20                20               
#>                 Mean (SD)                 58.2 (8.4)        59.6 (9.5)       
#>                 Median (Q1, Q3)           58.0 (53.0, 64.5) 57.0 (54.0, 64.0)
#>                 Min, Max                  41.0, 72.0        48.0, 88.0       
#>  Sex            F                         12 (60.0%)        13 (65.0%)       
#>                 M                         8 (40.0%)         7 (35.0%)        
#>  Race           ASIAN                     6 (30.0%)         4 (20.0%)        
#>                 BLACK OR AFRICAN AMERICAN 3 (15.0%)         5 (25.0%)        
#>                 WHITE                     11 (55.0%)        11 (55.0%)       
#>  Ethnicity      HISPANIC OR LATINO        3 (15.0%)         2 (10.0%)        
#>                 NOT HISPANIC OR LATINO    17 (85.0%)        18 (90.0%)       
#>  Age group      <65                       15 (75.0%)        16 (80.0%)       
#>                 >=65                      5 (25.0%)         4 (20.0%)        
#>  Placebo (N=20)    Total (N=60)     
#>  20                60               
#>  54.4 (10.8)       57.4 (9.7)       
#>  54.0 (46.0, 59.5) 56.5 (51.5, 63.5)
#>  31.0, 77.0        31.0, 88.0       
#>  13 (65.0%)        38 (63.3%)       
#>  7 (35.0%)         22 (36.7%)       
#>  4 (20.0%)         14 (23.3%)       
#>  4 (20.0%)         12 (20.0%)       
#>  12 (60.0%)        34 (56.7%)       
#>  8 (40.0%)         13 (21.7%)       
#>  12 (60.0%)        47 (78.3%)       
#>  17 (85.0%)        48 (80.0%)       
#>  3 (15.0%)         12 (20.0%)       
p <- tlf_build_figure("meanci", ex_adlb[ex_adlb$PARAMCD == "ALT", ])
```
