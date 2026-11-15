# Interrupted time series, segmented regression with AR(1) errors (R/calc_its.R; CHECKLIST OBS-12).

test_that("with independent errors the variance is that of ordinary least squares, and the power that of its t-test", {
  X <- .its_design(20, 25, TRUE, TRUE, "level")
  expect_equal(.its_gls_var(X, 0, 2), 4 * solve(crossprod(X)), ignore_attr = TRUE)
  r <- calc_its_power(20, 25, effect = 3, effect_type = "level", sd = 2, rho = 0)
  se <- sqrt((4 * solve(crossprod(X)))["level", "level"])
  expect_equal(r$se, se)
  expect_equal(r$df, 45 - 4)
  tc <- qt(0.975, 41)
  expect_equal(r$achieved_power, pt(tc, 41, ncp = 3 / se, lower.tail = FALSE) + pt(-tc, 41, ncp = 3 / se))
})

test_that("the closed-form inverse of the AR(1) correlation matrix is the inverse", {
  X <- .its_design(15, 12, TRUE, TRUE, "slope")
  for (rho in c(-0.4, 0.3, 0.8)) {
    R <- rho^abs(outer(1:27, 1:27, "-"))
    expect_equal(.its_gls_var(X, rho, 1.7), 1.7^2 * solve(t(X) %*% solve(R) %*% X), ignore_attr = TRUE)
  }
})

test_that("change in level: close to the simulated power of Beard, Brown & Shahab 2026, Table 1 (AR(1) 0.5, white-noise SD 1)", {
  # the paper's values are simulations of a fitted ARIMA model whose test rejects somewhat too often; from 100 time points on the
  # two agree within 0.06
  s <- 1 / sqrt(1 - 0.5^2)
  p <- function(n, e) calc_its_power(n / 2, n / 2, e, "level", sd = s, rho = 0.5, baseline_trend = FALSE, both_changes = FALSE)$achieved_power
  paper <- list(c(100, 0.5, 0.27), c(100, 0.8, 0.51), c(100, 1.0, 0.70), c(100, 1.2, 0.83), c(100, 1.5, 0.95),
                c(200, 0.3, 0.20), c(200, 0.5, 0.45), c(200, 0.7, 0.70), c(200, 0.9, 0.89),
                c(400, 0.2, 0.20), c(400, 0.4, 0.51), c(400, 0.6, 0.83))
  for (x in paper) expect_lt(abs(p(x[1], x[2]) - x[3]), 0.06, label = sprintf("n = %d, step %.1f", x[1], x[2]))
})

test_that("power rises with the length of the series and the size of the change, and falls with autocorrelation and model terms", {
  base <- function(...) {
    args <- utils::modifyList(list(n_pre = 30, n_post = 30, effect = 1.5, effect_type = "level", sd = 1.5, rho = 0.3), list(...))
    do.call(calc_its_power, args)$achieved_power
  }
  expect_gt(base(n_pre = 60, n_post = 60), base())
  expect_gt(base(effect = 2), base())
  expect_gt(base(rho = 0), base())
  expect_gt(base(both_changes = FALSE), base())
  expect_gt(base(baseline_trend = FALSE, both_changes = FALSE), base(both_changes = FALSE))
  expect_gt(base(), base(n_pre = 50, n_post = 10))                     # the midpoint beats an early or late interruption
  expect_equal(base(effect = -1.5), base())
})

test_that("the number of time points is the smallest reaching the power, split as asked", {
  r <- calc_its_n(effect = 2, effect_type = "level", sd = 1.5, rho = 0.3)
  expect_equal(c(r$n_total, r$n_pre, r$n_post), c(123, 62, 61))
  expect_gte(r$achieved_power, 0.8)
  expect_lt(calc_its_power(61, 61, 2, "level", 1.5, 0.3)$achieved_power, 0.8)
  r <- calc_its_n(effect = 2, effect_type = "level", sd = 1.5, rho = 0.3, pre_fraction = 0.25, power = 0.9)
  expect_equal(r$n_pre, round(r$n_total * 0.25))
  expect_gte(r$achieved_power, 0.9)
  expect_error(calc_its_n(effect = 0.001, sd = 5, rho = 0.9, max_n = 200), "not reached with 200")
})

test_that("the documented worked examples are what the functions return", {
  a <- calc_its_power(24, 24, 2, "level", 1.5, 0.3)
  expect_equal(round(c(a$se, a$achieved_power), 2), c(1.07, 0.45))
  expect_equal(round(calc_its_n(2, "level", 1.5, 0.3)$se, 2), 0.71)
  expect_equal(calc_its_n(2, "level", 1.5, 0.3, baseline_trend = FALSE, both_changes = FALSE)$n_total, 32)
  s <- 1 / sqrt(0.75)
  expect_equal(round(calc_its_power(50, 50, 0.05, "slope", s, 0.5)$achieved_power, 2), 0.45)
  expect_equal(calc_its_n(0.05, "slope", s, 0.5)$n_total, 133)
})

test_that("invalid inputs are rejected", {
  expect_error(calc_its_power(2, 20, 1), "n_pre")
  expect_error(calc_its_power(20, 20.5, 1), "n_post")
  expect_error(calc_its_power(20, 20, 0), "differ from 0")
  expect_error(calc_its_power(20, 20, 1, sd = 0), "sd")
  expect_error(calc_its_power(20, 20, 1, rho = 1), "rho")
  expect_error(calc_its_power(20, 20, 1, effect_type = "pulse"), "arg")
  expect_error(calc_its_n(1, power = 1), "power")
})
