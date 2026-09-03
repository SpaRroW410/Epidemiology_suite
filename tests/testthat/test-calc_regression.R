source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_regression.R"))

test_that("calc_regression_f2: r2=0.1, 5 predictors, alpha=.05, power=.8 -> n=122", {
  res <- calc_regression_f2(r2 = 0.1, num_predictors = 5, alpha = 0.05, power = 0.8)
  expect_equal(round(res$f2, 4), 0.1111)
  expect_equal(res$n, 122)
})

test_that("pwr::pwr.f2.test backend reproduces Cohen (1988) Exercise 9.1, p.424 exactly", {
  # u=5, v=89, f2=0.1/(1-0.1) -> power = 0.6735858.
  fit <- pwr::pwr.f2.test(u = 5, v = 89, f2 = 0.1 / (1 - 0.1), sig.level = 0.05)
  expect_equal(round(fit$power, 7), 0.6735858)
})

test_that("calc_regression_f2 rejects invalid inputs", {
  expect_error(calc_regression_f2(r2 = 1.5, num_predictors = 5), "between 0 and 1")
  expect_error(calc_regression_f2(r2 = 0.1, num_predictors = 0), ">= 1")
  expect_error(calc_regression_f2(r2 = 0.1, num_predictors = 2.5), ">= 1")
})

test_that("calc_regression_r2_increase: r2_reduced=.30, r2_full=.40, 2 of 5 predictors added -> n=64", {
  res <- calc_regression_r2_increase(r2_reduced = 0.30, r2_full = 0.40,
                                      num_predictors_added = 2, num_predictors_total = 5,
                                      alpha = 0.05, power = 0.8)
  expect_equal(round(res$f2, 4), 0.1667)
  expect_equal(res$v, 58)
  expect_equal(res$n, 64)
})

test_that("pwr::pwr.f2.test backend achieves ~0.80 power at the worked-example n", {
  fit <- pwr::pwr.f2.test(u = 2, v = 58, f2 = (0.40 - 0.30) / (1 - 0.40), sig.level = 0.05)
  expect_equal(round(fit$power, 4), 0.8007)
})

test_that("calc_regression_r2_increase rejects invalid inputs", {
  expect_error(calc_regression_r2_increase(1.1, 0.4, 2, 5), "between 0 and 1")
  expect_error(calc_regression_r2_increase(0.3, 1.1, 2, 5), "between 0 and 1")
  expect_error(calc_regression_r2_increase(0.4, 0.3, 2, 5), "greater than r2_reduced")
  expect_error(calc_regression_r2_increase(0.3, 0.4, 0, 5), ">= 1")
  expect_error(calc_regression_r2_increase(0.3, 0.4, 2.5, 5), ">= 1")
  expect_error(calc_regression_r2_increase(0.3, 0.4, 5, 5), "greater than num_predictors_added")
  expect_error(calc_regression_r2_increase(0.3, 0.4, 2, 5, alpha = 1.1), "between 0 and 1")
  expect_error(calc_regression_r2_increase(0.3, 0.4, 2, 5, power = 1.1), "between 0 and 1")
})
