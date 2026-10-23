# Column mapping for tabular TOC sources

Describes how a TOC stored as a flat table (a database table, CSV or RDS
file, or data frame) maps onto the canonical TOC fields. Column names
are matched case-insensitively. Multi-line cells are split on `delim`.

## Usage

``` r
toc_schema(
  program = "program_name",
  type = "output_type",
  number = "output_number",
  title = "output_title",
  subtitle = "output_subtitle",
  footnotes = "output_footnotes",
  output_file_name = "output_file_name",
  scope = c("study", "milestone"),
  delim = "\\"
)
```

## Arguments

- program:

  Column(s) holding the program name. When several are given, the first
  non-blank value in each row wins.

- type, number, title, subtitle, footnotes, output_file_name:

  Columns holding each field. Use `NA` for a field the source does not
  have.

- scope:

  Columns that scope a row, for example to a study or milestone. A named
  vector renames them: `c(study = "study_id")` exposes column `study_id`
  as scope key `study`.

- delim:

  Line delimiter inside multi-line cells.

## Value

An object of class `toc_schema`.

## Examples

``` r
toc_schema(program = c("r_program", "program_name"), scope = c(study = "study_id"))
#> $program
#> [1] "r_program"    "program_name"
#> 
#> $type
#> [1] "output_type"
#> 
#> $number
#> [1] "output_number"
#> 
#> $title
#> [1] "output_title"
#> 
#> $subtitle
#> [1] "output_subtitle"
#> 
#> $footnotes
#> [1] "output_footnotes"
#> 
#> $output_file_name
#> [1] "output_file_name"
#> 
#> $scope
#>      study 
#> "study_id" 
#> 
#> $delim
#> [1] "\\"
#> 
#> attr(,"class")
#> [1] "toc_schema"
```
