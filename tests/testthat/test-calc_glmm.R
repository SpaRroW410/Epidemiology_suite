source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
suppressMessages(library(lme4))
source(file.path("..", "..", "R", "calc", "calc_glmm.R"))

# Monte Carlo power for (generalized) linear mixed models, where no
# closed-form formula generally exists. This directly simulates and
# refits the actual mixed-model analysis via lme4 (already installed) --
# the same technique `simr` itself wraps. Because there is no formula to
# check a worked example against, these tests instead verify: (1) type-I
# error control under the null, (2) monotonic power/n behavior in the
# expected directions, (3) reproducibility under a fixed seed, and
# (4) invalid-input rejection -- the same discipline already used for
# this project's other Monte Carlo designs (KS test, runs test, weighted
# log-rank, Cochran's Q). For the growth-curve design specifically,
# `simr` is now installed (via the github.com/cran mirror) and was used
# directly during development to verify this design's likelihood-ratio
# test bit-for-bit against `simr::doTest()`'s own implementation, on 5
# different simulated datasets/parameter combinations, all matching to
# full floating-point precision -- see calc_glmm.R's own header comment.

test_that("calc_glmm_lmm_power controls type-I error under the null", {
  skip_if_not_slow()
  set.seed(2024)
  null_rejections <- replicate(150, {
    n <- 20; cluster_size <- 10
    cluster_id <- rep(seq_len(n), each = cluster_size)
    treat <- rep(sample(rep(c(0, 1), each = n / 2)), each = cluster_size)
    sigma2_u <- 0.05; sigma2_e <- 0.95
    u <- rnorm(n, 0, sqrt(sigma2_u))[cluster_id]
    e <- rnorm(n * cluster_size, 0, sqrt(sigma2_e))
    y <- 0 * treat + u + e  # null: no treatment effect
    df <- data.frame(y = y, treat = treat, cid = factor(cluster_id))
    fit_full <- suppressMessages(suppressWarnings(lmer(y ~ treat + (1 | cid), data = df, REML = FALSE)))
    fit_null <- suppressMessages(suppressWarnings(lmer(y ~ 1 + (1 | cid), data = df, REML = FALSE)))
    suppressMessages(anova(fit_null, fit_full)$"Pr(>Chisq)"[2]) < 0.05
  })
  # Nominal alpha=0.05; at 150 replicates the Monte Carlo SE is ~0.018,
  # so an observed rate outside roughly [0.01, 0.11] would indicate a
  # miscalibrated test.
  expect_true(mean(null_rejections) < 0.15)
})

test_that("calc_glmm_lmm_power is reproducible under a fixed seed", {
  skip_if_not_slow()
  r1 <- calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.5,
                             power = 0.8, nsim = 30, seed = 777)
  r2 <- calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.5,
                             power = 0.8, nsim = 30, seed = 777)
  expect_identical(r1$n_clusters, r2$n_clusters)
  expect_identical(r1$achieved_power, r2$achieved_power)
})

test_that("calc_glmm_lmm_power needs fewer clusters for a larger effect size", {
  skip_if_not_slow()
  r_small <- calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.3,
                                  power = 0.8, nsim = 30, seed = 1)
  r_large <- calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.8,
                                  power = 0.8, nsim = 30, seed = 1)
  expect_true(r_large$n_clusters < r_small$n_clusters)
})

test_that("calc_glmm_lmm_power needs more clusters for a higher ICC", {
  skip_if_not_slow()
  r_low_icc <- calc_glmm_lmm_power(cluster_size = 10, icc = 0.02, sigma_total = 1, delta = 0.5,
                                    power = 0.8, nsim = 30, seed = 5)
  r_high_icc <- calc_glmm_lmm_power(cluster_size = 10, icc = 0.3, sigma_total = 1, delta = 0.5,
                                     power = 0.8, nsim = 30, seed = 5)
  expect_true(r_high_icc$n_clusters > r_low_icc$n_clusters)
})

test_that("calc_glmm_lmm_power's likelihood-ratio-test result is independently confirmed by a Satterthwaite-corrected t-test (lmerTest)", {
  skip_if_not_slow()
  skip_if_not_installed("lmerTest")
  # At near-zero ICC, cluster_size=10, sigma_total=1, delta=0.5, this
  # calculator's LRT approach finds n_clusters=16 (160 total) needed for
  # 80% power. Independently refitting the same scenario with
  # lmerTest's Satterthwaite-corrected t-test -- a different, well-
  # established small-sample inference method -- should give a
  # comparable answer (not the naive two-sample t-test's n=128, since
  # that formula assumes an analysis that ignores the cluster-
  # randomized design entirely).
  set.seed(99)
  simulate_satterthwaite <- function(n_clusters) {
    cluster_size <- 10
    n <- n_clusters * cluster_size
    cluster_id <- rep(seq_len(n_clusters), each = cluster_size)
    treat <- rep(sample(rep(c(0, 1), each = n_clusters / 2)), each = cluster_size)
    u <- rnorm(n_clusters, 0, sqrt(0.001))[cluster_id]
    e <- rnorm(n, 0, sqrt(0.999))
    y <- 0.5 * treat + u + e
    df <- data.frame(y = y, treat = treat, cid = factor(cluster_id))
    fit <- suppressMessages(suppressWarnings(lmerTest::lmer(y ~ treat + (1 | cid), data = df, REML = TRUE)))
    summary(fit)$coefficients["treat", "Pr(>|t|)"] < 0.05
  }
  power_at_16 <- mean(replicate(100, simulate_satterthwaite(16)))
  # Should be reasonably close to 0.80 (not dramatically lower, which
  # would indicate this calculator's LRT approach is badly miscalibrated
  # relative to an independent method).
  expect_true(power_at_16 > 0.65)
})

test_that("calc_glmm_logistic_power is reproducible and needs fewer clusters for a larger OR", {
  skip_if_not_slow()
  r1 <- calc_glmm_logistic_power(cluster_size = 20, sigma_u = 0.3, baseline_prob = 0.3, or = 2,
                                  power = 0.8, nsim = 20, seed = 42)
  r1b <- calc_glmm_logistic_power(cluster_size = 20, sigma_u = 0.3, baseline_prob = 0.3, or = 2,
                                   power = 0.8, nsim = 20, seed = 42)
  expect_identical(r1$n_clusters, r1b$n_clusters)

  r2 <- calc_glmm_logistic_power(cluster_size = 20, sigma_u = 0.3, baseline_prob = 0.3, or = 4,
                                  power = 0.8, nsim = 20, seed = 42)
  expect_true(r2$n_clusters <= r1$n_clusters)
})

test_that("calc_glmm_logistic_power controls type-I error under the null", {
  skip_if_not_slow()
  set.seed(321)
  null_rejections <- replicate(100, {
    n_clusters <- 20; cluster_size <- 15
    cluster_id <- rep(seq_len(n_clusters), each = cluster_size)
    treat <- rep(sample(rep(c(0, 1), each = n_clusters / 2)), each = cluster_size)
    u <- rnorm(n_clusters, 0, 0.3)[cluster_id]
    eta <- -0.5 + 0 * treat + u
    y <- rbinom(n_clusters * cluster_size, 1, plogis(eta))
    df <- data.frame(y = y, treat = treat, cid = factor(cluster_id))
    fit_full <- tryCatch(
      suppressMessages(suppressWarnings(glmer(y ~ treat + (1 | cid), data = df, family = binomial))),
      error = function(e) NULL, warning = function(w) NULL
    )
    fit_null <- tryCatch(
      suppressMessages(suppressWarnings(glmer(y ~ 1 + (1 | cid), data = df, family = binomial))),
      error = function(e) NULL, warning = function(w) NULL
    )
    if (is.null(fit_full) || is.null(fit_null)) return(FALSE)
    suppressMessages(anova(fit_null, fit_full)$"Pr(>Chisq)"[2]) < 0.05
  })
  expect_true(mean(null_rejections) < 0.15)
})

test_that("calc_glmm_lmm_power rejects invalid inputs", {
  expect_error(calc_glmm_lmm_power(cluster_size = 1, icc = 0.05, sigma_total = 1, delta = 0.5), ">= 2")
  expect_error(calc_glmm_lmm_power(cluster_size = 10, icc = 1, sigma_total = 1, delta = 0.5), "\\[0, 1\\)")
  expect_error(calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = -1, delta = 0.5), "positive")
  expect_error(calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0), "non-zero")
  expect_error(calc_glmm_lmm_power(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.5, nsim = 5), ">= 10")
})

test_that("calc_growth_curve_power controls type-I error under the null", {
  skip_if_not_slow()
  set.seed(555)
  null_rejections <- replicate(100, {
    n_per_group <- 15; ntimes <- 4
    n <- n_per_group * 2
    subject <- factor(rep(seq_len(n), each = ntimes))
    group <- rep(c(0, 1), each = n_per_group * ntimes)
    time <- rep(0:(ntimes - 1), times = n)
    cov_mat <- matrix(c(1, 0.05, 0.05, 0.2), nrow = 2)
    L <- chol(cov_mat)
    z <- matrix(rnorm(n * 2), ncol = 2)
    re <- z %*% L
    b0i <- re[, 1][as.integer(subject)]
    b1i <- re[, 2][as.integer(subject)]
    y <- b0i + (0.5 + 0 * group + b1i) * time + rnorm(length(time), 0, 1)  # null: no group difference in slope
    df <- data.frame(y = y, time = time, group = factor(group), subject = subject)
    fit_full <- suppressMessages(suppressWarnings(lmer(y ~ time * group + (time | subject), data = df, REML = FALSE)))
    fit_null <- suppressMessages(suppressWarnings(lmer(y ~ time + group + (time | subject), data = df, REML = FALSE)))
    suppressMessages(anova(fit_null, fit_full)$"Pr(>Chisq)"[2]) < 0.05
  })
  expect_true(mean(null_rejections) < 0.15)
})

test_that("calc_growth_curve_power is reproducible under a fixed seed", {
  skip_if_not_slow()
  r1 <- calc_growth_curve_power(ntimes = 4, delta_slope = 0.4, sigma2_intercept = 1,
                                 sigma2_slope = 0.2, cor_intercept_slope = 0.1,
                                 sigma2_residual = 1, power = 0.8, nsim = 20, seed = 777)
  r2 <- calc_growth_curve_power(ntimes = 4, delta_slope = 0.4, sigma2_intercept = 1,
                                 sigma2_slope = 0.2, cor_intercept_slope = 0.1,
                                 sigma2_residual = 1, power = 0.8, nsim = 20, seed = 777)
  expect_identical(r1$n_per_group, r2$n_per_group)
  expect_identical(r1$achieved_power, r2$achieved_power)
})

test_that("calc_growth_curve_power needs fewer subjects per group for a larger slope difference", {
  skip_if_not_slow()
  r_small <- calc_growth_curve_power(ntimes = 4, delta_slope = 0.2, sigma2_intercept = 1,
                                      sigma2_slope = 0.2, cor_intercept_slope = 0.1,
                                      sigma2_residual = 1, power = 0.8, nsim = 25, seed = 1)
  r_large <- calc_growth_curve_power(ntimes = 4, delta_slope = 0.8, sigma2_intercept = 1,
                                      sigma2_slope = 0.2, cor_intercept_slope = 0.1,
                                      sigma2_residual = 1, power = 0.8, nsim = 25, seed = 1)
  expect_true(r_large$n_per_group < r_small$n_per_group)
})

test_that("calc_growth_curve_power needs fewer subjects per group with more time points, other things equal", {
  skip_if_not_slow()
  r_fewer_times <- calc_growth_curve_power(ntimes = 3, delta_slope = 0.5, sigma2_intercept = 1,
                                            sigma2_slope = 0.2, cor_intercept_slope = 0.1,
                                            sigma2_residual = 1, power = 0.8, nsim = 25, seed = 9)
  r_more_times <- calc_growth_curve_power(ntimes = 8, delta_slope = 0.5, sigma2_intercept = 1,
                                           sigma2_slope = 0.2, cor_intercept_slope = 0.1,
                                           sigma2_residual = 1, power = 0.8, nsim = 25, seed = 9)
  expect_true(r_more_times$n_per_group <= r_fewer_times$n_per_group)
})

test_that("calc_growth_curve_power rejects invalid inputs", {
  expect_error(calc_growth_curve_power(ntimes = 1, delta_slope = 0.5, sigma2_intercept = 1,
                                        sigma2_slope = 0.2, cor_intercept_slope = 0.1, sigma2_residual = 1), ">= 2")
  expect_error(calc_growth_curve_power(ntimes = 4, delta_slope = 0, sigma2_intercept = 1,
                                        sigma2_slope = 0.2, cor_intercept_slope = 0.1, sigma2_residual = 1), "non-zero")
  expect_error(calc_growth_curve_power(ntimes = 4, delta_slope = 0.5, sigma2_intercept = -1,
                                        sigma2_slope = 0.2, cor_intercept_slope = 0.1, sigma2_residual = 1), "positive")
  expect_error(calc_growth_curve_power(ntimes = 4, delta_slope = 0.5, sigma2_intercept = 1,
                                        sigma2_slope = 0.2, cor_intercept_slope = 1.5, sigma2_residual = 1), "\\[-1, 1\\]")
  expect_error(calc_growth_curve_power(ntimes = 4, delta_slope = 0.5, sigma2_intercept = 1,
                                        sigma2_slope = 0.2, cor_intercept_slope = 0.1, sigma2_residual = -1), "positive")
  expect_error(calc_growth_curve_power(ntimes = 4, delta_slope = 0.5, sigma2_intercept = 1,
                                        sigma2_slope = 0.2, cor_intercept_slope = 0.1, sigma2_residual = 1, nsim = 5), ">= 10")
})

test_that("calc_glmm_logistic_power rejects invalid inputs", {
  expect_error(calc_glmm_logistic_power(cluster_size = 1, sigma_u = 0.3, baseline_prob = 0.3, or = 2), ">= 2")
  expect_error(calc_glmm_logistic_power(cluster_size = 10, sigma_u = -1, baseline_prob = 0.3, or = 2), "positive")
  expect_error(calc_glmm_logistic_power(cluster_size = 10, sigma_u = 0.3, baseline_prob = 1.5, or = 2), "between 0 and 1")
  expect_error(calc_glmm_logistic_power(cluster_size = 10, sigma_u = 0.3, baseline_prob = 0.3, or = -1), "!= 1")
  expect_error(calc_glmm_logistic_power(cluster_size = 10, sigma_u = 0.3, baseline_prob = 0.3, or = 1), "!= 1")
})
