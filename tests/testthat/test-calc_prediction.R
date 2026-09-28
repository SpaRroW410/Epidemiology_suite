source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_prediction.R"))

test_that("calc_prediction_binary (csrsquared) matches Riley et al (2019, Part II) exactly", {
  # 24 parameters, prevalence=0.174, csrsquared=0.288 -> n=662, events~115.
  res <- calc_prediction_binary(parameters = 24, prevalence = 0.174, csrsquared = 0.288)
  expect_equal(res$n, 662)
  expect_equal(res$events, 116)
})

test_that("calc_prediction_binary (cstatistic) reproduces the csrsquared-based answer closely", {
  skip_if_not_slow()
  # Same scenario, but starting from a reported C-statistic of 0.89
  # instead -- approximates csrsquared via simulation (seeded), so we
  # expect a very close but not necessarily identical n.
  res <- calc_prediction_binary(parameters = 24, prevalence = 0.174, cstatistic = 0.89)
  expect_equal(res$n, 661)
  expect_equal(round(res$csrsquared, 2), 0.29)
})

test_that("calc_prediction_binary rejects invalid inputs", {
  expect_error(calc_prediction_binary(parameters = 24, prevalence = 0.174), "exactly one")
  expect_error(calc_prediction_binary(parameters = 24, prevalence = 0.174,
                                       csrsquared = 0.288, cstatistic = 0.89), "exactly one")
  expect_error(calc_prediction_binary(parameters = 0, prevalence = 0.174, csrsquared = 0.288), ">= 1")
  expect_error(calc_prediction_binary(parameters = 24, prevalence = 0.174, cstatistic = 0.4), "between 0.5 and 1")
})

test_that("calc_prediction_continuous matches Riley et al (2019, Part I) exactly", {
  # 25 parameters, intercept=1.9, sd=0.6, rsquared=0.2 -> n=918.
  res <- calc_prediction_continuous(parameters = 25, intercept = 1.9, sd = 0.6, rsquared = 0.2)
  expect_equal(res$n, 918)
})

test_that("calc_prediction_continuous rejects invalid inputs", {
  expect_error(calc_prediction_continuous(parameters = 0, intercept = 1.9, sd = 0.6, rsquared = 0.2), ">= 1")
  expect_error(calc_prediction_continuous(parameters = 25, intercept = 1.9, sd = -1, rsquared = 0.2), "positive")
  expect_error(calc_prediction_continuous(parameters = 25, intercept = 1.9, sd = 0.6, rsquared = 1.5), "between 0 and 1")
})

test_that("calc_prediction_survival matches Riley et al (2020, BMJ) exactly", {
  # 30 parameters, rate=0.065, timepoint=2, meanfup=2.07, csrsquared=0.051 -> n=5143, events~692.
  res <- calc_prediction_survival(parameters = 30, rate = 0.065, timepoint = 2,
                                   meanfup = 2.07, csrsquared = 0.051)
  expect_equal(res$n, 5143)
  expect_equal(res$events, 692)
})

test_that("calc_prediction_survival rejects invalid inputs", {
  expect_error(calc_prediction_survival(parameters = 30, rate = -1, timepoint = 2,
                                         meanfup = 2.07, csrsquared = 0.051), "positive")
  expect_error(calc_prediction_survival(parameters = 30, rate = 0.065, timepoint = 2,
                                         meanfup = 2.07, csrsquared = 1.5), "between 0 and 1")
})

test_that("calc_prediction_external_validation (normal LP) matches Riley et al (2021) worked example", {
  # prevalence=0.018, cstatistic=0.8, LP~N(-5,2.5), oeciwidth=1 (defaults elsewhere)
  # -> criterion 2 (c-slope) binds: n=4563, events=83. Verified against the
  # pmvalsampsize package's own source (fetched from its GitHub CRAN mirror,
  # since the package itself is not installed and CRAN is unreachable) at
  # simobs=1e6, and independently against actual glm()-fitted calibration-
  # slope SEs and pROC::ci.auc() CI widths on simulated data.
  res <- calc_prediction_external_validation(
    prevalence = 0.018, cstatistic = 0.8, lp_method = "normal",
    lp_param1 = -5, lp_param2 = 2.5, oeciwidth = 1, simobs = 1e6
  )
  expect_equal(res$n1, 905)
  expect_equal(res$n2, 4563)
  expect_equal(res$n3, 4252)
  expect_equal(res$n, 4563)
  expect_equal(res$events, 83)
})

test_that("calc_prediction_external_validation (beta LP) matches Riley et al (2021) alternative example", {
  # Same scenario but predicted-probability distribution ~ Beta(0.5,0.5)
  # -> criterion 3 (C-statistic) binds instead: n=4252, events=77.
  res <- calc_prediction_external_validation(
    prevalence = 0.018, cstatistic = 0.8, lp_method = "beta",
    lp_param1 = 0.5, lp_param2 = 0.5, oeciwidth = 1, simobs = 1e6
  )
  expect_equal(res$n1, 905)
  expect_equal(res$n3, 4252)
  expect_equal(res$n, 4252)
  expect_equal(res$events, 77)
})

test_that("calc_prediction_external_validation is reproducible with a fixed seed", {
  res1 <- calc_prediction_external_validation(
    prevalence = 0.018, cstatistic = 0.8, lp_method = "normal",
    lp_param1 = -5, lp_param2 = 2.5, oeciwidth = 1, simobs = 50000, seed = 42
  )
  res2 <- calc_prediction_external_validation(
    prevalence = 0.018, cstatistic = 0.8, lp_method = "normal",
    lp_param1 = -5, lp_param2 = 2.5, oeciwidth = 1, simobs = 50000, seed = 42
  )
  expect_identical(res1$n2, res2$n2)
})

test_that("calc_prediction_external_validation computes the optional net-benefit criterion", {
  res <- calc_prediction_external_validation(
    prevalence = 0.15, cstatistic = 0.75, lp_method = "normal",
    lp_param1 = -2, lp_param2 = 1.5, sensitivity = 0.6, specificity = 0.7,
    threshold = 0.2, simobs = 1e5
  )
  expect_false(is.null(res$n4))
  expect_equal(res$n, max(res$n1, res$n2, res$n3, res$n4))
})

test_that("calc_prediction_external_validation omits the net-benefit criterion by default", {
  res <- calc_prediction_external_validation(
    prevalence = 0.018, cstatistic = 0.8, lp_method = "normal",
    lp_param1 = -5, lp_param2 = 2.5, simobs = 1e5
  )
  expect_null(res$n4)
  expect_equal(res$n, max(res$n1, res$n2, res$n3))
})

test_that("calc_prediction_external_validation rejects invalid inputs", {
  expect_error(calc_prediction_external_validation(
    prevalence = 1.5, cstatistic = 0.8, lp_method = "normal", lp_param1 = -5, lp_param2 = 2.5
  ), "between 0 and 1")
  expect_error(calc_prediction_external_validation(
    prevalence = 0.1, cstatistic = 0.3, lp_method = "normal", lp_param1 = -5, lp_param2 = 2.5
  ), "between 0.5 and 1")
  expect_error(calc_prediction_external_validation(
    prevalence = 0.1, cstatistic = 0.8, lp_method = "normal", lp_param1 = -5, lp_param2 = -1
  ), "positive")
})
