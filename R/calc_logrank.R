# Pure calculation function for log-rank test sample size. No Shiny
# dependency here so this is directly unit-testable (see tests/testthat).
# Wraps .cf_pse_ssize_ct() (Freedman 1982, via Rosner 2006)
# rather than reimplementing the underlying math (project convention).

#' Sample size for comparing two survival curves (log-rank test)
#'
#' Wraps .cf_pse_ssize_ct(). Sizes a study to detect a given
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
#' @examples
#' calc_logrank(pE = 0.3707, pC = 0.489, hr = 0.7, ratio = 1, alpha = 0.05, power = 0.8)
#' @export
calc_logrank <- function(pE, pC, hr, ratio = 1, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(pE, "pE")
  .validate_unit_interval(pC, "pC")
  .validate_positive(hr, "hr")
  if (isTRUE(all.equal(hr, 1))) stop("hr must differ from 1 (no effect to detect).")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- .cf_pse_ssize_ct(power = power, k = ratio, pE = pE, pC = pC,
                                       RR = hr, alpha = alpha)

  n_exp <- ceiling(fit[["nE"]])
  n_control <- ceiling(fit[["nC"]])

  new_ss_result(list(
    n_exp = n_exp,
    n_control = n_control,
    n_total = n_exp + n_control,
    inputs = list(pE = pE, pC = pC, hr = hr, ratio = ratio, alpha = alpha, power = power)
  ))
}

#' Sample size for Cox proportional-hazards regression, binary covariate
#' of interest
#'
#' Wraps .cf_pse_ssize_epi() (Latouche et al. 2004, reducing to
#' Schoenfeld 1983 when rho2 = 0). Accounts for competing risks (via psi,
#' the overall event probability) and, optionally, confounding/adjustment
#' for another covariate correlated with the covariate of interest (rho2).
#'
#' @param power Desired power (0,1)
#' @param theta Postulated hazard ratio for the covariate of interest, > 0, != 1
#' @param p Proportion of subjects with the covariate of interest = 1 (0,1)
#' @param psi Proportion of subjects who experience the event of interest (0,1)
#' @param rho2 Squared correlation between the covariate of interest and
#'   any other adjustment covariate, \[0, 1); 0 = unadjusted/randomized
#' @param alpha Significance level, two-sided (0,1)
#' @return list(n, inputs)
#' @examples
#' calc_cox_binary(power = 0.8, theta = 2, p = 0.39, psi = 0.505, rho2 = 0.132^2)
#' @export
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

  n <- .cf_pse_ssize_epi(power = power, theta = theta, p = p,
                                      psi = psi, rho2 = rho2, alpha = alpha)

  new_ss_result(list(
    n = ceiling(n),
    inputs = list(power = power, theta = theta, p = p, psi = psi, rho2 = rho2, alpha = alpha)
  ))
}

#' Sample size for Cox proportional-hazards regression, continuous (or
#' other non-binary) covariate of interest
#'
#' Wraps .cf_pse_ssize_epi_cont() (Hsieh & Lavori 2000).
#'
#' @param power Desired power (0,1)
#' @param theta Postulated hazard ratio per one-unit increase in the
#'   covariate of interest, > 0, != 1
#' @param sigma2 Variance of the covariate of interest, > 0
#' @param psi Proportion of subjects who experience the event of interest (0,1)
#' @param rho2 Squared multiple correlation between the covariate of
#'   interest and other adjustment covariates, \[0, 1); 0 = unadjusted
#' @param alpha Significance level, two-sided (0,1)
#' @return list(n, inputs)
#' @examples
#' calc_cox_continuous(power = 0.806, theta = exp(1), sigma2 = 0.3126^2, psi = 0.738, 
#'     rho2 = 0.1837, alpha = 0.1)
#' @export
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

  n <- .cf_pse_ssize_epi_cont(power = power, theta = theta, sigma2 = sigma2,
                                          psi = psi, rho2 = rho2, alpha = alpha)

  new_ss_result(list(
    n = ceiling(n),
    inputs = list(power = power, theta = theta, sigma2 = sigma2, psi = psi,
                  rho2 = rho2, alpha = alpha)
  ))
}

#' Sample size for a stratified log-rank test, exponential survival,
#' binary predictor
#'
#' Wraps .cf_pse_ssize_stratify() (Palta & Amini 1985). Sizes a study
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
#' @examples
#' calc_survival_stratified(power = 0.9, timeUnit = 1.25, gVec = c(0.5, 0.5), pVec = c(0.5, 
#'     0.5), hr = 1/1.91, lambda0Vec = c(2.303, 1.139), alpha = 0.05)
#' @export
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

  n <- .cf_pse_ssize_stratify(power = power, timeUnit = timeUnit, gVec = gVec,
                                    PVec = pVec, HR = hr, lambda0Vec = lambda0Vec,
                                    alpha = alpha)

  new_ss_result(list(
    n_total = ceiling(n),
    inputs = list(power = power, timeUnit = timeUnit, gVec = gVec, pVec = pVec,
                  hr = hr, lambda0Vec = lambda0Vec, alpha = alpha)
  ))
}

# Weighted log-rank test (Fleming-Harrington G^rho family) under
# non-proportional hazards, via Monte Carlo simulation.
#
# The checklist's named package, `npsurvSS`, is not installed and CRAN is
# unreachable from this sandbox. Its source (read from its public GitHub
# CRAN mirror, https://github.com/cran/npsurvSS) implements a general
# two-parameter Fleming-Harrington G(rho,gamma) weighted log-rank family
# via numerical integration over an "arm" S4-style class spanning 11
# interdependent R files (survival/accrual/loss-to-follow-up
# distributions, counting-process moments, etc.) -- too large and
# tightly cross-referenced to safely reimplement and verify in one
# sitting (the same judgment call already made for `gsDesign`). The
# checklist item itself explicitly allows "npsurvSS/simulation", so this
# instead directly simulates the actual test via `survival::survdiff()`
# (already an installed project dependency, used elsewhere for Cox/RMST
# designs), which implements the one-parameter Fleming-Harrington G^rho
# family (`rho` argument: rho=0 is the ordinary log-rank test, rho=1 is
# the Gehan-Breslow/Wilcoxon-type test that up-weights early-follow-up
# differences via a weight of S(t-)^rho) -- Harrington & Fleming (1982).
# This is a narrower (one-parameter, not the full two-parameter G(rho,
# gamma)) but entirely genuine weighted log-rank family, not an
# approximation of one.
#
# Verified against well-documented properties of this family under two
# canonical non-proportional-hazards shapes: under a DELAYED treatment
# effect (hazards equal at first, diverge later), rho=0 (log-rank)
# outperforms rho=1 (which wastes power up-weighting the early period
# where there's no difference yet); under an EARLY/FADING effect
# (hazards diverge at first, converge later), rho=1 outperforms rho=0 --
# the mirror-image result, both confirmed directly by simulation before
# wiring into the app (see tests/testthat/test-calc_logrank.R).

.simulate_wlr_trial <- function(n0, n1, hazard0, hr, change_time, effect_timing, accrual, tot_time) {
  sim_arm <- function(n, haz_pre, haz_post) {
    u <- runif(n)
    cum_target <- -log(u)
    cum_at_change <- haz_pre * change_time
    is_before <- cum_target <= cum_at_change
    ifelse(is_before, cum_target / haz_pre,
           change_time + (cum_target - cum_at_change) / haz_post)
  }
  if (effect_timing == "delayed") {
    E0 <- sim_arm(n0, hazard0, hazard0)
    E1 <- sim_arm(n1, hazard0, hazard0 * hr)
  } else {
    E0 <- sim_arm(n0, hazard0, hazard0)
    E1 <- sim_arm(n1, hazard0 * hr, hazard0)
  }
  C0 <- tot_time - runif(n0, 0, accrual)
  C1 <- tot_time - runif(n1, 0, accrual)
  time0 <- pmin(E0, C0); status0 <- as.numeric(E0 <= C0)
  time1 <- pmin(E1, C1); status1 <- as.numeric(E1 <= C1)
  data.frame(
    time = c(time0, time1), status = c(status0, status1),
    arm = c(rep(0, n0), rep(1, n1))
  )
}

.wlr_empirical_power <- function(n0, n1, hazard0, hr, change_time, effect_timing,
                                  accrual, tot_time, rho, alpha, reps, seed) {
  set.seed(seed)
  survdiff <- .pkg_fn("survival", "survdiff")
  Surv <- .pkg_fn("survival", "Surv")   # found by the formula below, whose environment is this function's
  rejections <- replicate(reps, {
    d <- .simulate_wlr_trial(n0, n1, hazard0, hr, change_time, effect_timing, accrual, tot_time)
    d <- d[d$time > 0, ]
    sd <- tryCatch(
      survdiff(Surv(time, status) ~ arm, data = d, rho = rho),
      error = function(e) NULL
    )
    if (is.null(sd)) return(FALSE)
    (1 - pchisq(sd$chisq, df = 1)) < alpha
  })
  mean(rejections)
}

#' Sample size for a weighted log-rank test under non-proportional
#' hazards, via Monte Carlo simulation
#'
#' Solves for the per-arm sample size needed for a target power against a
#' non-proportional-hazards alternative, using the Fleming-Harrington
#' G^rho family of weighted log-rank tests (`survival::survdiff(...,
#' rho = rho)`; rho = 0 is the ordinary log-rank test). Two canonical
#' non-PH shapes are supported: a DELAYED effect (both arms share the
#' same hazard until `change_time`, after which the treatment arm's
#' hazard becomes `hazard0 * hr`) and an EARLY/FADING effect (the arms
#' differ by `hr` until `change_time`, after which they converge back to
#' the same hazard). Both are exponential-hazard, staggered-accrual,
#' administratively-censored designs.
#'
#' @param hazard0 Baseline (control-arm) hazard, > 0
#' @param hr Treatment-arm hazard ratio during the "effect" period
#'   (> 0, != 1)
#' @param change_time Time at which the hazard ratio switches on
#'   (`effect_timing = "early_fading"`) or off (`"delayed"`); must be
#'   less than `tot_time`
#' @param effect_timing `"delayed"` (no difference until `change_time`,
#'   then `hr` applies) or `"early_fading"` (`hr` applies until
#'   `change_time`, then no difference)
#' @param accrual Accrual (enrollment) period length (> 0)
#' @param tot_time Total study time (time of final analysis); must be
#'   greater than `accrual` and `change_time`
#' @param rho Fleming-Harrington weight parameter (>= 0); 0 = ordinary
#'   log-rank, 1 = Gehan-Breslow/Wilcoxon-type (up-weights early-
#'   follow-up differences)
#' @param allocation1 Proportion of patients allocated to the treatment
#'   arm (0,1), default 0.5
#' @param alpha Significance level (0,1), default 0.05
#' @param power Desired power (0,1), default 0.8
#' @param nsim Monte Carlo replicates per sample-size candidate evaluated
#'   during the search (>= 100)
#' @param seed RNG seed for reproducibility
#' @return list(n0, n1, n_total, achieved_power, inputs)
#' @examples
#' \donttest{
#' # nsim is kept small so that the example runs quickly; use the default (or more) for a real calculation
#' calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4, effect_timing = "delayed", 
#'     accrual = 12, tot_time = 30, rho = 0, power = 0.8, nsim = 100)
#' }
#' @export
calc_weighted_logrank <- function(hazard0, hr, change_time, effect_timing = "delayed",
                                   accrual, tot_time, rho = 0, allocation1 = 0.5,
                                   alpha = 0.05, power = 0.8, nsim = 300, seed = 20200601) {
  .validate_positive(hazard0, "hazard0")
  .validate_positive(hr, "hr")
  if (isTRUE(all.equal(hr, 1))) stop("hr must differ from 1 (no effect to detect).")
  .validate_positive(change_time, "change_time")
  if (!effect_timing %in% c("delayed", "early_fading")) {
    stop('effect_timing must be "delayed" or "early_fading".')
  }
  .validate_positive(accrual, "accrual")
  .validate_positive(tot_time, "tot_time")
  if (tot_time <= accrual) stop("tot_time must be greater than accrual.")
  if (change_time >= tot_time) stop("change_time must be less than tot_time.")
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || rho < 0) {
    stop("rho must be a single number >= 0.")
  }
  .validate_unit_interval(allocation1, "allocation1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 100 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 100.")
  }

  ratio <- allocation1 / (1 - allocation1)

  empirical_power <- function(n0, reps) {
    n1 <- max(2, round(n0 * ratio))
    .wlr_empirical_power(n0, n1, hazard0, hr, change_time, effect_timing,
                         accrual, tot_time, rho, alpha, reps, seed)
  }

  n0 <- .mc_search_n1(function(n) empirical_power(n, nsim), power, n_lo = 10, n_hi = 20, n_max = 5000)
  n1 <- max(2, round(n0 * ratio))

  new_ss_result(list(
    n0 = n0, n1 = n1, n_total = n0 + n1,
    achieved_power = empirical_power(n0, nsim * 3),
    inputs = list(hazard0 = hazard0, hr = hr, change_time = change_time,
                  effect_timing = effect_timing, accrual = accrual, tot_time = tot_time,
                  rho = rho, allocation1 = allocation1, alpha = alpha, power = power,
                  nsim = nsim)
  ))
}
