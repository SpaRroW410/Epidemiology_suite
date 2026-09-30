source(file.path("..", "..", "R", "calc", "calc_result.R"))
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

test_that("calc_detect_event_imperfect_test matches epiR::epi.ssdetect()'s own documented examples", {
  # N=1000, prev=0.05, se=0.90, sp=1.00, 95% CI -> n=65 (Cannon 2001 dairy-herd example).
  res1 <- calc_detect_event_imperfect_test(N = 1000, prev = 0.05, se = 0.90, sp = 1.00,
                                            conf_level = 0.95)
  expect_equal(res1$n_hypergeometric, 65)

  # N=200, prev=0.20, se=sp=1.00 (perfect test), 95% CI -> n=15 (Mycoplasma example).
  res3 <- calc_detect_event_imperfect_test(N = 200, prev = 0.20, se = 1.00, sp = 1.00,
                                            conf_level = 0.95)
  expect_equal(res3$n_hypergeometric, 15)
})

test_that("calc_detect_event_imperfect_test: two-test series/parallel matches hand-derived formulas", {
  # Combined Se/Sp independently re-derived from the standard series/
  # parallel test-combination formulas (Se1*Se2 / Sp1+Sp2-Sp1*Sp2 for
  # series; the complements for parallel), confirmed to match epiR's own
  # output exactly.
  res_series <- calc_detect_event_imperfect_test(
    N = 5000, prev = 0.08, se = c(0.90, 0.95), sp = c(0.80, 0.85),
    interpretation = "series", conf_level = 0.95
  )
  expect_equal(round(res_series$combined_se, 3), 0.855)
  expect_equal(round(res_series$combined_sp, 3), 0.970)
  expect_equal(res_series$n_hypergeometric, 44)

  res_parallel <- calc_detect_event_imperfect_test(
    N = 5000, prev = 0.08, se = c(0.90, 0.95), sp = c(0.80, 0.85),
    interpretation = "parallel", conf_level = 0.95
  )
  expect_equal(round(res_parallel$combined_se, 3), 0.995)
  expect_equal(round(res_parallel$combined_sp, 3), 0.680)
  expect_equal(res_parallel$n_hypergeometric, 38)
})

test_that("calc_detect_event_imperfect_test rejects invalid inputs", {
  expect_error(calc_detect_event_imperfect_test(N = 0, prev = 0.05, se = 0.9, sp = 1), ">= 1")
  expect_error(calc_detect_event_imperfect_test(N = 1000, prev = 1.5, se = 0.9, sp = 1), "between 0 and 1")
  expect_error(calc_detect_event_imperfect_test(N = 1000, prev = 0.05, se = 1.5, sp = 1), "in \\(0, 1\\]")
  expect_error(calc_detect_event_imperfect_test(N = 1000, prev = 0.05, se = c(0.9, 0.8), sp = 0.9),
               "same length")
})
