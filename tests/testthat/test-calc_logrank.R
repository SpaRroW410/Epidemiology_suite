source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_logrank.R"))

test_that("calc_logrank matches Rosner (2006) Example 14.42 exactly", {
  # pE = 0.3707, pC = 0.4890, HR = 0.7, ratio = 1, alpha = 0.05, power = 0.80
  # -> nE = nC = 294 (the textbook's own published answer).
  res <- calc_logrank(pE = 0.3707, pC = 0.4890, hr = 0.7, ratio = 1,
                       alpha = 0.05, power = 0.80)
  expect_equal(res$n_exp, 294)
  expect_equal(res$n_control, 294)
  expect_equal(res$n_total, 588)
})

test_that("calc_logrank rejects invalid inputs", {
  expect_error(calc_logrank(pE = 0.3, pC = 0.3, hr = 1), "must differ")
  expect_error(calc_logrank(pE = 0, pC = 0.3, hr = 0.7), "between 0 and 1")
  expect_error(calc_logrank(pE = 0.3, pC = 0.4, hr = -1), "positive")
})
