# Illustrative counts (not from an outbreak).
test_that("attack rate is cases / at risk and the interval is the verified proportion interval", {
  a <- calc_analyze_attack_rate(30, 120)
  expect_equal(a$attack_rate, 0.25)
  expect_equal(a$attack_rate_per_100, 25)
  ci <- calc_analyze_ci_proportion(30, 120)
  expect_equal(a$wilson_lower, ci$wilson_lower); expect_equal(a$wilson_upper, ci$wilson_upper)
  bt <- binom.test(30, 120)$conf.int
  expect_equal(c(a$exact_lower, a$exact_upper), as.numeric(bt), tolerance = 1e-8)
})

test_that("attack rate validates its inputs", {
  expect_error(calc_analyze_attack_rate(130, 120), "cannot exceed")
  expect_error(calc_analyze_attack_rate(-1, 120), "whole number")
  expect_error(calc_analyze_attack_rate(3.5, 120), "whole number")
  expect_error(calc_analyze_attack_rate(3, 0), "at risk")
  expect_equal(calc_analyze_attack_rate(0, 50)$attack_rate, 0)
})

test_that("exposure table rows equal calc_analyze_2x2 and fisher.test", {
  ex <- rbind(c(40, 50, 4, 30), c(25, 60, 19, 20), c(10, 12, 34, 68))
  r <- calc_analyze_exposure_table(ex, labels = c("Salad", "Chicken", "Dessert"))
  tb <- attr(r, "table")
  expect_equal(tb$exposure, c("Salad", "Chicken", "Dessert"))
  expect_equal(tb$attack_rate_exposed, c(40 / 50, 25 / 60, 10 / 12))
  expect_equal(tb$attack_rate_unexposed, c(4 / 30, 19 / 20, 34 / 68))
  for (i in 1:3) {
    ie <- ex[i, 1]; te <- ex[i, 2]; iu <- ex[i, 3]; tu <- ex[i, 4]
    m <- calc_analyze_2x2(ie, te - ie, iu, tu - iu, design = "cohort")
    expect_equal(tb$risk_ratio[i], m$risk_ratio)
    expect_equal(c(tb$risk_ratio_lower[i], tb$risk_ratio_upper[i]), c(m$risk_ratio_lower, m$risk_ratio_upper))
    expect_equal(tb$risk_difference[i], ie / te - iu / tu)
    expect_equal(tb$fisher_p[i], fisher.test(matrix(c(ie, te - ie, iu, tu - iu), 2, byrow = TRUE))$p.value, tolerance = 1e-10)
    expect_equal(tb$percent_of_cases_exposed[i], 100 * ie / (ie + iu))
  }
  expect_equal(r$highest_risk_ratio_exposure, "Salad")        # RR 6.0 versus 0.88 and 1.63
  expect_equal(r$highest_risk_ratio, (40 / 50) / (4 / 30))
})

test_that("exposure table accepts a data frame and guards its inputs", {
  df <- data.frame(a = 5, b = 10, c = 1, d = 10)
  expect_equal(calc_analyze_exposure_table(df)$n_exposures, 1)
  expect_error(calc_analyze_exposure_table(rbind(c(11, 10, 1, 10))), "cannot exceed")
  expect_error(calc_analyze_exposure_table(rbind(c(0, 0, 1, 10))), "at least one")
  expect_error(calc_analyze_exposure_table(rbind(c(1.5, 10, 1, 10))), "whole")
  expect_error(calc_analyze_exposure_table(c(1, 2)), "one row per exposure")
})

test_that("secondary attack rate and case fatality are proportions with the verified intervals", {
  s <- calc_analyze_secondary_attack(9, 60)
  expect_equal(s$secondary_attack_rate, 0.15)
  expect_equal(c(s$wilson_lower, s$wilson_upper), unlist(calc_analyze_ci_proportion(9, 60)[c("wilson_lower", "wilson_upper")]), ignore_attr = TRUE)
  expect_error(calc_analyze_secondary_attack(61, 60), "cannot exceed")

  f <- calc_analyze_case_fatality(6, 80)
  expect_equal(f$case_fatality, 0.075); expect_equal(f$case_fatality_percent, 7.5)
  bt <- binom.test(6, 80)$conf.int
  expect_equal(c(f$crude_exact_lower, f$crude_exact_upper), as.numeric(bt), tolerance = 1e-8)
  expect_null(f$case_fatality_resolved)

  g <- calc_analyze_case_fatality(6, 80, recovered = 34)
  expect_equal(g$unresolved, 40)
  expect_equal(g$case_fatality_resolved, 6 / 40)
  expect_equal(c(g$resolved_exact_lower, g$resolved_exact_upper), as.numeric(binom.test(6, 40)$conf.int), tolerance = 1e-8)
  expect_gt(g$case_fatality_resolved, g$case_fatality)          # resolved-case ratio is higher while cases are unresolved
  expect_error(calc_analyze_case_fatality(6, 80, recovered = 75), "cannot exceed")
  expect_error(calc_analyze_case_fatality(9, 8), "cannot exceed")
})
