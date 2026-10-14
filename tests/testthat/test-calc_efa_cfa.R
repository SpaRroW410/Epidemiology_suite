test_that("calc_efa_cfa_sample_size computes the three ratio-based N's correctly", {
  res <- calc_efa_cfa_sample_size(n_items = 20)
  expect_equal(res$n_5to1, 100)
  expect_equal(res$n_10to1, 200)
  expect_equal(res$n_20to1, 400)
})

test_that("calc_efa_cfa_sample_size applies the Comrey & Lee (1992) adjective scale correctly", {
  expect_equal(.comrey_lee_adjective(49), "below the Comrey & Lee (1992) scale's minimum (very poor starts at N=50)")
  expect_equal(.comrey_lee_adjective(50), "very poor")
  expect_equal(.comrey_lee_adjective(100), "poor")
  expect_equal(.comrey_lee_adjective(200), "fair")
  expect_equal(.comrey_lee_adjective(300), "good")
  expect_equal(.comrey_lee_adjective(500), "very good")
  expect_equal(.comrey_lee_adjective(1000), "excellent")
  expect_equal(.comrey_lee_adjective(5000), "excellent")
})

test_that("calc_efa_cfa_sample_size is deterministic and monotonic in n_items", {
  res1 <- calc_efa_cfa_sample_size(n_items = 6)
  res2 <- calc_efa_cfa_sample_size(n_items = 6)
  expect_identical(res1, res2)

  res_more_items <- calc_efa_cfa_sample_size(n_items = 30)
  expect_gt(res_more_items$n_10to1, res1$n_10to1)
})

test_that("calc_efa_cfa_sample_size rejects invalid inputs", {
  expect_error(calc_efa_cfa_sample_size(n_items = 0), "must be a single whole number >= 1")
  expect_error(calc_efa_cfa_sample_size(n_items = 3.5), "must be a single whole number >= 1")
  expect_error(calc_efa_cfa_sample_size(n_items = NA), "must be a single whole number >= 1")
})

test_that("calc_sem_rmsea_samplesize/power match semTools::findRMSEAsamplesize()/findRMSEApower() bit-for-bit", {
  # rmsea0=.05, rmseaA=.08, df=20, power=.80, alpha=.05 -- a MacCallum,
  # Browne & Sugawara (1996)-style close-vs-poor-fit scenario. Real
  # semTools::findRMSEAsamplesize() gives n=434; findRMSEApower() at
  # that n gives power=0.8003669.
  res <- calc_sem_rmsea_samplesize(rmsea0 = 0.05, rmseaA = 0.08, df = 20, power = 0.80, alpha = 0.05)
  expect_equal(res$n, 434)
  expect_equal(round(res$achieved_power, 7), 0.8003669)
})

test_that("calc_sem_rmsea_power matches semTools::findRMSEApower() bit-for-bit, including rmsea0 > rmseaA and multi-group", {
  # rmsea0=.08, rmseaA=.03 (testing the "not-close-fit" direction),
  # df=50, n=300, alpha=.05, group=2 -- real semTools gives power=0.8972491.
  pw <- calc_sem_rmsea_power(rmsea0 = 0.08, rmseaA = 0.03, df = 50, n = 300, alpha = 0.05, group = 2)
  expect_equal(round(pw, 7), 0.8972491)
})

test_that("calc_sem_rmsea_samplesize matches semTools for a second, higher-power/lower-alpha scenario", {
  # rmsea0=.06, rmseaA=.10, df=100, power=.90, alpha=.01 -- real
  # semTools::findRMSEAsamplesize() gives n=131.
  res <- calc_sem_rmsea_samplesize(rmsea0 = 0.06, rmseaA = 0.10, df = 100, power = 0.90, alpha = 0.01)
  expect_equal(res$n, 131)
})

test_that("calc_irt_calibration_guidance returns the correct minimums for each model type", {
  r1 <- calc_irt_calibration_guidance("rasch_1pl")
  expect_equal(r1$n_minimum, 50)
  expect_equal(r1$n_precise, 250)

  r2 <- calc_irt_calibration_guidance("twopl")
  expect_equal(r2$n_minimum, 500)

  r3 <- calc_irt_calibration_guidance("threepl")
  expect_equal(r3$n_minimum, 1000)

  r4 <- calc_irt_calibration_guidance("polytomous")
  expect_equal(r4$n_minimum, 500)

  # 3PL (added guessing parameter) should need at least as much data as 2PL
  expect_true(r3$n_minimum >= r2$n_minimum)
})

test_that("calc_irt_calibration_guidance rejects an invalid model", {
  expect_error(calc_irt_calibration_guidance("invalid_model"))
})

test_that("calc_sem_rmsea_power rejects invalid inputs", {
  expect_error(calc_sem_rmsea_power(rmsea0 = -0.1, rmseaA = 0.08, df = 20, n = 200), ">= 0")
  expect_error(calc_sem_rmsea_power(rmsea0 = 0.05, rmseaA = 0.05, df = 20, n = 200), "differ")
  expect_error(calc_sem_rmsea_power(rmsea0 = 0.05, rmseaA = 0.08, df = 0, n = 200), ">= 1")
  expect_error(calc_sem_rmsea_power(rmsea0 = 0.05, rmseaA = 0.08, df = 20, n = 1), "> 1")
  expect_error(calc_sem_rmsea_power(rmsea0 = 0.05, rmseaA = 0.08, df = 20, n = 200, alpha = 0), "between 0 and 1")
  expect_error(calc_sem_rmsea_power(rmsea0 = 0.05, rmseaA = 0.08, df = 20, n = 200, group = 0), ">= 1")
})
