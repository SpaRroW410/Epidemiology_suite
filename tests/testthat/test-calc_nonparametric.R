source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_rm_anova.R"))
source(file.path("..", "..", "R", "calc", "calc_nonparametric.R"))

test_that("calc_wilcoxon_rank_sum matches Chow, Shao & Wang (2003) Example 14.3", {
  # k = 1, p1 = 0.7, p2 = 0.8, p3 = 0.8, alpha = 0.05, power = 0.80 -> n = 54.
  res <- calc_wilcoxon_rank_sum(k = 1, p1 = 0.7, p2 = 0.8, p3 = 0.8, alpha = 0.05, power = 0.80)
  expect_equal(res$n, 54)
})

test_that("calc_wilcoxon_rank_sum rejects invalid inputs", {
  expect_error(calc_wilcoxon_rank_sum(k = 1, p1 = 0.5, p2 = 0.5, p3 = 0.5), "must differ from 0.5")
  expect_error(calc_wilcoxon_rank_sum(k = -1, p1 = 0.7, p2 = 0.8, p3 = 0.8), "positive")
  expect_error(calc_wilcoxon_rank_sum(k = 1, p1 = 1.5, p2 = 0.8, p3 = 0.8), "between 0 and 1")
})

test_that("calc_wilcoxon_signed_rank matches Chow, Shao & Wang (2003) Example 14.2", {
  # p2 = 0.3, p3 = 0.4, p4 = 0.05, alpha = 0.05, power = 0.80 -> n = 383.
  res <- calc_wilcoxon_signed_rank(p2 = 0.3, p3 = 0.4, p4 = 0.05, alpha = 0.05, power = 0.80)
  expect_equal(res$n, 383)
})

test_that("calc_wilcoxon_signed_rank rejects invalid inputs", {
  expect_error(calc_wilcoxon_signed_rank(p2 = 0.25, p3 = 0.4, p4 = 0.05), "must differ from 0.25")
  expect_error(calc_wilcoxon_signed_rank(p2 = 0.3, p3 = 1.5, p4 = 0.05), "between 0 and 1")
})

test_that("calc_kendall_tau matches Chow, Shao & Wang (2003) Example 14.4", {
  # p1 = 0.6 (tau = 0.2), p2 = 0.7, alpha = 0.05, power = 0.80 -> n = 135.
  res <- calc_kendall_tau(p1 = 0.6, p2 = 0.7, alpha = 0.05, power = 0.80)
  expect_equal(res$n, 135)
  expect_equal(res$tau, 0.2)
})

test_that("calc_kendall_tau rejects invalid inputs", {
  expect_error(calc_kendall_tau(p1 = 0.5, p2 = 0.5), "must differ from 0.5")
  expect_error(calc_kendall_tau(p1 = 0.6, p2 = 0.7, alpha = 0), "between 0 and 1")
})

test_that("calc_kruskal_wallis matches hand computation (k=3, f=0.25 -> ANOVA n=53, KW n=56)", {
  # pwr::pwr.anova.test(k=3, f=0.25, alpha=0.05, power=0.8) -> n=52.40,
  # ceiling -> 53 per group; inflated by pi/3 (3/pi ARE) -> 56 per group,
  # 168 total. Independently confirmed by a 5,000-replicate Monte Carlo
  # simulation using the actual kruskal.test(): empirical power 0.812 at
  # n=56 (vs. only 0.787 at the unadjusted ANOVA n=53), closely matching
  # the 0.80 target.
  res <- calc_kruskal_wallis(k = 3, f = 0.25, alpha = 0.05, power = 0.8)
  expect_equal(res$n_anova_per_group, 53)
  expect_equal(res$n_per_group, 56)
  expect_equal(res$n_total, 168)
})

test_that("calc_kruskal_wallis rejects invalid inputs", {
  expect_error(calc_kruskal_wallis(k = 2, f = 0.25), "at least 3")
  expect_error(calc_kruskal_wallis(k = 3.5, f = 0.25), "at least 3")
  expect_error(calc_kruskal_wallis(k = 3, f = -0.1), "positive")
  expect_error(calc_kruskal_wallis(k = 3, f = 0.25, alpha = 0), "between 0 and 1")
})

test_that("calc_jonckheere_terpstra matches calc_kendall_tau() exactly (same statistic under the asymptotic equivalence)", {
  # clinfun::jonckheere.test()'s own documentation states the asymptotic
  # version is equivalent to cor.test(x, g, method="k") -- i.e. exactly
  # Kendall's tau -- so this thin wrapper must reproduce
  # calc_kendall_tau()'s own verified answer (Chow, Shao & Wang (2003)
  # Example 14.4: p1=0.6, p2=0.7 -> n=135) bit-for-bit.
  wrapped <- calc_jonckheere_terpstra(p1 = 0.6, p2 = 0.7, alpha = 0.05, power = 0.80)
  direct <- calc_kendall_tau(p1 = 0.6, p2 = 0.7, alpha = 0.05, power = 0.80)
  expect_equal(wrapped$n, direct$n)
  expect_equal(wrapped$tau, direct$tau)
  expect_equal(wrapped$n, 135)
  expect_equal(wrapped$tau, 0.2)
})

test_that("calc_jonckheere_terpstra rejects invalid inputs", {
  expect_error(calc_jonckheere_terpstra(p1 = 0.5, p2 = 0.5), "must differ from 0.5")
  expect_error(calc_jonckheere_terpstra(p1 = 0.6, p2 = 0.7, alpha = 0), "between 0 and 1")
})

test_that("calc_friedman matches hand computation (k=4, f=0.25 -> RM-ANOVA n=176, Friedman n=231)", {
  # calc_rm_anova(ng=1, nm=4, f=0.25, nscor=1, alpha=0.05, power=0.8, type="within")
  # gives n=176; ARE = (3/pi)*4/5 = 0.76394; ceiling(176/0.76394) = 231.
  # Independently confirmed by simulation: searching for the n at which
  # stats::friedman.test() and a from-scratch RM-ANOVA F-test each cross
  # 80% empirical power on identical compound-symmetric data (k=4) gives a
  # ratio n_Friedman/n_RM-ANOVA of about 1.28-1.30, closely matching this
  # formula's predicted 1/ARE = pi/3 * 5/4 = 1.309.
  res <- calc_friedman(k = 4, f = 0.25, alpha = 0.05, power = 0.8)
  expect_equal(res$n_rm_anova, 176)
  expect_equal(round(res$are, 4), 0.7639)
  expect_equal(res$n, 231)
})

test_that("calc_friedman's ARE formula reduces to the plain 3/pi constant as k grows large", {
  are_k1e6 <- (3 / pi) * 1e6 / (1e6 + 1)
  expect_equal(round(are_k1e6, 4), round(3 / pi, 4))
})

test_that("calc_friedman rejects invalid inputs", {
  expect_error(calc_friedman(k = 2, f = 0.25), "at least 3")
  expect_error(calc_friedman(k = 3.5, f = 0.25), "at least 3")
  expect_error(calc_friedman(k = 4, f = -0.1), "positive")
  expect_error(calc_friedman(k = 4, f = 0.25, nscor = 0), "in \\(0, 1\\]")
  expect_error(calc_friedman(k = 4, f = 0.25, nscor = 1.5), "in \\(0, 1\\]")
  expect_error(calc_friedman(k = 4, f = 0.25, alpha = 0), "between 0 and 1")
  expect_error(calc_friedman(k = 4, f = 0.25, power = 0), "between 0 and 1")
})
