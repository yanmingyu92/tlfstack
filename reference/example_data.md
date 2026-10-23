# Synthetic example data

Small simulated ADaM-like datasets for examples, tests and vignettes.
All values are randomly generated and describe no real study.

## Format

Data frames.

## Source

Simulated; see `data-raw/make_example_data.R` in the package sources.

## Details

- `ex_adsl`: subject level, 60 subjects, three arms (`TRT01A`).

- `ex_adae`: adverse events (`AESOC`, `AEDECOD`, `AESEV`, `TRTEMFL`).

- `ex_adlb`: laboratory BDS for `ALT`, `AST` and `BILI` at four visits,
  with `BASE`, `CHG`, `PCHG` and reference ranges.

- `ex_adtte`: time to event (`AVAL` in days, `CNSR == 1` censored).
