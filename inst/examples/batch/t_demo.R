# Batch mode: one program, one output. Run with
#   Rscript t_demo.R
# Organization conventions normally come from a site profile that sets
# options(tlfstack.config = ...); the example data stands in for a real ADaM read.
library(tlfstack)

output_dir <- tempdir()

#--- parameters (edit per study) ------------------------------------------------
TRT_VAR <- "TRT01A"
CONT_VARS <- list(AGE = "Age (years)")
CAT_VARS <- list(SEX = "Sex", RACE = "Race", ETHNIC = "Ethnicity")

#--- read + build (the same builder the Shiny app calls) -------------------------
adsl <- ex_adsl
res <- tlf_build_table("demographics", list(adsl = adsl),
                       opts = list(trt_var = TRT_VAR, cont_vars = CONT_VARS, cat_vars = CAT_VARS))

#--- titles + render ------------------------------------------------------------
titles <- tlf_resolve_titles("t_demo", type = "Table",
                             sources = list(toc_source_data(ex_toc)),
                             scope = list(study = "STUDY01"),
                             source = "Program: t_demo.R")
out <- file.path(output_dir, titles$output_file_name)
tlf_rtf_table(res, out, titles = titles)
message("Wrote ", out, " (titles: ", titles$provenance$mode, ")")
