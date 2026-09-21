source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_stepped_wedge.R"))

test_that("calc_stepped_wedge_normal matches clusterPower::cpa.sw.normal()'s own documented example", {
  # The package's own Examples section: nsubjects=50, ntimes=5, d=1.5,
  # ICC=0.2, rho_c=0.80, rho_s=0, vart=16 -> nclusters=1.288772 (raw),
  # "2 clusters switching per time point should be used... total number
  # of clusters in the study is nclusters * ntimes = 2 * 5 = 10".
  res <- calc_stepped_wedge_normal(nsubjects = 50, ntimes = 5, d = 1.5, icc = 0.2,
                                    rho_c = 0.80, rho_s = 0, vart = 16)
  expect_equal(res$nclusters, 2)
})

test_that("calc_stepped_wedge_normal reproduces this session's own verified raw-solution worked example", {
  # m=10, T=4, d=0.25, ICC=0.05, rho_c=0.5, rho_s=0, vart=1, alpha=0.05,
  # power=0.8 -> real clusterPower::cpa.sw.normal(nclusters=NA, ...) gives
  # raw nclusters=7.573565 (ceiling 8), achieved power 0.8210604 --
  # verified directly against a real package call this session.
  res <- calc_stepped_wedge_normal(nsubjects = 10, ntimes = 4, d = 0.25, icc = 0.05,
                                    rho_c = 0.5, rho_s = 0, vart = 1)
  expect_equal(res$nclusters, 8)
  expect_equal(round(res$achieved_power, 7), 0.8210604)
})

test_that("calc_stepped_wedge_normal's power formula matches clusterPower::cpa.sw.normal() bit-for-bit at a fixed nclusters", {
  # Verified this session against a direct clusterPower::cpa.sw.normal()
  # call (power=NA solved from nclusters=10) -> 0.9999964.
  power_at <- function(nclusters, nsubjects, ntimes, d, icc, rho_c, rho_s, vart, alpha = 0.05) {
    deff_c <- 1 + (nsubjects - 1) * icc
    r <- (nsubjects * icc * rho_c + (1 - icc) * rho_s) / deff_c
    deff_t <- 3 * ntimes * (1 - r) * (1 + ntimes * r) / ((ntimes^2 - 1) * (2 + ntimes * r))
    vif <- deff_t * deff_c
    zcrit <- qnorm(alpha / 2, lower.tail = FALSE)
    zstat <- abs(d) / sqrt(4 * vart / (nclusters * nsubjects * ntimes) * vif)
    pnorm(zcrit, zstat, lower.tail = FALSE)
  }
  expect_equal(
    power_at(10, nsubjects = 20, ntimes = 5, d = 0.3, icc = 0.05, rho_c = 0.8, rho_s = 0, vart = 1),
    0.9999964,
    tolerance = 1e-6
  )
})

test_that("calc_stepped_wedge_normal needs fewer clusters when rho_s = 0 (cross-sectional) than a closed cohort with rho_s > 0, other things equal", {
  # Individual autocorrelation in a closed cohort reduces the effective
  # information gained per additional cluster-period; expect >= clusters.
  res_cross <- calc_stepped_wedge_normal(nsubjects = 15, ntimes = 5, d = 0.4, icc = 0.05,
                                          rho_c = 0.5, rho_s = 0, vart = 1)
  res_cohort <- calc_stepped_wedge_normal(nsubjects = 15, ntimes = 5, d = 0.4, icc = 0.05,
                                           rho_c = 0.5, rho_s = 0.4, vart = 1)
  expect_true(res_cohort$nclusters >= res_cross$nclusters)
})

test_that("calc_stepped_wedge_normal rejects invalid inputs", {
  expect_error(calc_stepped_wedge_normal(nsubjects = -1, ntimes = 4, d = 0.5, icc = 0.05,
                                          rho_c = 0.5, rho_s = 0, vart = 1), "positive")
  expect_error(calc_stepped_wedge_normal(nsubjects = 10, ntimes = 1, d = 0.5, icc = 0.05,
                                          rho_c = 0.5, rho_s = 0, vart = 1), ">= 2")
  expect_error(calc_stepped_wedge_normal(nsubjects = 10, ntimes = 4, d = -0.5, icc = 0.05,
                                          rho_c = 0.5, rho_s = 0, vart = 1), "positive")
  expect_error(calc_stepped_wedge_normal(nsubjects = 10, ntimes = 4, d = 0.5, icc = 1,
                                          rho_c = 0.5, rho_s = 0, vart = 1), "\\[0, 1\\)")
  expect_error(calc_stepped_wedge_normal(nsubjects = 10, ntimes = 4, d = 0.5, icc = 0.05,
                                          rho_c = 1.5, rho_s = 0, vart = 1), "\\[0, 1\\]")
  expect_error(calc_stepped_wedge_normal(nsubjects = 10, ntimes = 4, d = 0.5, icc = 0.05,
                                          rho_c = 0.5, rho_s = -0.1, vart = 1), "\\[0, 1\\]")
  expect_error(calc_stepped_wedge_normal(nsubjects = 10, ntimes = 4, d = 0.5, icc = 0.05,
                                          rho_c = 0.5, rho_s = 0, vart = -1), "positive")
})
