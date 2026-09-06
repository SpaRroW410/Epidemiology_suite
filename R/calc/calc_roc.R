# Pure calculation function for a single ROC curve's AUC sample size. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps pROC::power.roc.test() rather than reimplementing
# the underlying math (project convention).

#' Sample size to detect that a single test's AUC differs from chance (0.5)
#'
#' Wraps pROC::power.roc.test() for the one-ROC-curve case (Obuchowski et
#' al. 2004, formulas 2 and 3). Solves the number of cases (subjects with
#' the target condition) needed given the expected AUC, then the number of
#' controls via the case:control ratio (kappa).
#'
#' @param auc Expected AUC of the test (0.5, 1) -- must be better than chance
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param kappa Ratio of controls to cases (> 0); 1 = equal allocation
#' @return list(n_cases, n_controls, n_total, inputs)
calc_roc_auc <- function(auc, alpha = 0.05, power = 0.8, kappa = 1) {
  if (!is.numeric(auc) || length(auc) != 1 || is.na(auc) || auc <= 0.5 || auc >= 1) {
    stop("auc must be a single number strictly between 0.5 and 1.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(kappa, "kappa")

  res <- pROC::power.roc.test(auc = auc, sig.level = alpha, power = power, kappa = kappa)

  n_cases <- ceiling(res$ncases)
  n_controls <- ceiling(res$ncontrols)

  list(
    n_cases = n_cases,
    n_controls = n_controls,
    n_total = n_cases + n_controls,
    inputs = list(auc = auc, alpha = alpha, power = power, kappa = kappa)
  )
}
