source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_lan_demets.R"))

test_that("calc_lan_demets_normal OF boundaries match real rpact::getDesignGroupSequential() (alpha=0.025 one-sided, timing=0.5)", {
  # Verified exactly against rpact::getDesignGroupSequential(kMax=2,
  # alpha=0.025, sided=1, typeOfDesign="asOF", informationRates=c(0.5,1)):
  # criticalValues = 2.962588, 1.968596.
  res <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, r = 1,
                                 alpha = 0.05, power = 0.8, spending = "OF")
  expect_equal(round(res$boundary_interim, 4), 2.9626)
  expect_equal(round(res$boundary_final, 3), 1.969)
  expect_equal(round(res$alpha_spent[1], 6), 0.001525)
  expect_equal(round(res$alpha_spent[2], 3), 0.025)
})

test_that("calc_lan_demets_normal Pocock boundaries match real rpact (typeOfDesign='asP')", {
  # Verified against rpact::getDesignGroupSequential(kMax=2, alpha=0.025,
  # sided=1, typeOfDesign="asP", informationRates=c(0.5,1)):
  # criticalValues = 2.156999, 2.200977.
  res <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, r = 1,
                                 alpha = 0.05, power = 0.8, spending = "Pocock")
  expect_equal(round(res$boundary_interim, 3), 2.157)
  expect_equal(round(res$boundary_final, 2), 2.20)
})

test_that("calc_lan_demets_normal gives a realistic, small OF inflation factor (n1=64/arm, n_total=128)", {
  res <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, r = 1,
                                 alpha = 0.05, power = 0.8, spending = "OF")
  expect_equal(res$n_total, 128)
  expect_equal(res$n_control, 64)
  expect_equal(res$n_experimental, 64)
  # OF inflation should be small (a few percent), not the ~2x a units error
  # would produce.
  expect_true(res$inflation_factor > 1 && res$inflation_factor < 1.1)
})

test_that("calc_lan_demets_normal Pocock inflation factor is larger than OF's, as expected", {
  res_of <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, alpha = 0.05,
                                    power = 0.8, spending = "OF")
  res_p <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, alpha = 0.05,
                                   power = 0.8, spending = "Pocock")
  expect_true(res_p$inflation_factor > res_of$inflation_factor)
  expect_true(res_p$inflation_factor < 1.2)
})

test_that("calc_lan_demets_normal achieves at least the target power via Monte Carlo simulation of the actual two-stage test", {
  res <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, r = 1,
                                 alpha = 0.05, power = 0.8, spending = "OF")
  set.seed(20260918)
  n_per_arm <- res$n_control
  n1_per_arm <- round(n_per_arm * 0.5)
  nsim <- 20000
  x_ctrl <- matrix(rnorm(n_per_arm * nsim, mean = 0, sd = 1), nrow = nsim, ncol = n_per_arm)
  x_trt <- matrix(rnorm(n_per_arm * nsim, mean = 0.5, sd = 1), nrow = nsim, ncol = n_per_arm)
  z1 <- (rowMeans(x_trt[, 1:n1_per_arm, drop = FALSE]) - rowMeans(x_ctrl[, 1:n1_per_arm, drop = FALSE])) /
    (1 * sqrt(2 / n1_per_arm))
  z2 <- (rowMeans(x_trt) - rowMeans(x_ctrl)) / (1 * sqrt(2 / n_per_arm))
  empirical_power <- mean(z1 > res$boundary_interim | (z1 <= res$boundary_interim & z2 > res$boundary_final))
  expect_true(abs(empirical_power - 0.8) < 0.02)
})

test_that("calc_lan_demets_normal rejects invalid inputs", {
  expect_error(calc_lan_demets_normal(delta = 0, sd = 1), "differ from 0")
  expect_error(calc_lan_demets_normal(delta = 0.5, sd = -1), "positive")
  expect_error(calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0), "between 0 and 1")
  expect_error(calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 1), "between 0 and 1")
  expect_error(calc_lan_demets_normal(delta = 0.5, sd = 1, alpha = 0), "between 0 and 1")
})
