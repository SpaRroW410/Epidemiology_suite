source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_curve.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_proportion.R"))
source(file.path("..", "..", "R", "calc", "calc_means.R"))

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
