# Stepped-wedge, binary outcome (TRIAL-28). Reference: swCRTdesign::swGlmPwr(), the authors' function for Xia et al. 2021.

sw_ref <- function(cps, n, p0, p1, tau, tm = 0, alpha = 0.05) {
  d <- swCRTdesign::swDsn(cps)
  swCRTdesign::swGlmPwr(d, distn = "binomial", n = n, fixed.intercept = qlogis(p0), fixed.treatment.effect = qlogis(p1) - qlogis(p0),
                        fixed.time.effect = tm, tau = tau, alpha = alpha, silent = TRUE)
}

test_that("power equals swCRTdesign::swGlmPwr() over random settings", {
  skip_if_not_installed("swCRTdesign")
  set.seed(1)
  for (i in 1:8) {
    s <- sample(2:5, 1); k <- sample(1:4, 1); n <- sample(10:80, 1)
    p0 <- runif(1, 0.05, 0.5); p1 <- min(0.95, max(0.02, p0 + runif(1, -0.15, 0.15))); tau <- runif(1, 0.05, 0.6); tm <- runif(1, -0.3, 0.3)
    if (abs(p1 - p0) < 0.02) next
    mine <- calc_stepped_wedge_binary(p0, p1, n, s, tau, time_effect = tm, nclusters = k)$achieved_power
    expect_equal(mine, as.numeric(sw_ref(rep(k, s), n, p0, p1, tau, tm)), tolerance = 1e-8)
  }
})

test_that("the clusters found are the smallest that reach the power, and power rises with clusters", {
  r <- calc_stepped_wedge_binary(0.2, 0.14, 50, 3, 0.2, power = 0.8)
  expect_gte(r$achieved_power, 0.8)
  expect_lt(calc_stepped_wedge_binary(0.2, 0.14, 50, 3, 0.2, nclusters = r$nclusters - 1)$achieved_power, 0.8)
  expect_equal(r$total_clusters, r$nclusters * 3)
  expect_equal(r$odds_ratio, (0.14 / 0.86) / (0.2 / 0.8))
})

test_that("inputs are checked", {
  expect_error(calc_stepped_wedge_binary(0.2, 0.2, 50, 3, 0.2), "no effect")
  expect_error(calc_stepped_wedge_binary(0.2, 0.1, 50, 1, 0.2), "nsteps")
  expect_error(calc_stepped_wedge_binary(0.2, 0.1, 50, 3, -1), "tau")
  expect_error(calc_stepped_wedge_binary(1.2, 0.1, 50, 3, 0.2), "p0")
})
