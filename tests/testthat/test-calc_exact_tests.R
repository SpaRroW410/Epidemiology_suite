source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_exact_tests.R"))

test_that("calc_fisher_exact finds the first stable n1 crossing the target power", {
  # p1=0.15, p2=0.60, ratio=2, alpha=.05, power=.8, two-sided. Power is
  # non-monotonic in n1 (Chernick & Liu 2002); n1=14 is the first n1 where
  # power stays >= 0.8 for n1, n1+1, n1+2.
  res <- calc_fisher_exact(p1 = 0.15, p2 = 0.60, alpha = 0.05, power = 0.8, ratio = 2)
  expect_equal(res$n1, 14)
  expect_equal(res$n2, 28)
  expect_equal(res$n_total, 42)
  expect_gte(res$achieved_power, 0.8)
})

test_that("Exact::power.exact.test backend reproduces the package's own documented example exactly", {
  # Exact's own doc example: p1=0.15, p2=0.60, n1=15, n2=30, method="fisher"
  # -> power = 0.8049468.
  fit <- Exact::power.exact.test(p1 = 0.15, p2 = 0.60, n1 = 15, n2 = 30, method = "fisher")
  expect_equal(round(fit$power, 7), 0.8049468)
})

test_that("calc_fisher_exact rejects invalid inputs", {
  expect_error(calc_fisher_exact(p1 = 0.5, p2 = 0.5), "must differ")
  expect_error(calc_fisher_exact(p1 = 0.15, p2 = 0.60, ratio = -1), "positive")
})

test_that("calc_binomial_exact finds the first stable n crossing the target power", {
  # p0=0.1, p1=0.3, alpha=.05, power=.8, two-sided -> n=25 is the first n
  # where achieved exact power stays >= 0.8 for n, n+1, n+2.
  res <- calc_binomial_exact(p0 = 0.1, p1 = 0.3, alpha = 0.05, power = 0.8)
  expect_equal(res$n, 25)
  expect_equal(round(res$achieved_power, 4), 0.8065)
})

test_that("calc_binomial_exact rejects invalid inputs", {
  expect_error(calc_binomial_exact(p0 = 0.3, p1 = 0.3), "must differ")
  expect_error(calc_binomial_exact(p0 = 1.5, p1 = 0.3), "between 0 and 1")
})

test_that("calc_boschloo_exact finds a smaller (or equal) n1 than Fisher's exact test on the same inputs", {
  # Boschloo's test is uniformly at least as powerful as Fisher's exact
  # test (Boschloo 1970), so for identical p1/p2/alpha/power it should
  # never need a larger n1: p1=0.30, p2=0.60, alpha=0.05, power=0.80 ->
  # boschloo n1=44 (88 total), vs. fisher n1=48 (96 total).
  res_boschloo <- calc_boschloo_exact(p1 = 0.30, p2 = 0.60, alpha = 0.05, power = 0.8)
  res_fisher <- calc_fisher_exact(p1 = 0.30, p2 = 0.60, alpha = 0.05, power = 0.8)
  expect_equal(res_boschloo$n1, 44)
  expect_equal(res_boschloo$n_total, 88)
  expect_lte(res_boschloo$n1, res_fisher$n1)
  expect_gte(res_boschloo$achieved_power, 0.8)
})

test_that("calc_boschloo_exact rejects invalid inputs", {
  expect_error(calc_boschloo_exact(p1 = 0.5, p2 = 0.5), "must differ")
  expect_error(calc_boschloo_exact(p1 = 0.30, p2 = 0.60, ratio = -1), "positive")
  expect_error(calc_boschloo_exact(p1 = 1.5, p2 = 0.60), "between 0 and 1")
})

test_that("calc_poisson_exact finds the first stable person-time crossing the target power", {
  # rate0=5, rate1=10, alpha=0.05, power=0.8, two-sided -> T=3 is the first
  # person-time where achieved exact power stays >= 0.8 for T, T+1, T+2;
  # independently cross-checked by a 20,000-replicate Monte Carlo
  # simulation (empirical power 0.8835, matching the exact 0.8854).
  res <- calc_poisson_exact(rate0 = 5, rate1 = 10, alpha = 0.05, power = 0.8)
  expect_equal(res$person_time, 3)
  expect_equal(res$expected_events, 30)
  expect_equal(round(res$achieved_power, 4), 0.8854)
})

test_that("calc_poisson_exact rejects invalid inputs", {
  expect_error(calc_poisson_exact(rate0 = 5, rate1 = 5), "must differ")
  expect_error(calc_poisson_exact(rate0 = -1, rate1 = 5), "positive")
  expect_error(calc_poisson_exact(rate0 = 5, rate1 = 10, alpha = 0), "between 0 and 1")
})

test_that("calc_sign_test matches calc_binomial_exact(p0 = 0.5) exactly", {
  # The sign test is exactly a binomial test against 0.5 -- verify the thin
  # wrapper reproduces calc_binomial_exact()'s own result bit-for-bit for
  # the same p_pos, and returns its own (not the internal p0/p1) inputs.
  wrapped <- calc_sign_test(p_pos = 0.7, alpha = 0.05, power = 0.8)
  direct <- calc_binomial_exact(p0 = 0.5, p1 = 0.7, alpha = 0.05, power = 0.8)
  expect_equal(wrapped$n, direct$n)
  expect_equal(wrapped$achieved_power, direct$achieved_power)
  expect_equal(wrapped$inputs, list(p_pos = 0.7, alpha = 0.05, power = 0.8, alternative = "two.sided"))
  expect_equal(wrapped$n, 54)
})

test_that("calc_sign_test rejects invalid inputs", {
  expect_error(calc_sign_test(p_pos = 0.5), "must differ from 0.5")
  expect_error(calc_sign_test(p_pos = 1.5), "between 0 and 1")
})
