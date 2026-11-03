test_that("calc_case_control_unmatched matches Woodward (2014) Example 8.17", {
  # p0 = 0.30, OR = 2.0, power = 0.90, two-sided alpha = 0.05, ratio = 1 ->
  # n = 376 total (188 cases, 188 controls).
  res <- calc_case_control_unmatched(p0 = 0.30, OR = 2.0, power = 0.90,
                                      ratio = 1, alpha = 0.05, alternative = "two.sided")
  expect_equal(res$n_total, 376)
  expect_equal(res$n_case, 188)
  expect_equal(res$n_control, 188)
})

test_that("calc_case_control_unmatched rejects invalid inputs", {
  expect_error(calc_case_control_unmatched(p0 = 0.3, OR = 1), "must differ")
  expect_error(calc_case_control_unmatched(p0 = 0, OR = 2), "between 0 and 1")
  expect_error(calc_case_control_unmatched(p0 = 0.3, OR = -1), "positive")
  expect_error(calc_case_control_unmatched(p0 = 0.3, OR = 2, alpha = 0), "between 0 and 1")
})

test_that("calc_case_control_matched matches Dupont (1988) p. 1164 (1:1)", {
  # p0 = 0.60, OR = 3.0, phi = 0.2, power = 0.80, two-sided alpha = 0.05,
  # ratio = 1 -> n = 162 total (81 cases, 81 controls).
  res <- calc_case_control_matched(p0 = 0.60, OR = 3.0, phi_coef = 0.2,
                                    power = 0.80, ratio = 1, alpha = 0.05,
                                    alternative = "two.sided")
  expect_equal(res$n_total, 162)
  expect_equal(res$n_case, 81)
  expect_equal(res$n_control, 81)
})

test_that("calc_case_control_matched matches Dupont (1988) p. 1164 (1:3)", {
  # Same scenario, but 3 controls per case -> n = 204 total (51 cases, 153 controls).
  res <- calc_case_control_matched(p0 = 0.60, OR = 3.0, phi_coef = 0.2,
                                    power = 0.80, ratio = 3, alpha = 0.05,
                                    alternative = "two.sided")
  expect_equal(res$n_total, 204)
  expect_equal(res$n_case, 51)
  expect_equal(res$n_control, 153)
})

test_that("calc_case_control_matched rejects invalid inputs", {
  expect_error(calc_case_control_matched(p0 = 0.6, OR = 3, phi_coef = 1), "between -1 and 1")
  expect_error(calc_case_control_matched(p0 = 0.6, OR = 1, phi_coef = 0.2), "must differ")
})

test_that("calc_case_control_nested_binary matches Lachin (2008) Sec 3.3 example", {
  # OR = 3.5, pE = 0.15, nD = 1, nH = 2, R2 = 0, alpha = 0.05, power = 0.80
  # -> N = 58.84 matched sets, ceiling -> 59 sets (177 subjects total).
  res <- calc_case_control_nested_binary(OR = 3.5, pE = 0.15, nD = 1, nH = 2,
                                          R2 = 0, alpha = 0.05, power = 0.80)
  expect_equal(res$n_sets, 59)
  expect_equal(res$n_total, 177)
})

test_that("calc_case_control_nested_continuous matches Lachin (2008) Sec 3.1 example", {
  # OR = 1.39, sigma = 1, nD = 1, nH = 2, R2 = 0, alpha = 0.05, power = 0.85
  # -> N = 124.19 matched sets, ceiling -> 125 sets (375 subjects total).
  res <- calc_case_control_nested_continuous(OR = 1.39, sigma = 1, nD = 1, nH = 2,
                                              R2 = 0, alpha = 0.05, power = 0.85)
  expect_equal(res$n_sets, 125)
  expect_equal(res$n_total, 375)
})

test_that("nested case-control functions reject invalid inputs", {
  expect_error(calc_case_control_nested_binary(OR = 1, pE = 0.15, nD = 1, nH = 2), "must differ")
  expect_error(calc_case_control_nested_binary(OR = 3.5, pE = 0.15, nD = 0, nH = 2), "positive integer")
  expect_error(calc_case_control_nested_continuous(OR = 1.39, sigma = -1, nD = 1, nH = 2), "positive")
  expect_error(calc_case_control_nested_binary(OR = 3.5, pE = 0.15, nD = 1, nH = 2, R2 = 1), "\\[0, 1\\)")
})

test_that("calc_case_control_case_cohort matches Cai & Zeng (2004) ARIC example", {
  # n = 15792, pD = 0.03, p1 = 0.25, alpha = 0.05, power = 0.8 -- three HR
  # rows from the paper's own worked table.
  res1 <- calc_case_control_case_cohort(n = 15792, pD = 0.03, p1 = 0.25, hr = 1.35,
                                         alpha = 0.05, power = 0.8)
  expect_equal(res1$subcohort_n, 1463)
  expect_equal(res1$full_cohort_n, 15792)

  res2 <- calc_case_control_case_cohort(n = 15792, pD = 0.03, p1 = 0.25, hr = 1.40,
                                         alpha = 0.05, power = 0.8)
  expect_equal(res2$subcohort_n, 722)

  res3 <- calc_case_control_case_cohort(n = 15792, pD = 0.03, p1 = 0.25, hr = 1.45,
                                         alpha = 0.05, power = 0.8)
  expect_equal(res3$subcohort_n, 468)
})

test_that("calc_case_control_case_cohort rejects invalid inputs", {
  expect_error(calc_case_control_case_cohort(n = 15792, pD = 0.03, p1 = 0.25, hr = 1), "must differ")
  expect_error(calc_case_control_case_cohort(n = 0, pD = 0.03, p1 = 0.25, hr = 1.35), "positive integer")
  expect_error(calc_case_control_case_cohort(n = 15792, pD = 1.5, p1 = 0.25, hr = 1.35), "between 0 and 1")
})

test_that("case-control: the effect given as p1 (proportion of cases exposed) equals the odds ratio it implies", {
  for (p0 in c(0.1, 0.3, 0.6)) for (or in c(0.5, 1.5, 2, 3)) {
    p1 <- or * p0 / (1 - p0 + or * p0)
    a <- calc_case_control_unmatched(p0 = p0, OR = or, power = 0.8)
    b <- calc_case_control_unmatched(p0 = p0, p1 = p1, power = 0.8)
    expect_equal(b$n_total, a$n_total)
    expect_equal(b$OR, or)
    expect_equal(a$p1, p1)
    m1 <- calc_case_control_matched(p0 = p0, OR = or, phi_coef = 0.2, ratio = 2)
    m2 <- calc_case_control_matched(p0 = p0, p1 = p1, phi_coef = 0.2, ratio = 2)
    expect_equal(m2$n_total, m1$n_total)
  }
  # epiR (the oracle) with the odds ratio computed from p1
  skip_if_not_installed("epiR")
  p0 <- 0.3; p1 <- 0.45
  or <- p1 * (1 - p0) / (p0 * (1 - p1))
  ref <- epiR::epi.sscc(N = NA, OR = or, p1 = NA, p0 = p0, n = NA, power = 0.8, r = 1, phi.coef = 0.2, design = 1,
                        sided.test = 2, nfractional = FALSE, conf.level = 0.95, method = "matched", fleiss = FALSE)
  expect_equal(calc_case_control_matched(p0 = p0, p1 = p1, phi_coef = 0.2)$n_total, ref$n.total)
  expect_error(calc_case_control_unmatched(p0 = 0.3, OR = 2, p1 = 0.4), "either")
  expect_error(calc_case_control_unmatched(p0 = 0.3), "either")
  expect_error(calc_case_control_matched(p0 = 0.3, p1 = 0.3), "must differ")
})

test_that("phi from a table of matched pairs is the correlation of the case and control exposures", {
  t <- calc_matched_pairs_phi(both = 30, case_only = 25, control_only = 10, neither = 35)
  case <- rep(c(1, 1, 0, 0), c(30, 25, 10, 35))
  control <- rep(c(1, 0, 1, 0), c(30, 25, 10, 35))
  expect_equal(t$phi, stats::cor(case, control))
  expect_equal(t$p1, mean(case))
  expect_equal(t$p0, mean(control))
  expect_equal(t$OR_matched, 25 / 10)
  # pairs simulated from Dupont's model (the exposure of the control given the case's, as in the sample-size formula) recover phi
  set.seed(1)
  p0 <- 0.4; p1 <- 0.55; phi <- 0.25; n <- 2e5
  pq <- p1 * (1 - p1) * p0 * (1 - p0)
  case <- stats::rbinom(n, 1, p1)
  control <- stats::rbinom(n, 1, ifelse(case == 1, (p1 * p0 + phi * sqrt(pq)) / p1, (p0 * (1 - p1) - phi * sqrt(pq)) / (1 - p1)))
  tab <- calc_matched_pairs_phi(sum(case & control), sum(case & !control), sum(!case & control), sum(!case & !control))
  expect_lt(abs(tab$phi - phi), 0.01)   # standard error about 0.002
  expect_lt(abs(tab$p0 - p0), 0.01)
  expect_error(calc_matched_pairs_phi(10, 0, 0, 0), "undefined")
  expect_error(calc_matched_pairs_phi(10, 2.5, 3, 4), "whole numbers")
})
