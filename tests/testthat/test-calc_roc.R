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

test_that("calc_compare_two_aucs matches Obuchowski & McClish (1997) Example 2 (partial AUC)", {
  # A1=2.6, B1=1, A2=1.9, B2=1, rn=ra=0.6, delta=0.037, FPR range [0,0.2]
  # -- pROC's own documentation example, sourced from the paper itself.
  # Raw ncases=ncontrols=107.02; this calculator's always-round-up
  # convention gives 108 (the package's own doc rounds to the nearest
  # whole number, 107, for illustration -- both describe the same raw
  # computation).
  res <- calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6,
                                delta = 0.037, alpha = 0.05, power = 0.8,
                                fpr11 = 0, fpr12 = 0.2, fpr21 = 0, fpr22 = 0.2)
  expect_equal(res$n_cases, 108)
  expect_equal(res$n_controls, 108)
  expect_equal(res$n_total, 216)
})

test_that("calc_compare_two_aucs matches the full-AUC version of the same scenario", {
  # Same binormal parameters, no partial-AUC restriction -- pROC's own
  # computation (verified directly against pROC::power.roc.test()).
  res <- calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6,
                                delta = 0.037, alpha = 0.05, power = 0.8)
  expect_equal(res$n_cases, 166)
  expect_equal(res$n_controls, 166)
  expect_equal(res$n_total, 332)

  # Round-trip self-consistency: power at that n should be ~0.80.
  fit <- pROC::power.roc.test(
    list(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6, delta = 0.037),
    power = NULL, sig.level = 0.05, ncases = res$n_cases
  )
  expect_true(abs(fit$power - 0.8) < 0.01)
})

test_that("calc_compare_two_aucs respects the kappa (control:case) ratio", {
  res <- calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6,
                                delta = 0.037, alpha = 0.05, power = 0.8, kappa = 2)
  expect_equal(round(res$n_controls / res$n_cases), 2)
})

test_that("calc_compare_two_aucs rejects invalid inputs", {
  expect_error(calc_compare_two_aucs(A1 = 2.6, B1 = -1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6, delta = 0.037), "positive")
  expect_error(calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 1.5, ra = 0.6, delta = 0.037), "\\[-1, 1\\]")
  expect_error(calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6, delta = 0), "non-zero")
  expect_error(calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6, delta = 0.037, fpr11 = 0), "all provided")
  expect_error(calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6, delta = 0.037,
                                      fpr11 = 0, fpr12 = 0.2, fpr21 = 0, fpr22 = 1.5), "\\[0, 1\\]")
})
