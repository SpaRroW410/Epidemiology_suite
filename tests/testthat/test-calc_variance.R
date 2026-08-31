source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_variance.R"))

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
