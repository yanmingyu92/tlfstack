# Changelog

## tlfstack 0.1.0

First release. tlfstack is a clean re-implementation, as an open-source
package, of the mechanism layer of a convention-driven clinical TLF
reporting system described in a SESUG 2026 conference paper.

### Features

- Configuration layer:
  [`tlf_config()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_config.md)
  holds page geometry, fonts, page header, palette, treatment-variable
  candidates and render policy. It resolves from the argument, then
  `options(tlfstack.config)`, then the `TLFSTACK_CONFIG` YAML file, then
  defaults.
- 8 table/listing builders (9 dispatcher types) and 9 figure builders
  (12 dispatcher types), all pure functions. Organizations can register
  their own builders with
  [`tlf_register_table()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_register_table.md)
  and
  [`tlf_register_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_register_table.md).
- Structured title blocks
  ([`tlf_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_titles.md))
  with `{placeholder}` filling and provenance.
- Three-mode title resolution
  ([`tlf_resolve_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_titles.md)):
  live DBI source, then snapshot, then a TODO placeholder with a
  warning.
- A JSON/YAML TOC interchange format
  ([`toc_write()`](https://yanmingyu92.github.io/tlfstack/reference/toc_write.md),
  [`toc_source_file()`](https://yanmingyu92.github.io/tlfstack/reference/toc_sources.md))
  with a published JSON Schema.
- Crash-isolated figure rendering with bounded retries and a CSV attempt
  log
  ([`tlf_run_isolated()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_run_isolated.md),
  [`tlf_rtf_figure()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_rtf_figure.md)).

### Fixes relative to the system described in the SESUG 2026 paper

- Snapshot discovery found only `.rds` snapshots by default, so a
  deployed `.csv` snapshot silently degraded to fallback mode.
  [`toc_source_dir()`](https://yanmingyu92.github.io/tlfstack/reference/toc_sources.md)
  now looks for `.json`, `.yml`, `.yaml`, `.csv` and `.rds`, and a
  regression test covers the CSV-only case.
- Text is written to RTF verbatim by default. With r2rtf’s default
  markup conversion, `_` in names such as `t_demo.R` became a subscript
  and `>=` became a symbol, which broke character-identical title
  blocks. RTF control characters are escaped and non-ASCII characters
  are written as RTF Unicode. r2rtf conversion is available with
  `tlf_config(text_convert = TRUE)`.
- The text-layer font is resolved by name from r2rtf’s public output. It
  no longer relies on an unexported r2rtf function.
- Portrait tables now get portrait page dimensions.
- Ambiguous TOC matches (several rows for one program and scope) are now
  an error, not a silent first-row pick. Use `number` to choose.
- A treatment group given as a factor keeps its level order in tables
  and figures.
- A standard deviation from a single value prints as `NE`.

### Not included (planned)

- MMRM, subgroup regression and observed-case efficacy tables.
- Backoff between render retries, detection of deterministic crashes,
  and a placeholder RTF in batch mode when retries are exhausted.
- Analysis Results Data (cards/cardx) as an alternative builder input.
