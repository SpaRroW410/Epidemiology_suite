test_that("calc_rm_anova (between) matches WebPower::wp.rmanova()'s own documented example", {
  # ng = 3, nm = 4, f = 0.36, nscor = 0.7, power = 0.8 -> n = 110 (WebPower's
  # own table shows n = 110 gives power = 0.8029337, the first rung >= 0.80).
  res <- calc_rm_anova(ng = 3, nm = 4, f = 0.36, nscor = 0.7, alpha = 0.05,
                        power = 0.8, type = "between")
  expect_equal(res$n, 110)
  expect_equal(res$achieved_power, 0.8029337, tolerance = 1e-6)
})

test_that("calc_rm_anova (within) matches a direct run of WebPower::wp.rmanova()'s extracted algorithm", {
  # ng = 2, nm = 3, f = 0.25, nscor = 0.8, power = 0.8 -> n = 182 (root of the
  # identical noncentral-F equation, verified independently, since this
  # combination isn't in WebPower's own published \\examples{}).
  res <- calc_rm_anova(ng = 2, nm = 3, f = 0.25, nscor = 0.8, alpha = 0.05,
                        power = 0.8, type = "within")
  expect_equal(res$n, 182)
  expect_equal(res$achieved_power, 0.80018, tolerance = 1e-4)
})

test_that("calc_rm_anova (interaction) matches a direct run of WebPower::wp.rmanova()'s extracted algorithm", {
  # ng = 3, nm = 3, f = 0.25, nscor = 0.8, power = 0.8 -> n = 226.
  res <- calc_rm_anova(ng = 3, nm = 3, f = 0.25, nscor = 0.8, alpha = 0.05,
                        power = 0.8, type = "interaction")
  expect_equal(res$n, 226)
  expect_equal(res$achieved_power, 0.8018846, tolerance = 1e-6)
})

test_that("calc_rm_anova rejects invalid inputs", {
  expect_error(calc_rm_anova(ng = 1, nm = 4, f = 0.36, type = "between"), "at least 2")
  expect_error(calc_rm_anova(ng = 1, nm = 4, f = 0.36, type = "interaction"), "at least 2")
  expect_error(calc_rm_anova(ng = 3, nm = 1, f = 0.36, type = "between"), ">= 2")
  expect_error(calc_rm_anova(ng = 3, nm = 4, f = -0.1, type = "between"), "positive")
  expect_error(calc_rm_anova(ng = 3, nm = 4, f = 0.36, nscor = 1.5, type = "between"), "\\(0, 1\\]")
  expect_error(calc_rm_anova(ng = 3, nm = 4, f = 0.36, power = 0), "between 0 and 1")
})

test_that("calc_rm_anova allows a single group for a within-subjects-only design", {
  res <- calc_rm_anova(ng = 1, nm = 4, f = 0.4, nscor = 1, alpha = 0.05,
                        power = 0.8, type = "within")
  expect_true(res$n >= 2)
  expect_gte(res$achieved_power, 0.8)
})
