source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_means.R"))

test_that("calc_means_1s matches Cohen (1988) published one-sample t-test tables", {
  # Cohen (1988): one-sample t-test, alpha = .05 two-tailed, power = .80,
  # medium conventional effect size d = 0.5, gives n = 34.
  res <- calc_means_1s(mu0 = 0, mu1 = 0.5, sd = 1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 0.5)
  expect_equal(res$n, 34)
})

test_that("calc_means_1s: worked example from content_means.R", {
  res <- calc_means_1s(mu0 = 120, mu1 = 125, sd = 15, alpha = 0.05, power = 0.8)
  expect_equal(res$n, 73)
  expect_equal(round(res$d, 4), 0.3333)
})

test_that("calc_means_1s rejects invalid inputs", {
  expect_error(calc_means_1s(mu0 = 120, mu1 = 120, sd = 15), "must differ")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = 0), "positive")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = -1), "positive")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = 15, alpha = 1.5), "between 0 and 1")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = 15, power = 0), "between 0 and 1")
})

test_that("calc_means_2s_indep matches Cohen (1988) published two-sample t-test tables", {
  # Cohen (1988): two-sample t-test, alpha = .05 two-tailed, power = .80,
  # medium conventional effect size d = 0.5, gives n = 64 per group.
  res <- calc_means_2s_indep(mu1 = 0.5, mu2 = 0, sd = 1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 0.5)
  expect_equal(res$n_per_group, 64)
  expect_equal(res$n_total, 128)
})

test_that("calc_means_2s_indep: worked example from content_means.R", {
  res <- calc_means_2s_indep(mu1 = 12.5, mu2 = 11.5, sd = 2, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_group, 64)
  expect_equal(res$n_total, 128)
  expect_equal(round(res$d, 4), 0.5)
})

test_that("calc_means_2s_indep rejects invalid inputs", {
  expect_error(calc_means_2s_indep(mu1 = 10, mu2 = 10, sd = 2), "must differ")
  expect_error(calc_means_2s_indep(mu1 = 10, mu2 = 8, sd = 0), "positive")
  expect_error(calc_means_2s_indep(mu1 = 10, mu2 = 8, sd = 2, alpha = 0), "between 0 and 1")
})

test_that("calc_means_paired matches Cohen (1988) published paired t-test tables", {
  # Cohen (1988): paired t-test, alpha = .05 two-tailed, power = .80,
  # medium conventional effect size d = 0.5, gives n = 34 pairs.
  res <- calc_means_paired(mean_diff = 0.5, sd_diff = 1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 0.5)
  expect_equal(res$n, 34)
})

test_that("calc_means_paired: worked example from content_means.R", {
  res <- calc_means_paired(mean_diff = 2, sd_diff = 5, alpha = 0.05, power = 0.8)
  expect_equal(res$n, 52)
  expect_equal(round(res$d, 4), 0.4)
})

test_that("calc_means_paired rejects invalid inputs", {
  expect_error(calc_means_paired(mean_diff = 0, sd_diff = 5), "must not be zero")
  expect_error(calc_means_paired(mean_diff = 2, sd_diff = 0), "positive")
  expect_error(calc_means_paired(mean_diff = 2, sd_diff = 5, power = 1), "between 0 and 1")
})
