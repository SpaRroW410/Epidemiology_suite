# Illustrative counts (not from a trial).
test_that("VE = 1 - ratio, and the interval is 1 minus the ratio interval with the limits swapped (risk design)", {
  v <- calc_analyze_vaccine_efficacy("risk", 8, 160, 1000, 1000)
  r <- calc_analyze_compare_proportions(8, 1000, 160, 1000)
  expect_equal(v$ve, 1 - 8 / 160 * 1)                       # equal group sizes: RR = 8/160
  expect_equal(v$ve, 1 - r$risk_ratio)
  expect_equal(c(v$ve_koopman_lower, v$ve_koopman_upper), c(1 - r$ratio_koopman_upper, 1 - r$ratio_koopman_lower))
  expect_equal(c(v$ve_katz_lower, v$ve_katz_upper), c(1 - r$ratio_katz_upper, 1 - r$ratio_katz_lower))
  expect_equal(c(v$attack_rate_vaccinated, v$attack_rate_unvaccinated), c(0.008, 0.16))
  expect_lt(v$ve_koopman_lower, v$ve); expect_gt(v$ve_koopman_upper, v$ve)
})

test_that("rate design equals 1 - the incidence rate ratio limits and the conditional exact interval", {
  v <- calc_analyze_vaccine_efficacy("rate", 8, 160, 2000, 2100)
  r <- calc_analyze_rate_ratio(8, 2000, 160, 2100, multiplier = 1)
  expect_equal(v$ve, 1 - r$rate_ratio)
  expect_equal(c(v$ve_exact_lower, v$ve_exact_upper), 1 - rev(c(r$rate_ratio_exact_lower, r$rate_ratio_exact_upper)))
  # independent route: Clopper-Pearson on the share of vaccinated cases, mapped to VE
  p <- binom.test(8, 168)$conf.int
  rr <- p / (1 - p) * 2100 / 2000
  expect_equal(c(v$ve_exact_lower, v$ve_exact_upper), 1 - rev(rr), tolerance = 1e-10)
})

test_that("case-control design: VE = 1 - OR, Woolf and Fisher limits", {
  v <- calc_analyze_vaccine_efficacy("odds", 10, 40, controls_vaccinated = 50, controls_unvaccinated = 50)
  expect_equal(v$ve, 1 - (10 / 40) / (50 / 50))
  se <- sqrt(1 / 10 + 1 / 40 + 1 / 50 + 1 / 50); z <- qnorm(0.975)
  expect_equal(c(v$ve_woolf_lower, v$ve_woolf_upper), 1 - exp(log(0.25) + c(1, -1) * z * se))
  ft <- fisher.test(matrix(c(10, 40, 50, 50), 2, byrow = TRUE))
  expect_equal(c(v$ve_exact_lower, v$ve_exact_upper), 1 - rev(ft$conf.int), tolerance = 1e-6)
  expect_equal(v$ve_conditional, 1 - unname(ft$estimate), tolerance = 1e-6)
})

test_that("VE of 0 means no effect and negative VE means more disease among the vaccinated; zero cases give VE = 100%", {
  expect_equal(calc_analyze_vaccine_efficacy("risk", 20, 20, 500, 500)$ve, 0)
  expect_lt(calc_analyze_vaccine_efficacy("risk", 30, 20, 500, 500)$ve, 0)
  z <- calc_analyze_vaccine_efficacy("risk", 0, 12, 500, 500)
  expect_equal(z$ve, 1)
  expect_true(is.finite(z$ve_adjusted_log_lower) && z$ve_adjusted_log_upper < 1 + 1e-12)   # +1/2 keeps the limits defined
})

test_that("epiR agrees on the risk ratio the VE is built from", {
  skip_if_not_installed("epiR")
  e <- suppressMessages(epiR::epi.2by2(as.table(matrix(c(8, 160, 992, 840), 2, dimnames = list(c("V", "U"), c("D+", "D-")))), method = "cohort.count"))
  v <- calc_analyze_vaccine_efficacy("risk", 8, 160, 1000, 1000)
  expect_equal(v$ve, 1 - e$massoc.detail$RR.strata.wald$est, tolerance = 1e-10)
  expect_equal(c(v$ve_katz_lower, v$ve_katz_upper), 1 - rev(c(e$massoc.detail$RR.strata.wald$lower, e$massoc.detail$RR.strata.wald$upper)), tolerance = 1e-8)
})

test_that("display table has one row per method and input is validated", {
  expect_equal(nrow(analyze_vaccine_table(calc_analyze_vaccine_efficacy("risk", 8, 160, 1000, 1000))), 3)
  expect_equal(nrow(analyze_vaccine_table(calc_analyze_vaccine_efficacy("rate", 8, 160, 2000, 2100))), 3)
  expect_equal(nrow(analyze_vaccine_table(calc_analyze_vaccine_efficacy("odds", 10, 40, controls_vaccinated = 5, controls_unvaccinated = 9))), 2)
  expect_error(calc_analyze_vaccine_efficacy("odds", 10, 40), "controls")
  expect_error(calc_analyze_vaccine_efficacy("risk", 10, 40), "participants")
  expect_error(calc_analyze_vaccine_efficacy("rate", 10, 40), "person-time")
  expect_error(calc_analyze_vaccine_efficacy("risk", 10, 40, 5, 100))          # more cases than participants
})
