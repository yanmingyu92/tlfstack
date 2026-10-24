## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local Windows 11, R 4.6.0 (`R CMD check --as-cran`)
* GitHub Actions: ubuntu-latest (R-devel, R-release, R-oldrel-1),
  windows-latest (R-release), macos-latest (R-release)

## Notes for the reviewer

* Tests that start child R processes (crash isolation via callr) are skipped
  on CRAN.
* Examples write only to `tempdir()` and need no network access.
