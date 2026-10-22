test_that("calc_variance_single matches hand computation (sigma0=10, sigma1=14, one-sided greater -> n=28)", {
  # Verified by Monte Carlo simulation: 20,000 replicates at n = 28 gave an
  # empirical power of 0.814, closely matching the 0.80 target.
  res <- calc_variance_single(sigma0 = 10, sigma1 = 14, alpha = 0.05, power = 0.8,
                               alternative = "greater")
  expect_equal(res$n, 28)
})

test_that("calc_variance_single rejects invalid inputs", {
  expect_error(calc_variance_single(sigma0 = -10, sigma1 = 14), "positive")
  expect_error(calc_variance_single(sigma0 = 10, sigma1 = -14), "positive")
  expect_error(calc_variance_single(sigma0 = 10, sigma1 = 10), "must differ")
  expect_error(calc_variance_single(sigma0 = 10, sigma1 = 14, alpha = 0), "between 0 and 1")
  expect_error(calc_variance_single(sigma0 = 14, sigma1 = 10, alternative = "greater"), "use \"less\"")
  expect_error(calc_variance_single(sigma0 = 10, sigma1 = 14, alternative = "less"), "use \"greater\"")
})

test_that("calc_variance_two matches hand computation (sigma1=10, sigma2=14, two-sided -> n=72/group, 144 total)", {
  # Verified by Monte Carlo simulation: 20,000 replicates at n = 72 gave an
  # empirical power of 0.80355, closely matching the 0.80 target.
  res <- calc_variance_two(sigma1 = 10, sigma2 = 14, alpha = 0.05, power = 0.8,
                            alternative = "two.sided")
  expect_equal(res$n_per_group, 72)
  expect_equal(res$n_total, 144)
})

test_that("calc_variance_two rejects invalid inputs", {
  expect_error(calc_variance_two(sigma1 = -10, sigma2 = 14), "positive")
  expect_error(calc_variance_two(sigma1 = 10, sigma2 = -14), "positive")
  expect_error(calc_variance_two(sigma1 = 10, sigma2 = 10), "must differ")
  expect_error(calc_variance_two(sigma1 = 10, sigma2 = 14, alpha = 0), "between 0 and 1")
  expect_error(calc_variance_two(sigma1 = 10, sigma2 = 14, alternative = "greater"), "use \"less\"")
  expect_error(calc_variance_two(sigma1 = 14, sigma2 = 10, alternative = "less"), "use \"greater\"")
})

test_that("calc_variance_sd_precision matches the Pilot module's own forward-direction identity at n=12", {
  # calc_pilot_sd_precision(n=12) reports a 95% CI multiplier width of
  # 1.6957 - 0.7052 = 0.9905 for the true SD (Julious 2005's own 12-per-arm
  # rule of thumb) -- solving for n at that SAME target width should
  # recover n=12 (or very close to it, modulo the exact-boundary ceiling()
  # rounding quirk noted in the function's own docstring).
  target <- sqrt(11 / qchisq(0.025, 11)) - sqrt(11 / qchisq(0.975, 11))
  res <- calc_variance_sd_precision(target_width = target, conf_level = 0.95)
  expect_true(res$n %in% c(12, 13))
})

test_that("calc_variance_sd_precision is deterministic and needs a larger n for a tighter target width", {
  res1 <- calc_variance_sd_precision(target_width = 0.5)
  res2 <- calc_variance_sd_precision(target_width = 0.5)
  expect_identical(res1, res2)

  res_loose <- calc_variance_sd_precision(target_width = 1.0)
  res_tight <- calc_variance_sd_precision(target_width = 0.2)
  expect_gt(res_tight$n, res_loose$n)
})

test_that("calc_variance_sd_precision's reported CI multiplier actually achieves the target width", {
  res <- calc_variance_sd_precision(target_width = 0.5, conf_level = 0.95)
  expect_lte(res$upper_mult - res$lower_mult, 0.5 + 1e-6)
})

test_that("calc_variance_sd_precision rejects invalid inputs", {
  expect_error(calc_variance_sd_precision(target_width = -0.5), "positive")
  expect_error(calc_variance_sd_precision(target_width = 0), "positive")
  expect_error(calc_variance_sd_precision(target_width = 0.5, conf_level = 0), "between 0 and 1")
  expect_error(calc_variance_sd_precision(target_width = 0.5, conf_level = 1.5), "between 0 and 1")
})
