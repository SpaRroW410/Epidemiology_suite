# Pure calculation functions for non-inferiority trial sample size (means
# and proportions). No Shiny dependency here so these are directly
# unit-testable (see tests/testthat). Wraps epiR::epi.ssninfc() /
# epi.ssninfb() rather than reimplementing the underlying math (project
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

  fit <- epiR::epi.ssninfc(treat = mean_new, control = mean_standard, sigma = sd,
                            delta = margin, n = NA, power = power, r = ratio,
                            nfractional = FALSE, alpha = alpha)

  list(
    n_total = fit$n.total,
    n_new = fit$n.treat,
    n_standard = fit$n.control,
    inputs = list(mean_new = mean_new, mean_standard = mean_standard, sd = sd,
                  margin = margin, alpha = alpha, power = power, ratio = ratio)
  )
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

  fit <- epiR::epi.ssninfb(treat = p_new, control = p_standard, delta = margin,
                            n = NA, power = power, r = ratio,
                            nfractional = FALSE, alpha = alpha)

  list(
    n_total = fit$n.total,
    n_new = fit$n.treat,
    n_standard = fit$n.control,
    inputs = list(p_new = p_new, p_standard = p_standard, margin = margin,
                  alpha = alpha, power = power, ratio = ratio)
  )
}
