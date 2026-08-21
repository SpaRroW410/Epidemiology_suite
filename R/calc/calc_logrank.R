# Pure calculation function for log-rank test sample size. No Shiny
# dependency here so this is directly unit-testable (see tests/testthat).
# Wraps powerSurvEpi::ssizeCT.default() (Freedman 1982, via Rosner 2006)
# rather than reimplementing the underlying math (project convention).

#' Sample size for comparing two survival curves (log-rank test)
#'
#' Wraps powerSurvEpi::ssizeCT.default(). Sizes a study to detect a given
#' hazard ratio between an experimental and control group over a fixed
#' maximum follow-up period, expressed via each group's expected cumulative
#' probability of the event (not person-time/rate-based).
#'
#' @param pE Expected probability of the event in the experimental group,
#'   over the maximum follow-up period (0,1)
#' @param pC Expected probability of the event in the control group, over
#'   the same period (0,1)
#' @param hr Postulated hazard ratio (experimental vs. control), > 0, != 1
#' @param ratio Number of participants in the experimental group divided by
#'   the number in the control group (> 0)
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n_exp, n_control, n_total, inputs)
calc_logrank <- function(pE, pC, hr, ratio = 1, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(pE, "pE")
  .validate_unit_interval(pC, "pC")
  .validate_positive(hr, "hr")
  if (isTRUE(all.equal(hr, 1))) stop("hr must differ from 1 (no effect to detect).")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- powerSurvEpi::ssizeCT.default(power = power, k = ratio, pE = pE, pC = pC,
                                       RR = hr, alpha = alpha)

  n_exp <- ceiling(fit[["nE"]])
  n_control <- ceiling(fit[["nC"]])

  list(
    n_exp = n_exp,
    n_control = n_control,
    n_total = n_exp + n_control,
    inputs = list(pE = pE, pC = pC, hr = hr, ratio = ratio, alpha = alpha, power = power)
  )
}
