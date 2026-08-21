source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_correlation.R"))

test_that("calc_correlation matches Cohen (1988)'s classic medium-effect example", {
  # r = 0.3, alpha = 0.05 two-sided, power = 0.80 -> n = 85, one of the most
  # frequently quoted sample-size figures in the literature.
  res <- calc_correlation(r = 0.3, alpha = 0.05, power = 0.8, alternative = "two.sided")
  expect_equal(res$n, 85)
})

test_that("calc_correlation rejects invalid inputs", {
  expect_error(calc_correlation(r = 0), "must not be zero")
  expect_error(calc_correlation(r = 1), "between -1 and 1")
  expect_error(calc_correlation(r = -1), "between -1 and 1")
  expect_error(calc_correlation(r = 0.3, alpha = 0), "between 0 and 1")
})
