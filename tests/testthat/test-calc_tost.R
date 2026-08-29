source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_tost.R"))

test_that("calc_tost_means matches PowerTOST::sampleN.TOST()'s own documented example", {
  # PowerTOST's own doc example (logscale=FALSE, relative-to-reference
  # framing): theta0=-0.05, theta1=-0.2, theta2=0.2, CV=0.2, parallel ->
  # "should give n=48 (total) power=0.815435" per the package's own docs.
  res <- calc_tost_means(mean_diff = -0.05, margin = 0.2, sd = 0.2,
                          alpha = 0.05, power = 0.8)
  expect_equal(res$n_total, 48)
  expect_equal(round(res$achieved_power, 6), 0.815435)
})

test_that("calc_tost_means: worked example from content_tost.R", {
  res <- calc_tost_means(mean_diff = 0.5, margin = 2, sd = 5, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_group, 141)
  expect_equal(res$n_total, 282)
})

test_that("calc_tost_means rejects invalid inputs", {
  expect_error(calc_tost_means(mean_diff = 3, margin = 2, sd = 5), "must fall strictly within")
  expect_error(calc_tost_means(mean_diff = -3, margin = 2, sd = 5), "must fall strictly within")
  expect_error(calc_tost_means(mean_diff = 0.5, margin = -1, sd = 5), "positive")
  expect_error(calc_tost_means(mean_diff = 0.5, margin = 2, sd = 0), "positive")
})

test_that("calc_tost_proportions matches Machin/Campbell/Tan/Tan (2009, p.113) example", {
  # Bennett et al. (1979) cryptococcal meningitis trial, as reproduced in
  # Machin et al.: treat=control=0.50, margin=0.20, one-sided alpha=0.10,
  # power=0.80 -> n=83 per group (166 total), the textbook's own answer.
  res <- calc_tost_proportions(p_new = 0.50, p_standard = 0.50, margin = 0.20,
                                alpha = 0.10, power = 0.80, ratio = 1)
  expect_equal(res$n_total, 166)
  expect_equal(res$n_new, 83)
  expect_equal(res$n_standard, 83)
})

test_that("calc_tost_proportions rejects invalid inputs", {
  expect_error(calc_tost_proportions(p_new = 1.5, p_standard = 0.5, margin = 0.2), "between 0 and 1")
  expect_error(calc_tost_proportions(p_new = 0.5, p_standard = 0.5, margin = -0.1), "between 0 and 1")
  expect_error(calc_tost_proportions(p_new = 0.5, p_standard = 0.5, margin = 0.2, ratio = -1), "positive")
})

test_that("calc_tost_bioequivalence matches PowerTOST::sampleN.TOST()'s own documented example (2x2)", {
  # PowerTOST's own doc example: CV=0.3, theta0=0.95 (default), standard
  # 0.8-1.25 limits, alpha=0.05, power=0.8, classical 2x2 crossover ->
  # n=40 (total), achieved power=0.815845 per the package's own example.
  res <- calc_tost_bioequivalence(cv = 0.3, design = "2x2")
  expect_equal(res$n_total, 40)
  expect_equal(round(res$achieved_power, 6), 0.815845)
})

test_that("calc_tost_bioequivalence: replicate designs need fewer subjects than classical 2x2", {
  res_full <- calc_tost_bioequivalence(cv = 0.3, design = "2x2x4")
  expect_equal(res_full$n_total, 20)

  res_partial <- calc_tost_bioequivalence(cv = 0.3, design = "2x3x3")
  expect_equal(res_partial$n_total, 30)
})

test_that("calc_tost_bioequivalence rejects invalid inputs", {
  expect_error(calc_tost_bioequivalence(cv = 0.3, theta0 = 1.3), "must fall strictly within")
  expect_error(calc_tost_bioequivalence(cv = 0.3, theta0 = 0.7), "must fall strictly within")
  expect_error(calc_tost_bioequivalence(cv = -0.1), "positive")
  expect_error(calc_tost_bioequivalence(cv = 0.3, alpha = 1.5), "between 0 and 1")
})
