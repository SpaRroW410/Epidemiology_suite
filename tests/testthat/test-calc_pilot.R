source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_pilot.R"))

test_that("calc_pilot_sd_precision matches the well-known n=12 illustration", {
  # At n = 12, a 95% CI for the true SD spans ~0.708x to ~1.698x the
  # observed sample SD -- the standard illustration of why 12/arm is only
  # a loose compromise (Julious 2005's own rationale).
  res <- calc_pilot_sd_precision(n = 12, conf_level = 0.95)
  expect_equal(round(res$lower_mult, 3), 0.708)
  expect_equal(round(res$upper_mult, 3), 1.698)
})

test_that("calc_pilot_sd_precision: precision improves as n grows", {
  small <- calc_pilot_sd_precision(n = 12)
  large <- calc_pilot_sd_precision(n = 100)
  expect_gt(small$upper_mult - small$lower_mult, large$upper_mult - large$lower_mult)
})

test_that("calc_pilot_sd_precision rejects invalid inputs", {
  expect_error(calc_pilot_sd_precision(n = 1), ">= 2")
  expect_error(calc_pilot_sd_precision(n = 5.5), ">= 2")
  expect_error(calc_pilot_sd_precision(n = 12, conf_level = 1), "between 0 and 1")
})
