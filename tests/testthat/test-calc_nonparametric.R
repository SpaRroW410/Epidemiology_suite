source(file.path("..", "..", "R", "calc", "calc_utils.R"))
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
