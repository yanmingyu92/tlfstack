# Three-mode title resolution: live (mock DB), snapshot (files), fallback.

flat_toc <- function() {
  data.frame(
    program_name = c("t_demo", "t_ae", "t_demo"),
    output_type = c("Table", "Table", "Table"),
    output_number = c("14.1.1", "14.3.1", "14.1.1"),
    output_title = c("Summary of Demographics\\Baseline Characteristics", "TEAEs by SOC and PT",
                     "Demographics (Study B)"),
    output_subtitle = c("Safety Population", "Safety Population", ""),
    output_footnotes = c("Note one.\\Note two.", "", ""),
    output_file_name = c("t-14-01-01.rtf", "t-14-03-01.rtf", "t-b.rtf"),
    study = c("", "", "STUDYB"),
    milestone = NA_character_,
    stringsAsFactors = FALSE)
}

test_that("tabular TOCs are normalized: delimiter split, string numbers", {
  toc <- toc_read(toc_source_data(flat_toc()))
  expect_identical(toc$title[[1]], c("Summary of Demographics", "Baseline Characteristics"))
  expect_identical(toc$footnotes[[1]], c("Note one.", "Note two."))
  expect_identical(toc$footnotes[[2]], character())
  expect_type(toc$number, "character")
})

test_that("snapshot mode resolves titles exactly", {
  t <- tlf_resolve_titles("t_demo", sources = list(toc_source_data(flat_toc())))
  expect_identical(t$provenance$mode, "snapshot")
  expect_identical(t$banner, "Table 14.1.1")
  expect_identical(t$title, c("Summary of Demographics", "Baseline Characteristics"))
  expect_identical(t$subtitle, "Safety Population")
  expect_identical(t$output_file_name, "t-14-01-01.rtf")
})

test_that("the most specific scope match wins; wildcard rows apply elsewhere", {
  src <- toc_source_data(flat_toc())
  b <- tlf_resolve_titles("t_demo", sources = src, scope = list(study = "STUDYB"))
  expect_identical(b$title, "Demographics (Study B)")
  a <- tlf_resolve_titles("t_demo", sources = src, scope = list(study = "STUDYA"))
  expect_identical(a$title[1], "Summary of Demographics")
})

test_that("program matching ignores case and .R/.sas extensions", {
  t <- tlf_resolve_titles("T_AE.R", sources = toc_source_data(flat_toc()))
  expect_identical(t$banner, "Table 14.3.1")
})

test_that("ambiguous matches fail loudly; `number` disambiguates", {
  src <- toc_source_data(ex_toc)
  expect_error(suppressWarnings(tlf_resolve_titles("t_eff", sources = src, scope = list(study = "STUDY01"))),
               class = "tlfstack_ambiguous_toc")
  t <- tlf_resolve_titles("t_eff", sources = src, scope = list(study = "STUDY01"), number = "14.2.2",
                          vars = list(param = "ALT"))
  expect_identical(t$title, c("Summary of ALT", "Observed Values by Visit"))
})

test_that("fallback: placeholder title, warning, program keeps running", {
  expect_warning(t <- tlf_resolve_titles("t_missing", type = "Figure",
                                         sources = list(toc_source_data(flat_toc()))),
                 class = "tlfstack_toc_fallback")
  expect_identical(t$provenance$mode, "fallback")
  expect_identical(t$banner, "Figure x.y.z")
  expect_match(t$title, "TODO: t_missing title from TOC")
  expect_identical(t$output_file_name, "t_missing.rtf")
  expect_warning(t0 <- tlf_resolve_titles("t_demo"), "no TOC source")
  expect_identical(t0$provenance$mode, "fallback")
})

test_that("REGRESSION: a CSV-only snapshot directory engages snapshot mode", {
  # Earlier implementations looked only for an .rds snapshot by default, so
  # a deployed .csv snapshot silently degraded to fallback.
  dir <- withr::local_tempdir()
  utils::write.csv(flat_toc(), file.path(dir, "toc_snapshot.csv"), row.names = FALSE)
  t <- tlf_resolve_titles("t_demo", sources = list(toc_source_dir(dir)))
  expect_identical(t$provenance$mode, "snapshot")
  expect_identical(t$title[1], "Summary of Demographics")
})

test_that("RDS snapshots still work, and unreadable sources fall through in order", {
  dir <- withr::local_tempdir()
  saveRDS(flat_toc(), file.path(dir, "toc_snapshot.rds"))
  srcs <- list(toc_source_file(file.path(dir, "missing.csv")), toc_source_dir(dir))
  t <- tlf_resolve_titles("t_ae", sources = srcs)
  expect_identical(t$provenance$mode, "snapshot")
  expect_identical(t$banner, "Table 14.3.1")
})

test_that("live mode reads a DBI table; the live source is authoritative", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  db <- withr::local_tempfile(fileext = ".sqlite")
  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  live <- flat_toc()
  live$output_title[1] <- "Live Title"
  DBI::dbWriteTable(con, "toc", live)
  DBI::dbDisconnect(con)
  connector <- function() DBI::dbConnect(RSQLite::SQLite(), db)
  srcs <- list(toc_source_db(connector, "toc"), toc_source_data(flat_toc()))
  t <- tlf_resolve_titles("t_demo", sources = srcs)
  expect_identical(t$provenance$mode, "live")
  expect_identical(t$title, "Live Title")
})

test_that("an unreachable live source degrades to the snapshot", {
  skip_if_not_installed("DBI")
  broken <- function() stop("network unreachable")
  srcs <- list(toc_source_db(broken, "toc"), toc_source_data(flat_toc()))
  t <- tlf_resolve_titles("t_demo", sources = srcs)
  expect_identical(t$provenance$mode, "snapshot")
})

test_that("JSON and YAML snapshots round-trip losslessly", {
  for (ext in c("json", "yml")) {
    if (ext == "json") skip_if_not_installed("jsonlite")
    if (ext == "yml") skip_if_not_installed("yaml")
    f <- withr::local_tempfile(fileext = paste0(".", ext))
    toc_write(ex_toc, f, source = "unit test")
    back <- toc_read(toc_source_file(f))
    for (col in c("program", "type", "number", "output_file_name")) {
      expect_identical(back[[col]], ex_toc[[col]], info = paste(ext, col))
    }
    for (col in c("title", "subtitle", "footnotes")) {
      expect_identical(back[[col]], ex_toc[[col]], info = paste(ext, col))
    }
    expect_identical(back$study, ex_toc$study)
    expect_identical(attr(back, "toc_meta")$source, "unit test")
    expect_false(is.null(attr(back, "toc_meta")$generated_at))
  }
})

test_that("snapshot provenance carries generated_at into resolved titles", {
  skip_if_not_installed("jsonlite")
  f <- withr::local_tempfile(fileext = ".json")
  toc_write(ex_toc, f)
  t <- tlf_resolve_titles("t_demo", sources = toc_source_file(f), scope = list(study = "STUDY01"))
  expect_false(is.null(t$provenance$generated_at))
  expect_identical(t$provenance$source, basename(f))
})

test_that("CSV round-trip uses the schema delimiter", {
  f <- withr::local_tempfile(fileext = ".csv")
  toc_write(ex_toc, f)
  raw <- utils::read.csv(f, colClasses = "character")
  expect_true(any(grepl("\\", raw$output_title, fixed = TRUE)))
  back <- toc_read(toc_source_file(f))
  expect_identical(back$title, ex_toc$title)
})

test_that("interchange files are validated", {
  skip_if_not_installed("jsonlite")
  f <- withr::local_tempfile(fileext = ".json")
  writeLines('{"outputs": []}', f)
  expect_error(toc_read(toc_source_file(f)), "tlfstack_toc")
  writeLines('{"tlfstack_toc": 99, "outputs": []}', f)
  expect_error(toc_read(toc_source_file(f)), "version")
  writeLines('{"tlfstack_toc": 1, "outputs": [{"program": "t_x"}]}', f)
  expect_error(toc_read(toc_source_file(f)), "no `title`")
})

test_that("on_resolve hook receives the titles; its errors become warnings", {
  seen <- NULL
  tlf_resolve_titles("t_demo", sources = toc_source_data(flat_toc()),
                     on_resolve = function(t) seen <<- t$provenance$mode)
  expect_identical(seen, "snapshot")
  expect_warning(tlf_resolve_titles("t_demo", sources = toc_source_data(flat_toc()),
                                    on_resolve = function(t) stop("disk full")), "disk full")
})

test_that("custom schemas map other column names and multiple program columns", {
  d <- data.frame(r_prog = c("", "t_x"), sas_prog = c("t_y", "t_z.sas"), num = c("1", "2"),
                  ttl = c("Title Y", "Title X"), stringsAsFactors = FALSE)
  sch <- toc_schema(program = c("r_prog", "sas_prog"), type = NA, number = "num", title = "ttl",
                    subtitle = NA, footnotes = NA, output_file_name = NA, scope = character())
  toc <- toc_read(toc_source_data(d, schema = sch))
  expect_identical(toc$program, c("t_y", "t_x"))
  t <- tlf_resolve_titles("t_x", sources = toc_source_data(d, schema = sch))
  expect_identical(t$banner, "Table 2")
})

test_that("the shipped JSON Schema exists and names the format version", {
  path <- system.file("schema", "tlfstack-toc-v1.schema.json", package = "tlfstack")
  expect_true(nzchar(path))
  expect_match(paste(readLines(path), collapse = ""), "tlfstack_toc")
})
