source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_rmst.R"))

test_that("calc_rmst_comparison is reproducible under a fixed seed", {
  skip_if_not_slow()
  res1 <- calc_rmst_comparison(
    ac_period = 35, tot_time = 510, tau = 500,
    scale0 = 8500, scale1 = 8500, margin = 18, power = 0.8
  )
  res2 <- calc_rmst_comparison(
    ac_period = 35, tot_time = 510, tau = 500,
    scale0 = 8500, scale1 = 8500, margin = 18, power = 0.8
  )
  expect_identical(res1$n0, res2$n0)
  expect_identical(res1$achieved_power_separate, res2$achieved_power_separate)
})

test_that("calc_rmst_comparison reproduces SSRMST's own documented example scenarios", {
  skip_if_not_slow()
  # SSRMST::ssrmst()'s own roxygen example uses ac_rate=15, ac_period=35,
  # tot_time=510, tau=500 for both its non-inferiority and superiority
  # illustrations. SSRMST isn't installable from CRAN in this sandbox
  # (no network access), and its own power calculation calls
  # survRM2::rmst2() internally -- also not installed -- so both
  # packages' source was read directly from their public GitHub CRAN
  # mirrors and their core RMST-difference estimator (confirmed
  # identical: sum each arm's own Kaplan-Meier-area RMST variance) was
  # reimplemented using only the `survival` package. These numbers were
  # directly verified by an Rscript run before wiring into the app.
  res_ni <- calc_rmst_comparison(
    ac_period = 35, tot_time = 510, tau = 500,
    scale0 = 8500, scale1 = 8500, margin = 18, power = 0.8
  )
  expect_equal(res_ni$n0, 206)
  expect_equal(res_ni$n1, 206)
  expect_equal(res_ni$achieved_power_separate, 0.78, tolerance = 0.05)

  res_sup <- calc_rmst_comparison(
    ac_period = 35, tot_time = 510, tau = 500,
    scale0 = 4000, scale1 = 8500, margin = 0, power = 0.8
  )
  expect_equal(res_sup$n0, 432)
  expect_equal(res_sup$n1, 432)
  expect_equal(res_sup$achieved_power_separate, 0.82, tolerance = 0.05)
})

test_that("calc_rmst_comparison needs a larger sample size for a higher target power", {
  skip_if_not_slow()
  res_low <- calc_rmst_comparison(
    ac_period = 35, tot_time = 510, tau = 500,
    scale0 = 4000, scale1 = 8500, margin = 0, power = 0.7
  )
  res_high <- calc_rmst_comparison(
    ac_period = 35, tot_time = 510, tau = 500,
    scale0 = 4000, scale1 = 8500, margin = 0, power = 0.9
  )
  expect_lt(res_low$n_total, res_high$n_total)
})

test_that("calc_rmst_comparison rejects invalid inputs", {
  expect_error(
    calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 520, scale0 = 8500, scale1 = 8500),
    "less than tot_time"
  )
  expect_error(
    calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 500, scale0 = 8500, scale1 = 4000),
    "proportional-hazards"
  )
  expect_error(
    calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 500, scale0 = 8500, scale1 = 8500, margin = -1),
    "margin"
  )
  expect_error(
    calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 500, scale0 = 8500, scale1 = 8500, allocation1 = 1.5),
    "allocation1"
  )
  expect_error(
    calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 500, scale0 = -1, scale1 = 8500),
    "positive"
  )
})
