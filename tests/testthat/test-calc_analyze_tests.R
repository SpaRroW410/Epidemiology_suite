# ---- McNemar / matched pairs -------------------------------------------------------------------

mn <- c(a = 30, b = 12, c = 5, d = 53)
call_mn <- function(...) calc_analyze_mcnemar(mn[["a"]], mn[["b"]], mn[["c"]], mn[["d"]], ...)

test_that("McNemar chi-square (with and without continuity correction) equals stats::mcnemar.test()", {
  for (tb in list(c(30, 12, 5, 53), c(10, 4, 9, 20), c(80, 7, 25, 60), c(5, 2, 2, 9))) {
    r <- calc_analyze_mcnemar(tb[1], tb[2], tb[3], tb[4])
    m <- matrix(tb, 2, byrow = TRUE)
    u <- mcnemar.test(m, correct = FALSE); cc <- mcnemar.test(m, correct = TRUE)
    expect_equal(c(r$mcnemar_chisq, r$mcnemar_p), c(unname(u$statistic), u$p.value), tolerance = 1e-10)
    expect_equal(c(r$mcnemar_chisq_corrected, r$mcnemar_p_corrected), c(unname(cc$statistic), cc$p.value), tolerance = 1e-10)
  }
})

test_that("exact McNemar test equals binom.test on the discordant pairs; mid-P equals the exact p-value minus the point probability", {
  r <- call_mn()
  expect_equal(r$exact_p, binom.test(12, 17, 0.5)$p.value)
  expect_equal(r$mid_p, binom.test(12, 17, 0.5)$p.value - dbinom(12, 17, 0.5))
  expect_lt(r$mid_p, r$exact_p)
})

test_that("matched-pair odds ratio: b/c with exact (conditional binomial) and Wald-log intervals", {
  r <- call_mn(); z <- qnorm(0.975)
  expect_equal(r$matched_odds_ratio, 12 / 5)
  ci <- binom.test(12, 17)$conf.int
  expect_equal(c(r$matched_odds_ratio_exact_lower, r$matched_odds_ratio_exact_upper), as.numeric(ci / (1 - ci)))
  expect_equal(c(r$matched_odds_ratio_wald_lower, r$matched_odds_ratio_wald_upper), exp(log(12 / 5) + c(-1, 1) * z * sqrt(1 / 12 + 1 / 5)))
})

test_that("difference in paired proportions: Wald SE (Fleiss-Levin-Paik) matches the simulated SD", {
  r <- call_mn()
  expect_equal(r$paired_difference, (12 - 5) / 100)
  expect_equal(r$positive_test1, 0.42); expect_equal(r$positive_test2, 0.35)
  set.seed(5)
  sim <- replicate(20000, { x <- as.vector(rmultinom(1, 100, c(30, 12, 5, 53) / 100)); (x[2] - x[3]) / 100 })
  se <- (r$paired_difference_upper - r$paired_difference_lower) / (2 * qnorm(0.975))
  expect_equal(se, sd(sim), tolerance = 0.03)
})

test_that("McNemar edge cases: no discordant pairs leaves the tests NA; one empty discordant cell leaves the OR NA", {
  r <- calc_analyze_mcnemar(20, 0, 0, 30)
  expect_true(is.na(r$mcnemar_chisq) && is.na(r$exact_p) && is.na(r$matched_odds_ratio_exact_lower))
  r0 <- calc_analyze_mcnemar(20, 6, 0, 30)
  expect_true(is.na(r0$matched_odds_ratio) && is.na(r0$matched_odds_ratio_wald_lower))
  expect_true(is.infinite(r0$matched_odds_ratio_exact_upper)) # p = 1 -> OR infinite
  expect_error(calc_analyze_mcnemar(-1, 2, 3, 4), "non-negative whole number")
  expect_error(calc_analyze_mcnemar(0, 0, 0, 0), "empty")
  expect_error(calc_analyze_mcnemar(1, 2, 3, 4, conf_level = 1))
})

# ---- Kappa -------------------------------------------------------------------------------------

kappa_tables <- list(
  matrix(c(40, 10, 5, 45), 2, byrow = TRUE),
  matrix(c(20, 5, 2, 4, 25, 6, 1, 5, 32), 3, byrow = TRUE),
  matrix(c(30, 4, 1, 0, 5, 25, 6, 1, 2, 6, 22, 5, 0, 1, 4, 18), 4, byrow = TRUE))

test_that("kappa and its interval equal DescTools::CohenKappa() for unweighted, linear and quadratic weights", {
  skip_if_not_installed("DescTools")
  map <- c(unweighted = "Unweighted", linear = "Equal-Spacing", quadratic = "Fleiss-Cohen")
  for (tb in kappa_tables) for (w in names(map)) {
    r <- calc_analyze_kappa(tb, w)
    d <- DescTools::CohenKappa(tb, weights = map[[w]], conf.level = 0.95)
    expect_equal(c(r$kappa, r$kappa_lower, r$kappa_upper), unname(d), tolerance = 1e-8, info = paste(nrow(tb), w))
  }
})

test_that("unweighted standard error equals the explicit Fleiss-Cohen-Everitt (1969) expression", {
  for (tb in kappa_tables) {
    n <- sum(tb); p <- tb / n; pi_ <- rowSums(p); pj <- colSums(p); k <- nrow(tb)
    po <- sum(diag(p)); pe <- sum(pi_ * pj)
    t1 <- sum(sapply(1:k, function(i) p[i, i] * ((1 - pe) - (pj[i] + pi_[i]) * (1 - po))^2))
    t2 <- (1 - po)^2 * sum(sapply(1:k, function(i) sum(sapply(setdiff(1:k, i), function(j) p[i, j] * (pj[i] + pi_[j])^2))))
    t3 <- (po * pe - 2 * pe + po)^2
    se_explicit <- sqrt((t1 + t2 - t3) / (n * (1 - pe)^4))
    expect_equal(calc_analyze_kappa(tb)$kappa_se, se_explicit, tolerance = 1e-10)
  }
})

test_that("2x2: kappa, PABAK and the standard error under H0 equal epiR::epi.kappa()", {
  skip_if_not_installed("epiR")
  tb <- kappa_tables[[1]]
  r <- calc_analyze_kappa(tb)
  e <- suppressMessages(epiR::epi.kappa(tb, method = "fleiss", alternative = "two.sided", conf.level = 0.95))
  expect_equal(r$kappa, e$kappa$est[1], tolerance = 1e-8)
  expect_equal(r$pabak, e$pabak$est[1], tolerance = 1e-8)
  expect_equal(r$kappa / r$z_test_kappa0, e$kappa$se[1], tolerance = 1e-6)  # epiR's se is the null-hypothesis SE
})

test_that("kappa basics: agreement, chance agreement, perfect and chance-level agreement, label thresholds", {
  tb <- kappa_tables[[1]]; r <- calc_analyze_kappa(tb)
  expect_equal(r$observed_agreement, 0.85); expect_equal(r$expected_agreement, 0.5)
  expect_equal(r$kappa, 0.7)
  perfect <- calc_analyze_kappa(matrix(c(30, 0, 0, 70), 2, byrow = TRUE))
  expect_equal(perfect$kappa, 1); expect_equal(perfect$kappa_se, 0)
  chance <- calc_analyze_kappa(matrix(c(25, 25, 25, 25), 2, byrow = TRUE))
  expect_equal(chance$kappa, 0); expect_gt(chance$p_value_kappa0, 0.99)
  expect_true(is.na(calc_analyze_kappa(matrix(c(50, 0, 0, 0), 2, byrow = TRUE))$kappa)) # all in one cell: kappa undefined
  expect_equal(vapply(c(-0.1, 0, 0.2, 0.3, 0.5, 0.7, 0.9), analyze_kappa_label, character(1)),
               c("poor", "slight", "slight", "fair", "moderate", "substantial", "almost perfect"))
})

test_that("kappa input is validated", {
  expect_error(calc_analyze_kappa(matrix(1:6, 2)), "square")
  expect_error(calc_analyze_kappa(matrix(1, 7, 7)), "between 2 and 6")
  expect_error(calc_analyze_kappa(matrix(c(1, -1, 2, 3), 2)), "non-negative whole number")
  expect_error(calc_analyze_kappa(matrix(c(1.5, 1, 2, 3), 2)), "whole number")
  expect_error(calc_analyze_kappa(matrix(0, 2, 2)), "empty")
})

# ---- Trend -------------------------------------------------------------------------------------

test_that("chi-square for trend equals stats::prop.trend.test() with default and custom scores", {
  cases <- list(
    list(e = c(10, 20, 35, 50), n = c(100, 100, 100, 100), s = NULL),
    list(e = c(3, 8, 12), n = c(50, 60, 40), s = NULL),
    list(e = c(2, 5, 9, 15, 30), n = c(120, 110, 100, 90, 80), s = c(0, 1, 2, 4, 8)),
    list(e = c(30, 14, 6), n = c(80, 80, 80), s = c(1, 2, 3)))
  for (cs in cases) {
    r <- if (is.null(cs$s)) calc_analyze_trend(cs$e, cs$n) else calc_analyze_trend(cs$e, cs$n, cs$s)
    pt <- if (is.null(cs$s)) prop.trend.test(cs$e, cs$n) else prop.trend.test(cs$e, cs$n, score = cs$s)
    expect_equal(c(r$trend_chisq, r$trend_p), c(unname(pt$statistic), pt$p.value), tolerance = 1e-10)
  }
})

test_that("trend: direction follows the slope; the statistic is unchanged by reversing the order or rescaling the scores", {
  up <- calc_analyze_trend(c(10, 20, 35, 50), rep(100, 4)); down <- calc_analyze_trend(c(50, 35, 20, 10), rep(100, 4))
  expect_equal(up$trend_direction, "increasing"); expect_equal(down$trend_direction, "decreasing")
  expect_equal(up$trend_chisq, down$trend_chisq)
  scaled <- calc_analyze_trend(c(10, 20, 35, 50), rep(100, 4), scores = c(10, 20, 30, 40) * 7 + 3)
  expect_equal(up$trend_chisq, scaled$trend_chisq, tolerance = 1e-10)
  flat <- calc_analyze_trend(c(20, 20, 20), rep(100, 3)); expect_equal(flat$trend_chisq, 0); expect_equal(flat$trend_direction, "flat")
})

test_that("trend: per-group proportions come with Wilson intervals; no events leaves the test NA", {
  r <- calc_analyze_trend(c(10, 20, 35), rep(100, 3))
  w <- calc_analyze_ci_proportion(20, 100)
  expect_equal(c(r$group2_proportion, r$group2_wilson_lower, r$group2_wilson_upper), c(0.2, w$wilson_lower, w$wilson_upper))
  none <- calc_analyze_trend(c(0, 0, 0), rep(50, 3)); expect_true(is.na(none$trend_chisq))
})

test_that("trend input is validated", {
  expect_error(calc_analyze_trend(5, 10), "between 2 and 8")
  expect_error(calc_analyze_trend(c(1, 2), c(10, 10, 10)), "same length")
  expect_error(calc_analyze_trend(c(11, 2), c(10, 10)), "more events than subjects")
  expect_error(calc_analyze_trend(c(1, 2), c(0, 10)), "at least 1")
  expect_error(calc_analyze_trend(c(1, 2), c(10, 10), scores = c(3, 3)), "not all be equal")
  expect_error(calc_analyze_trend(c(-1, 2), c(10, 10)), "non-negative whole number")
})
