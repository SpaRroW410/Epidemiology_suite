strata_a <- rbind(c(20, 10, 15, 45), c(30, 25, 20, 60), c(12, 8, 40, 70))   # a, b, c, d per stratum
strata_b <- rbind(c(8, 12, 5, 30), c(14, 6, 9, 22))                          # two strata
strata_c <- rbind(c(3, 17, 1, 29), c(0, 12, 2, 16), c(6, 4, 7, 9), c(10, 30, 5, 45)) # a zero cell
all_sets <- list(strata_a, strata_b, strata_c)

to_array <- function(tb) {
  arr <- array(NA_real_, c(2, 2, nrow(tb)))
  for (i in seq_len(nrow(tb))) arr[, , i] <- matrix(tb[i, ], 2, byrow = TRUE) # rows exposure, columns outcome
  arr
}

test_that("pooled OR, RR and RD (Sato) equal epiR::epi.2by2() on stratified tables", {
  skip_if_not_installed("epiR")
  for (tb in all_sets) {
    r <- calc_analyze_mantel_haenszel(tb)
    d <- suppressMessages(epiR::epi.2by2(as.table(to_array(tb)), method = "cohort.count"))$massoc.detail
    expect_equal(c(r$mh_odds_ratio, r$mh_odds_ratio_lower, r$mh_odds_ratio_upper), as.numeric(d$OR.mh.wald), tolerance = 1e-6)
    expect_equal(c(r$mh_risk_ratio, r$mh_risk_ratio_lower, r$mh_risk_ratio_upper), as.numeric(d$RR.mh.wald), tolerance = 1e-6)
    expect_equal(100 * c(r$mh_risk_difference, r$mh_risk_difference_lower, r$mh_risk_difference_upper),
                 as.numeric(d$ARisk.mh.sato), tolerance = 1e-6)
  }
})

test_that("pooled OR and CMH tests equal stats::mantelhaen.test()", {
  for (tb in all_sets) {
    r <- calc_analyze_mantel_haenszel(tb)
    m <- mantelhaen.test(to_array(tb))
    expect_equal(r$mh_odds_ratio, unname(m$estimate), tolerance = 1e-8)
    expect_equal(c(r$mh_odds_ratio_lower, r$mh_odds_ratio_upper), as.numeric(m$conf.int), tolerance = 1e-8)
    expect_equal(r$cmh_chisq_corrected, unname(m$statistic), tolerance = 1e-8)
    expect_equal(r$cmh_p_corrected, m$p.value, tolerance = 1e-8)
    mu <- mantelhaen.test(to_array(tb), correct = FALSE)
    expect_equal(c(r$cmh_chisq, r$cmh_p), c(unname(mu$statistic), mu$p.value), tolerance = 1e-8)
  }
})

test_that("Breslow-Day and Tarone statistics equal DescTools::BreslowDayTest()", {
  skip_if_not_installed("DescTools")
  for (tb in list(strata_a, strata_b)) {   # strata_c has a zero margin cell pattern handled separately
    r <- calc_analyze_mantel_haenszel(tb)
    bd <- DescTools::BreslowDayTest(to_array(tb), correct = FALSE)
    tr <- DescTools::BreslowDayTest(to_array(tb), correct = TRUE)
    expect_equal(r$breslow_day_chisq, unname(bd$statistic), tolerance = 1e-6)
    expect_equal(r$breslow_day_p, bd$p.value, tolerance = 1e-6)
    expect_equal(r$tarone_chisq, unname(tr$statistic), tolerance = 1e-6)
    expect_equal(r$tarone_p, tr$p.value, tolerance = 1e-6)
    expect_equal(r$breslow_day_df, nrow(tb) - 1)
  }
})

test_that("the expected counts A* solve the defining equation A D / (B C) = pooled OR", {
  tb <- strata_a; r <- calc_analyze_mantel_haenszel(tb)
  a <- tb[, 1]; b <- tb[, 2]; c <- tb[, 3]; d <- tb[, 4]
  astar <- .mh_expected_a(r$mh_odds_ratio, a + b, c + d, a + c)
  bstar <- (a + b) - astar; cstar <- (a + c) - astar; dstar <- (c + d) - (a + c) + astar
  expect_equal(astar * dstar / (bstar * cstar), rep(r$mh_odds_ratio, 3), tolerance = 1e-8)
  expect_true(all(astar >= 0 & astar <= pmin(a + b, a + c)))
  expect_equal(.mh_expected_a(1, 40, 60, 30), 40 * 30 / 100)  # OR = 1 limit: independence
})

test_that("Woolf homogeneity tests equal their textbook form (uncorrected; epiR adds 0.5 to every cell)", {
  tb <- strata_a; r <- calc_analyze_mantel_haenszel(tb)
  a <- tb[, 1]; b <- tb[, 2]; c <- tb[, 3]; d <- tb[, 4]
  woolf <- function(ln, v) { w <- 1 / v; sum(w * (ln - sum(w * ln) / sum(w))^2) }
  expect_equal(r$woolf_or_chisq, woolf(log(a * d / (b * c)), 1 / a + 1 / b + 1 / c + 1 / d))
  expect_equal(r$woolf_or_df, 2); expect_equal(r$woolf_or_p, pchisq(r$woolf_or_chisq, 2, lower.tail = FALSE))
  rr <- log((a / (a + b)) / (c / (c + d)))
  expect_equal(r$woolf_rr_chisq, woolf(rr, 1 / a - 1 / (a + b) + 1 / c - 1 / (c + d)))
  skip_if_not_installed("epiR")
  d_epi <- suppressMessages(epiR::epi.2by2(as.table(to_array(tb)), method = "cohort.count"))$massoc.detail
  expect_equal(r$woolf_rr_chisq, d_epi$wRR.homog$test.statistic, tolerance = 1e-6)
  # epiR's OR version is Woolf on the +0.5 (Haldane) corrected cells -- reproduce it to show that is the only difference
  ln5 <- log((a + .5) * (d + .5) / ((b + .5) * (c + .5))); v5 <- 1 / (a + .5) + 1 / (b + .5) + 1 / (c + .5) + 1 / (d + .5)
  expect_equal(woolf(ln5, v5), d_epi$wOR.homog$test.statistic, tolerance = 1e-6)
})

test_that("crude estimates are the collapsed table; the confounding change is crude vs pooled", {
  r <- calc_analyze_mantel_haenszel(strata_a)
  tot <- colSums(strata_a)
  crude <- calc_analyze_2x2(tot[1], tot[2], tot[3], tot[4])
  expect_equal(r$crude_odds_ratio, crude$odds_ratio); expect_equal(r$crude_risk_ratio, crude$risk_ratio)
  expect_equal(r$odds_ratio_change_percent, 100 * (crude$odds_ratio - r$mh_odds_ratio) / r$mh_odds_ratio)
})

test_that("a textbook confounding case: crude odds ratio differs from the stratified one, strata agree", {
  # two strata with the same OR (= 4) but different exposure prevalence and baseline risk: Simpson-type confounding
  tb <- rbind(c(80, 20, 20, 20), c(10, 40, 5, 80))            # stratum ORs: 4 and 4
  r <- calc_analyze_mantel_haenszel(tb)
  expect_equal(r$mh_odds_ratio, 4, tolerance = 1e-10)
  expect_gt(abs(r$odds_ratio_change_percent), 10)                 # the usual 10% rule of thumb for confounding
  expect_gt(r$breslow_day_p, 0.99)
})

test_that("with identical stratum odds ratios the homogeneity statistics are ~0 and the pooled OR is that common OR", {
  tb <- rbind(c(30, 10, 20, 20), c(60, 20, 40, 40), c(15, 5, 10, 10))  # all OR = 3
  r <- calc_analyze_mantel_haenszel(tb)
  expect_equal(r$mh_odds_ratio, 3, tolerance = 1e-10)
  expect_equal(r$woolf_or_chisq, 0, tolerance = 1e-8); expect_equal(r$breslow_day_chisq, 0, tolerance = 1e-8)
})

test_that("case-control design: odds ratio and tests only", {
  r <- calc_analyze_mantel_haenszel(strata_a, design = "case_control")
  expect_null(r$mh_risk_ratio); expect_null(r$mh_risk_difference); expect_null(r$woolf_rr_chisq)
  expect_equal(r$mh_odds_ratio, calc_analyze_mantel_haenszel(strata_a)$mh_odds_ratio)
})

test_that("zero cells: pooled estimates still computed (the point of Mantel-Haenszel), cell-based tests use the full strata only", {
  r <- calc_analyze_mantel_haenszel(strata_c)
  expect_true(is.finite(r$mh_odds_ratio) && is.finite(r$mh_odds_ratio_lower))
  expect_equal(r$zero_cell_strata, 1)
  expect_equal(r$strata_in_homogeneity_tests, 3)
  expect_equal(r$woolf_or_df, 2)
})

test_that("not enough usable strata leaves the homogeneity tests NA rather than inventing them", {
  r <- calc_analyze_mantel_haenszel(rbind(c(5, 5, 0, 10), c(0, 8, 3, 9)))   # each stratum has a zero cell
  expect_true(is.na(r$woolf_or_chisq)); expect_true(is.finite(r$mh_odds_ratio) || is.na(r$mh_odds_ratio))
})

test_that("stratum table rebuilds each stratum's own estimates", {
  r <- calc_analyze_mantel_haenszel(strata_a)
  tb <- analyze_mh_strata_table(r, labels = c("Young", "", "Old"))
  expect_equal(nrow(tb), 3); expect_equal(tb$stratum, c("Young", "Stratum 2", "Old"))
  expect_equal(tb$odds_ratio, c(6, 3.6, 2.625))      # the epiR strata odds ratios for these tables
  expect_equal(tb$risk_ratio[1], (20 / 30) / (15 / 60))
})

test_that("input is validated", {
  expect_error(calc_analyze_mantel_haenszel(rbind(c(1, 2, 3, 4))), "at least 2 strata")
  expect_error(calc_analyze_mantel_haenszel(rbind(c(1, 2, 3, 4), c(-1, 2, 3, 4))), "Stratum 2")
  expect_error(calc_analyze_mantel_haenszel(rbind(c(1, 2, 3, 4), c(1.5, 2, 3, 4))), "whole number")
  expect_error(calc_analyze_mantel_haenszel(rbind(c(1, 2, 3, 4), c(0, 0, 0, 0))), "empty")
  expect_error(calc_analyze_mantel_haenszel(rbind(c(1, 2, 3, 4), c(NA, 2, 3, 4))), "whole number")
  expect_error(calc_analyze_mantel_haenszel(strata_a, conf_level = 1))
})

test_that("a wider confidence level widens the pooled intervals; the result is an ss_result", {
  r90 <- calc_analyze_mantel_haenszel(strata_a, conf_level = 0.90); r99 <- calc_analyze_mantel_haenszel(strata_a, conf_level = 0.99)
  expect_gt(r99$mh_odds_ratio_upper - r99$mh_odds_ratio_lower, r90$mh_odds_ratio_upper - r90$mh_odds_ratio_lower)
  expect_s3_class(r90, "ss_result")
})
