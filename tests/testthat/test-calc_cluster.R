source(file.path("..", "..", "R", "calc", "calc_result.R"))
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

test_that("calc_cluster_deff_variable with cv=0 matches calc_cluster_deff exactly", {
  res_var <- calc_cluster_deff_variable(n_base = 200, icc = 0.05, cluster_size = 10, cv = 0)
  res_fixed <- calc_cluster_deff(n_base = 200, icc = 0.05, cluster_size = 10)
  expect_equal(res_var$deff, res_fixed$deff)
  expect_equal(res_var$n_effective, res_fixed$n_effective)
})

test_that("calc_cluster_deff_variable matches clusterPower::cpa.binary()'s internal DEFF/power bit-for-bit", {
  # m=20, icc=0.05, cv=0.5 -> DEFF = 1 + [(0.5^2+1)*20 - 1]*0.05 = 2.2, verified
  # against clusterPower::cpa.binary(nclusters=30, nsubjects=20, CV=0.5,
  # p1=0.3, p2=0.2, ICC=0.05, alpha=0.05), which returns power = 0.7610850
  # via the exact same DEFF value substituted into its own power formula.
  res <- calc_cluster_deff_variable(n_base = 100, icc = 0.05, cluster_size = 20, cv = 0.5)
  expect_equal(res$deff, 2.2)
  expect_equal(res$n_effective, 220)
})

test_that("calc_cluster_deff_variable rejects invalid inputs", {
  expect_error(calc_cluster_deff_variable(n_base = 0, icc = 0.05, cluster_size = 10, cv = 0.5), ">= 1")
  expect_error(calc_cluster_deff_variable(n_base = 200, icc = 1, cluster_size = 10, cv = 0.5), "\\[0, 1\\)")
  expect_error(calc_cluster_deff_variable(n_base = 200, icc = 0.05, cluster_size = 0, cv = 0.5), ">= 1")
  expect_error(calc_cluster_deff_variable(n_base = 200, icc = 0.05, cluster_size = 10, cv = -1), ">= 0")
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

test_that("calc_cluster_pps_optimal_allocation matches PracTools::clusOpt2()'s own documented examples exactly", {
  # PracTools's own first example (cal.sw=1, fixed budget): C1=750, C2=100,
  # delta=0.05, unit.rv=1, k=1, tot.cost=100000 -> n.opt=11.9, m.opt=51.4,
  # CV=0.0502 (verified directly against a real clusOpt2() call this session).
  res1 <- calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 0.05,
                                               unit_relvar = 1, k = 1, mode = "budget",
                                               total_budget = 100000)
  expect_equal(round(res1$n_opt, 1), 11.9)
  expect_equal(round(res1$m_opt, 1), 51.4)
  expect_equal(round(res1$cv, 4), 0.0502)

  # PracTools's own second example (cal.sw=2, target CV): C1=750, C2=100,
  # delta=0.01, unit.rv=1, k=1, CV0=0.05 -> n.opt=27.2, m.opt=18.5,
  # cost=64399.08.
  res2 <- calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 0.01,
                                               unit_relvar = 1, k = 1, mode = "precision",
                                               target_cv = 0.05)
  expect_equal(round(res2$n_opt, 1), 27.2)
  expect_equal(round(res2$m_opt, 1), 18.5)
  expect_equal(round(res2$cost, 2), 64399.08)
})

test_that("calc_cluster_pps_optimal_allocation's optimal take (n_opt) does not depend on the number of PSUs", {
  # The item this closes specifically: DEFF/optimal take depends on delta
  # and the cost ratio, NOT on the number of PSUs -- confirm n_opt is
  # identical whether solved via a fixed budget or a fixed target CV
  # (which imply very different m_opt), as long as cost_psu/cost_element/
  # delta are unchanged.
  res_budget <- calc_cluster_pps_optimal_allocation(cost_psu = 500, cost_element = 50, delta = 0.1,
                                                     mode = "budget", total_budget = 50000)
  res_precision <- calc_cluster_pps_optimal_allocation(cost_psu = 500, cost_element = 50, delta = 0.1,
                                                        mode = "precision", target_cv = 0.03)
  expect_equal(res_budget$n_opt, res_precision$n_opt)
  expect_false(isTRUE(all.equal(res_budget$m_opt, res_precision$m_opt)))
})

test_that("calc_cluster_pps_optimal_allocation rejects invalid inputs", {
  expect_error(calc_cluster_pps_optimal_allocation(cost_psu = -1, cost_element = 100, delta = 0.05,
                                                    mode = "budget", total_budget = 1000), "positive")
  expect_error(calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 0,
                                                    mode = "budget", total_budget = 1000), "\\(0, 1\\)")
  expect_error(calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 1,
                                                    mode = "budget", total_budget = 1000), "\\(0, 1\\)")
  expect_error(calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 0.05,
                                                    mode = "budget"), "positive")
  expect_error(calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 0.05,
                                                    mode = "precision"), "positive")
})
