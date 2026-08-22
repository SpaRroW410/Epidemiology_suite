source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_roc.R"))

test_that("calc_roc_auc matches pROC's own worked example (aSAH S100B biomarker)", {
  # auc=0.73, alpha=.05, power=.95, kappa=1.7 -> ncases=29.67, ncontrols=50.44
  # (ceiling 30/51).
  res <- calc_roc_auc(auc = 0.73, alpha = 0.05, power = 0.95, kappa = 1.7)
  expect_equal(res$n_cases, 30)
  expect_equal(res$n_controls, 51)
  expect_equal(res$n_total, 81)
})

test_that("pROC::power.roc.test backend reproduces the aSAH real-data power exactly", {
  # ncases=41, ncontrols=72, auc=0.73 (the real aSAH/S100B numbers) ->
  # power = 0.9897453.
  fit <- pROC::power.roc.test(ncases = 41, ncontrols = 72, auc = 0.73, sig.level = 0.05)
  expect_equal(round(fit$power, 7), 0.9897453)
})

test_that("calc_roc_auc rejects invalid inputs", {
  expect_error(calc_roc_auc(auc = 0.5), "between 0.5 and 1")
  expect_error(calc_roc_auc(auc = 1), "between 0.5 and 1")
  expect_error(calc_roc_auc(auc = 0.73, kappa = -1), "positive")
})
