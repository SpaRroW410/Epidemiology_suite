# Feychting et al. (1998), the worked example in epiR::epi.2by2()'s help page: cancer rate of 136 cases in
# 22050 person-years among the blind vs 1709 in 127650 person-years among the visually impaired. Published
# reading: "incidence rate ratio 0.46, 95% CI 0.38 to 0.55".
feychting <- function(...) calc_analyze_rate_ratio(136, 22050, 1709, 127650, ...)

test_that("reproduces the published Feychting et al. (1998) / epiR example", {
  r <- feychting()
  expect_equal(round(c(r$rate_ratio, r$rate_ratio_exact_lower, r$rate_ratio_exact_upper), 2), c(0.46, 0.38, 0.55))
  expect_equal(round(r$rate_difference, 2), -7.22)   # "7.22 cases per 1000 person-years less in the blind"
})

test_that("single-rate exact and Byar intervals equal epiR::epi.conf(); exact also equals the chi-square (Garwood) form", {
  skip_if_not_installed("epiR")
  for (cs in list(c(7, 1000), c(0, 500), c(1, 40), c(25, 3000), c(180, 52000))) {
    r <- calc_analyze_rate_single(cs[1], cs[2], multiplier = 1)
    for (m in c("exact", "byar")) {
      e <- suppressMessages(epiR::epi.conf(as.matrix(cbind(cs[1], cs[2])), ctype = "inc.rate", method = m,
                                           N = 1e9, design = 1, conf.level = 0.95))
      expect_equal(c(r[[paste0(m, "_lower")]], r[[paste0(m, "_upper")]]), pmax(0, as.numeric(e[1, c("lower", "upper")])),
                   tolerance = 1e-6, info = paste(cs, collapse = "/", m))
    }
    pt <- poisson.test(cs[1], cs[2])$conf.int
    expect_equal(c(r$exact_lower, r$exact_upper), as.numeric(pt), tolerance = 1e-8)
  }
})

test_that("rates are reported per the chosen multiplier", {
  r <- calc_analyze_rate_single(7, 1000, multiplier = 1000)
  expect_equal(r$rate, 7)
  expect_equal(r$exact_lower, 1000 * poisson.test(7, 1000)$conf.int[1])
  r365 <- calc_analyze_rate_single(7, 1000, multiplier = 100)
  expect_equal(r365$rate, 0.7)
})

test_that("single-rate mid-P limits satisfy their defining equation; Wald is the textbook formula; ordering exact > mid-P", {
  for (d in c(1, 7, 25)) {
    r <- calc_analyze_rate_single(d, 1, multiplier = 1); a <- 0.05
    expect_equal(ppois(d, r$mid_p_lower, lower.tail = FALSE) + 0.5 * dpois(d, r$mid_p_lower), a / 2, tolerance = 1e-8)
    expect_equal(ppois(d - 1, r$mid_p_upper) + 0.5 * dpois(d, r$mid_p_upper), a / 2, tolerance = 1e-8)
    expect_lt(r$exact_lower, r$mid_p_lower); expect_gt(r$exact_upper, r$mid_p_upper)
  }
  z <- calc_analyze_rate_single(0, 10, multiplier = 1)
  expect_equal(z$mid_p_lower, 0); expect_gt(z$mid_p_upper, 0)
  w <- calc_analyze_rate_single(25, 100, multiplier = 1)
  expect_equal(c(w$wald_lower, w$wald_upper), (25 + c(-1, 1) * qnorm(0.975) * 5) / 100)
  expect_equal(calc_analyze_rate_single(0, 10)$wald_upper, 0)   # the known zero-width failure of the Wald interval
})

test_that("rate ratio: exact interval equals stats::poisson.test() and epiR::epi.2by2(method = 'cohort.time')", {
  skip_if_not_installed("epiR")
  for (v in list(c(10, 2000, 4, 2500), c(136, 22050, 1709, 127650), c(3, 500, 12, 4000), c(60, 800, 25, 900))) {
    r <- calc_analyze_rate_ratio(v[1], v[2], v[3], v[4], multiplier = 1)
    pt <- poisson.test(c(v[1], v[3]), c(v[2], v[4]))
    expect_equal(c(r$rate_ratio, r$rate_ratio_exact_lower, r$rate_ratio_exact_upper), c(unname(pt$estimate), as.numeric(pt$conf.int)), tolerance = 1e-8)
    expect_equal(r$exact_test_p, pt$p.value, tolerance = 1e-8)
    d <- suppressMessages(epiR::epi.2by2(as.table(matrix(v, 2, byrow = TRUE)), method = "cohort.time", units = 1))$massoc.detail
    expect_equal(c(r$rate_ratio, r$rate_ratio_exact_lower, r$rate_ratio_exact_upper), as.numeric(d$IRR.strata.wald), tolerance = 1e-6)
    expect_equal(c(r$rate_difference, r$rate_difference_lower, r$rate_difference_upper), as.numeric(d$ARate.strata.wald), tolerance = 1e-6)
    expect_equal(c(r$attributable_fraction_exposed, r$attributable_fraction_exposed_lower, r$attributable_fraction_exposed_upper),
                 as.numeric(d$AFRate.strata.wald) , tolerance = 1e-6)
  }
})

test_that("rate ratio: Wald (log) interval is the textbook formula; mid-P conditional limits satisfy their equation", {
  r <- calc_analyze_rate_ratio(10, 2000, 4, 2500, multiplier = 1)
  expect_equal(c(r$rate_ratio_wald_lower, r$rate_ratio_wald_upper),
               exp(log(3.125) + c(-1, 1) * qnorm(0.975) * sqrt(1 / 10 + 1 / 4)))
  # mid-P: map back to the conditional proportion p = IRR T1 / (IRR T1 + T0) and check the tail equation
  to_p <- function(irr) irr * 2000 / (irr * 2000 + 2500)
  pl <- to_p(r$rate_ratio_mid_p_lower); pu <- to_p(r$rate_ratio_mid_p_upper)
  expect_equal(pbinom(10, 14, pl, lower.tail = FALSE) + 0.5 * dbinom(10, 14, pl), 0.025, tolerance = 1e-8)
  expect_equal(pbinom(9, 14, pu) + 0.5 * dbinom(10, 14, pu), 0.025, tolerance = 1e-8)
  expect_gt(r$rate_ratio_mid_p_lower, r$rate_ratio_exact_lower)   # mid-P is narrower than exact
  expect_lt(r$rate_ratio_mid_p_upper, r$rate_ratio_exact_upper)
})

test_that("tests: score chi-square equals prop.test() without correction; mid-P p-value is below the exact one", {
  r <- calc_analyze_rate_ratio(10, 2000, 4, 2500)
  pp <- suppressWarnings(prop.test(10, 14, p = 2000 / 4500, correct = FALSE))
  expect_equal(r$score_chisq, unname(pp$statistic), tolerance = 1e-8)
  expect_equal(r$score_test_p, pp$p.value, tolerance = 1e-8)
  expect_lt(r$mid_p_test_p, r$exact_test_p)
  expect_equal(feychting()$exact_test_p < 1e-10, TRUE)
})

test_that("rate difference matches its Wald formula; attributable fractions follow from the rates", {
  r <- calc_analyze_rate_ratio(10, 2000, 4, 2500, multiplier = 1000)
  expect_equal(r$rate_difference, 1000 * (10 / 2000 - 4 / 2500))
  se <- 1000 * sqrt(10 / 2000^2 + 4 / 2500^2)
  expect_equal(c(r$rate_difference_lower, r$rate_difference_upper), r$rate_difference + c(-1, 1) * qnorm(0.975) * se)
  expect_equal(r$attributable_fraction_exposed, (3.125 - 1) / 3.125)
  ipop <- 14 / 4500; expect_equal(r$population_attributable_fraction, (ipop - 4 / 2500) / ipop)
})

test_that("population attributable fraction interval: delta-method SE (with the rates' covariance) matches simulation", {
  set.seed(17)
  l1 <- 0.01; l0 <- 0.005; t1 <- 40000; t0 <- 60000          # about 400 and 300 expected events
  sim <- replicate(20000, {
    d1 <- rpois(1, l1 * t1); d0 <- rpois(1, l0 * t0)
    ipop <- (d1 + d0) / (t1 + t0); log(ipop / (d0 / t0))
  })
  d0 <- l0 * t0; dd <- l1 * t1 + d0
  expect_equal(sqrt(1 / d0 - 1 / dd), sd(sim), tolerance = 0.03)
  # coverage of the interval
  hit <- replicate(4000, {
    d1 <- rpois(1, l1 * t1); d0 <- rpois(1, l0 * t0)
    r <- calc_analyze_rate_ratio(d1, t1, d0, t0)
    truth <- ((l1 * t1 + l0 * t0) / (t1 + t0) - l0) / ((l1 * t1 + l0 * t0) / (t1 + t0))
    r$population_attributable_fraction_lower <= truth && truth <= r$population_attributable_fraction_upper
  })
  expect_equal(mean(hit), 0.95, tolerance = 0.02)
})

test_that("zero events leave the undefined estimates NA or infinite, never invented", {
  r0 <- calc_analyze_rate_ratio(5, 1000, 0, 1000)
  expect_true(is.na(r0$rate_ratio)); expect_true(is.infinite(r0$rate_ratio_exact_upper)); expect_gt(r0$rate_ratio_exact_lower, 0)
  expect_true(is.na(r0$rate_ratio_wald_lower)); expect_true(is.na(r0$population_attributable_fraction_lower))
  r1 <- calc_analyze_rate_ratio(0, 1000, 5, 1000)
  expect_equal(r1$rate_ratio, 0); expect_equal(r1$rate_ratio_exact_lower, 0)
  expect_error(calc_analyze_rate_ratio(0, 1000, 0, 1000), "At least one event")
})

test_that("input is validated", {
  expect_error(calc_analyze_rate_single(-1, 10), "non-negative whole number")
  expect_error(calc_analyze_rate_single(2.5, 10), "whole number")
  expect_error(calc_analyze_rate_single(3, 0), "positive")
  expect_error(calc_analyze_rate_single(3, 10, multiplier = 0), "multiplier")
  expect_error(calc_analyze_rate_single(3, 10, conf_level = 1))
  expect_error(calc_analyze_rate_ratio(1, -5, 2, 10), "positive")
  expect_error(calc_analyze_rate_ratio(NA, 5, 2, 10), "whole number")
})

test_that("display table lists four single-rate methods; results are ss_result objects", {
  r <- calc_analyze_rate_single(7, 1000)
  expect_equal(nrow(analyze_rate_single_table(r)), 4); expect_s3_class(r, "ss_result"); expect_s3_class(feychting(), "ss_result")
})

# ---- stratified rates (Mantel-Haenszel) -------------------------------------------------------
strat3 <- rbind(c(20, 3000, 10, 4000), c(12, 2000, 8, 2500), c(5, 1000, 9, 3000))   # d1, t1, d0, t0

test_that("stratified: Mantel-Haenszel rate ratio and rate difference with Wald limits equal epiR::epi.2by2(cohort.time)", {
  skip_if_not_installed("epiR")
  arr <- array(NA_real_, dim = c(2, 2, 3), dimnames = list(c("E+", "E-"), c("D", "T"), paste0("s", 1:3)))
  for (i in 1:3) arr[, , i] <- matrix(c(strat3[i, 1], strat3[i, 3], strat3[i, 2], strat3[i, 4]), 2)
  e <- suppressWarnings(suppressMessages(epiR::epi.2by2(as.table(arr), method = "cohort.time")))
  r <- calc_analyze_rate_stratified(strat3, multiplier = 100)       # epiR reports the difference per 100
  expect_equal(c(r$mh_rate_ratio, r$mh_rate_ratio_lower, r$mh_rate_ratio_upper), as.numeric(e$massoc.detail$IRR.mh.wald[1, ]), tolerance = 1e-8)
  expect_equal(c(r$mh_rate_difference, r$mh_rate_difference_lower, r$mh_rate_difference_upper),
               as.numeric(e$massoc.detail$ARate.mh.wald[1, ]), tolerance = 1e-8)
  expect_equal(c(r$crude_rate_ratio, r$crude_rate_ratio_lower, r$crude_rate_ratio_upper), as.numeric(e$massoc.detail$IRR.crude.wald[1, ]), tolerance = 1e-8)
  tb <- analyze_rate_strata_table(r)
  expect_equal(as.matrix(tb[, c("rate_ratio", "rate_ratio_lower", "rate_ratio_upper")]), unname(as.matrix(e$massoc.detail$IRR.strata.wald)), ignore_attr = TRUE, tolerance = 1e-8)
})

test_that("stratified: closed forms, the one-stratum limit and invariance to rescaling person-time", {
  r <- calc_analyze_rate_stratified(strat3)
  tt <- rowSums(strat3[, c(2, 4)])
  expect_equal(r$mh_rate_ratio, sum(strat3[, 1] * strat3[, 4] / tt) / sum(strat3[, 3] * strat3[, 2] / tt))
  # two identical strata give the same rate ratio as one of them
  one <- calc_analyze_rate_ratio(20, 3000, 10, 4000)
  two <- calc_analyze_rate_stratified(rbind(strat3[1, ], strat3[1, ]))
  expect_equal(two$mh_rate_ratio, one$rate_ratio, tolerance = 1e-12)
  # the CMH-type score test of one stratum is the score test of the two-group tool; of two identical strata it is ~ twice that
  expect_equal(calc_analyze_rate_stratified(rbind(strat3[1, ], strat3[1, ]))$cmh_chisq, 2 * one$score_chisq, tolerance = 1e-10)
  # person-time in other units changes nothing
  s2 <- strat3; s2[, c(2, 4)] <- s2[, c(2, 4)] / 365.25
  r2 <- calc_analyze_rate_stratified(s2)
  expect_equal(c(r2$mh_rate_ratio, r2$mh_rate_ratio_lower, r2$cmh_chisq, r2$woolf_chisq), c(r$mh_rate_ratio, r$mh_rate_ratio_lower, r$cmh_chisq, r$woolf_chisq), tolerance = 1e-10)
  # rate difference scales with the multiplier
  expect_equal(calc_analyze_rate_stratified(strat3, multiplier = 1000)$mh_rate_difference,
               10 * calc_analyze_rate_stratified(strat3, multiplier = 100)$mh_rate_difference)
})

test_that("stratified: Woolf homogeneity statistic equals a weighted least-squares residual sum of squares", {
  r <- calc_analyze_rate_stratified(strat3)
  y <- log((strat3[, 1] / strat3[, 2]) / (strat3[, 3] / strat3[, 4])); w <- 1 / (1 / strat3[, 1] + 1 / strat3[, 3])
  fit <- lm(y ~ 1, weights = w)
  expect_equal(r$woolf_chisq, sum(w * residuals(fit)^2), tolerance = 1e-10)
  expect_equal(r$woolf_df, 2L)
  expect_equal(r$woolf_p, pchisq(r$woolf_chisq, 2, lower.tail = FALSE))
})

test_that("stratified: strongly heterogeneous strata are flagged by both homogeneity tests", {
  r <- calc_analyze_rate_stratified(rbind(c(60, 1000, 10, 1000), c(10, 1000, 60, 1000), c(30, 1000, 30, 1000)))
  expect_lt(r$woolf_p, 1e-6); expect_lt(r$breslow_day_type_p, 1e-6)
})

test_that("stratified: zero counts are handled, never invented", {
  r <- calc_analyze_rate_stratified(rbind(c(0, 500, 0, 600), c(4, 800, 2, 900), c(3, 300, 0, 400)))
  expect_true(is.finite(r$mh_rate_ratio))                 # an empty stratum contributes nothing
  expect_equal(r$zero_count_strata, 2)
  expect_true(is.na(r$woolf_chisq))                       # only one stratum has both counts > 0
  expect_true(is.na(calc_analyze_rate_stratified(rbind(c(3, 100, 0, 100), c(2, 100, 0, 100)))$mh_rate_ratio))
  expect_error(calc_analyze_rate_stratified(rbind(c(0, 100, 0, 100), c(0, 100, 0, 100))), "At least one event")
  tb <- analyze_rate_strata_table(calc_analyze_rate_stratified(rbind(c(0, 500, 0, 600), c(4, 800, 2, 900))))
  expect_true(is.na(tb$rate_ratio[1]))
})

test_that("stratified: input is validated", {
  expect_error(calc_analyze_rate_stratified(rbind(c(1, 10, 1, 10))), "at least 2 strata")
  expect_error(calc_analyze_rate_stratified(rbind(c(1, 10, 1, 10), c(1.5, 10, 1, 10))), "whole numbers")
  expect_error(calc_analyze_rate_stratified(rbind(c(1, 0, 1, 10), c(1, 10, 1, 10))), "person-time must be positive")
  expect_error(calc_analyze_rate_stratified(rbind(c(1, 10, 1, 10), c(NA, 10, 1, 10))), "must be a number")
  expect_error(calc_analyze_rate_stratified(strat3, conf_level = 1.2))
})

test_that("stratified (simulation): MH interval covers, the CMH test and both homogeneity tests have about nominal size", {
  skip_if_not_slow()
  set.seed(2026)
  t1 <- c(3000, 2000, 1000) * 5; t0 <- c(4000, 2500, 3000) * 5; base <- c(0.002, 0.003, 0.004); theta <- 1.8   # ~ 60-150 events per stratum
  reps <- 3000
  res <- replicate(reps, {
    r <- calc_analyze_rate_stratified(cbind(rpois(3, base * theta * t1), t1, rpois(3, base * t0), t0))
    c(r$mh_rate_ratio_lower <= theta && theta <= r$mh_rate_ratio_upper, r$woolf_p < 0.05, r$breslow_day_type_p < 0.05)
  })
  # absolute tolerances: the Monte Carlo SE of a rate near 0.05 with 3000 replicates is about 0.004
  expect_lt(abs(mean(res[1, ]) - 0.95), 0.015)
  expect_lt(abs(mean(res[2, ], na.rm = TRUE) - 0.05), 0.015)
  expect_lt(abs(mean(res[3, ], na.rm = TRUE) - 0.05), 0.015)
  null <- replicate(reps, {
    r <- calc_analyze_rate_stratified(cbind(rpois(3, base * t1), t1, rpois(3, base * t0), t0))
    r$cmh_p < 0.05
  })
  expect_lt(abs(mean(null) - 0.05), 0.015)
})
