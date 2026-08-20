source(file.path("..", "..", "R", "calc", "calc_proportion.R"))

test_that("calc_proportion_1s matches Cohen (1988) published one-sample tables", {
  # Cohen (1988) Table 6.4.1: one-sample proportion test, alpha = .05 two-tailed,
  # power = .80, small conventional arcsine effect size h = 0.2, gives n = 197.
  # p0 = 0.5, p1 chosen so that ES.h(p1, p0) == 0.2 exactly.
  p0 <- 0.5
  p1 <- sin(asin(sqrt(p0)) + 0.2 / 2)^2
  res <- calc_proportion_1s(p0 = p0, p1 = p1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$h, 4), 0.2)
  expect_equal(res$n, 197)
})

test_that("calc_proportion_1s: worked example from content_proportion.R", {
  res <- calc_proportion_1s(p0 = 0.20, p1 = 0.30, alpha = 0.05, power = 0.8,
                             alternative = "two.sided")
  expect_equal(res$n, 146)
  expect_equal(round(res$h, 4), 0.2320)
})

test_that("calc_proportion_1s rejects invalid inputs", {
  expect_error(calc_proportion_1s(p0 = 0, p1 = 0.3), "between 0 and 1")
  expect_error(calc_proportion_1s(p0 = 1, p1 = 0.3), "between 0 and 1")
  expect_error(calc_proportion_1s(p0 = 0.3, p1 = 0.3), "must differ")
  expect_error(calc_proportion_1s(p0 = 0.2, p1 = 0.3, alpha = 1.5), "between 0 and 1")
  expect_error(calc_proportion_1s(p0 = 0.2, p1 = 0.3, power = 0), "between 0 and 1")
})

test_that("calc_proportion_2s: worked example from content_proportion.R", {
  res <- calc_proportion_2s(p1 = 0.10, p2 = 0.25, alpha = 0.05, power = 0.8,
                             alternative = "two.sided")
  expect_equal(res$n_per_group, 97)
  expect_equal(res$n_total, 194)
  expect_equal(round(abs(res$h), 4), 0.4037)
})

test_that("calc_proportion_2s rejects invalid inputs", {
  expect_error(calc_proportion_2s(p1 = 0.10, p2 = 0.10), "must differ")
  expect_error(calc_proportion_2s(p1 = -0.1, p2 = 0.25), "between 0 and 1")
  expect_error(calc_proportion_2s(p1 = 0.10, p2 = 0.25, alpha = 0), "between 0 and 1")
})
