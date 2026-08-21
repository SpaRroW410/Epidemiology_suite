source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_rule_of_three.R"))

test_that("calc_rule_of_three_bound matches the classic Hanley & Lippman-Hand (1983) illustration", {
  # n=30 subjects, zero events -> approx 3/30 = 0.0999..., exact 0.0950.
  res <- calc_rule_of_three_bound(n = 30, conf_level = 0.95)
  expect_equal(round(res$approx_bound, 4), 0.0999)
  expect_equal(round(res$exact_bound, 4), 0.0950)
})

test_that("calc_rule_of_three_bound rejects invalid inputs", {
  expect_error(calc_rule_of_three_bound(n = 0), ">= 1")
  expect_error(calc_rule_of_three_bound(n = 5.5), ">= 1")
  expect_error(calc_rule_of_three_bound(n = 30, conf_level = 1), "between 0 and 1")
})

test_that("calc_rule_of_three_n: p=0.01, 95% -> n_exact=299, n_approx=300", {
  res <- calc_rule_of_three_n(p = 0.01, conf_level = 0.95)
  expect_equal(res$n_exact, 299)
  expect_equal(res$n_approx, 300)
})

test_that("calc_rule_of_three_n rejects invalid inputs", {
  expect_error(calc_rule_of_three_n(p = 0), "between 0 and 1")
  expect_error(calc_rule_of_three_n(p = 1), "between 0 and 1")
  expect_error(calc_rule_of_three_n(p = 0.01, conf_level = 0), "between 0 and 1")
})
