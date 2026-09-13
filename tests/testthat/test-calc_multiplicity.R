source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_proportion.R"))
source(file.path("..", "..", "R", "calc", "calc_means.R"))
source(file.path("..", "..", "R", "calc", "calc_multiplicity.R"))

test_that("calc_multiplicity_adjusted_alpha: Bonferroni and Sidak", {
  expect_equal(calc_multiplicity_adjusted_alpha(0.05, 4, "bonferroni"), 0.0125)
  expect_equal(round(calc_multiplicity_adjusted_alpha(0.05, 4, "sidak"), 7), 0.0127415)
  # m=1 leaves alpha unchanged under either method
  expect_equal(calc_multiplicity_adjusted_alpha(0.05, 1, "bonferroni"), 0.05)
  expect_equal(calc_multiplicity_adjusted_alpha(0.05, 1, "sidak"), 0.05)
})

test_that("calc_multiplicity_adjusted_alpha rejects invalid inputs", {
  expect_error(calc_multiplicity_adjusted_alpha(1.1, 4), "between 0 and 1")
  expect_error(calc_multiplicity_adjusted_alpha(0.05, 0), ">= 1")
  expect_error(calc_multiplicity_adjusted_alpha(0.05, 2.5), ">= 1")
})

test_that("calc_multiplicity_proportion_2s: m=1 reduces exactly to calc_proportion_2s", {
  base <- calc_proportion_2s(p1 = 0.5, p2 = 0.65, alpha = 0.05, power = 0.8)
  adj <- calc_multiplicity_proportion_2s(p1 = 0.5, p2 = 0.65, m = 1, method = "bonferroni",
                                          alpha = 0.05, power = 0.8)
  expect_equal(adj$n_total, base$n_total)
  expect_equal(adj$n_per_group, base$n_per_group)
})

test_that("calc_multiplicity_proportion_2s: worked example, m=4 Bonferroni", {
  res <- calc_multiplicity_proportion_2s(p1 = 0.5, p2 = 0.65, m = 4, method = "bonferroni",
                                          alpha = 0.05, power = 0.8)
  expect_equal(res$alpha_adjusted, 0.0125)
  expect_equal(res$n_per_group, 241)
  expect_equal(res$n_total, 482)
})

test_that("calc_multiplicity_proportion_1s reuses calc_proportion_1s with adjusted alpha", {
  res <- calc_multiplicity_proportion_1s(p0 = 0.3, p1 = 0.5, m = 3, method = "bonferroni",
                                          alpha = 0.05, power = 0.8)
  expected <- calc_proportion_1s(p0 = 0.3, p1 = 0.5, alpha = 0.05 / 3, power = 0.8)
  expect_equal(res$n, expected$n)
  expect_equal(res$alpha_adjusted, 0.05 / 3)
})

test_that("calc_multiplicity_means_1s reuses calc_means_1s with adjusted alpha", {
  res <- calc_multiplicity_means_1s(mu0 = 0, mu1 = 0.5, sd = 1, m = 2, method = "sidak",
                                     alpha = 0.05, power = 0.8)
  alpha_adj <- 1 - (1 - 0.05)^(1 / 2)
  expected <- calc_means_1s(mu0 = 0, mu1 = 0.5, sd = 1, alpha = alpha_adj, power = 0.8)
  expect_equal(res$n, expected$n)
  expect_equal(res$alpha_adjusted, alpha_adj)
})

test_that("calc_multiplicity_means_2s reuses calc_means_2s_indep with adjusted alpha", {
  res <- calc_multiplicity_means_2s(mu1 = 10, mu2 = 12, sd = 5, m = 3, method = "sidak",
                                     alpha = 0.05, power = 0.8)
  alpha_adj <- 1 - (1 - 0.05)^(1 / 3)
  expected <- calc_means_2s_indep(mu1 = 10, mu2 = 12, sd = 5, alpha = alpha_adj, power = 0.8)
  expect_equal(res$n_total, expected$n_total)
  expect_equal(res$alpha_adjusted, alpha_adj)
  expect_equal(res$inputs$alpha_family, 0.05)
})

test_that("multiplicity wrapper functions reject invalid m the same way as calc_multiplicity_adjusted_alpha", {
  expect_error(calc_multiplicity_proportion_2s(p1 = 0.5, p2 = 0.65, m = 0), ">= 1")
  expect_error(calc_multiplicity_means_2s(mu1 = 10, mu2 = 12, sd = 5, m = 1.5), ">= 1")
})

test_that("calc_multiplicity_fdr_means matches independently-verified worked examples exactly", {
  # Worked example 1: m=1000, pi1=0.1 (m1=100), d=2, fdr_level=0.1, power=0.8.
  # Independently re-derived alpha* = fdr_level*m1*power/(m0*(1-fdr_level))
  # = 0.1*100*0.8/(900*0.9) = 0.00988, and separately confirmed by a
  # 500-replicate simulation of the ACTUAL Benjamini-Hochberg procedure
  # (stats::p.adjust(method="BH")) at the resulting n: empirical average
  # FDR 0.082 (target 0.1), empirical average power 0.794 (target 0.8).
  res1 <- calc_multiplicity_fdr_means(d = 2, m = 1000, pi1 = 0.1, fdr_level = 0.1, power = 0.8)
  expect_equal(res1$n_per_group, 8)
  expect_equal(res1$m1, 100)
  expect_equal(res1$m0, 900)
  expect_equal(res1$alpha_star, 0.1 * 100 * 0.8 / (900 * 0.9))

  # Worked example 2: m=500, pi1=0.1 (m1=50), d=1, fdr_level=0.05, power=0.9.
  # 400-replicate simulation at the resulting n: empirical average FDR
  # 0.045 (target 0.05), empirical average power 0.904 (target 0.9).
  res2 <- calc_multiplicity_fdr_means(d = 1, m = 500, pi1 = 0.1, fdr_level = 0.05, power = 0.9)
  expect_equal(res2$n_per_group, 36)
  expect_equal(res2$m1, 50)
  expect_equal(res2$m0, 450)
})

test_that("calc_multiplicity_fdr_means reduces exactly to pwr::pwr.t.test() at its own alpha_star", {
  res <- calc_multiplicity_fdr_means(d = 1.5, m = 200, pi1 = 0.2, fdr_level = 0.1, power = 0.85)
  fit <- pwr::pwr.t.test(d = 1.5, sig.level = res$alpha_star, power = 0.85, type = "two.sample")
  expect_equal(res$n_per_group, ceiling(fit$n))
})

test_that("calc_multiplicity_fdr_means needs a smaller n as pi1 increases (more true positives ease FDR control)", {
  res_low <- calc_multiplicity_fdr_means(d = 1, m = 500, pi1 = 0.05, fdr_level = 0.05, power = 0.8)
  res_high <- calc_multiplicity_fdr_means(d = 1, m = 500, pi1 = 0.3, fdr_level = 0.05, power = 0.8)
  expect_lt(res_high$n_per_group, res_low$n_per_group)
})

test_that("calc_multiplicity_fdr_means rejects invalid inputs", {
  expect_error(calc_multiplicity_fdr_means(d = -1, m = 100, pi1 = 0.1), "positive")
  expect_error(calc_multiplicity_fdr_means(d = 1, m = 1, pi1 = 0.1), ">= 2")
  expect_error(calc_multiplicity_fdr_means(d = 1, m = 100, pi1 = 1.5), "between 0 and 1")
  expect_error(calc_multiplicity_fdr_means(d = 1, m = 100, pi1 = 0.001), "at least 1")
  expect_error(calc_multiplicity_fdr_means(d = 1, m = 100, pi1 = 0.9, fdr_level = 0.9, power = 0.999),
               "No feasible design")
})

test_that("calc_multiplicity_dunnett reproduces this session's own worked example", {
  # k=3 active arms vs. 1 control, d=0.5, alpha=0.05, power=0.80 -> n=83/arm,
  # verified this session against calc_multiplicity_means_2s's Bonferroni
  # (n=86) and Sidak (n=85) at m=3 on the identical inputs.
  res <- calc_multiplicity_dunnett(d = 0.5, k = 3, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_arm, 83)
  expect_equal(res$n_total, 83 * 4)
  expect_true(abs(res$achieved_power - 0.8) < 0.02)
})

test_that("calc_multiplicity_dunnett is less conservative than Bonferroni/Sidak for the same m", {
  res_dunnett <- calc_multiplicity_dunnett(d = 0.5, k = 3, alpha = 0.05, power = 0.8)
  res_bonf <- calc_multiplicity_means_2s(mu1 = 0, mu2 = 0.5, sd = 1, m = 3, method = "bonferroni",
                                          alpha = 0.05, power = 0.8)
  res_sidak <- calc_multiplicity_means_2s(mu1 = 0, mu2 = 0.5, sd = 1, m = 3, method = "sidak",
                                           alpha = 0.05, power = 0.8)
  expect_lte(res_dunnett$n_per_arm, res_sidak$n_per_group)
  expect_lte(res_dunnett$n_per_arm, res_bonf$n_per_group)
})

test_that("calc_multiplicity_dunnett is deterministic (fixed internal seed) and needs a larger n for more arms", {
  res1 <- calc_multiplicity_dunnett(d = 0.5, k = 3, alpha = 0.05, power = 0.8)
  res2 <- calc_multiplicity_dunnett(d = 0.5, k = 3, alpha = 0.05, power = 0.8)
  expect_identical(res1, res2)

  res_k2 <- calc_multiplicity_dunnett(d = 0.5, k = 2, alpha = 0.05, power = 0.8)
  res_k4 <- calc_multiplicity_dunnett(d = 0.5, k = 4, alpha = 0.05, power = 0.8)
  expect_gte(res_k4$n_per_arm, res_k2$n_per_arm)
})

test_that("calc_multiplicity_dunnett rejects invalid inputs", {
  expect_error(calc_multiplicity_dunnett(d = 0.5, k = 1), ">= 2")
  expect_error(calc_multiplicity_dunnett(d = -0.5, k = 2), "positive")
  expect_error(calc_multiplicity_dunnett(d = 0.5, k = 2, alpha = 0), "between 0 and 1")
  expect_error(calc_multiplicity_dunnett(d = 0.5, k = 2, power = 0), "between 0 and 1")
})
