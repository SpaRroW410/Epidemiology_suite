source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_case_control.R"))

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
