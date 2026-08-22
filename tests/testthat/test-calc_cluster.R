source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_cluster.R"))

test_that("calc_cluster_deff matches Killip, Mahfoud & Pearce (2004)'s worked example exactly", {
  # icc=0.05, cluster_size=10 -> deff = 1 + (10-1)*0.05 = 1.45 (their own
  # illustration of the design-effect formula).
  res <- calc_cluster_deff(n_base = 200, icc = 0.05, cluster_size = 10)
  expect_equal(res$deff, 1.45)
  expect_equal(res$n_effective, 290)
})

test_that("calc_cluster_deff with icc=0 leaves n unchanged (deff=1)", {
  res <- calc_cluster_deff(n_base = 200, icc = 0, cluster_size = 25)
  expect_equal(res$deff, 1)
  expect_equal(res$n_effective, 200)
})

test_that("calc_cluster_deff rejects invalid inputs", {
  expect_error(calc_cluster_deff(n_base = 0, icc = 0.05, cluster_size = 10), ">= 1")
  expect_error(calc_cluster_deff(n_base = 200, icc = 1, cluster_size = 10), "\\[0, 1\\)")
  expect_error(calc_cluster_deff(n_base = 200, icc = 0.05, cluster_size = 0), ">= 1")
})
