# Analysis Results Data behind a table

Returns the Analysis Results Data (ARD) behind a table, for QC and for
numeric comparison with an independently produced result, such as a SAS
dataset.

## Usage

``` r
tlf_ard(x)

tlf_write_ard(x, path)
```

## Arguments

- x:

  A `card`, a gtsummary table, or a `tlf_table` converted from either.

- path:

  Output file, `.csv` or `.json`.

## Value

`tlf_ard()`: the ARD, or `NULL` when there is none. `tlf_write_ard()`:
`path`, invisibly.

## Details

- `tlf_ard()` returns the ARD: a cards `card` object, or a named list of
  them for a gtsummary table built in several steps.

- `tlf_write_ard()` flattens it to one row per statistic and writes CSV
  (or JSON, by file extension).

## Examples

``` r
if (requireNamespace("cards", quietly = TRUE)) {
  ard <- cards::ard_continuous(ex_adsl, by = TRT01A, variables = AGE)
  f <- tempfile(fileext = ".csv")
  tlf_write_ard(ard, f)
  head(read.csv(f))
  unlink(f)
}
```
