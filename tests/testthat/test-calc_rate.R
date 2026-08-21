source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_rate.R"))

test_that("calc_rate_precision matches presize::prec_rate()'s own documented example", {
  # presize's own doc example: r=2.5, conf.width=2.243, score method ->
  # x = 20.005 events (ceiling 21), time = x/r.
  res <- calc_rate_precision(rate = 2.5, conf_width = 2.243, conf_level = 0.95, method = "score")
  expect_equal(res$n_events, 21)
  expect_equal(round(res$person_time, 1), 8.4)
})

test_that("calc_rate_precision rejects invalid inputs", {
  expect_error(calc_rate_precision(rate = -1, conf_width = 1), "positive")
  expect_error(calc_rate_precision(rate = 2.5, conf_width = -1), "positive")
  expect_error(calc_rate_precision(rate = 2.5, conf_width = 20), "should not exceed 5 times")
})
