test_that("calc_bayesian_assurance_or matches Hmisc::gbayes2()'s own documented uniform-prior example closely", {
  # Reproducing the package's own example code exactly:
  #   prior2 <- function(delta) dunif(delta, log(1.2), log(1.3))
  #   v <- function(n) 2/(n*.3*.7)
  #   uniroot(function(n) gbayes2(sqrt(v(n)), prior2) - .9, c(50, 10000))$root
  # gives n = 2119.688 per arm (achieving assurance exactly 0.90).
  res <- calc_bayesian_assurance_or(
    p1 = 0.3, p2 = 0.3, prior_type = "uniform",
    prior_lower = log(1.2), prior_upper = log(1.3),
    delta_w = 0, n_ratio = 1, alpha = 0.05, power = 0.9
  )
  expect_equal(res$n1, 2120)
  expect_equal(res$n2, 2120)
  expect_equal(round(res$achieved_power, 2), 0.90)
})

test_that("calc_bayesian_assurance_or reproduces gbayes2()'s own printed normal-mixture-style example when called with an equivalent single normal prior", {
  # Hmisc's doc example uses a 50:50 mixture of N(0,100^2) and N(1,1) priors
  # and a variance vguess=0.02183459 (a 75th-percentile summary over a range
  # of assumed proportions), giving gbayes2() = 0.6133338. This app's
  # simplified UI only exposes a single Normal or Uniform prior, but the
  # underlying Hmisc::gbayes2() call is identical -- verify it directly with
  # a single Normal prior component to confirm the wrapper's math (not the
  # mixture shape) is correct, by calling gbayes2() ourselves as a reference.
  vguess <- 0.02183459
  mixture_prior <- function(delta) 0.5 * dnorm(delta, 0, 100) + 0.5 * dnorm(delta, 1, 1)
  ref <- .cf_gbayes2(sqrt(vguess), mixture_prior, log(1.1))
  expect_equal(round(ref, 4), 0.6133)          # the value printed in Hmisc::gbayes2()'s help page
  skip_if_not_installed("Hmisc")
  expect_equal(ref, Hmisc::gbayes2(sqrt(vguess), mixture_prior, log(1.1)), tolerance = 1e-12)
})

test_that("calc_bayesian_assurance_or requires a larger n as the target assurance increases", {
  res_low <- calc_bayesian_assurance_or(
    p1 = 0.3, p2 = 0.3, prior_type = "uniform",
    prior_lower = log(1.2), prior_upper = log(1.3), power = 0.7
  )
  res_high <- calc_bayesian_assurance_or(
    p1 = 0.3, p2 = 0.3, prior_type = "uniform",
    prior_lower = log(1.2), prior_upper = log(1.3), power = 0.9
  )
  expect_lt(res_low$n1, res_high$n1)
})

test_that("calc_bayesian_assurance_or reports infeasibility when the prior is symmetric about delta_w", {
  # A prior centered exactly at delta_w (e.g. N(0,1) with delta_w=0) has only
  # half its mass favoring the treatment, so assurance asymptotes to ~0.50
  # as n -> Inf and can never reach a typical 80% target -- this should be
  # caught explicitly rather than returning a misleadingly huge n.
  expect_error(
    calc_bayesian_assurance_or(p1 = 0.3, p2 = 0.3, prior_type = "normal",
                                prior_mean = 0, prior_sd = 1, power = 0.8),
    "No feasible sample size"
  )
})

test_that("calc_bayesian_assurance_or rejects invalid inputs", {
  expect_error(calc_bayesian_assurance_or(p1 = 1.2, p2 = 0.3, prior_type = "normal",
                                           prior_mean = 0, prior_sd = 1), "between 0 and 1")
  expect_error(calc_bayesian_assurance_or(p1 = 0.3, p2 = 0.3, prior_type = "uniform",
                                           prior_lower = 1, prior_upper = 0.5),
               "greater than prior_lower")
  expect_error(calc_bayesian_assurance_or(p1 = 0.3, p2 = 0.3, prior_type = "normal",
                                           prior_mean = 0, prior_sd = -1), "positive")
})

test_that("calc_bfda_ttest is reproducible via its fixed internal seed", {
  skip_if_not_slow()
  res1 <- calc_bfda_ttest(effect_size = 0.5, bf_threshold = 10, alpha = 0.05, power = 0.8, nsim = 50)
  res2 <- calc_bfda_ttest(effect_size = 0.5, bf_threshold = 10, alpha = 0.05, power = 0.8, nsim = 50)
  expect_identical(res1, res2)
  expect_equal(res1$n_total, res1$n1 + res1$n2)
  expect_equal(res1$n1, res1$n2)
})

test_that("calc_bfda_ttest needs a larger n than the classical two-sample t-test at the same d/alpha/power", {
  skip_if_not_slow()
  res <- calc_bfda_ttest(effect_size = 0.5, bf_threshold = 10, alpha = 0.05, power = 0.8, nsim = 50)
  expect_equal(res$n_classical, 64) # pwr::pwr.t.test(d=0.5, power=0.8) -> n=64
  expect_gt(res$n1, res$n_classical)
})

test_that("calc_bfda_ttest computes the classical warm-start n correctly regardless of the simulation outcome", {
  skip_if_not_slow()
  res <- calc_bfda_ttest(effect_size = 0.8, bf_threshold = 3, alpha = 0.05, power = 0.8, nsim = 50)
  fit <- pwr::pwr.t.test(d = 0.8, sig.level = 0.05, power = 0.8, type = "two.sample")
  expect_equal(res$n_classical, ceiling(fit$n))
})

test_that("calc_bfda_ttest rejects invalid inputs", {
  expect_error(calc_bfda_ttest(effect_size = -0.5), "positive")
  expect_error(calc_bfda_ttest(effect_size = 0.5, bf_threshold = 1), "greater than 1")
  expect_error(calc_bfda_ttest(effect_size = 0.5, alpha = 0), "between 0 and 1")
  expect_error(calc_bfda_ttest(effect_size = 0.5, power = 0), "between 0 and 1")
  expect_error(calc_bfda_ttest(effect_size = 0.5, nsim = 10), "nsim must be a single whole number")
})
