# Mendelian randomisation with a single instrument (R/calc_mendelian.R; CHECKLIST OBS-15). Checked against Burgess 2014
# (Int J Epidemiol 43:922-929): the "Formula" columns of its validation table (Table 1, 54 values) and the constants of its
# equations 5 and 11.

test_that("binary outcome: power equals all 54 'Formula' values of Burgess 2014, Table 1", {
  # rows: R-squared 0.01, 0.02, 0.03, each with beta1 = 0.1, 0.2, 0.3; columns: 10 000, 20 000, 30 000 cases (percent)
  ratio_1_1 <- matrix(c(10.5, 16.9, 23.1,   29.3, 51.6, 68.8,   56.4, 85.1, 95.7,
                        16.9, 29.3, 41.0,   51.6, 80.7, 93.4,   85.1, 98.9, 99.9,
                        23.1, 41.0, 56.4,   68.8, 93.4, 98.9,   95.7, 99.9, 100.0), ncol = 3, byrow = TRUE)
  ratio_1_2 <- matrix(c(12.6, 21.0, 29.3,   37.2, 63.7, 80.7,   68.8, 93.4, 98.9,
                        21.0, 37.2, 51.6,   63.7, 90.4, 97.9,   93.4, 99.8, 100.0,
                        29.3, 51.6, 68.8,   80.7, 97.9, 99.8,   98.9, 100.0, 100.0), ncol = 3, byrow = TRUE)
  grid <- expand.grid(beta = c(0.1, 0.2, 0.3), r2 = c(0.01, 0.02, 0.03))
  cases <- c(10000, 20000, 30000)
  for (i in seq_len(nrow(grid))) for (j in 1:3) {
    info <- sprintf("beta %.1f, r2 %.2f, %d cases", grid$beta[i], grid$r2[i], cases[j])
    expect_equal(round(100 * calc_mr_binary(exp(grid$beta[i]), grid$r2[i], 1, n_cases = cases[j])$achieved_power, 1),
                 ratio_1_1[i, j], info = paste(info, "1:1"))
    expect_equal(round(100 * calc_mr_binary(exp(grid$beta[i]), grid$r2[i], 2, n_cases = cases[j])$achieved_power, 1),
                 ratio_1_2[i, j], info = paste(info, "1:2"))
  }
})

test_that("sample sizes follow the paper's equations 5 (7.848 / (beta^2 rho^2)) and 11 (31.392 / (beta^2 rho^2))", {
  k <- (qnorm(0.975) + qnorm(0.8))^2              # 7.8489; the paper prints 7.848
  expect_equal(round(k, 2), 7.85)
  for (b in c(0.05, 0.1, 0.2, 0.3)) for (r2 in c(0.005, 0.02, 0.08)) {
    expect_equal(calc_mr_continuous(b, r2)$n, ceiling(k / (b^2 * r2)))
    res <- calc_mr_binary(exp(b), r2)
    expect_equal(res$n_cases, ceiling(4 * k / (b^2 * r2) / 2))
    expect_equal(res$n_total, 2 * res$n_cases)
    expect_gte(res$achieved_power, 0.8)
    expect_gte(calc_mr_continuous(b, r2)$achieved_power, 0.8)
  }
  # a binary outcome needs more people than a continuous one for the same effect size and instrument (the paper's key message)
  expect_gt(calc_mr_binary(exp(0.2), 0.02)$n_total, calc_mr_continuous(0.2, 0.02)$n)
})

test_that("power at a given sample size is the inverse of the sample size, and the direction of the effect does not matter", {
  n <- calc_mr_continuous(0.15, 0.03, power = 0.9)$n
  expect_gte(calc_mr_continuous(0.15, 0.03, n = n)$achieved_power, 0.9)
  expect_lt(calc_mr_continuous(0.15, 0.03, n = n - 1)$achieved_power, 0.9)
  expect_equal(calc_mr_continuous(-0.15, 0.03, power = 0.9)$n, n)
  b <- calc_mr_binary(1.3, 0.02, controls_per_case = 3, power = 0.9)
  expect_equal(b$n_controls, 3 * b$n_cases)
  expect_gte(b$achieved_power, 0.9)
  expect_lt(calc_mr_binary(1.3, 0.02, 3, n_cases = b$n_cases - 1)$achieved_power, 0.9)
  expect_equal(calc_mr_binary(1 / 1.3, 0.02, 3, power = 0.9)$n_cases, b$n_cases)
  # for a fixed total, equal numbers of cases and controls give the most power (30 000 cases 1:1 vs 20 000 cases 1:2)
  expect_gt(calc_mr_binary(exp(0.1), 0.01, 1, n_cases = 30000)$achieved_power,
            calc_mr_binary(exp(0.1), 0.01, 2, n_cases = 20000)$achieved_power)
  # the power tends to alpha / 2 as the information tends to zero
  expect_equal(calc_mr_continuous(0.0001, 0.001, n = 3)$achieved_power, 0.025, tolerance = 1e-3)
})

test_that("the documented worked examples are what the functions return", {
  expect_equal(calc_mr_continuous(0.2, 0.02)$n, 9812)
  expect_equal(round(calc_mr_continuous(0.2, 0.02, n = 5000)$achieved_power, 3), 0.516)
  b <- calc_mr_binary(exp(0.2), 0.02)
  expect_equal(c(b$n_cases, b$n_controls, b$n_total), c(19623, 19623, 39246))
  b <- calc_mr_binary(1.5, 0.03, controls_per_case = 2)
  expect_equal(c(b$n_cases, b$n_controls, b$n_total), c(2388, 4776, 7164))
})

test_that("invalid inputs are rejected", {
  expect_error(calc_mr_continuous(0, 0.02), "differ from 0")
  expect_error(calc_mr_continuous(0.2, 0), "r2")
  expect_error(calc_mr_continuous(0.2, 1), "r2")
  expect_error(calc_mr_continuous(0.2, 0.02, n = 2), "at least 3")
  expect_error(calc_mr_binary(1, 0.02), "differ from 1")
  expect_error(calc_mr_binary(-1, 0.02), "or")
  expect_error(calc_mr_binary(1.2, 0.02, controls_per_case = 0), "controls_per_case")
  expect_error(calc_mr_binary(1.2, 0.02, alpha = 1.2), "alpha")
})
