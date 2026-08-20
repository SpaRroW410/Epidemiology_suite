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

test_that("calc_proportion_precision matches the well-known n=385 default", {
  # Cochran (1977): p = 0.5 (unknown/most conservative), d = 0.05, 95% CI ->
  # the widely-quoted default prevalence-survey sample size of 385.
  res <- calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 0.95)
  expect_equal(res$n, 385)
  expect_equal(round(res$z, 4), 1.9600)
})

test_that("calc_proportion_precision: worked example from content_proportion.R", {
  res <- calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 0.95)
  expect_equal(res$n, 385)
})

test_that("calc_proportion_precision rejects invalid inputs", {
  expect_error(calc_proportion_precision(p = 0, d = 0.05), "between 0 and 1")
  expect_error(calc_proportion_precision(p = 0.5, d = 0), "between 0 and 1")
  expect_error(calc_proportion_precision(p = 0.5, d = 1), "between 0 and 1")
  expect_error(calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 1), "between 0 and 1")
})

test_that("calc_proportion_precision applies the finite population correction", {
  # Cochran (1977) FPC: n = n0 / (1 + (n0-1)/N). n0 = 385 (p=.5, d=.05, 95% CI),
  # N = 1000 -> adjusted n = 278 (manually cross-checked).
  res <- calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 0.95, N = 1000)
  expect_equal(res$n_unadjusted, 385)
  expect_equal(res$n, 278)
  expect_equal(res$N, 1000)
})

test_that("calc_proportion_precision: FPC is a no-op as N grows large", {
  res_no_fpc <- calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 0.95)
  res_huge_n <- calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 0.95, N = 1e9)
  expect_equal(res_no_fpc$n, res_huge_n$n)
})

test_that("calc_proportion_precision rejects invalid N", {
  expect_error(calc_proportion_precision(p = 0.5, d = 0.05, N = 0), ">= 1")
  expect_error(calc_proportion_precision(p = 0.5, d = 0.05, N = -10), ">= 1")
  expect_error(calc_proportion_precision(p = 0.5, d = 0.05, N = NA), ">= 1")
})
