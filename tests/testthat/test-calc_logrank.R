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

test_that("calc_cox_binary matches Latouche et al (2004) Section 5.2 exactly", {
  # power=0.80, theta=2, p=0.39, psi=0.505, rho2=0.132^2 -> n=139.
  res <- calc_cox_binary(power = 0.80, theta = 2, p = 0.39, psi = 0.505, rho2 = 0.132^2)
  expect_equal(res$n, 139)
})

test_that("calc_cox_binary rejects invalid inputs", {
  expect_error(calc_cox_binary(power = 0.8, theta = 1, p = 0.39, psi = 0.505), "must differ")
  expect_error(calc_cox_binary(power = 0.8, theta = 2, p = 1.5, psi = 0.505), "between 0 and 1")
  expect_error(calc_cox_binary(power = 0.8, theta = 2, p = 0.39, psi = 0.505, rho2 = 1), "\\[0, 1\\)")
})

test_that("calc_cox_continuous matches Hsieh & Lavori (2000) worked example exactly", {
  # power=0.806, theta=exp(1), sigma2=0.3126^2, psi=0.738, rho2=0.1837, alpha=0.1
  # (two-sided alpha=0.1 corresponds to their one-sided alpha=0.05) -> n=107.
  res <- calc_cox_continuous(power = 0.806, theta = exp(1), sigma2 = 0.3126^2,
                              psi = 0.738, rho2 = 0.1837, alpha = 0.1)
  expect_equal(res$n, 107)
})

test_that("calc_cox_continuous rejects invalid inputs", {
  expect_error(calc_cox_continuous(power = 0.8, theta = 1, sigma2 = 0.1, psi = 0.5), "must differ")
  expect_error(calc_cox_continuous(power = 0.8, theta = 2, sigma2 = -1, psi = 0.5), "positive")
  expect_error(calc_cox_continuous(power = 0.8, theta = 2, sigma2 = 0.1, psi = 0.5, rho2 = 1), "\\[0, 1\\)")
})
