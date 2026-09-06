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
