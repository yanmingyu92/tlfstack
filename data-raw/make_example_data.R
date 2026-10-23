# Generates the synthetic example datasets shipped in data/. Every value is
# simulated; no real study data is involved. Run from the package root:
#   Rscript --no-init-file data-raw/make_example_data.R
set.seed(20261022)

n <- 60
arms <- c("Placebo", "Drug 10 mg", "Drug 20 mg")
ids <- sprintf("STUDY01-%03d", seq_len(n))
trt <- rep(arms, length.out = n)
age <- round(stats::rnorm(n, 58, 11))
disc <- stats::runif(n) < 0.15

ex_adsl <- data.frame(
  STUDYID = "STUDY01", USUBJID = ids, TRT01A = trt, TRT01P = trt,
  AGE = age, AGEGR1 = ifelse(age < 65, "<65", ">=65"),
  SEX = sample(c("F", "M"), n, TRUE),
  RACE = sample(c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN"), n, TRUE, prob = c(0.6, 0.25, 0.15)),
  ETHNIC = sample(c("HISPANIC OR LATINO", "NOT HISPANIC OR LATINO"), n, TRUE, prob = c(0.2, 0.8)),
  RANDFL = "Y", SAFFL = "Y", COMPLFL = ifelse(disc, "N", "Y"),
  EOSSTT = ifelse(disc, "DISCONTINUED", "COMPLETED"),
  DCSREAS = ifelse(disc, sample(c("ADVERSE EVENT", "WITHDRAWAL BY SUBJECT", "LOST TO FOLLOW-UP"), n, TRUE), ""),
  stringsAsFactors = FALSE)

soc_pt <- data.frame(
  AESOC = c("GASTROINTESTINAL DISORDERS", "GASTROINTESTINAL DISORDERS", "NERVOUS SYSTEM DISORDERS",
            "NERVOUS SYSTEM DISORDERS", "INFECTIONS AND INFESTATIONS", "SKIN AND SUBCUTANEOUS TISSUE DISORDERS"),
  AEDECOD = c("NAUSEA", "DIARRHOEA", "HEADACHE", "DIZZINESS", "NASOPHARYNGITIS", "RASH"),
  stringsAsFactors = FALSE)
n_ae <- 120
pick <- sample(nrow(soc_pt), n_ae, TRUE)
subj <- sample(n, n_ae, TRUE)
ex_adae <- data.frame(
  STUDYID = "STUDY01", USUBJID = ids[subj], TRT01A = trt[subj],
  AESOC = soc_pt$AESOC[pick], AEDECOD = soc_pt$AEDECOD[pick],
  AESEV = sample(c("MILD", "MODERATE", "SEVERE"), n_ae, TRUE, prob = c(0.6, 0.3, 0.1)),
  AEREL = sample(c("RELATED", "NOT RELATED"), n_ae, TRUE),
  AEOUT = sample(c("RECOVERED/RESOLVED", "NOT RECOVERED/NOT RESOLVED"), n_ae, TRUE, prob = c(0.85, 0.15)),
  AESTDTC = format(as.Date("2026-01-15") + sample(0:120, n_ae, TRUE)),
  TRTEMFL = ifelse(stats::runif(n_ae) < 0.92, "Y", "N"),
  stringsAsFactors = FALSE)
ex_adae <- ex_adae[order(ex_adae$USUBJID, ex_adae$AESTDTC), ]
rownames(ex_adae) <- NULL

visits <- data.frame(AVISIT = c("Baseline", "Week 4", "Week 8", "Week 12"), AVISITN = c(0, 4, 8, 12))
params <- data.frame(PARAMCD = c("ALT", "AST", "BILI"),
                     PARAM = c("Alanine Aminotransferase (U/L)", "Aspartate Aminotransferase (U/L)",
                               "Bilirubin (umol/L)"),
                     AVALU = c("U/L", "U/L", "umol/L"), ANRLO = c(7, 10, 3), ANRHI = c(40, 35, 21),
                     mu = c(28, 25, 11), stringsAsFactors = FALSE)
eff <- c(Placebo = 0, `Drug 10 mg` = 2, `Drug 20 mg` = 4)
rows <- list()
for (i in seq_len(n)) for (p in seq_len(nrow(params))) {
  base <- max(1, stats::rnorm(1, params$mu[p], params$mu[p] * 0.3))
  if (i %% 25 == 0 && params$PARAMCD[p] != "BILI") base <- base * 4
  if (i %% 25 == 0 && params$PARAMCD[p] == "BILI") base <- base * 2.5
  aval <- round(c(base, base + eff[[trt[i]]] * visits$AVISITN[-1] / 4 +
                    stats::rnorm(3, 0, params$mu[p] * 0.15)), 1)
  aval <- pmax(aval, 0.5)
  rows[[length(rows) + 1L]] <- data.frame(
    STUDYID = "STUDY01", USUBJID = ids[i], TRT01A = trt[i], SEX = ex_adsl$SEX[i],
    AGEGR1 = ex_adsl$AGEGR1[i], PARAMCD = params$PARAMCD[p], PARAM = params$PARAM[p],
    AVISIT = visits$AVISIT, AVISITN = visits$AVISITN, AVAL = aval, BASE = aval[1],
    CHG = c(NA, aval[-1] - aval[1]), PCHG = c(NA, round((aval[-1] - aval[1]) / aval[1] * 100, 1)),
    AVALU = params$AVALU[p], ANRLO = params$ANRLO[p], ANRHI = params$ANRHI[p],
    ANRIND = ifelse(aval < params$ANRLO[p], "LOW", ifelse(aval > params$ANRHI[p], "HIGH", "NORMAL")),
    stringsAsFactors = FALSE)
}
ex_adlb <- do.call(rbind, rows)
rownames(ex_adlb) <- NULL

hz <- c(Placebo = 1 / 300, `Drug 10 mg` = 1 / 380, `Drug 20 mg` = 1 / 460)
ev_t <- stats::rexp(n, hz[trt])
cens_t <- stats::runif(n, 200, 540)
ex_adtte <- data.frame(
  STUDYID = "STUDY01", USUBJID = ids, TRT01A = trt, SEX = ex_adsl$SEX, AGEGR1 = ex_adsl$AGEGR1,
  PARAMCD = "PFS", PARAM = "Progression-free survival (days)",
  AVAL = round(pmin(ev_t, cens_t)), CNSR = as.integer(ev_t > cens_t), AVALU = "DAYS",
  stringsAsFactors = FALSE)

# Example table of contents in the canonical layout (see ?toc_read).
ex_toc <- data.frame(
  program = c("t_demo", "t_ae", "t_eff", "t_eff", "f_meanci", "l_ae"),
  type = c("Table", "Table", "Table", "Table", "Figure", "Listing"),
  number = c("14.1.1", "14.3.1", "14.2.1", "14.2.2", "14.2.3", "16.2.7"),
  stringsAsFactors = FALSE)
ex_toc$title <- list("Summary of Demographic and Baseline Characteristics",
                     "Treatment-Emergent Adverse Events by System Organ Class and Preferred Term",
                     c("Summary of {param}", "Change from Baseline by Visit"),
                     c("Summary of {param}", "Observed Values by Visit"),
                     c("Mean (95% CI) of {param} by Visit"),
                     "Listing of Adverse Events")
ex_toc$subtitle <- list("Safety Population", "Safety Population", "Safety Population",
                        "Safety Population", "Safety Population", "Safety Population")
ex_toc$footnotes <- list("Percentages are based on the number of subjects in each column.",
                         c("A subject is counted once per system organ class and preferred term.",
                           "MedDRA version 27.0."),
                         character(), character(), "Error bars are 95% confidence intervals.",
                         character())
ex_toc$output_file_name <- c("t-14-01-01-demog.rtf", "t-14-03-01-teae.rtf", "t-14-02-01-chg.rtf",
                             "t-14-02-02-obs.rtf", "f-14-02-03-meanci.rtf", "l-16-02-07-ae.rtf")
ex_toc$study <- c("STUDY01", "STUDY01", "STUDY01", "STUDY01", NA, NA)

save(ex_adsl, file = "data/ex_adsl.rda", compress = "xz")
save(ex_adae, file = "data/ex_adae.rda", compress = "xz")
save(ex_adlb, file = "data/ex_adlb.rda", compress = "xz")
save(ex_adtte, file = "data/ex_adtte.rda", compress = "xz")
save(ex_toc, file = "data/ex_toc.rda", compress = "xz")
