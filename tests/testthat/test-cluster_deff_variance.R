# Design effect from variances (calc_cluster_deff_variance): the formulas checked against simulated clustered data, and against the
# existing ICC route.

test_that("variance components give the ICC and the design effect of the ICC route", {
  r <- calc_cluster_deff_variance(cluster_size = 10, var_between = 2, var_within = 38, n_base = 200)
  expect_equal(r$icc, 0.05); expect_equal(r$deff, 1.45); expect_equal(r$n_effective, 290)
  expect_equal(r$deff, calc_cluster_deff(200, icc = 0.05, cluster_size = 10)$deff)
  expect_equal(calc_cluster_deff_variance(1, var_between = 5, var_within = 5)$deff, 1)          # clusters of one: no effect
  expect_equal(calc_cluster_deff_variance(10, var_between = 0, var_within = 1)$deff, 1)
})

test_that("DEFF = m x var(cluster means) / total variance, in clustered continuous data (simulation)", {
  set.seed(11)
  k <- 6000; m <- 10; vb <- 2; vw <- 38
  b <- rnorm(k, 0, sqrt(vb)); y <- matrix(b + rnorm(k * m, 0, sqrt(vw)), k, m)
  est <- calc_cluster_deff_variance(cluster_size = m, var_means = stats::var(rowMeans(y)), var_total = stats::var(as.vector(y)))
  expect_equal(est$deff, 1 + (m - 1) * vb / (vb + vw), tolerance = 0.04)
  expect_equal(est$icc, vb / (vb + vw), tolerance = 0.15)
})

test_that("the design effect is the ratio of the variance of the mean under cluster sampling to that under simple random sampling (simulation)", {
  set.seed(12)
  k <- 30; m <- 10; vb <- 2; vw <- 38; reps <- 20000
  means_cluster <- replicate(reps, { b <- rnorm(k, 0, sqrt(vb)); mean(rep(b, each = m) + rnorm(k * m, 0, sqrt(vw))) })
  means_srs <- replicate(reps, mean(rnorm(k * m, 0, sqrt(vb + vw))))
  r <- calc_cluster_deff_variance(var_design = stats::var(means_cluster), var_srs = stats::var(means_srs), cluster_size = m)
  expect_equal(r$deff, 1 + (m - 1) * vb / (vb + vw), tolerance = 0.05)
  expect_equal(calc_cluster_deff_variance(var_design = 0.0021, var_srs = 0.0014)$deff, 1.5)
})

test_that("a binary outcome: cluster proportions with the overall proportion give the design effect (beta-binomial simulation)", {
  set.seed(13)
  k <- 20000; m <- 20; p <- 0.3; icc <- 0.05
  ab <- 1 / icc - 1                                           # beta-binomial: ICC = 1 / (a + b + 1)
  pi_k <- rbeta(k, p * ab, (1 - p) * ab); props <- stats::rbinom(k, m, pi_k) / m
  r <- calc_cluster_deff_variance(cluster_size = m, var_means = stats::var(props), p = mean(props))
  expect_equal(r$deff, 1 + (m - 1) * icc, tolerance = 0.04)
  expect_equal(r$icc, icc, tolerance = 0.06)
  # the worked example of the help text
  w <- calc_cluster_deff_variance(cluster_size = 20, var_means = 0.0125, p = 0.3)
  expect_equal(round(c(w$deff, w$icc), 4), c(1.1905, 0.0100))
})

test_that("notes and errors", {
  low <- calc_cluster_deff_variance(cluster_size = 10, var_means = 0.001, p = 0.3)
  expect_lt(low$deff, 1); expect_match(low$notes, "below 1")
  expect_match(calc_cluster_deff_variance(cluster_size = 2, var_means = 0.5, p = 0.3)$notes[1], "above 1")
  expect_error(calc_cluster_deff_variance(), "exactly one set")
  expect_error(calc_cluster_deff_variance(cluster_size = 10, var_between = 1), "both the between")
  expect_error(calc_cluster_deff_variance(var_between = 1, var_within = 1), "cluster size")
  expect_error(calc_cluster_deff_variance(cluster_size = 10, var_means = 0.1), "total")
  expect_error(calc_cluster_deff_variance(cluster_size = 10, var_means = 0.1, p = 0.3, var_total = 1), "not both")
  expect_error(calc_cluster_deff_variance(cluster_size = 0.5, var_between = 1, var_within = 1), "cluster_size")
  expect_error(calc_cluster_deff_variance(var_design = 1), "both")
})

test_that("the design effect can be given directly (1.5 when nothing is known)", {
  r <- calc_cluster_deff(n_base = 200, deff = 1.5)
  expect_equal(c(r$deff, r$n_effective), c(1.5, 300))
  expect_equal(calc_cluster_deff(200, 0.05, 10)$n_effective, 290)                 # existing positional call unchanged
  expect_error(calc_cluster_deff(200, icc = 0.05, deff = 2), "not both")
  expect_error(calc_cluster_deff(200), "Give the ICC")
  expect_error(calc_cluster_deff(200, deff = 0), "greater than 0")
})
