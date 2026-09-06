source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_rate.R"))

test_that("calc_rate_precision matches presize::prec_rate()'s own documented example", {
  # presize's own doc example: r=2.5, conf.width=2.243, score method ->
  # x = 20.005 events (ceiling 21), time = x/r.
  res <- calc_rate_precision(rate = 2.5, conf_width = 2.243, conf_level = 0.95, method = "score")
  expect_equal(res$n_events, 21)
  expect_equal(round(res$person_time, 1), 8.4)
})

test_that("calc_rate_precision rejects invalid inputs", {
  expect_error(calc_rate_precision(rate = -1, conf_width = 1), "positive")
  expect_error(calc_rate_precision(rate = 2.5, conf_width = -1), "positive")
  expect_error(calc_rate_precision(rate = 2.5, conf_width = 20), "should not exceed 5 times")
})

test_that("calc_rate_comparison matches WebPower::wp.poisson()'s own documented example", {
  # WebPower's own doc example: rate_ref=2.798, rate_ratio=0.8938,
  # prop_exposed=0.53, alpha=.05, power=.8 -> n=943.2628 (ceiling 944).
  res <- calc_rate_comparison(rate_ref = 2.798, rate_ratio = 0.8938, prop_exposed = 0.53,
                               alpha = 0.05, power = 0.8)
  expect_equal(res$n_total, 944)
  expect_equal(res$n_exposed, 501)
  expect_equal(res$n_reference, 443)
})

test_that("calc_rate_comparison rejects invalid inputs", {
  expect_error(calc_rate_comparison(rate_ref = -1, rate_ratio = 1.5), "positive")
  expect_error(calc_rate_comparison(rate_ref = 2, rate_ratio = 1), "must differ")
  expect_error(calc_rate_comparison(rate_ref = 2, rate_ratio = 1.5, prop_exposed = 1.5), "between 0 and 1")
})

test_that("calc_poisson_regression_continuous matches powerMediation::sizePoisson()'s own documented example", {
  # powerMediation's own doc example: beta0=0.1, beta1=0.5, mu.x1=0,
  # sigma2.x1=1, mu.T=1, phi=1, alpha=0.05, power=0.8 -> n=28.
  res <- calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0,
                                             sigma2_x1 = 1, mu_T = 1, phi = 1,
                                             alpha = 0.05, power = 0.8)
  expect_equal(res$n_total, 28)
})

test_that("calc_poisson_regression_continuous rejects invalid inputs", {
  expect_error(calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0, mu_x1 = 0, sigma2_x1 = 1), "must differ from 0")
  expect_error(calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0, sigma2_x1 = -1), "positive")
  expect_error(calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0, sigma2_x1 = 1, mu_T = -1), "positive")
  expect_error(calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0, sigma2_x1 = 1, phi = 0.5), ">= 1")
  expect_error(calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0, sigma2_x1 = 1, alpha = 0), "between 0 and 1")
  expect_error(calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0, sigma2_x1 = 1, power = 0), "between 0 and 1")
})
