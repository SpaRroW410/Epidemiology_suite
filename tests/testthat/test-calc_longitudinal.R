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

test_that("calc_longitudinal_diggle reproduces the printed table on page 29 of Diggle et al (2002)", {
  # longpower::diggle.linear.power() -- a single, self-contained function
  # with no cross-file dependencies -- was read directly from its public
  # GitHub CRAN mirror and transcribed. Verified by literally reproducing
  # the function's own documented example: the 3x3 table (rho x sigma2)
  # on page 29 of Diggle et al (2002), 3 visits at t=0,2,5, delta=0.5,
  # one-sided alpha=0.05, power=0.80.
  t <- c(0, 2, 5)
  expected <- list(
    "0.2" = c("100" = 313, "200" = 625, "300" = 938),
    "0.5" = c("100" = 196, "200" = 391, "300" = 586),
    "0.8" = c("100" = 79, "200" = 157, "300" = 235)
  )
  for (rho in c(0.2, 0.5, 0.8)) {
    for (sigma2 in c(100, 200, 300)) {
      res <- calc_longitudinal_diggle(visit_times = t, delta = 0.5, sigma2 = sigma2, rho = rho,
                                       alternative = "one.sided", power = 0.80)
      expect_equal(res$n_per_group, unname(expected[[as.character(rho)]][as.character(sigma2)]))
    }
  }
})

test_that("calc_longitudinal_diggle needs a larger sample size for a smaller correlation", {
  t <- c(0, 2, 5)
  res_low_rho <- calc_longitudinal_diggle(visit_times = t, delta = 0.5, sigma2 = 100, rho = 0.2,
                                           alternative = "one.sided", power = 0.80)
  res_high_rho <- calc_longitudinal_diggle(visit_times = t, delta = 0.5, sigma2 = 100, rho = 0.8,
                                            alternative = "one.sided", power = 0.80)
  expect_gt(res_low_rho$n_per_group, res_high_rho$n_per_group)
})

test_that("calc_longitudinal_diggle rejects invalid inputs", {
  expect_error(calc_longitudinal_diggle(visit_times = c(0), delta = 0.5, sigma2 = 100, rho = 0.2), "at least 2")
  expect_error(calc_longitudinal_diggle(visit_times = c(0, 2), delta = 0, sigma2 = 100, rho = 0.2), "non-zero")
  expect_error(calc_longitudinal_diggle(visit_times = c(0, 2), delta = 0.5, sigma2 = -1, rho = 0.2), "positive")
  expect_error(calc_longitudinal_diggle(visit_times = c(0, 2), delta = 0.5, sigma2 = 100, rho = 1.5), "between 0 and 1")
})

test_that("calc_longitudinal_edland matches longpower::edland.linear.power()'s own documented example", {
  # longpower::edland.linear.power() -- a single, self-contained function
  # with no cross-file dependencies -- was read directly from its public
  # GitHub CRAN mirror and transcribed. Verified two ways: (1) reproduces
  # the function's own documented Alzheimer's-disease example exactly
  # (raw N=414.6202, ~207/arm); (2) independently matches this app's
  # already-verified Liu & Liang implementation's raw N for the
  # equivalent (near-zero random-intercept variance) scenario exactly.
  t <- seq(0, 1.5, 0.25)
  res <- calc_longitudinal_edland(visit_times = t, delta = 1.5, sigma2_slope = 24,
                                   sigma2_residual = 10, alpha = 0.05, power = 0.80)
  expect_equal(res$n_per_group, 208)
  expect_equal(res$n_total, 416)

  # Liu & Liang ceilings the *total* N directly (ceiling(414.62)=415);
  # edland ceilings *per-group* n first then doubles (ceiling(207.31)*2
  # =416) -- a rounding-methodology difference, not a real numeric gap:
  # both round-trip to the same raw underlying N to within 1.
  res_ll <- calc_longitudinal_slope_diff(visit_times = t, delta = 1.5, sigma2_intercept = 1e-9,
                                          sigma2_slope = 24, cov_intercept_slope = 0,
                                          sigma2_residual = 10, alpha = 0.05, power = 0.80)
  expect_lte(abs(res_ll$n_total - res$n_total), 1)
})

test_that("calc_longitudinal_edland needs a larger sample size for a bigger residual variance", {
  t <- seq(0, 1.5, 0.25)
  res_low <- calc_longitudinal_edland(visit_times = t, delta = 1.5, sigma2_slope = 24, sigma2_residual = 5)
  res_high <- calc_longitudinal_edland(visit_times = t, delta = 1.5, sigma2_slope = 24, sigma2_residual = 20)
  expect_lt(res_low$n_total, res_high$n_total)
})

test_that("calc_longitudinal_edland rejects invalid inputs", {
  t <- seq(0, 1.5, 0.25)
  expect_error(calc_longitudinal_edland(visit_times = c(0), delta = 1.5, sigma2_slope = 24, sigma2_residual = 10), "at least 2")
  expect_error(calc_longitudinal_edland(visit_times = t, delta = 0, sigma2_slope = 24, sigma2_residual = 10), "non-zero")
  expect_error(calc_longitudinal_edland(visit_times = t, delta = 1.5, sigma2_slope = -1, sigma2_residual = 10), "positive")
  expect_error(calc_longitudinal_edland(visit_times = t, delta = 1.5, sigma2_slope = 24, sigma2_residual = -1), "positive")
})

test_that("calc_longitudinal_hu matches longpower::hu.mackey.thomas.linear.power()'s own documented examples", {
  # longpower::hu.mackey.thomas.linear.power() -- a single, self-
  # contained function with no cross-file dependencies -- was read
  # directly from its public GitHub CRAN mirror and transcribed.
  # Verified against 3 of the package's own documented round-trip
  # examples exactly (ADAS-cog-style pilot estimates, no attrition).
  t <- seq(0, 1.5, 0.25)
  p <- c(rep(0, 6), 1)

  res1 <- calc_longitudinal_hu(visit_times = t, p = p, delta = 1.5, sigma2_slope = 24,
                                sigma2_residual = 10, cor_intercept_slope = 0.5, power = 0.80)
  expect_equal(res1$n1, 180)
  expect_equal(res1$n2, 180)
  expect_equal(res1$n_total, 360)

  res2 <- calc_longitudinal_hu(visit_times = t, p = p, delta = 1.5, sigma2_slope = 24,
                                sigma2_residual = 10, cor_intercept_slope = 0.5, lambda = 2, power = 0.80)
  expect_equal(res2$n1, 270)
  expect_equal(res2$n2, 135)

  res3 <- calc_longitudinal_hu(visit_times = t, p = p, delta = 1.5, sigma2_slope = 24,
                                sigma2_residual = 10, cor_intercept_slope = 0.5, power = 0.80,
                                alternative = "one.sided")
  expect_equal(res3$n1, 142)
  expect_equal(res3$n2, 142)
})

test_that("calc_longitudinal_hu needs a larger sample size for more attrition earlier", {
  t <- seq(0, 1.5, 0.25)
  p_complete <- c(rep(0, 6), 1)
  p_early_dropout <- c(0.3, rep(0, 5), 0.7)
  res_complete <- calc_longitudinal_hu(visit_times = t, p = p_complete, delta = 1.5, sigma2_slope = 24,
                                        sigma2_residual = 10, cor_intercept_slope = 0.5, power = 0.80)
  res_dropout <- calc_longitudinal_hu(visit_times = t, p = p_early_dropout, delta = 1.5, sigma2_slope = 24,
                                       sigma2_residual = 10, cor_intercept_slope = 0.5, power = 0.80)
  expect_gt(res_dropout$n_total, res_complete$n_total)
})

test_that("calc_longitudinal_hu rejects invalid inputs", {
  t <- seq(0, 1.5, 0.25)
  p <- c(rep(0, 6), 1)
  expect_error(calc_longitudinal_hu(visit_times = c(1, 2), p = c(0, 1), delta = 1, sigma2_slope = 1, sigma2_residual = 1), "must be 0")
  expect_error(calc_longitudinal_hu(visit_times = t, p = c(0.3, 0.3, rep(0, 5)), delta = 1, sigma2_slope = 1, sigma2_residual = 1), "sum to 1")
  expect_error(calc_longitudinal_hu(visit_times = t, p = p, delta = 0, sigma2_slope = 1, sigma2_residual = 1), "non-zero")
  expect_error(calc_longitudinal_hu(visit_times = t, p = p, delta = 1, sigma2_slope = -1, sigma2_residual = 1), "positive")
  expect_error(calc_longitudinal_hu(visit_times = t, p = p, delta = 1, sigma2_slope = 1, sigma2_residual = 1, cor_intercept_slope = 1.5), "\\[-1, 1\\]")
})
