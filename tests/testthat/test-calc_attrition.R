test_that("one stage: n / (1 - d), rounded up; adding the loss instead under-recruits", {
  r <- calc_attrition_stages(100, 0.2)
  expect_equal(r$n_enrolled, 125)
  expect_equal(r$n_if_loss_added_instead, 120)
  expect_equal(r$extra_to_recruit, 25)
  expect_equal(calc_attrition_stages(100, 0.15)$n_enrolled, 118)       # 117.65 -> 118
  expect_equal(calc_attrition_stages(80, 0)$n_enrolled, 80)
  expect_gt(9 / (1 - 55 / 100), 20)                                      # floating-point fuzz: 20.000000000000004, so a bare ceiling() would give 21
  expect_equal(calc_attrition_stages(9, 55 / 100)$n_enrolled, 20)
  expect_equal(calc_attrition_stages(17, 32 / 100)$n_enrolled, 25)
  expect_equal(calc_attrition_stages(21, 30 / 100)$n_enrolled, 30)
})

test_that("stages multiply, and the expected completers recompute the requirement", {
  r <- calc_attrition_stages(200, c(0.10, 0.15, 0.20))
  expect_equal(r$overall_retention, 0.9 * 0.85 * 0.8)
  expect_equal(r$n_enrolled, ceiling(200 / (0.9 * 0.85 * 0.8)))
  expect_gte(r$expected_analyzable, 200)                               # the rounding never leaves the analysis short
  expect_lt(r$expected_analyzable, 200 + 1 / (0.9 * 0.85 * 0.8) + 1e-9)  # ... and over-recruits by less than one participant's worth
  expect_equal(r$expected_after_stage_1, r$n_enrolled * 0.9)
  expect_equal(r$expected_after_stage_3, r$expected_analyzable)
  # the order of the stages does not matter for the total
  expect_equal(calc_attrition_stages(200, c(0.2, 0.1, 0.15))$n_enrolled, r$n_enrolled)
  # two 10% losses keep 81%, not 80%
  expect_equal(calc_attrition_stages(100, c(0.1, 0.1))$n_enrolled, 124)  # 100 / 0.81 = 123.46
})

test_that("arms: each arm uses its own loss; averaging the losses gives a different (wrong) total", {
  r <- calc_attrition_arms(c(100, 100), c(0.10, 0.30))
  expect_equal(c(r$n_enrolled_arm_1, r$n_enrolled_arm_2), c(112, 143))  # 111.1, 142.9
  expect_equal(r$n_enrolled_total, 255)
  expect_equal(r$n_total_if_average_loss_used, 250)                     # 200 / 0.8: pretends the arms lose alike
  expect_equal(calc_attrition_arms(c(60, 30), c(0.2, 0.2))$n_enrolled_total, 75 + 38)
  expect_error(calc_attrition_arms(c(100, 100), 0.1), "one loss fraction")
})

test_that("dilution by drop-out and drop-in: n / (1 - R_E - R_C)^2", {
  r <- calc_attrition_noncompliance(100, 0.10, 0.05)
  expect_equal(r$n_adjusted, ceiling(100 / 0.85^2))                     # 138.4 -> 139
  expect_equal(r$dilution_factor, 0.85)
  expect_equal(calc_attrition_noncompliance(100, 0, 0)$n_adjusted, 100)
  expect_gt(r$n_adjusted, r$n_if_simple_loss_used)                      # the square matters
  expect_error(calc_attrition_noncompliance(100, 0.6, 0.4), "below 1")
})

test_that("dilution (simulation): with the inflated n the intention-to-treat z test reaches the planned power; with n it does not", {
  skip_if_not_slow()
  set.seed(5)
  delta <- 0.5; sd <- 1; RE <- 0.15; RC <- 0.10
  n0 <- ceiling(2 * ((qnorm(0.975) + qnorm(0.8)) * sd / delta)^2)       # per arm, full compliance, 80% power
  power_at <- function(n) mean(replicate(4000, {
    t <- rbinom(n, 1, 1 - RE); y1 <- rnorm(n, mean = delta * t, sd = sd)           # treatment arm: compliers get the effect
    c0 <- rbinom(n, 1, RC); y0 <- rnorm(n, mean = delta * c0, sd = sd)             # control arm: drop-ins get the effect
    (mean(y1) - mean(y0)) / sqrt((var(y1) + var(y0)) / n) > qnorm(0.975)           # (variance is inflated slightly by the mixing)
  }))
  n_adj <- calc_attrition_noncompliance(n0, RE, RC)$n_adjusted
  expect_lt(power_at(n0), 0.65)
  expect_gt(power_at(n_adj), 0.77)                                       # about the planned 0.80 (mixing adds a little variance)
})

test_that("input is validated", {
  expect_error(calc_attrition_stages(0, 0.1), "single number >= 1")
  expect_error(calc_attrition_stages(100, 1), "up to")
  expect_error(calc_attrition_stages(100, -0.1), "up to")
  expect_error(calc_attrition_stages(100, numeric(0)), "between 1 and 6")
  expect_error(calc_attrition_stages(100, rep(0.1, 7)), "between 1 and 6")
})
