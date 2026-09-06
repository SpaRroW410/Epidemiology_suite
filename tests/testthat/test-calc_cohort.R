source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_cohort.R"))

test_that("calc_cohort matches epiR::epi.sscohortc's own documented example", {
  # Anoestrus-in-dairy-cattle example: p1 = 0.30 (exposed/treatment),
  # p0 = 0.15 (unexposed/control), power = 0.80, two-sided alpha = 0.05,
  # ratio = 1 -> n = 242 total (121/121), implied RR = 2.0.
  res <- calc_cohort(p0 = 0.15, p1 = 0.30, power = 0.80, ratio = 1,
                      alpha = 0.05, alternative = "two.sided")
  expect_equal(res$n_total, 242)
  expect_equal(res$n_exposed, 121)
  expect_equal(res$n_unexposed, 121)
  expect_equal(res$rr, 2)
})

test_that("calc_cohort rejects invalid inputs", {
  expect_error(calc_cohort(p0 = 0.3, p1 = 0.3), "must differ")
  expect_error(calc_cohort(p0 = 0, p1 = 0.3), "between 0 and 1")
  expect_error(calc_cohort(p0 = 0.15, p1 = 0.30, alpha = 1.5), "between 0 and 1")
  expect_error(calc_cohort(p0 = 0.15, p1 = 0.30, ratio = -1), "positive")
})

test_that("calc_cohort applies finite population correction when N is given", {
  no_fpc <- calc_cohort(p0 = 0.15, p1 = 0.30, power = 0.80, N = NULL)
  with_fpc <- calc_cohort(p0 = 0.15, p1 = 0.30, power = 0.80, N = 300)
  expect_lte(with_fpc$n_total, no_fpc$n_total)
})
