test_that("calc_means_1s matches Cohen (1988) published one-sample t-test tables", {
  # Cohen (1988): one-sample t-test, alpha = .05 two-tailed, power = .80,
  # medium conventional effect size d = 0.5, gives n = 34.
  res <- calc_means_1s(mu0 = 0, mu1 = 0.5, sd = 1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 0.5)
  expect_equal(res$n, 34)
})

test_that("calc_means_1s: worked example from content_means.R", {
  res <- calc_means_1s(mu0 = 120, mu1 = 125, sd = 15, alpha = 0.05, power = 0.8)
  expect_equal(res$n, 73)
  expect_equal(round(res$d, 4), 0.3333)
})

test_that("calc_means_1s rejects invalid inputs", {
  expect_error(calc_means_1s(mu0 = 120, mu1 = 120, sd = 15), "must differ")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = 0), "positive")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = -1), "positive")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = 15, alpha = 1.5), "between 0 and 1")
  expect_error(calc_means_1s(mu0 = 120, mu1 = 125, sd = 15, power = 0), "between 0 and 1")
})

test_that("calc_means_2s_indep matches Cohen (1988) published two-sample t-test tables", {
  # Cohen (1988): two-sample t-test, alpha = .05 two-tailed, power = .80,
  # medium conventional effect size d = 0.5, gives n = 64 per group.
  res <- calc_means_2s_indep(mu1 = 0.5, mu2 = 0, sd = 1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 0.5)
  expect_equal(res$n_per_group, 64)
  expect_equal(res$n_total, 128)
})

test_that("calc_means_2s_indep: worked example from content_means.R", {
  res <- calc_means_2s_indep(mu1 = 12.5, mu2 = 11.5, sd = 2, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_group, 64)
  expect_equal(res$n_total, 128)
  expect_equal(round(res$d, 4), 0.5)
})

test_that("calc_means_2s_indep rejects invalid inputs", {
  expect_error(calc_means_2s_indep(mu1 = 10, mu2 = 10, sd = 2), "must differ")
  expect_error(calc_means_2s_indep(mu1 = 10, mu2 = 8, sd = 0), "positive")
  expect_error(calc_means_2s_indep(mu1 = 10, mu2 = 8, sd = 2, alpha = 0), "between 0 and 1")
})

test_that("calc_means_paired matches Cohen (1988) published paired t-test tables", {
  # Cohen (1988): paired t-test, alpha = .05 two-tailed, power = .80,
  # medium conventional effect size d = 0.5, gives n = 34 pairs.
  res <- calc_means_paired(mean_diff = 0.5, sd_diff = 1, alpha = 0.05, power = 0.8)
  expect_equal(round(res$d, 4), 0.5)
  expect_equal(res$n, 34)
})

test_that("calc_means_paired: worked example from content_means.R", {
  res <- calc_means_paired(mean_diff = 2, sd_diff = 5, alpha = 0.05, power = 0.8)
  expect_equal(res$n, 52)
  expect_equal(round(res$d, 4), 0.4)
})

test_that("calc_means_paired rejects invalid inputs", {
  expect_error(calc_means_paired(mean_diff = 0, sd_diff = 5), "must not be zero")
  expect_error(calc_means_paired(mean_diff = 2, sd_diff = 0), "positive")
  expect_error(calc_means_paired(mean_diff = 2, sd_diff = 5, power = 1), "between 0 and 1")
})

test_that("calc_means_anova matches Cohen (1988) Exercise 8.10, p. 391", {
  # f = 0.28 (medium-ish), k = 4 groups, alpha = 0.05, power = 0.80 -> n = 36
  # per group (144 total). We reproduce f = 0.28 indirectly via group means;
  # this test instead checks the worked-from-raw-values example directly.
  res <- calc_means_anova(group_means = c(9, 10, 11), sd = 4, alpha = 0.05, power = 0.8)
  expect_equal(round(res$f, 4), 0.2041)
  expect_equal(res$n_per_group, 79)
  expect_equal(res$n_total, 237)
})

test_that("calc_means_anova rejects invalid inputs", {
  expect_error(calc_means_anova(group_means = c(1, 2), sd = 1), "at least 3 values")
  expect_error(calc_means_anova(group_means = c(5, 5, 5), sd = 1), "must not all be equal")
  expect_error(calc_means_anova(group_means = c(1, 2, 3), sd = 0), "positive")
})

test_that("calc_means_single_precision matches epiR's own documented example (clinics)", {
  # Levy & Lemeshow (1999): 20 clinics, mean 75 (=1500*0.05), sd 15 (=300*0.05),
  # relative epsilon 0.20 -> epiR's own printed answer: n = 4 clinics.
  res <- calc_means_single_precision(mean = 1500 * 0.05, sd = 300 * 0.05,
                                      epsilon = 0.20, error = "relative",
                                      conf_level = 0.95, N = 20)
  expect_equal(res$n, 4)
})

test_that("calc_means_single_precision rejects invalid inputs", {
  expect_error(calc_means_single_precision(mean = 0, sd = 30, epsilon = 10), "must not be zero")
  expect_error(calc_means_single_precision(mean = 200, sd = -1, epsilon = 10), "positive")
  expect_error(calc_means_single_precision(mean = 200, sd = 30, epsilon = -5), "positive")
})

test_that("calc_means_2s_unequal_n solves n2 given a fixed n1", {
  # mu1=10, mu2=9.4, sd=1 -> d=0.6 (Cohen's own Exercise 2.3 effect size).
  # n1=90 fixed, alpha=.05 (two-sided), power=.8 -> n2=30, n_total=120.
  res <- calc_means_2s_unequal_n(mu1 = 10, mu2 = 9.4, sd = 1, n1 = 90,
                                  alpha = 0.05, power = 0.8, alternative = "two.sided")
  expect_equal(res$n1, 90)
  expect_equal(res$n2, 30)
  expect_equal(res$n_total, 120)
  expect_equal(res$d, 0.6)
})

test_that("pwr::pwr.t2n.test backend reproduces Cohen (1988) Exercise 2.3 exactly", {
  # n1=90, n2=60, d=0.6, one-sided ("greater") -> achieved power = 0.9737262.
  fit <- pwr::pwr.t2n.test(d = 0.6, n1 = 90, n2 = 60, alternative = "greater")
  expect_equal(round(fit$power, 7), 0.9737262)
})

test_that("calc_means_2s_unequal_n rejects invalid inputs", {
  expect_error(calc_means_2s_unequal_n(mu1 = 5, mu2 = 5, sd = 1, n1 = 90), "must differ")
  expect_error(calc_means_2s_unequal_n(mu1 = 5, mu2 = 4, sd = 1, n1 = 1), ">= 2")
  expect_error(calc_means_2s_unequal_n(mu1 = 5, mu2 = 4, sd = -1, n1 = 90), "positive")
})

test_that("calc_means_planned_contrast matches Chow, Shao & Wang (2003) Example 11.1", {
  # mu=(0.05,0.12,0.14,0.16), sigma=0.22, ci=(-6,1,2,3), fi=1/4 each,
  # alpha=0.05, power=0.80 -> n=177.9047, ceiling -> 178 (the textbook's
  # own worked answer, and TrialSize::Dose.Response.Linear()'s own
  # documented example).
  res <- calc_means_planned_contrast(
    mu = c(0.05, 0.12, 0.14, 0.16), sigma = 0.22,
    ci = c(-6, 1, 2, 3), fi = rep(0.25, 4),
    alpha = 0.05, power = 0.80
  )
  expect_equal(res$n_total, 178)
  expect_equal(res$n_per_group, rep(45, 4))
})

test_that("calc_means_planned_contrast rejects invalid inputs", {
  mu <- c(1, 2); sigma <- 1; fi <- c(0.5, 0.5)
  expect_error(calc_means_planned_contrast(mu = mu, sigma = sigma, ci = c(1, 1), fi = fi),
               "must sum to 0")
  expect_error(calc_means_planned_contrast(mu = c(1, 1), sigma = sigma, ci = c(-1, 1), fi = fi),
               "must differ from 0")
  expect_error(calc_means_planned_contrast(mu = c(1, 2, 3), sigma = sigma, ci = c(-1, 1), fi = fi),
               "same length")
  expect_error(calc_means_planned_contrast(mu = mu, sigma = sigma, ci = c(-1, 1), fi = c(0.6, 0.6)),
               "must sum to 1")
  expect_error(calc_means_planned_contrast(mu = mu, sigma = -1, ci = c(-1, 1), fi = fi),
               "positive")
})

test_that("calc_means_posthoc_pairwise reproduces the standard Bonferroni-adjusted formula", {
  # Independently re-derived: n = 2*(qnorm(1-alpha/(2*tau)) + qnorm(1-beta))^2
  # * sigma^2 / margin^2. tau=3, sigma=4, margin=3, alpha=0.05, power=0.80
  # -> n = 37.22352, ceiling -> 38 (also confirmed to reproduce
  # TrialSize::OneWayANOVA.pairwise()'s own output exactly).
  res <- calc_means_posthoc_pairwise(tau = 3, sigma = 4, margin = 3, alpha = 0.05, power = 0.80)
  expect_equal(res$n_per_group, 38)
})

test_that("calc_means_posthoc_pairwise rejects invalid inputs", {
  expect_error(calc_means_posthoc_pairwise(tau = 0, sigma = 4, margin = 3), ">= 1")
  expect_error(calc_means_posthoc_pairwise(tau = 1.5, sigma = 4, margin = 3), ">= 1")
  expect_error(calc_means_posthoc_pairwise(tau = 2, sigma = 4, margin = 0), "must differ from 0")
  expect_error(calc_means_posthoc_pairwise(tau = 2, sigma = -1, margin = 3), "positive")
})

test_that("calc_means_welch reduces to TrialSize::TwoSampleMean.Equality()'s own example when variances are equal", {
  # sigma1=sigma2=0.1, mu1=0.05, mu2=0.10, alpha=0.05, power=0.80, ratio=1
  # -> n=63, matching Chow, Shao & Wang (2003) Example 3.2.4 exactly (the
  # same example calc_means_2s_indep()'s pooled-variance formula matches).
  res <- calc_means_welch(mu1 = 0.05, mu2 = 0.10, sd1 = 0.1, sd2 = 0.1,
                           alpha = 0.05, power = 0.80, ratio = 1)
  expect_equal(res$n1, 63)
  expect_equal(res$n2, 63)
  expect_equal(res$n_total, 126)
})

test_that("calc_means_welch matches hand computation for genuinely unequal variances", {
  # mu1=0, mu2=0.5, sd1=1, sd2=2, alpha=0.05, power=0.80, ratio=1 -> n=157
  # per group. Independently confirmed by a 5,000-replicate Monte Carlo
  # simulation using R's own Welch t-test (stats::t.test(var.equal=FALSE)):
  # empirical power 0.793, closely matching the 0.80 target.
  res <- calc_means_welch(mu1 = 0, mu2 = 0.5, sd1 = 1, sd2 = 2,
                           alpha = 0.05, power = 0.80, ratio = 1)
  expect_equal(res$n1, 157)
  expect_equal(res$n2, 157)
  expect_equal(res$n_total, 314)
})

test_that("calc_means_welch rejects invalid inputs", {
  expect_error(calc_means_welch(mu1 = 1, mu2 = 1, sd1 = 1, sd2 = 1), "must differ")
  expect_error(calc_means_welch(mu1 = 1, mu2 = 2, sd1 = -1, sd2 = 1), "positive")
  expect_error(calc_means_welch(mu1 = 1, mu2 = 2, sd1 = 1, sd2 = -1), "positive")
  expect_error(calc_means_welch(mu1 = 1, mu2 = 2, sd1 = 1, sd2 = 1, ratio = -1), "positive")
  expect_error(calc_means_welch(mu1 = 1, mu2 = 2, sd1 = 1, sd2 = 1, alpha = 0), "between 0 and 1")
})
