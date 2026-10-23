# Release gate: the installed package must not contain identifying strings.
# The pattern list never ships with the package. It is read from a local file
# named by TLFSTACK_DEID_PATTERNS (one regular expression per line) that only
# exists on the maintainer's machine, so this test is skipped elsewhere.

test_that("no identifying strings in the package tree", {
  pat_file <- Sys.getenv("TLFSTACK_DEID_PATTERNS", "")
  skip_if(!nzchar(pat_file) || !file.exists(pat_file), "no local de-identification pattern list")
  pats <- readLines(pat_file, warn = FALSE)
  pats <- pats[nzchar(pats) & !startsWith(pats, "#")]
  root <- system.file(package = "tlfstack")
  files <- list.files(root, recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("\\.(rda|rds|png|ico|rdb|rdx)$", files, ignore.case = TRUE)]
  hits <- character()
  for (f in files) {
    txt <- tryCatch(readLines(f, warn = FALSE), error = function(e) character())
    for (p in pats) if (any(grepl(p, txt, ignore.case = TRUE, perl = TRUE))) {
      hits <- c(hits, sprintf("%s: /%s/", sub(root, "", f, fixed = TRUE), p))
    }
  }
  expect_identical(hits, character())
})
