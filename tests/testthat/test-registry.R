test_that("built-in registries list the expected types", {
  expect_setequal(tlf_table_types()$type,
                  c("demographics", "disposition", "ae", "ae_severity", "eff", "shift", "tte",
                    "listing_ae", "listing_lab"))
  expect_length(tlf_figure_types()$type, 12)
  expect_identical(tlf_table_types()$class[tlf_table_types()$type == "listing_ae"], "Listing")
})

test_that("the dispatcher passes options and rejects unknown types or data", {
  r <- tlf_build_table("eff", list(bds = ex_adlb), opts = list(paramcd = "AST", value_col = "AVAL"))
  expect_identical(r$meta$value_col, "AVAL")
  expect_error(tlf_build_table("nope", list()), "Unknown table type")
  expect_error(tlf_build_table("demographics", ex_adsl), "named list")
  expect_error(tlf_build_table("demographics", list(adae = ex_adae)), "needs data\\$adsl")
  expect_error(tlf_build_figure("nope", alt()), "Unknown figure type")
})

test_that("organizations can register and remove their own builders", {
  tlf_register_table("n_by_arm", function(data, opts, config) {
    n <- stat_big_n(data$adsl, "TRT01A")
    tlf_table_result(data.frame(Group = names(n), N = as.character(n)))
  }, label = "Subjects by arm", domains = "adsl")
  withr::defer(tlf_unregister("n_by_arm"))
  expect_true("n_by_arm" %in% tlf_table_types()$type)
  expect_s3_class(tlf_build_table("n_by_arm", list(adsl = ex_adsl)), "tlf_table")
  tlf_register_table("bad", function(data, opts, config) 1L)
  withr::defer(tlf_unregister("bad"))
  expect_error(tlf_build_table("bad", list()), "did not return")
  expect_error(tlf_register_table("bad key", identity), "identifier")
})

test_that("same builder call gives identical output in either mode (dual-mode seam)", {
  # A batch program and an interactive app make the same dispatcher call; the
  # rendered RTF must be byte-identical.
  f1 <- withr::local_tempfile(fileext = ".rtf")
  f2 <- withr::local_tempfile(fileext = ".rtf")
  t <- tlf_resolve_titles("t_demo", sources = toc_source_data(ex_toc), scope = list(study = "STUDY01"))
  batch <- tlf_build_table("demographics", list(adsl = ex_adsl))
  interactive_ <- tlf_build_table("demographics", list(adsl = ex_adsl))
  tlf_rtf_table(batch, f1, titles = t)
  tlf_rtf_table(interactive_, f2, titles = t)
  expect_identical(unname(tools::md5sum(f1)), unname(tools::md5sum(f2)))
})
