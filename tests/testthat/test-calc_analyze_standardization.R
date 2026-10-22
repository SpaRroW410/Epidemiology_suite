# Thrusfield (2007, pp. 63-64), the worked example in epiR::epi.directadj()'s help page: leptospirosis in dogs,
# cases and dog-years by sex (M, F) in Edinburgh and Glasgow, standard population 250 males + 250 females.
# Published reading: "The adjusted incidence rate of leptospirosis in Glasgow dogs is 26 (95% CI 20 to 34) cases
# per 100 dog-years at risk."
ed <- function(...) calc_analyze_dsr(c(15, 46), c(48, 212), c(250, 250), multiplier = 1, ...)
gl <- function(...) calc_analyze_dsr(c(53, 16), c(180, 71), c(250, 250), multiplier = 1, ...)

test_that("reproduces the published Thrusfield (2007) / epiR directly standardized rates", {
  g <- gl()
  expect_equal(round(100 * c(g$standardized_rate, g$standardized_rate_lower, g$standardized_rate_upper)), c(26, 20, 34))
  expect_equal(c(g$standardized_rate, g$standardized_rate_lower, g$standardized_rate_upper), c(0.2598983, 0.1964162, 0.3406224), tolerance = 1e-6)
  e <- ed()
  expect_equal(c(e$standardized_rate, e$standardized_rate_lower, e$standardized_rate_upper), c(0.2647406, 0.1866047, 0.3692766), tolerance = 1e-6)
  expect_equal(c(e$crude_rate, e$crude_rate_lower, e$crude_rate_upper), c(0.2346154, 0.1794622, 0.3013733), tolerance = 1e-6)
})

test_that("direct standardization equals epiR::epi.directadj() on several data sets, including a zero-event stratum", {
  skip_if_not_installed("epiR")
  sets <- list(
    list(d = c(15, 46), t = c(48, 212), s = c(250, 250)),
    list(d = c(2, 8, 25, 60, 90), t = c(5000, 8000, 9000, 7000, 3000), s = c(25000, 30000, 28000, 12000, 5000)),
    list(d = c(0, 3, 12), t = c(400, 700, 500), s = c(1, 2, 3)),
    list(d = c(10, 30, 70, 150), t = c(1e4, 8e3, 6e3, 3e3), s = c(40, 30, 20, 10)))
  for (st in sets) {
    k <- length(st$d)
    r <- calc_analyze_dsr(st$d, st$t, st$s, multiplier = 1)
    obs <- matrix(st$d, 1, dimnames = list("A", paste0("s", 1:k))); tar <- matrix(st$t, 1, dimnames = list("A", paste0("s", 1:k)))
    std <- matrix(st$s, 1, dimnames = list("", paste0("s", 1:k)))
    e <- suppressMessages(epiR::epi.directadj(obs, tar, std, units = 1, conf.level = 0.95))
    expect_equal(c(r$standardized_rate, r$standardized_rate_lower, r$standardized_rate_upper), as.numeric(e$adj.strata[1, c("est", "lower", "upper")]), tolerance = 1e-6)
    expect_equal(c(r$crude_rate, r$crude_rate_lower, r$crude_rate_upper), as.numeric(e$crude.strata[1, c("est", "lower", "upper")]), tolerance = 1e-6)
  }
})

test_that("identity: standardizing to the group's own person-time distribution gives the crude rate and its variance", {
  d <- c(5, 12, 30); t <- c(1000, 2000, 1500)
  r <- calc_analyze_dsr(d, t, t, multiplier = 1)
  expect_equal(r$standardized_rate, sum(d) / sum(t))
  # variance: sum (t_i/T)^2 d_i / t_i^2 = d / T^2, so the gamma interval is a function of d and T only
  w <- t / sum(t); v <- sum(w^2 * d / t^2)
  expect_equal(v, sum(d) / sum(t)^2)
})

test_that("the multiplier rescales rates; the standard population only matters through its proportions", {
  a <- calc_analyze_dsr(c(15, 46), c(48, 212), c(250, 250), multiplier = 1)
  b <- calc_analyze_dsr(c(15, 46), c(48, 212), c(1, 1), multiplier = 1000)
  expect_equal(b$standardized_rate, 1000 * a$standardized_rate)
  expect_equal(b$standardized_rate_lower, 1000 * a$standardized_rate_lower)
})

test_that("two groups: ratio and difference of directly standardized rates, SEs checked by simulation", {
  set.seed(9)
  lam_a <- c(0.002, 0.008, 0.02); lam_b <- c(0.003, 0.009, 0.015); ta <- c(30000, 20000, 15000); tb <- c(25000, 22000, 18000); std <- c(40, 35, 25)
  w <- std / sum(std)
  sim <- replicate(8000, {
    da <- rpois(3, lam_a * ta); db <- rpois(3, lam_b * tb)
    dsr_a <- sum(w * da / ta); dsr_b <- sum(w * db / tb)
    c(log(dsr_a / dsr_b), dsr_a - dsr_b)
  })
  da <- round(lam_a * ta); db <- round(lam_b * tb)       # expected counts as the observed data
  r <- calc_analyze_dsr(da, ta, std, db, tb, multiplier = 1)
  z <- qnorm(0.975)
  se_log <- (log(r$standardized_rate_ratio_upper) - log(r$standardized_rate_ratio_lower)) / (2 * z)
  se_diff <- (r$standardized_rate_difference_upper - r$standardized_rate_difference_lower) / (2 * z)
  expect_equal(se_log, sd(sim[1, ]), tolerance = 0.04)
  expect_equal(se_diff, sd(sim[2, ]), tolerance = 0.04)
  expect_equal(r$standardized_rate_ratio, r$standardized_rate / r$b_standardized_rate)
  expect_equal(r$standardized_rate_difference, r$standardized_rate - r$b_standardized_rate)
  expect_lt(r$standardized_rate_ratio_lower, r$standardized_rate_ratio); expect_gt(r$standardized_rate_ratio_upper, r$standardized_rate_ratio)
})

test_that("DSR input is validated", {
  expect_error(calc_analyze_dsr(5, 100, 10), "between 2 and 20")
  expect_error(calc_analyze_dsr(c(1, 2), c(10, 20, 30), c(1, 1)), "same strata")
  expect_error(calc_analyze_dsr(c(1, 2), c(10, 20), c(1, 1, 1)), "one per stratum")
  expect_error(calc_analyze_dsr(c(1, 2), c(10, 20), c(0, 0)), "positive total")
  expect_error(calc_analyze_dsr(c(1, 2), c(0, 20), c(1, 1)), "no person-time")
  expect_error(calc_analyze_dsr(c(0, 2), c(0, 20), c(1, 1)), "cannot be standardized")
  expect_error(calc_analyze_dsr(c(-1, 2), c(10, 20), c(1, 1)), "non-negative whole number")
  expect_error(calc_analyze_dsr(c(1, 2), c(10, 20), c(1, 1), events_b = c(1, 2)), "both events and person-time")
  expect_error(calc_analyze_dsr(c(1, 2), c(10, 20), c(1, 1), conf_level = 1))
})

# ---- SMR / indirect --------------------------------------------------------------------------

test_that("SMR exact interval and p-value equal stats::poisson.test(); mid-P limits satisfy their equation", {
  for (oe in list(c(58, 52), c(130, 140), c(3, 7.5), c(0, 2.2), c(25, 10))) {
    r <- calc_analyze_smr(oe[1], oe[2])
    pt <- poisson.test(oe[1], oe[2])
    expect_equal(c(r$smr, r$smr_exact_lower, r$smr_exact_upper), c(unname(pt$estimate), as.numeric(pt$conf.int)), tolerance = 1e-8)
    expect_equal(r$exact_test_p, pt$p.value, tolerance = 1e-8)
    if (oe[1] > 0) {
      l <- r$smr_mid_p_lower * oe[2]; u <- r$smr_mid_p_upper * oe[2]
      expect_equal(ppois(oe[1], l, lower.tail = FALSE) + 0.5 * dpois(oe[1], l), 0.025, tolerance = 1e-8)
      expect_equal(ppois(oe[1] - 1, u) + 0.5 * dpois(oe[1], u), 0.025, tolerance = 1e-8)
    }
    expect_lte(r$smr_mid_p_upper - r$smr_mid_p_lower, r$smr_exact_upper - r$smr_exact_lower)
  }
})

test_that("indirect standardization: expected events are sum(reference rate x person-time), as in epiR's tuberculosis example", {
  # epiR::epi.indirectadj() example 2: area A has 550 beef and 450 dairy herds, standard risks 0.025 and 0.085 (per herd) -> 52 expected
  a <- calc_analyze_indirect(c(550, 450), c(0.025, 0.085), observed = 58, multiplier = 1)
  expect_equal(a$expected, 52); expect_equal(a$smr, 58 / 52)
  b <- calc_analyze_indirect(c(500, 1500), c(25, 85), observed = 130, multiplier = 1000)  # same rates per 1000
  expect_equal(b$expected, 140); expect_equal(b$smr, 130 / 140)
  skip_if_not_installed("epiR")
  e <- suppressMessages(epiR::epi.indirectadj(
    obs = matrix(c(58, 130), 2, dimnames = list(c("A", "B"), "")),
    pop = matrix(c(550, 450, 500, 1500), 2, byrow = TRUE, dimnames = list(c("A", "B"), c("Beef", "Dairy"))),
    std = matrix(c(0.025, 0.085, 0.060), 1, dimnames = list("", c("Beef", "Dairy", "Total"))), units = 100))
  expect_equal(c(a$observed, a$expected, a$smr), as.numeric(e$smr.strata["A", c("obs", "exp", "est")]), tolerance = 1e-8)
  expect_equal(c(b$observed, b$expected, b$smr), as.numeric(e$smr.strata["B", c("obs", "exp", "est")]), tolerance = 1e-8)
})

test_that("SMR below, at and above 1: interval and test agree", {
  hi <- calc_analyze_smr(40, 20); lo <- calc_analyze_smr(5, 20)
  expect_gt(hi$smr_exact_lower, 1); expect_lt(hi$exact_test_p, 0.05)
  expect_lt(lo$smr_exact_upper, 1); expect_lt(lo$exact_test_p, 0.05)
  at <- calc_analyze_smr(20, 20); expect_lt(at$smr_exact_lower, 1); expect_gt(at$smr_exact_upper, 1); expect_equal(at$exact_test_p, 1)
})

test_that("SMR / indirect input is validated", {
  expect_error(calc_analyze_smr(-1, 5), "non-negative whole number")
  expect_error(calc_analyze_smr(5, 0), "positive")
  expect_error(calc_analyze_smr(2.5, 5), "whole number")
  expect_error(calc_analyze_smr(5, 5, conf_level = 1))
  expect_error(calc_analyze_indirect(c(10, 20), c(1, 2, 3), 5), "every stratum")
  expect_error(calc_analyze_indirect(c(10, -20), c(1, 2), 5), "non-negative")
  expect_error(calc_analyze_indirect(c(10, 20), c(0, 0), 5), "expected number of events is zero")
  expect_error(calc_analyze_indirect(5, 1, 5), "between 2 and 20")
})

test_that("strata display table and results are well formed", {
  tb <- analyze_dsr_strata_table(c(15, 46), c(48, 212), c(250, 250), multiplier = 1)
  expect_equal(tb$standard_weight, c(0.5, 0.5)); expect_equal(sum(tb$contribution), ed()$standardized_rate)
  expect_s3_class(ed(), "ss_result"); expect_s3_class(calc_analyze_smr(5, 4), "ss_result")
})

# ---- SMR: several interval methods side by side ----------------------------------------------
# Reference values computed with epiR 3.0.0's epi.smr() (CRAN, 13 Oct 2026; the version in this project's
# renv.lock predates epi.smr) for each (O, E): Byar CI and test, Rothman-Greenland, Vandenbroucke (95%),
# chi-square test, and -- for O <= 5, where epi.smr allows it -- the mid-P CI and p-value.
epi_smr_ref <- list(
  list(o = 4,   e = 3.3, byar = c(0.32610618, 3.1032584), byar_z = 0.20600097, byar_p = 0.83679016, rg = c(0.45493074, 3.2295858),
       van = c(0.31528386, 2.6909978), chi = c(0.14848485, 0.69998752), mid = c(0.38513966, 2.9237665), mid_p = 0.65707143),
  list(o = 5,   e = 2.1, byar = c(0.76730844, 5.5562686), byar_z = 1.5354444, byar_p = 0.1246747, rg = c(0.9910186, 5.7203106),
       van = c(0.75131048, 4.9252273), chi = c(4.0047619, 0.045371905), mid = c(0.87237791, 5.2773436), mid_p = 0.082575195),
  list(o = 2,   e = 7.5, byar = c(0.029950028, 0.96278253), byar_z = -2.0485615, byar_p = 0.040505012, rg = c(0.066692708, 1.0662502),
       van = c(0.025140941, 0.76428965), chi = c(4.0333333, 0.044609718), mid = c(0.044709798, 0.88106124), mid_p = 0.024957932),
  list(o = 12,  e = 8.2, byar = c(0.75530608, 2.5564461), byar_z = 1.1425329, byar_p = 0.2532326, rg = c(0.83108735, 2.5768439),
       van = c(0.75254272, 2.4085218), chi = c(1.7609756, 0.18450287)),
  list(o = 58,  e = 52,  byar = c(0.84690802, 1.4419191), byar_z = 0.77291451, byar_p = 0.43957298, rg = c(0.86229608, 1.442756),
       van = c(0.84680238, 1.420904), chi = c(0.69230769, 0.40538056)),
  list(o = 25,  e = 10,  byar = c(1.6174266, 3.6906451), byar_z = 3.8812388, byar_p = 0.00010392572, rg = c(1.6892725, 3.6998176),
       van = c(1.6160545, 3.5760185), chi = c(22.5, 2.101436e-06)))

test_that("SMR interval methods and tests equal epiR 3.0.0's epi.smr() reference values", {
  for (cs in epi_smr_ref) {
    r <- calc_analyze_smr(cs$o, cs$e); info <- paste(cs$o, cs$e)
    expect_equal(c(r$smr_byar_lower, r$smr_byar_upper), cs$byar, tolerance = 1e-6, info = info)
    expect_equal(c(r$byar_z, r$byar_test_p), c(cs$byar_z, cs$byar_p), tolerance = 1e-6, info = info)
    expect_equal(c(r$smr_rothman_greenland_lower, r$smr_rothman_greenland_upper), cs$rg, tolerance = 1e-6, info = info)
    expect_equal(c(r$smr_vandenbroucke_lower, r$smr_vandenbroucke_upper), cs$van, tolerance = 1e-6, info = info)
    expect_equal(c(r$chisq, r$chisq_p), cs$chi, tolerance = 1e-6, info = info)
    if (!is.null(cs$mid)) {
      # epiR solves for the limits with uniroot()'s default tolerance (~1e-4); ours is solved to 1e-12 and
      # checked against the defining equation in an earlier test, so agree to 1e-4 only
      expect_equal(c(r$smr_mid_p_lower, r$smr_mid_p_upper), cs$mid, tolerance = 1e-4, info = info)
      expect_equal(r$mid_p_test_p, cs$mid_p, tolerance = 1e-6, info = info)
    }
  }
})

test_that("epiR's own documented SMR example (4 observed, 3.3 expected, mid-P) is reproduced: 1.2 (95% CI 0.38 to 2.9), p = 0.657", {
  r <- calc_analyze_smr(4, 3.3)
  expect_equal(round(c(r$smr, r$smr_mid_p_lower, r$smr_mid_p_upper), 2), c(1.21, 0.39, 2.92))   # epiR's text rounds 0.385 -> 0.38
  expect_equal(round(r$mid_p_test_p, 3), 0.657)
})

test_that("SMR intervals agree with DescTools::PoissonCI(): exact, and the a + 1/2 Byar form is a different (also published) variant", {
  skip_if_not_installed("DescTools")
  for (oe in list(c(4, 3.3), c(12, 8.2), c(58, 52), c(25, 10))) {
    r <- calc_analyze_smr(oe[1], oe[2])
    ex <- DescTools::PoissonCI(oe[1], n = 1, method = "exact")
    expect_equal(c(r$smr_exact_lower, r$smr_exact_upper), unname(ex[1, c("lwr.ci", "upr.ci")]) / oe[2], tolerance = 1e-8)
  }
})

test_that("Byar tracks the exact limits closely for O >= 12; Rothman-Greenland is undefined at O = 0; limits are never negative", {
  for (oe in list(c(12, 8.2), c(58, 52), c(130, 140), c(25, 10))) {
    r <- calc_analyze_smr(oe[1], oe[2])
    expect_equal(r$smr_byar_lower, r$smr_exact_lower, tolerance = 0.01); expect_equal(r$smr_byar_upper, r$smr_exact_upper, tolerance = 0.01)
  }
  z <- calc_analyze_smr(0, 2.4)
  expect_true(is.na(z$smr_rothman_greenland_lower) && is.na(z$smr_rothman_greenland_upper))
  expect_equal(c(z$smr_exact_lower, z$smr_mid_p_lower, z$smr_byar_lower, z$smr_vandenbroucke_lower, z$smr_wald_lower), rep(0, 5))
  expect_equal(z$smr_wald_upper, 0)   # the Wald interval's zero-width failure at O = 0
  for (oe in list(c(1, 0.9), c(2, 7.5), c(0, 5)))
    expect_true(all(unlist(calc_analyze_smr(oe[1], oe[2])[c("smr_exact_lower", "smr_byar_lower", "smr_vandenbroucke_lower", "smr_wald_lower")]) >= 0))
})

test_that("method intervals are ordered as expected: exact is the widest of the exact family, all contain the SMR (O >= 12)", {
  r <- calc_analyze_smr(25, 10)
  expect_lt(r$smr_exact_lower, r$smr_mid_p_lower); expect_gt(r$smr_exact_upper, r$smr_mid_p_upper)
  for (m in c("exact", "mid_p", "byar", "rothman_greenland", "vandenbroucke", "wald")) {
    expect_true(r[[paste0("smr_", m, "_lower")]] < 2.5 && 2.5 < r[[paste0("smr_", m, "_upper")]], info = m)
  }
})

test_that("SMR display table lists the six methods with notes", {
  tb <- analyze_smr_table(calc_analyze_smr(58, 52))
  expect_equal(nrow(tb), 6); expect_true(all(nzchar(tb$note)))
  expect_match(tb$method[1], "Exact"); expect_match(tb$method[6], "Wald")
})
