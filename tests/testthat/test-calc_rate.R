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

test_that("calc_negative_binomial_rates matches MKpower::power.nb.test()'s own documented example exactly", {
  # MKpower isn't installable from CRAN in this sandbox (no network
  # access); power.nb.test()'s source -- a single, self-contained
  # closed-form function (Zhu & Lakkis 2014) -- was read directly from
  # its public GitHub CRAN mirror and transcribed. Its own man-page
  # \examples{} include this exact scenario (mu0=10, RR=1.5, theta=1/5,
  # duration=1, ssize.ratio=3/2, power=0.8, approach=3), for which the
  # transcribed formula gives n0=404.2/n1=606.3 (this calculator's
  # ceiling() convention: 405/607). Independently verified two ways by
  # Monte Carlo before wiring into the app: (1) reproducing the paper's
  # own test statistic on simulated MASS::rnegbin() data at this n gives
  # empirical power 0.814; (2) a genuinely different check -- fitting
  # MASS::glm.nb() (which ESTIMATES the dispersion from data, unlike the
  # design formula which assumes it known) on the same simulated data and
  # using its own Wald test -- gives empirical power 0.797. Both closely
  # bracket the formula's 0.8 target.
  res <- calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = 1 / 5, duration = 1,
                                       ssize_ratio = 3 / 2, power = 0.8, approach = 3)
  expect_equal(res$n0, 405)
  expect_equal(res$n1, 607)

  # Table I (row 1) example: mu0=0.8, RR=0.85, theta=1/0.4, duration=0.75,
  # power=0.8, equal allocation -- verified for all three approaches.
  res1 <- calc_negative_binomial_rates(mu0 = 0.8, RR = 0.85, theta = 1 / 0.4, duration = 0.75,
                                        power = 0.8, approach = 1)
  res2 <- calc_negative_binomial_rates(mu0 = 0.8, RR = 0.85, theta = 1 / 0.4, duration = 0.75,
                                        power = 0.8, approach = 2)
  res3 <- calc_negative_binomial_rates(mu0 = 0.8, RR = 0.85, theta = 1 / 0.4, duration = 0.75,
                                        power = 0.8, approach = 3)
  expect_equal(res1$n0, 1255)
  expect_equal(res2$n0, 1316)
  expect_equal(res3$n0, 1311)
})

test_that("calc_negative_binomial_rates needs a larger sample size for a higher target power", {
  res_low <- calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = 1 / 5, power = 0.7)
  res_high <- calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = 1 / 5, power = 0.9)
  expect_lt(res_low$n_total, res_high$n_total)
})

test_that("calc_negative_binomial_rates rejects invalid inputs", {
  expect_error(calc_negative_binomial_rates(mu0 = -1, RR = 1.5, theta = 1), "positive")
  expect_error(calc_negative_binomial_rates(mu0 = 10, RR = 1, theta = 1), "must differ from 1")
  expect_error(calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = -1), "positive")
  expect_error(calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = 1, approach = 4), "approach must be")
  expect_error(calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = 1, alternative = "bad"), "two.sided")
})
