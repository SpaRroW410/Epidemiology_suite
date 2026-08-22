source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_prediction.R"))

test_that("calc_prediction_binary (csrsquared) matches Riley et al (2019, Part II) exactly", {
  # 24 parameters, prevalence=0.174, csrsquared=0.288 -> n=662, events~115.
  res <- calc_prediction_binary(parameters = 24, prevalence = 0.174, csrsquared = 0.288)
  expect_equal(res$n, 662)
  expect_equal(res$events, 116)
})

test_that("calc_prediction_binary (cstatistic) reproduces the csrsquared-based answer closely", {
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
