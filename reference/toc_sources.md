# TOC sources

Sources are passed, in priority order, to
[`tlf_resolve_titles()`](https://yanmingyu92.github.io/tlfstack/reference/tlf_resolve_titles.md)
and
[`toc_read()`](https://yanmingyu92.github.io/tlfstack/reference/toc_read.md).

## Usage

``` r
toc_source_db(conn, table, schema = toc_schema(), label = "database")

toc_source_file(path, schema = toc_schema(), label = basename(path))

toc_source_dir(dir, stem = "toc_snapshot", schema = toc_schema())

toc_source_data(data, schema = toc_schema(), label = "data frame")
```

## Arguments

- conn:

  A `DBIConnection`, or a function with no arguments returning one.

- table:

  Table name, or a
  [`DBI::Id()`](https://dbi.r-dbi.org/reference/Id.html) for
  schema-qualified names. The name is quoted by DBI, never pasted into
  SQL.

- schema:

  A
  [`toc_schema()`](https://yanmingyu92.github.io/tlfstack/reference/toc_schema.md)
  mapping for tabular sources.

- label:

  Short description recorded in the provenance of resolved titles.

- path:

  File path.

- dir:

  Directory to search.

- stem:

  File name without extension.

- data:

  A data frame in the layout described by `schema`.

## Value

An object of class `toc_source`.

## Details

- `toc_source_db()`: a live database table read through DBI (mode
  `"live"`).

- `toc_source_file()`: a snapshot file (mode `"snapshot"`). `.json`,
  `.yml`/`.yaml` (the tlfstack interchange format, see
  [`toc_write()`](https://yanmingyu92.github.io/tlfstack/reference/toc_write.md)),
  `.csv` and `.rds` are supported.

- `toc_source_dir()`: finds a snapshot in a directory by trying
  `<stem>.json`, `<stem>.yml`, `<stem>.yaml`, `<stem>.csv` and
  `<stem>.rds`, in that order.

- `toc_source_data()`: an in-memory data frame (mode `"snapshot"`).

## Credentials

tlfstack never reads credentials or builds connection strings. Pass
either an open DBI connection, which you own and close, or a function
with no arguments that returns one. tlfstack calls the function for each
read and disconnects afterwards. Keep secrets in your own secret store
(for example a keyring, an ODBC DSN, or environment variables read
inside your function).

## Examples

``` r
f <- tempfile(fileext = ".yml")
toc_write(ex_toc, f)
src <- toc_source_file(f)
nrow(toc_read(src))
#> [1] 6
unlink(f)
```
