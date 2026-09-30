source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_curve.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_proportion.R"))
source(file.path("..", "..", "R", "calc", "calc_means.R"))
source(file.path("..", "..", "R", "calc", "calc_case_control.R"))

test_that("ss_curve_points traces n_per_group across a grid of p2, holding p1/alpha/power fixed", {
  pts <- ss_curve_points(
    calc_proportion_2s,
    list(p1 = 0.1, alpha = 0.05, power = 0.8, alternative = "two.sided"),
    "p2", c(0.15, 0.2, 0.3, 0.5)
  )
  expect_equal(nrow(pts), 4)
  expect_equal(pts$x, c(0.15, 0.2, 0.3, 0.5))
  # farther p2 is from p1 = 0.1, the larger the effect and the smaller n needed
  expect_true(all(diff(pts$y) <= 0))

  direct <- calc_proportion_2s(p1 = 0.1, p2 = 0.3, alpha = 0.05, power = 0.8, alternative = "two.sided")
  expect_equal(pts$y[pts$x == 0.3], direct$n_per_group)
})

test_that("ss_curve_points silently skips a value outside the formula's valid domain rather than erroring", {
  pts <- ss_curve_points(
    calc_proportion_2s,
    list(p1 = 0.1, alpha = 0.05, power = 0.8, alternative = "two.sided"),
    "p2", c(0.3, 1.5) # 1.5 is not a valid proportion
  )
  expect_equal(nrow(pts), 1)
  expect_equal(pts$x, 0.3)
})

test_that("ss_curve_points silently skips a value that hits a design's own 'no effect to detect' guard", {
  pts <- ss_curve_points(
    calc_means_paired,
    list(sd_diff = 5, alpha = 0.05, power = 0.8, alternative = "two.sided"),
    "mean_diff", c(-2, 0, 2)
  )
  expect_equal(nrow(pts), 2)
  expect_false(0 %in% pts$x)
})

test_that("ss_curve_points traces n vs. power, holding effect size fixed", {
  pts <- ss_curve_points(
    calc_proportion_2s,
    list(p1 = 0.1, p2 = 0.3, alpha = 0.05, alternative = "two.sided"),
    "power", c(0.7, 0.8, 0.9)
  )
  expect_equal(nrow(pts), 3)
  expect_true(all(diff(pts$y) > 0)) # higher power needs a larger n
})

test_that(".ss_curve_n_field picks the first n/k-shaped field, never a power-shaped one", {
  r <- calc_proportion_2s(p1 = 0.1, p2 = 0.3)
  expect_equal(.ss_curve_n_field(r), "n_per_group")

  r2 <- new_ss_result(list(achieved_power = 0.8, n_total = 40, inputs = list()))
  expect_equal(.ss_curve_n_field(r2), "n_total")
})

test_that(".ss_curve_n_field prefers a strict n/k-prefixed field over a wider token match, even when a wider match would otherwise sort first", {
  # calc_means_welch()'s own shape: n1/n2 (only a token match) precede
  # n_total (a strict match) in field order -- n_total must still win.
  r <- new_ss_result(list(n1 = 50, n2 = 50, n_total = 100, inputs = list()))
  expect_equal(.ss_curve_n_field(r), "n_total")
})

test_that(".ss_curve_n_field falls back to a wider n/k-as-a-token match when no field starts with n/k", {
  # calc_case_control_case_cohort()'s own shape: neither field starts with
  # n/k, but "subcohort_n" is still the design's own headline sample size.
  r <- new_ss_result(list(subcohort_n = 120, full_cohort_n = 15792, inputs = list()))
  expect_equal(.ss_curve_n_field(r), "subcohort_n")
})

test_that("ss_curve_points traces the case_cohort design's subcohort_n across a grid of hr", {
  pts <- ss_curve_points(
    calc_case_control_case_cohort,
    list(n = 15792, pD = 0.03, p1 = 0.25, alpha = 0.05, power = 0.8),
    "hr", c(1.35, 1.5, 1.6)
  )
  expect_equal(nrow(pts), 3)
  expect_true(all(diff(pts$y) <= 0)) # a larger hazard ratio needs a smaller subcohort
})

test_that("ss_curve_points silently skips an hr for which no feasible subcohort exists", {
  # hr = 1.2 is infeasible at these inputs (required subcohort > full cohort)
  pts <- ss_curve_points(
    calc_case_control_case_cohort,
    list(n = 15792, pD = 0.03, p1 = 0.25, alpha = 0.05, power = 0.8),
    "hr", c(1.2, 1.35)
  )
  expect_equal(nrow(pts), 1)
  expect_equal(pts$x, 1.35)
})

test_that("curve_range_proportion stays within (0, 1)", {
  v <- curve_range_proportion()
  expect_true(all(v > 0 & v < 1))
})

test_that("curve_range_around excludes its own center and is symmetric around it", {
  v <- curve_range_around(10, 3, n = 11)
  expect_false(10 %in% v)
  expect_equal(min(v), 7)
  expect_equal(max(v), 13)
})

test_that("curve_range_power stays within the app's own (0.5, 0.99) power domain", {
  v <- curve_range_power()
  expect_true(all(v >= 0.5 & v <= 0.99))
})

test_that("curve_range_correlation stays within (-1, 1) and excludes zero", {
  v <- curve_range_correlation()
  expect_true(all(v > -1 & v < 1))
  expect_false(0 %in% v)
})

test_that("curve_range_within stays strictly inside its own (lower, upper) bound", {
  v <- curve_range_within(0.8, 1.25)
  expect_true(all(v > 0.8 & v < 1.25))
  expect_equal(length(v), 40)
})

test_that("curve_range_ratio is a positive, log-spaced grid excluding 1", {
  v <- curve_range_ratio()
  expect_true(all(v > 0))
  expect_false(1 %in% v)
  # log-spaced: consecutive ratios (v[i+1]/v[i]) are constant
  ratios <- v[-1] / v[-length(v)]
  expect_equal(ratios, rep(ratios[1], length(ratios)), tolerance = 1e-8)
})
