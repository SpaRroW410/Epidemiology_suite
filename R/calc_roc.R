# Pure calculation function for a single ROC curve's AUC sample size. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). The Obuchowski formulas are written out in calc_closed_forms_pwr.R and
# equal pROC::power.roc.test() (the tests compare them).

#' Sample size to detect that a single test's AUC differs from chance (0.5)
#'
#' Obuchowski's sample size (equal to pROC::power.roc.test()) for the one-ROC-curve case (Obuchowski et
#' al. 2004, formulas 2 and 3). Solves the number of cases (subjects with
#' the target condition) needed given the expected AUC, then the number of
#' controls via the case:control ratio (kappa).
#'
#' @param auc Expected AUC of the test (0.5, 1) -- must be better than chance
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param kappa Ratio of controls to cases (> 0); 1 = equal allocation
#' @return list(n_cases, n_controls, n_total, inputs)
#' @examples
#' calc_roc_auc(auc = 0.73, alpha = 0.05, power = 0.95, kappa = 1.7)
#' @export
calc_roc_auc <- function(auc, alpha = 0.05, power = 0.8, kappa = 1) {
  if (!is.numeric(auc) || length(auc) != 1 || is.na(auc) || auc <= 0.5 || auc >= 1) {
    stop("auc must be a single number strictly between 0.5 and 1.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(kappa, "kappa")

  res <- .cf_pwr_roc_auc(auc = auc, sig.level = alpha, power = power, kappa = kappa)

  n_cases <- ceiling(res$ncases)
  n_controls <- ceiling(res$ncontrols)

  new_ss_result(list(
    n_cases = n_cases,
    n_controls = n_controls,
    n_total = n_cases + n_controls,
    inputs = list(auc = auc, alpha = alpha, power = power, kappa = kappa)
  ))
}

#' Sample size to compare two correlated (paired) ROC curves' AUCs
#'
#' Obuchowski & McClish's sample size (equal to pROC::power.roc.test()) for the two-ROC-curve case with a list
#' of binormal parameters (no empirical ROC curve needed) -- Obuchowski &
#' McClish (1997)'s method for comparing two AUCs measured on the same
#' subjects (e.g. two diagnostic tests applied to the same patients).
#' Each curve's shape is described by its own binormal A/B parameters
#' (see e.g. Metz 1978); the correlation between the two tests' results
#' is given separately for the diseased ("cases") and non-diseased
#' ("controls") subgroups, since it need not be the same in both. An
#' optional partial-AUC region (restricted to a false-positive-rate
#' range) can be specified via the fpr* arguments; omitting them
#' compares the FULL AUC of each curve.
#'
#' @param A1,B1 Binormal parameters for ROC curve 1
#' @param A2,B2 Binormal parameters for ROC curve 2
#' @param rn Correlation between the two tests' results in controls (non-diseased)
#' @param ra Correlation between the two tests' results in cases (diseased)
#' @param delta The AUC (or partial-AUC) difference between the two curves to detect (!= 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param kappa Ratio of controls to cases (> 0); 1 = equal allocation
#' @param fpr11,fpr12 Upper/lower FPR bounds for curve 1's partial AUC (both NULL = full AUC)
#' @param fpr21,fpr22 Upper/lower FPR bounds for curve 2's partial AUC (both NULL = full AUC)
#' @return list(n_cases, n_controls, n_total, inputs)
#' @examples
#' calc_compare_two_aucs(A1 = 2.6, B1 = 1, A2 = 1.9, B2 = 1, rn = 0.6, ra = 0.6, delta = 0.037, 
#'     alpha = 0.05, power = 0.8, fpr11 = 0, fpr12 = 0.2, fpr21 = 0, fpr22 = 0.2)
#' @export
calc_compare_two_aucs <- function(A1, B1, A2, B2, rn, ra, delta,
                                   alpha = 0.05, power = 0.8, kappa = 1,
                                   fpr11 = NULL, fpr12 = NULL, fpr21 = NULL, fpr22 = NULL) {
  .validate_number(A1, "A1"); .validate_positive(B1, "B1")
  .validate_number(A2, "A2"); .validate_positive(B2, "B2")
  if (!is.numeric(rn) || length(rn) != 1 || is.na(rn) || rn < -1 || rn > 1) {
    stop("rn must be a single number in [-1, 1].")
  }
  if (!is.numeric(ra) || length(ra) != 1 || is.na(ra) || ra < -1 || ra > 1) {
    stop("ra must be a single number in [-1, 1].")
  }
  if (!is.numeric(delta) || length(delta) != 1 || is.na(delta) || delta == 0) {
    stop("delta must be a single non-zero number.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(kappa, "kappa")

  fpr_args <- list(fpr11 = fpr11, fpr12 = fpr12, fpr21 = fpr21, fpr22 = fpr22)
  fpr_given <- !vapply(fpr_args, is.null, logical(1))
  if (any(fpr_given) && !all(fpr_given)) {
    stop("fpr11, fpr12, fpr21, and fpr22 must be either all provided (partial AUC) or all omitted (full AUC).")
  }

  if (all(fpr_given)) {
    for (nm in names(fpr_args)) {
      if (!is.numeric(fpr_args[[nm]]) || length(fpr_args[[nm]]) != 1 || is.na(fpr_args[[nm]]) ||
            fpr_args[[nm]] < 0 || fpr_args[[nm]] > 1) {
        stop(sprintf("%s must be a single number in [0, 1].", nm))
      }
    }
  }

  res <- .cf_pwr_roc_two(A1 = A1, B1 = B1, A2 = A2, B2 = B2, rn = rn, ra = ra, delta = delta, sig.level = alpha, power = power,
                         kappa = kappa, fpr11 = fpr11, fpr12 = fpr12, fpr21 = fpr21, fpr22 = fpr22)

  n_cases <- ceiling(res$ncases)
  n_controls <- ceiling(res$ncontrols)

  new_ss_result(list(
    n_cases = n_cases,
    n_controls = n_controls,
    n_total = n_cases + n_controls,
    inputs = list(A1 = A1, B1 = B1, A2 = A2, B2 = B2, rn = rn, ra = ra, delta = delta,
                  alpha = alpha, power = power, kappa = kappa,
                  fpr11 = fpr11, fpr12 = fpr12, fpr21 = fpr21, fpr22 = fpr22)
  ))
}
