source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_longitudinal.R"))

test_that("calc_longitudinal_slope_diff matches longpower's own documented Alzheimer's-disease example", {
  # longpower isn't installable from CRAN in this sandbox (no network
  # access); liu.liang.linear.power()'s source -- a single, self-
  # contained function with no cross-file dependencies -- was read
  # directly from its public GitHub CRAN mirror and transcribed. Its own
  # vignette states this exact scenario "would require about 207
  # subjects per arm": 7 visits (0 to 1.5, step 0.25), slope difference
  # to detect = 1.5, random-intercept variance = 55, random-slope
  # variance = 24, intercept-slope correlation = 0.8, residual variance
  # = 10, alpha = 0.05, power = 0.80.
  res <- calc_longitudinal_slope_diff(
    visit_times = seq(0, 1.5, 0.25), delta = 1.5,
    sigma2_intercept = 55, sigma2_slope = 24,
    cov_intercept_slope = 0.8 * sqrt(55) * sqrt(24), sigma2_residual = 10,
    alpha = 0.05, power = 0.80
  )
  expect_equal(res$n_total, 415)
  expect_equal(res$n1, 208)
  expect_equal(res$n0, 208)
})

test_that("calc_longitudinal_slope_diff needs a larger sample size for a higher target power", {
  res_low <- calc_longitudinal_slope_diff(
    visit_times = seq(0, 1.5, 0.25), delta = 1.5,
    sigma2_intercept = 55, sigma2_slope = 24,
    cov_intercept_slope = 0.8 * sqrt(55) * sqrt(24), sigma2_residual = 10,
    power = 0.7
  )
  res_high <- calc_longitudinal_slope_diff(
    visit_times = seq(0, 1.5, 0.25), delta = 1.5,
    sigma2_intercept = 55, sigma2_slope = 24,
    cov_intercept_slope = 0.8 * sqrt(55) * sqrt(24), sigma2_residual = 10,
    power = 0.9
  )
  expect_lt(res_low$n_total, res_high$n_total)
})

test_that("calc_longitudinal_slope_diff rejects invalid inputs", {
  base_args <- list(visit_times = c(0, 1), sigma2_intercept = 1, sigma2_slope = 1,
                     cov_intercept_slope = 0, sigma2_residual = 1)
  expect_error(do.call(calc_longitudinal_slope_diff, c(base_args, list(delta = 0))), "non-zero")
  expect_error(
    do.call(calc_longitudinal_slope_diff, c(list(visit_times = c(0, 1), delta = 1,
                                                   sigma2_intercept = 1, sigma2_slope = 1,
                                                   cov_intercept_slope = 5, sigma2_residual = 1))),
    "not a valid covariance"
  )
  expect_error(
    do.call(calc_longitudinal_slope_diff, c(list(visit_times = c(0, 1), delta = 1,
                                                   sigma2_intercept = -1, sigma2_slope = 1,
                                                   cov_intercept_slope = 0, sigma2_residual = 1))),
    "positive"
  )
  expect_error(
    do.call(calc_longitudinal_slope_diff, c(list(visit_times = c(0), delta = 1,
                                                   sigma2_intercept = 1, sigma2_slope = 1,
                                                   cov_intercept_slope = 0, sigma2_residual = 1))),
    "at least 2"
  )
  expect_error(
    do.call(calc_longitudinal_slope_diff, c(base_args, list(delta = 1, allocation1 = 1.5))),
    "between 0 and 1"
  )
})

test_that("calc_mmrm_ar1 matches longpower::power.mmrm.ar1()'s own documented Table 5 example", {
  # longpower isn't installable from CRAN in this sandbox (no network
  # access); power.mmrm.ar1()'s source -- a single, self-contained
  # function with no cross-file dependencies, from the same longpower
  # package as calc_longitudinal_slope_diff() above -- was read directly
  # from its public GitHub CRAN mirror and transcribed. Verified against
  # the package's own documented "approximate simulation results from
  # Table 5" of Lu, Luo & Chen (2008): rho=0.6, arm-1 retention=(1,0.76,
  # 0.63,0.52), arm-2 retention=(1,0.87,0.81,0.78), sigma=1, delta=0.9,
  # lambda=sqrt(1.25/1.75), target power=0.904 -> N=81 total (37/44 per
  # arm), matching the package's own companion example exactly (which
  # fixes N=81 and solves back for rho, recovering rho=0.585, close to
  # the input 0.6 -- the gap explained by N=81 being a rounded integer).
  ra <- c(1, 0.76, 0.63, 0.52)
  rb <- c(1, 0.87, 0.81, 0.78)
  res <- calc_mmrm_ar1(rho = 0.6, ra = ra, rb = rb, sigma = 1,
                        lambda = sqrt(1.25 / 1.75), delta = 0.9, power = 0.904)
  expect_equal(res$n1, 37)
  expect_equal(res$n2, 44)
  expect_equal(res$n_total, 81)
})

test_that("calc_mmrm_ar1 needs a larger sample size for a higher target power", {
  ra <- c(1, 0.76, 0.63, 0.52)
  rb <- c(1, 0.87, 0.81, 0.78)
  res_low <- calc_mmrm_ar1(rho = 0.6, ra = ra, rb = rb, sigma = 1, lambda = 1, delta = 0.9, power = 0.7)
  res_high <- calc_mmrm_ar1(rho = 0.6, ra = ra, rb = rb, sigma = 1, lambda = 1, delta = 0.9, power = 0.9)
  expect_lt(res_low$n_total, res_high$n_total)
})

test_that("calc_mmrm_ar1 rejects invalid inputs", {
  ra <- c(1, 0.76, 0.63, 0.52)
  expect_error(calc_mmrm_ar1(rho = 1.5, ra = ra, sigma = 1, delta = 0.9), "between 0 and 1")
  expect_error(calc_mmrm_ar1(rho = 0.6, ra = c(0.5, 0.9), sigma = 1, delta = 0.9), "non-increasing")
  expect_error(calc_mmrm_ar1(rho = 0.6, ra = ra, sigma = -1, delta = 0.9), "positive")
  expect_error(calc_mmrm_ar1(rho = 0.6, ra = ra, sigma = 1, delta = 0), "non-zero")
})
