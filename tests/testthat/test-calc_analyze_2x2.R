# Willeberg (1977) dry-cat-food / feline urologic syndrome counts, the worked
# example in epiR::epi.2by2()'s help page: "The prevalence of FUS in DCF exposed
# cats was 4.01 (95% CI 1.43 to 11.23) times greater ...", "75% (95% CI 30% to
# 91%) of the FUS cases were attributable to DCF".
fus <- c(a = 13, b = 2163, c = 5, d = 3349)
call_fus <- function(...) calc_analyze_2x2(fus[["a"]], fus[["b"]], fus[["c"]], fus[["d"]], ...)

test_that("reproduces the published Willeberg (1977) / epiR worked example", {
  r <- call_fus(design = "cross_sectional")
  expect_equal(round(c(r$risk_ratio, r$risk_ratio_lower, r$risk_ratio_upper), 2), c(4.01, 1.43, 11.23))
  expect_equal(round(100 * c(r$attributable_fraction_exposed, r$attributable_fraction_exposed_lower,
                             r$attributable_fraction_exposed_upper)), c(75, 30, 91))
})

test_that("RR, OR and RD match independent hand formulas (Katz, Woolf, Wald)", {
  r <- call_fus()
  z <- qnorm(0.975)
  rr <- (13 / 2176) / (5 / 3354)
  se_rr <- sqrt(1 / 13 - 1 / 2176 + 1 / 5 - 1 / 3354)
  expect_equal(r$risk_ratio, rr)
  expect_equal(c(r$risk_ratio_lower, r$risk_ratio_upper), exp(log(rr) + c(-1, 1) * z * se_rr))
  or <- (13 * 3349) / (2163 * 5)
  se_or <- sqrt(1 / 13 + 1 / 2163 + 1 / 5 + 1 / 3349)
  expect_equal(c(r$odds_ratio, r$odds_ratio_lower, r$odds_ratio_upper), c(or, exp(log(or) + c(-1, 1) * z * se_or)))
  rd <- 13 / 2176 - 5 / 3354
  se_rd <- sqrt((13 / 2176) * (1 - 13 / 2176) / 2176 + (5 / 3354) * (1 - 5 / 3354) / 3354)
  expect_equal(c(r$risk_difference, r$risk_difference_lower, r$risk_difference_upper), rd + c(0, -1, 1) * z * se_rd)
})

test_that("cohort and cross-sectional estimates equal epiR::epi.2by2() (the verification oracle)", {
  skip_if_not_installed("epiR")
  tables <- list(c(13, 2163, 5, 3349), c(40, 60, 20, 80), c(8, 92, 30, 70), c(100, 400, 60, 440))
  for (tb in tables) {
    for (design in c("cohort", "cross_sectional")) {
      r <- calc_analyze_2x2(tb[1], tb[2], tb[3], tb[4], design = design)
      e <- suppressMessages(epiR::epi.2by2(as.table(matrix(tb, 2, byrow = TRUE)),
                                           method = if (design == "cohort") "cohort.count" else "cross.sectional"))$massoc.summary
      get <- function(pattern) as.numeric(e[grepl(pattern, e$var, fixed = FALSE), c("est", "lower", "upper")][1, ])
      expect_equal(c(r$risk_ratio, r$risk_ratio_lower, r$risk_ratio_upper), get("risk ratio"), tolerance = 1e-6, info = paste(tb, design))
      expect_equal(c(r$odds_ratio, r$odds_ratio_lower, r$odds_ratio_upper), get("odds ratio"), tolerance = 1e-6)
      expect_equal(100 * c(r$risk_difference, r$risk_difference_lower, r$risk_difference_upper),
                   get("^Attrib (inc risk|prev) \\*"), tolerance = 1e-6)
      expect_equal(100 * c(r$attributable_fraction_exposed, r$attributable_fraction_exposed_lower, r$attributable_fraction_exposed_upper),
                   get("fraction in exposed"), tolerance = 1e-6)
      expect_equal(100 * c(r$population_attributable_fraction, r$population_attributable_fraction_lower, r$population_attributable_fraction_upper),
                   get("fraction in population"), tolerance = 1e-6)
    }
  }
})

test_that("case-control: OR as in the cohort layout, population attributable fraction equals epiR's Jewell estimate", {
  skip_if_not_installed("epiR")
  r <- call_fus(design = "case_control")
  e <- suppressMessages(epiR::epi.2by2(as.table(matrix(fus, 2, byrow = TRUE)), method = "case.control"))$massoc.summary
  expect_null(r$risk_ratio)
  expect_null(r$number_needed)
  expect_equal(c(r$odds_ratio, r$odds_ratio_lower, r$odds_ratio_upper), as.numeric(e[1, c("est", "lower", "upper")]), tolerance = 1e-6)
  expect_equal(100 * c(r$population_attributable_fraction, r$population_attributable_fraction_lower,
                       r$population_attributable_fraction_upper),
               as.numeric(e[3, c("est", "lower", "upper")]), tolerance = 1e-6)
  # (OR - 1)/OR from the sample OR; epiR's exposed fraction uses the conditional MLE of the OR instead
  expect_equal(r$attributable_fraction_exposed, (r$odds_ratio - 1) / r$odds_ratio)
})

test_that("number needed: reciprocal of the risk difference, interval only when the RD interval excludes 0 (Altman 1998)", {
  r <- call_fus()
  expect_equal(r$number_needed, 1 / (13 / 2176 - 5 / 3354))
  expect_equal(r$number_needed_label, "NNH (harm)")
  expect_equal(c(r$number_needed_lower, r$number_needed_upper), sort(1 / abs(c(r$risk_difference_lower, r$risk_difference_upper))))
  prot <- calc_analyze_2x2(10, 190, 40, 160) # exposure protective
  expect_equal(prot$number_needed_label, "NNT (benefit)")
  null <- calc_analyze_2x2(21, 79, 20, 80)   # RD interval includes 0
  expect_true(is.na(null$number_needed_lower) && is.na(null$number_needed_upper))
})

test_that("tests of association: Pearson (uncorrected) chi-square and Fisher exact", {
  r <- call_fus()
  m <- matrix(fus, 2, byrow = TRUE)
  expect_equal(r$chisq_p, suppressWarnings(chisq.test(m, correct = FALSE))$p.value)
  expect_equal(r$fisher_p, fisher.test(m)$p.value)
  expect_lt(r$min_expected_count, 10)
})

test_that("a zero cell gives NA for the undefined interval and is flagged, never silently corrected", {
  r <- calc_analyze_2x2(0, 50, 10, 40)
  expect_true(r$zero_cell)
  expect_equal(r$risk_ratio, 0)
  expect_true(is.na(r$risk_ratio_lower))
  expect_false(call_fus()$zero_cell)
})

test_that("invalid input is refused with a plain message", {
  expect_error(calc_analyze_2x2(-1, 5, 5, 5), "non-negative whole number")
  expect_error(calc_analyze_2x2(1.5, 5, 5, 5), "whole number")
  expect_error(calc_analyze_2x2(NA, 5, 5, 5), "whole number")
  expect_error(calc_analyze_2x2(0, 0, 5, 5), "at least one subject")
  expect_error(calc_analyze_2x2(5, 0, 5, 0), "at least one subject")
  expect_error(calc_analyze_2x2(5, 5, 5, 5, conf_level = 1.2))
})

test_that("a wider confidence level widens every interval; the result is an ss_result", {
  r90 <- call_fus(conf_level = 0.90); r99 <- call_fus(conf_level = 0.99)
  expect_gt(r99$risk_ratio_upper - r99$risk_ratio_lower, r90$risk_ratio_upper - r90$risk_ratio_lower)
  expect_s3_class(r90, "ss_result")
})

test_that("analyze_2x2_table lists one row per measure with labels that follow the design", {
  tb <- analyze_2x2_table(call_fus())
  expect_equal(tb$measure[1], "Risk ratio (RR)")
  expect_true("NNH (harm)" %in% tb$measure)
  expect_equal(analyze_2x2_table(call_fus(design = "cross_sectional"))$measure[1], "Prevalence ratio (PR)")
  expect_equal(nrow(analyze_2x2_table(call_fus(design = "case_control"))), 3)
})
