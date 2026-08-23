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

#' Sample size for Cox proportional-hazards regression, binary covariate
#' of interest
#'
#' Wraps powerSurvEpi::ssizeEpi.default() (Latouche et al. 2004, reducing to
#' Schoenfeld 1983 when rho2 = 0). Accounts for competing risks (via psi,
#' the overall event probability) and, optionally, confounding/adjustment
#' for another covariate correlated with the covariate of interest (rho2).
#'
#' @param power Desired power (0,1)
#' @param theta Postulated hazard ratio for the covariate of interest, > 0, != 1
#' @param p Proportion of subjects with the covariate of interest = 1 (0,1)
#' @param psi Proportion of subjects who experience the event of interest (0,1)
#' @param rho2 Squared correlation between the covariate of interest and
#'   any other adjustment covariate, [0, 1); 0 = unadjusted/randomized
#' @param alpha Significance level, two-sided (0,1)
#' @return list(n, inputs)
calc_cox_binary <- function(power, theta, p, psi, rho2 = 0, alpha = 0.05) {
  .validate_unit_interval(power, "power")
  .validate_positive(theta, "theta")
  if (isTRUE(all.equal(theta, 1))) stop("theta must differ from 1 (no effect to detect).")
  .validate_unit_interval(p, "p")
  .validate_unit_interval(psi, "psi")
  if (!is.numeric(rho2) || length(rho2) != 1 || is.na(rho2) || rho2 < 0 || rho2 >= 1) {
    stop("rho2 must be a single number in [0, 1).")
  }
  .validate_unit_interval(alpha, "alpha")

  n <- powerSurvEpi::ssizeEpi.default(power = power, theta = theta, p = p,
                                      psi = psi, rho2 = rho2, alpha = alpha)

  list(
    n = ceiling(n),
    inputs = list(power = power, theta = theta, p = p, psi = psi, rho2 = rho2, alpha = alpha)
  )
}

#' Sample size for Cox proportional-hazards regression, continuous (or
#' other non-binary) covariate of interest
#'
#' Wraps powerSurvEpi::ssizeEpiCont.default() (Hsieh & Lavori 2000).
#'
#' @param power Desired power (0,1)
#' @param theta Postulated hazard ratio per one-unit increase in the
#'   covariate of interest, > 0, != 1
#' @param sigma2 Variance of the covariate of interest, > 0
#' @param psi Proportion of subjects who experience the event of interest (0,1)
#' @param rho2 Squared multiple correlation between the covariate of
#'   interest and other adjustment covariates, [0, 1); 0 = unadjusted
#' @param alpha Significance level, two-sided (0,1)
#' @return list(n, inputs)
calc_cox_continuous <- function(power, theta, sigma2, psi, rho2 = 0, alpha = 0.05) {
  .validate_unit_interval(power, "power")
  .validate_positive(theta, "theta")
  if (isTRUE(all.equal(theta, 1))) stop("theta must differ from 1 (no effect to detect).")
  .validate_positive(sigma2, "sigma2")
  .validate_unit_interval(psi, "psi")
  if (!is.numeric(rho2) || length(rho2) != 1 || is.na(rho2) || rho2 < 0 || rho2 >= 1) {
    stop("rho2 must be a single number in [0, 1).")
  }
  .validate_unit_interval(alpha, "alpha")

  n <- powerSurvEpi::ssizeEpiCont.default(power = power, theta = theta, sigma2 = sigma2,
                                          psi = psi, rho2 = rho2, alpha = alpha)

  list(
    n = ceiling(n),
    inputs = list(power = power, theta = theta, sigma2 = sigma2, psi = psi,
                  rho2 = rho2, alpha = alpha)
  )
}

#' Sample size for a stratified log-rank test, exponential survival,
#' binary predictor
#'
#' Wraps powerSurvEpi::ssize.stratify() (Palta & Amini 1985). Sizes a study
#' with m strata (e.g. sites, age bands) where the hazard is exponential
#' within each stratum, the treatment effect (hazard ratio) is constant
#' across strata (proportional hazards), and the analysis will be a
#' stratified log-rank test. Reduces to a single unstratified exponential
#' log-rank test when m = 1.
#'
#' @param power Desired power (0,1)
#' @param timeUnit Total study length (accrual + follow-up), > 0
#' @param gVec Proportion of the total sample size in each stratum (sums to 1)
#' @param pVec Proportion of subjects in treatment group 1 within each
#'   stratum (0,1), same length as gVec
#' @param hr Postulated hazard ratio (treatment group 1 vs. group 0), > 0, != 1
#' @param lambda0Vec Hazard for treatment group 0 (reference) in each
#'   stratum, > 0, same length as gVec
#' @param alpha Significance level, two-sided (0,1)
#' @return list(n_total, inputs)
calc_survival_stratified <- function(power, timeUnit, gVec, pVec, hr, lambda0Vec, alpha = 0.05) {
  .validate_unit_interval(power, "power")
  .validate_positive(timeUnit, "timeUnit")
  .validate_positive(hr, "hr")
  if (isTRUE(all.equal(hr, 1))) stop("hr must differ from 1 (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")

  m <- length(gVec)
  if (m < 1 || length(pVec) != m || length(lambda0Vec) != m) {
    stop("gVec, pVec, and lambda0Vec must all be the same length (one entry per stratum).")
  }
  if (any(gVec <= 0) || any(gVec >= 1)) stop("Each entry of gVec must be strictly between 0 and 1.")
  if (!isTRUE(all.equal(sum(gVec), 1))) stop("gVec must sum to 1 (proportions across strata).")
  if (any(pVec <= 0) || any(pVec >= 1)) stop("Each entry of pVec must be strictly between 0 and 1.")
  if (any(lambda0Vec <= 0)) stop("Each entry of lambda0Vec must be positive.")

  n <- powerSurvEpi::ssize.stratify(power = power, timeUnit = timeUnit, gVec = gVec,
                                    PVec = pVec, HR = hr, lambda0Vec = lambda0Vec,
                                    alpha = alpha, verbose = FALSE)

  list(
    n_total = ceiling(n),
    inputs = list(power = power, timeUnit = timeUnit, gVec = gVec, pVec = pVec,
                  hr = hr, lambda0Vec = lambda0Vec, alpha = alpha)
  )
}
