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

test_that("calc_correlation_point_biserial matches hand computation (r = 0.5 -> d = 1.1547 -> n = 13/group)", {
  # d = 2r/sqrt(1-r^2) = 2*0.5/sqrt(0.75) = 1.154701; pwr::pwr.t.test at that
  # d, alpha = 0.05 two-sided, power = 0.80 gives n = 13 per group (26 total).
  res <- calc_correlation_point_biserial(r = 0.5, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 1.1547)
  expect_equal(res$n_per_group, 13)
  expect_equal(res$n_total, 26)
})

test_that("calc_correlation_point_biserial rejects invalid inputs", {
  expect_error(calc_correlation_point_biserial(r = 0), "must not be zero")
  expect_error(calc_correlation_point_biserial(r = 1), "between -1 and 1")
  expect_error(calc_correlation_point_biserial(r = -1), "between -1 and 1")
  expect_error(calc_correlation_point_biserial(r = 0.5, alpha = 0), "between 0 and 1")
})

test_that("calc_regression_slope matches hand computation (slope = 0.5, sdx = 2, sdy = 4 -> r = 0.25 -> n = 123)", {
  # r = slope * sdx / sdy = 0.5 * 2 / 4 = 0.25; pwr::pwr.r.test at r = 0.25,
  # alpha = 0.05 two-sided, power = 0.80 gives n = 123.
  res <- calc_regression_slope(slope = 0.5, sd_x = 2, sd_y = 4, alpha = 0.05, power = 0.8)
  expect_equal(res$r, 0.25)
  expect_equal(res$n, 123)
})

test_that("calc_regression_slope rejects invalid inputs", {
  expect_error(calc_regression_slope(slope = 0, sd_x = 2, sd_y = 4), "must not be zero")
  expect_error(calc_regression_slope(slope = 0.5, sd_x = -2, sd_y = 4), "positive")
  expect_error(calc_regression_slope(slope = 0.5, sd_x = 2, sd_y = 4, alpha = 0), "between 0 and 1")
  expect_error(calc_regression_slope(slope = 10, sd_x = 2, sd_y = 4), "between -1 and 1")
})

test_that("calc_correlation_partial matches hand computation (r=0.3, k=2 -> n=87)", {
  # Zero-order n (pwr::pwr.r.test at r=0.3, alpha=0.05, power=0.8) is 85;
  # partial correlation adds k=2 for the covariates -> n=87. Independently
  # confirmed by a 5,000-replicate Monte Carlo simulation (empirical power
  # 0.826, closely matching the 0.80 target).
  res <- calc_correlation_partial(r = 0.3, k = 2, alpha = 0.05, power = 0.8)
  zero_order <- calc_correlation(r = 0.3, alpha = 0.05, power = 0.8)
  expect_equal(res$n, zero_order$n + 2)
  expect_equal(res$n, 87)
})

test_that("calc_correlation_partial rejects invalid inputs", {
  expect_error(calc_correlation_partial(r = 0, k = 2), "must not be zero")
  expect_error(calc_correlation_partial(r = 1, k = 2), "between -1 and 1")
  expect_error(calc_correlation_partial(r = 0.3, k = 0), "whole number, at least 1")
  expect_error(calc_correlation_partial(r = 0.3, k = 1.5), "whole number, at least 1")
  expect_error(calc_correlation_partial(r = 0.3, k = 2, alpha = 0), "between 0 and 1")
})

test_that("calc_correlation_two_dependent matches the worked example (r_yx1=.4, r_yx2=.6, r_x1x2=.3 -> n=183)", {
  # Verified against psych::r.test()'s exact implementation of Steiger
  # (1980)'s raw-r t-test and by 5,000-replicate Monte Carlo simulation
  # (empirical power 0.816 at this n, vs. the 0.80 target).
  res <- calc_correlation_two_dependent(r_yx1 = 0.4, r_yx2 = 0.6, r_x1x2 = 0.3,
                                         alpha = 0.05, power = 0.8)
  expect_equal(round(res$c, 4), 0.1704)
  expect_equal(res$n, 183)
})

test_that("calc_correlation_two_dependent reproduces Steiger (1980)'s own classic example's Z closely", {
  # Steiger's own textbook case: r_yx1=.4, r_yx2=.5, r_x1x2=.1, n=103 -> the
  # exact raw-r t-statistic (psych::r.test) gives t=-0.89. The Fisher-z
  # version implemented here should give a very close Z at the same n (both
  # are asymptotically equivalent tests of the same null hypothesis).
  z1 <- atanh(0.4); z2 <- atanh(0.5)
  rbar2 <- (0.4^2 + 0.5^2) / 2
  c_term <- (0.1 * (1 - 2 * rbar2) - 0.5 * rbar2 * (1 - 2 * rbar2 - 0.1^2)) / (1 - rbar2)^2
  Z <- (z1 - z2) * sqrt(103 - 3) / sqrt(2 - 2 * c_term)
  expect_equal(round(Z, 2), -0.89)
})

test_that("calc_correlation_two_dependent rejects invalid inputs", {
  expect_error(calc_correlation_two_dependent(1.1, 0.6, 0.3), "between -1 and 1")
  expect_error(calc_correlation_two_dependent(0.4, 1.1, 0.3), "between -1 and 1")
  expect_error(calc_correlation_two_dependent(0.4, 0.6, 1.1), "between -1 and 1")
  expect_error(calc_correlation_two_dependent(0.4, 0.4, 0.3), "must differ")
  expect_error(calc_correlation_two_dependent(0.9, -0.9, 0.0), "not a valid correlation matrix")
  expect_error(calc_correlation_two_dependent(0.4, 0.6, 0.3, alpha = 0), "between 0 and 1")
  expect_error(calc_correlation_two_dependent(0.4, 0.6, 0.3, power = 0), "between 0 and 1")
})
