# Registered types

Registered types

## Usage

``` r
tlf_table_types()

tlf_figure_types()
```

## Value

A data frame with one row per registered type: `type`, `label`, and for
tables also `class` and `domains`.

## Examples

``` r
tlf_table_types()
#>           type                                               label   class
#> 1 demographics           Demographics and baseline characteristics   Table
#> 2  disposition                                 Subject disposition   Table
#> 3           ae                        Adverse events by SOC and PT   Table
#> 4  ae_severity                  Adverse events by maximum severity   Table
#> 5          eff Summary by visit (observed or change from baseline)   Table
#> 6        shift                Shift: baseline vs endpoint category   Table
#> 7          tte         Time to event: KM medians, Cox HR, log-rank   Table
#> 8   listing_ae                           Listing of adverse events Listing
#> 9  listing_lab                       Listing of laboratory results Listing
#>      domains
#> 1       adsl
#> 2       adsl
#> 3 adae, adsl
#> 4 adae, adsl
#> 5        bds
#> 6        bds
#> 7      adtte
#> 8       adae
#> 9        bds
tlf_figure_types()
#>             type                                     label
#> 1         meanci                        Mean (CI) by visit
#> 2     meanci_chg   Mean (CI) change from baseline by visit
#> 3        boxplot                         Box plot by visit
#> 4      spaghetti               Individual subject profiles
#> 5  spaghetti_chg  Individual change-from-baseline profiles
#> 6        lsmeans                         LS-means by visit
#> 7    lsmeans_chg LS-means of change from baseline by visit
#> 8             km                        Kaplan-Meier curve
#> 9         forest                      Subgroup forest plot
#> 10     waterfall                Waterfall of best % change
#> 11         edish                     eDISH (Hy's Law) plot
#> 12         shift                                Shift plot
```
