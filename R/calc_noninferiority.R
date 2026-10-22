# Pure calculation functions for non-inferiority trial sample size (means,
# proportions, odds ratio, and hazard ratio). No Shiny dependency here so
# these are directly unit-testable (see tests/testthat). Wraps
# epiR::epi.ssninfc()/epi.ssninfb() and TrialSize::RelativeRisk.NIS()/
# Cox.NIS() rather than reimplementing the underlying math (project
# convention).

#' Sample size for a non-inferiority trial, continuous (means) outcome
#'
#' Wraps epiR::epi.ssninfc(). A non-inferiority trial aims to show a new
#' treatment is not worse than a standard treatment by more than a
#' clinically acceptable margin, rather than showing a difference exists.
#'
#' @param mean_new Expected mean of the outcome in the new-treatment group
#' @param mean_standard Expected mean of the outcome in the standard-treatment group
#' @param sd Expected population standard deviation of the outcome (> 0)
#' @param margin Non-inferiority margin (> 0): the maximum acceptable
#'   (mean_standard - mean_new) still considered "not inferior"
#' @param alpha One-sided significance level (0,1)
#' @param power Desired power (0,1)
#' @param ratio Number in the new-treatment group divided by the number in
#'   the standard-treatment group (> 0)
#' @return list(n_total, n_new, n_standard, inputs)
calc_noninferiority_means <- function(mean_new, mean_standard, sd, margin,
                                       alpha = 0.05, power = 0.8, ratio = 1) {
  .validate_number(mean_new, "mean_new")
  .validate_number(mean_standard, "mean_standard")
  .validate_positive(sd, "sd")
  .validate_positive(margin, "margin")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")

  fit <- .cf_ssninfc(treat = mean_new, control = mean_standard, sigma = sd,
                     delta = margin, power = power, r = ratio, alpha = alpha)

  new_ss_result(list(
    n_total = fit$n.total,
    n_new = fit$n.treat,
    n_standard = fit$n.control,
    inputs = list(mean_new = mean_new, mean_standard = mean_standard, sd = sd,
                  margin = margin, alpha = alpha, power = power, ratio = ratio)
  ))
}

#' Sample size for a non-inferiority trial, binary (proportions) outcome
#'
#' Wraps epiR::epi.ssninfb(). See calc_noninferiority_means() for the
#' non-inferiority framing.
#'
#' @param p_new Expected proportion of successes in the new-treatment group (0,1)
#' @param p_standard Expected proportion of successes in the standard-treatment group (0,1)
#' @param margin Non-inferiority margin (0,1): the maximum acceptable
#'   (p_standard - p_new) still considered "not inferior"
#' @param alpha One-sided significance level (0,1)
#' @param power Desired power (0,1)
#' @param ratio Number in the new-treatment group divided by the number in
#'   the standard-treatment group (> 0)
#' @return list(n_total, n_new, n_standard, inputs)
calc_noninferiority_proportions <- function(p_new, p_standard, margin,
                                             alpha = 0.05, power = 0.8, ratio = 1) {
  .validate_unit_interval(p_new, "p_new")
  .validate_unit_interval(p_standard, "p_standard")
  .validate_unit_interval(margin, "margin")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")

  fit <- .cf_ssninfb(treat = p_new, control = p_standard, delta = margin,
                     power = power, r = ratio, alpha = alpha)

  new_ss_result(list(
    n_total = fit$n.total,
    n_new = fit$n.treat,
    n_standard = fit$n.control,
    inputs = list(p_new = p_new, p_standard = p_standard, margin = margin,
                  alpha = alpha, power = power, ratio = ratio)
  ))
}

#' Sample size for a non-inferiority trial, odds ratio outcome
#'
#' Wraps TrialSize::RelativeRisk.NIS() -- despite that function's name (and
#' the "or" argument's ambiguous documentation, which even calls it "OR"
#' inconsistently in different places), reading its source confirms the
#' formula's noncentrality term is log(or) where
#' or = pt(1-pc) / (pc(1-pt)) -- the odds ratio, not the relative risk
#' pt/pc. `RelativeRisk.Equality()` (the non-inferiority package's
#' equivalent equality-test function) uses the identical odds-ratio
#' expression, confirming this is a package-wide naming inconsistency
#' (Chow, Shao & Wang 2003's own formula is genuinely odds-ratio-based),
#' not a one-off documentation typo -- so this app labels the design by
#' what the formula actually computes. TrialSize already a project
#' dependency (zero package dependencies of its own).
#'
#' @param pt Expected probability of the outcome in the test/new-treatment
#'   group (0,1)
#' @param pc Expected probability of the outcome in the control/standard
#'   group (0,1)
#' @param margin Non-inferiority margin, on the log-odds-ratio scale
#'   (i.e. the smallest acceptable log(OR); a negative value if a lower
#'   odds ratio would still be acceptable for non-inferiority)
#' @param k Allocation ratio, n_test / n_control (> 0)
#' @param alpha One-sided significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_control, n_test, n_total, or, inputs)
calc_noninferiority_or <- function(pt, pc, margin, k = 1, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(pt, "pt")
  .validate_unit_interval(pc, "pc")
  .validate_number(margin, "margin")
  .validate_positive(k, "k")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  or <- (pt * (1 - pc)) / (pc * (1 - pt))
  if (isTRUE(all.equal(log(or), margin))) {
    stop("The implied log-odds-ratio equals the margin exactly (no effect to detect).")
  }

  n_control <- TrialSize::RelativeRisk.NIS(alpha = alpha, beta = 1 - power, or = or,
                                            k = k, pt = pt, pc = pc, margin = margin)
  n_control <- ceiling(n_control)
  n_test <- ceiling(n_control * k)

  new_ss_result(list(
    n_control = n_control, n_test = n_test, n_total = n_control + n_test,
    or = or,
    inputs = list(pt = pt, pc = pc, margin = margin, k = k, alpha = alpha, power = power)
  ))
}

#' Sample size for a non-inferiority trial, hazard ratio (Cox PH) outcome
#'
#' Wraps TrialSize::Cox.NIS() (Chow, Shao & Wang 2003).
#'
#' @param hr Expected hazard ratio (test/control), > 0, e.g. hr < 1 if the
#'   new treatment is expected to reduce the hazard
#' @param margin Non-inferiority margin on the log-hazard-ratio scale
#'   (the largest acceptable log(HR) still considered "not inferior";
#'   typically a small positive number since a hazard ratio > 1 usually
#'   means a worse outcome)
#' @param p1 Proportion of patients allocated to the treatment group (0,1)
#' @param d Probability of observing an event during the study (0,1)
#' @param alpha One-sided significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, hr, inputs)
calc_noninferiority_hr <- function(hr, margin, p1 = 0.5, d = 0.8, alpha = 0.05, power = 0.8) {
  .validate_positive(hr, "hr")
  .validate_number(margin, "margin")
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(d, "d")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  loghr <- log(hr)
  if (isTRUE(all.equal(loghr, margin))) {
    stop("The log-hazard-ratio equals the margin exactly (no effect to detect).")
  }

  n <- TrialSize::Cox.NIS(alpha = alpha, beta = 1 - power, loghr = loghr,
                           p1 = p1, d = d, delta = margin)

  new_ss_result(list(
    n = ceiling(n), hr = hr,
    inputs = list(hr = hr, margin = margin, p1 = p1, d = d, alpha = alpha, power = power)
  ))
}
