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
