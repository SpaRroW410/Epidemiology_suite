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

test_that("calc_cluster_survey_binary matches epiR::epi.ssclus2estb()'s own documented examples", {
  # b=20 (constant), p=0.20, epsilon=0.05 (absolute), rho=0.02, 95% CI ->
  # n.psu=17, n.ssu=340 (the package's own WHO-style example). epiR itself
  # issues an informational "<25 PSUs recommended" warning here (n.psu=17),
  # which is expected, not a bug -- suppressed to keep test output clean.
  res1 <- suppressWarnings(calc_cluster_survey_binary(
    b = 20, p = 0.20, epsilon = 0.05, error = "absolute", rho = 0.02, conf_level = 0.95
  ))
  expect_equal(res1$n_psu, 17)
  expect_equal(res1$n_ssu, 340)

  # Levy & Lemeshow (1999) p.258 cook-stove example: b=75, p=0.46,
  # epsilon=0.10 (relative), rho=0.20, 90% CI -> n_psu=67.
  res2 <- calc_cluster_survey_binary(b = 75, p = 0.46, epsilon = 0.10,
                                      error = "relative", rho = 0.20, conf_level = 0.90)
  expect_equal(res2$n_psu, 67)

  # Same, but cluster size varies (mean 75, SD 35) -> n_psu=81.
  res3 <- calc_cluster_survey_binary(b = 75, b_sd = 35, p = 0.46, epsilon = 0.10,
                                      error = "relative", rho = 0.20, conf_level = 0.90)
  expect_equal(res3$n_psu, 81)

  # Same, with a finite population of 220 total clusters -> n_psu=60.
  res4 <- calc_cluster_survey_binary(b = 75, b_sd = 35, p = 0.46, epsilon = 0.10,
                                      error = "relative", rho = 0.20, N_psu = 220,
                                      conf_level = 0.90)
  expect_equal(res4$n_psu, 60)
})

test_that("calc_cluster_survey_binary rejects invalid inputs", {
  expect_error(calc_cluster_survey_binary(b = -1, p = 0.5, epsilon = 0.1, rho = 0.1), "positive")
  expect_error(calc_cluster_survey_binary(b = 20, p = 1.5, epsilon = 0.1, rho = 0.1), "between 0 and 1")
  expect_error(calc_cluster_survey_binary(b = 20, p = 0.5, epsilon = 0.1, rho = 1), "\\[0, 1\\)")
  expect_error(calc_cluster_survey_binary(b = 20, p = 0.5, epsilon = -0.1, rho = 0.1), "positive")
  expect_error(calc_cluster_survey_binary(b = 20, p = 0.5, epsilon = 0.1, rho = 0.1, N_psu = 0), ">= 1")
})
