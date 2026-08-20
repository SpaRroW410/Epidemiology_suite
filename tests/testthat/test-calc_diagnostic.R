source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_diagnostic.R"))

# All worked examples below are independently recomputed from Akoglu H.
# User's guide to sample size estimation in diagnostic accuracy studies.
# Turk J Emerg Med. 2022;22(4):177-185 -- Table 2 (equations) and the
# article's own worked examples (Tables 3-6 and body text). Where our
# precise (unrounded) computation differs by 1 from the article's own
# pre-rounded table figure, that's noted -- expected from the article's own
# chain of intermediate rounding, not a formula discrepancy (verified by
# hand against the source PDF).

test_that("calc_diagnostic_accuracy (Eq 1): matches the article's own worked example exactly", {
  # Se = 90%, prevalence = 10%, d = 5%, 95% CI -> n = 1383 (Table 3B; also
  # given directly in the article's body text). Exact match, no rounding gap.
  res <- calc_diagnostic_accuracy(sens = 0.90, spec = 0.85, prevalence = 0.10,
                                   prec_sens = 0.05, prec_spec = 0.05, conf_level = 0.95)
  expect_equal(res$n_sens, 1383)
})

test_that("calc_diagnostic_accuracy (Eq 1): worst-case symmetric check", {
  res <- calc_diagnostic_accuracy(sens = 0.5, spec = 0.5, prevalence = 0.5,
                                   prec_sens = 0.05, prec_spec = 0.05, conf_level = 0.95)
  expect_equal(res$n, 769)
  expect_equal(res$n_diseased, 385)
  expect_equal(res$n_healthy, 385)
})

test_that("calc_diagnostic_accuracy (Eq 1) rejects invalid inputs", {
  expect_error(calc_diagnostic_accuracy(sens = 0, spec = 0.85, prevalence = 0.3), "between 0 and 1")
  expect_error(calc_diagnostic_accuracy(sens = 0.9, spec = 0.85, prevalence = 0.3, conf_level = 1), "between 0 and 1")
})

test_that("calc_diagnostic_vs_reference (Eq 2): matches the article's appendicitis CT example", {
  # Sn0=90%, Sn1=95%, Sp0=80%, Sp1=85%, prevalence=40%, alpha=.05, power=.90,
  # two-sided -> article's own (Yates-corrected, prevalence-adjusted) table
  # figures are 849 (sensitivity) and 1093 (specificity), N=1093 (specificity
  # binds). Our unrounded computation lands within 1 of each.
  res <- calc_diagnostic_vs_reference(sens0 = 0.90, sens1 = 0.95,
                                       spec0 = 0.80, spec1 = 0.85,
                                       prevalence = 0.40, alpha = 0.05, power = 0.90,
                                       alternative = "two.sided")
  expect_equal(res$n_sens, 850)
  expect_equal(res$n_spec, 1094)
  expect_equal(res$n, 1094)
  expect_equal(res$binding, "specificity")
})

test_that("calc_diagnostic_vs_reference (Eq 2) rejects invalid inputs", {
  expect_error(calc_diagnostic_vs_reference(sens0 = 0.9, sens1 = 0.9, spec0 = 0.8, spec1 = 0.85,
                                             prevalence = 0.4), "must differ")
  expect_error(calc_diagnostic_vs_reference(sens0 = 0.9, sens1 = 0.95, spec0 = 0.8, spec1 = 0.8,
                                             prevalence = 0.4), "must differ")
})

test_that("calc_diagnostic_two_indep (Eq 3a): matches the article's two-pathway example", {
  # P1=80%, P2=70%, one-sided alpha=.05, power=.80 -> article's own
  # (Yates-corrected) figure is 250 per pathway (500 total); ours is 251/502.
  res <- calc_diagnostic_two_indep(p1 = 0.80, p2 = 0.70, alpha = 0.05, power = 0.80,
                                    alternative = "greater")
  expect_equal(res$n_per_group, 251)
  expect_equal(res$n_total, 502)
})

test_that("calc_diagnostic_two_indep (Eq 3a) rejects invalid inputs", {
  expect_error(calc_diagnostic_two_indep(p1 = 0.7, p2 = 0.7), "must differ")
})

test_that("calc_diagnostic_two_paired (Eq 3b): matches the article's paired-pathway example", {
  # Same P1=80%/P2=70% comparison, but paired (within-subjects): article's
  # own range is 78 (Psi_min) to 252 (Psi_max); ours is 79/253.
  res <- calc_diagnostic_two_paired(p1 = 0.70, p2 = 0.80, alpha = 0.05, power = 0.80,
                                     alternative = "greater")
  expect_equal(res$n_min, 79)
  expect_equal(res$n_max, 253)
  expect_equal(round(res$psi_min, 2), 0.10)
  expect_equal(round(res$psi_max, 2), 0.38)
})

test_that("calc_diagnostic_two_paired (Eq 3b): paired range sits well below the unpaired n", {
  paired <- calc_diagnostic_two_paired(p1 = 0.80, p2 = 0.70, alpha = 0.05, power = 0.80,
                                        alternative = "greater")
  indep <- calc_diagnostic_two_indep(p1 = 0.80, p2 = 0.70, alpha = 0.05, power = 0.80,
                                      alternative = "greater")
  expect_lt(paired$n_max, indep$n_total)
})

test_that("calc_diagnostic_two_paired (Eq 3b) rejects invalid inputs", {
  expect_error(calc_diagnostic_two_paired(p1 = 0.7, p2 = 0.7), "must differ")
})
