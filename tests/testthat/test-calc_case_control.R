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
