source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_correlation.R"))

test_that("calc_correlation matches Cohen (1988)'s classic medium-effect example", {
  # r = 0.3, alpha = 0.05 two-sided, power = 0.80 -> n = 85, one of the most
  # frequently quoted sample-size figures in the literature.
  res <- calc_correlation(r = 0.3, alpha = 0.05, power = 0.8, alternative = "two.sided")
  expect_equal(res$n, 85)
})

test_that("calc_correlation rejects invalid inputs", {
  expect_error(calc_correlation(r = 0), "must not be zero")
  expect_error(calc_correlation(r = 1), "between -1 and 1")
  expect_error(calc_correlation(r = -1), "between -1 and 1")
  expect_error(calc_correlation(r = 0.3, alpha = 0), "between 0 and 1")
})

test_that("calc_correlation_two_independent matches UCLA's G*Power worked example (power = 0.90)", {
  # r1 = 0.89, r2 = 0.76, alpha = 0.05 two-sided, power = 0.90 -> n = 61 per
  # group -- this row matches exactly under both round-to-nearest (as UCLA's
  # published table shows) and this project's ceiling() convention.
  res <- calc_correlation_two_independent(r1 = 0.89, r2 = 0.76, alpha = 0.05, power = 0.90)
  expect_equal(res$n_per_group, 61)
  expect_equal(round(res$q, 4), 0.4257)
})

test_that("calc_correlation_two_independent's other UCLA rows agree once ceiling()'d", {
  # UCLA's table shows n = 46 (power = 0.80) and n = 37 (power = 0.70) using
  # round-to-nearest; ceiling() of the same underlying continuous n (46.31,
  # 37.06) gives one more in each case, consistent with every other
  # calculator in this app always rounding up.
  res80 <- calc_correlation_two_independent(r1 = 0.89, r2 = 0.76, alpha = 0.05, power = 0.80)
  expect_equal(res80$n_per_group, 47)
  res70 <- calc_correlation_two_independent(r1 = 0.89, r2 = 0.76, alpha = 0.05, power = 0.70)
  expect_equal(res70$n_per_group, 38)
})

test_that("calc_correlation_two_independent rejects invalid inputs", {
  expect_error(calc_correlation_two_independent(r1 = 0.5, r2 = 0.5), "must differ")
  expect_error(calc_correlation_two_independent(r1 = 1, r2 = 0.5), "between -1 and 1")
  expect_error(calc_correlation_two_independent(r1 = 0.5, r2 = 0.3, alpha = 0), "between 0 and 1")
})
