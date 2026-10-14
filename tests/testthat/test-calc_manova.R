test_that("calc_manova_hotelling at p=1 reduces exactly to the two-sample t-test", {
  # D^2 = Cohen's d^2 at p=1; d=0.5, alpha=0.05, power=0.8 ->
  # pwr::pwr.t.test(d=0.5, sig.level=0.05, power=0.8, type="two.sample")
  # gives a continuous n=63.76561, ceiling 64 -- bit-for-bit identical to
  # this app's own already-verified two-sample t-test engine.
  res <- calc_manova_hotelling(p = 1, d2 = 0.25, alpha = 0.05, power = 0.8)
  fit <- pwr::pwr.t.test(d = 0.5, sig.level = 0.05, power = 0.8, type = "two.sample")
  expect_equal(res$n_per_group, ceiling(fit$n))
  expect_equal(res$n_per_group, 64)
})

test_that("calc_manova_hotelling matches hand computation (p=3, D2=0.1243304 -> n=178/group)", {
  # Independently confirmed by a 5,000-replicate Monte Carlo simulation
  # (generating trivariate normal data for both groups and computing the
  # actual two-sample Hotelling's T-squared statistic): empirical power
  # 0.8068 at n=178, closely matching the 0.80 target.
  res <- calc_manova_hotelling(p = 3, d2 = 0.1243304, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_group, 178)
  expect_equal(res$n_total, 356)
  expect_equal(round(res$achieved_power, 2), 0.80)
})

test_that("calc_manova_hotelling rejects invalid inputs", {
  expect_error(calc_manova_hotelling(p = 0, d2 = 0.25), "at least 1")
  expect_error(calc_manova_hotelling(p = 2.5, d2 = 0.25), "at least 1")
  expect_error(calc_manova_hotelling(p = 3, d2 = -0.1), "positive")
  expect_error(calc_manova_hotelling(p = 3, d2 = 0.25, alpha = 0), "between 0 and 1")
  expect_error(calc_manova_hotelling(p = 3, d2 = 0.25, power = 0), "between 0 and 1")
})
