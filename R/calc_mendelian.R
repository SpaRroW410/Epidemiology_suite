# Pure calculation functions for Mendelian randomisation with a single genetic instrument (one variant or an allele score):
# sample size and power for a continuous and for a binary outcome. No Shiny dependency, so directly unit-testable
# (tests/testthat/test-calc_mendelian.R). Source, read in full (PubMed Central, PMC4052137; the equations from the article's
# equation images): Burgess S. Sample size and power calculations in Mendelian randomization with a single instrumental variable
# and a binary outcome. Int J Epidemiol 2014;43(3):922-929.
#   continuous outcome  equations 4-6 with var(R_Y) = var(X) = 1 (effect in SD of the outcome per SD of the exposure):
#     n = (z_(1-alpha/2) + z_power)^2 / (beta1^2 rho^2)        power = Phi(beta1 rho sqrt(N) - z_(1-alpha/2))
#   binary outcome      equations 9-12 (beta1 = log odds ratio per SD of the exposure):
#     N = (z_(1-alpha/2) + z_power)^2 / (beta1^2 rho^2 P(Y=1) P(Y=0))
#     power = Phi(beta1 rho sqrt(N P(Y=1) P(Y=0)) - z_(1-alpha/2))
# The paper prints the binary-outcome formulas for a 5% significance level and 80% power (7.848, 1.96); other levels use the same
# variance (its equation 9) with the corresponding normal quantiles, as its equation 4 does for the continuous outcome. The power
# is that of finding an effect in the direction of the true effect (the other tail is ignored, as in the paper). The binary
# formulas reproduce all 54 "Formula" values of the paper's validation table (Table 1).

.validate_mr_r2 <- function(r2) {
  .validate_unit_interval(r2, "r2")
  invisible(r2)
}

.validate_mr_n <- function(n, label) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 3) stop(label, " must be a single number of at least 3.")
  invisible(n)
}

#' Mendelian randomisation with a single genetic instrument, continuous outcome
#'
#' Sample size, or power at a given sample size, to detect the causal effect of an exposure on a continuous outcome when a
#' single genetic instrument (one variant or an allele score) stands in for the exposure (Burgess 2014, equations 4 to 6).
#' The effect is in standard deviations of the outcome per standard deviation of the exposure.
#'
#' @param beta Causal effect to detect: change in the outcome, in standard deviations, per standard deviation increase in the
#'   exposure (not 0).
#' @param r2 Proportion of the variance of the exposure explained by the genetic instrument (the squared correlation between
#'   instrument and exposure, R-squared of the regression of the exposure on the instrument); strictly between 0 and 1.
#' @param alpha Significance level, two-sided, strictly between 0 and 1.
#' @param power Desired power, strictly between 0 and 1 (ignored when `n` is given).
#' @param n Optional sample size; when given, the power at that sample size is returned instead of the sample size.
#' @return A named list of class `ss_result` with the components `n` (sample size), `achieved_power` and `inputs`, the
#'   arguments the result was calculated from.
#' @examples
#' calc_mr_continuous(beta = 0.2, r2 = 0.02)
#' calc_mr_continuous(beta = 0.2, r2 = 0.02, n = 5000)$achieved_power
#' @export
calc_mr_continuous <- function(beta, r2, alpha = 0.05, power = 0.8, n = NULL) {
  .validate_number(beta, "beta")
  if (isTRUE(all.equal(beta, 0))) stop("beta must differ from 0 (no effect to detect).")
  .validate_mr_r2(r2)
  .validate_unit_interval(alpha, "alpha")
  za <- stats::qnorm(1 - alpha / 2)
  if (is.null(n)) {
    .validate_unit_interval(power, "power")
    n <- ceiling((za + stats::qnorm(power))^2 / (beta^2 * r2))
  } else {
    .validate_mr_n(n, "n")
  }
  new_ss_result(list(
    n = n,
    achieved_power = stats::pnorm(abs(beta) * sqrt(r2) * sqrt(n) - za),
    inputs = list(beta = beta, r2 = r2, alpha = alpha, power = power)
  ))
}

#' Mendelian randomisation with a single genetic instrument, binary outcome
#'
#' Number of cases and controls, or power at a given number, to detect the causal effect of an exposure on a binary outcome
#' (disease) when a single genetic instrument (one variant or an allele score) stands in for the exposure (Burgess 2014,
#' equations 9 to 12). The effect is an odds ratio per standard deviation of the exposure.
#'
#' @param or Causal odds ratio of the outcome per standard deviation increase in the exposure (greater than 0, not 1).
#' @param r2 Proportion of the variance of the exposure explained by the genetic instrument (the squared correlation between
#'   instrument and exposure); strictly between 0 and 1.
#' @param controls_per_case Number of controls per case (greater than 0; default 1).
#' @param alpha Significance level, two-sided, strictly between 0 and 1.
#' @param power Desired power, strictly between 0 and 1 (ignored when `n_cases` is given).
#' @param n_cases Optional number of cases; when given, the power with that many cases (and `controls_per_case` times as many
#'   controls) is returned instead of the sample size.
#' @return A named list of class `ss_result` with the components `n_total`, `n_cases`, `n_controls`, `achieved_power` and
#'   `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_mr_binary(or = exp(0.2), r2 = 0.02)
#' # 0.807, as in Burgess 2014, Table 1
#' calc_mr_binary(or = exp(0.2), r2 = 0.02, n_cases = 20000)$achieved_power
#' @export
calc_mr_binary <- function(or, r2, controls_per_case = 1, alpha = 0.05, power = 0.8, n_cases = NULL) {
  .validate_positive(or, "or")
  if (isTRUE(all.equal(or, 1))) stop("or must differ from 1 (no effect to detect).")
  .validate_mr_r2(r2)
  .validate_positive(controls_per_case, "controls_per_case")
  .validate_unit_interval(alpha, "alpha")
  beta <- log(or)
  za <- stats::qnorm(1 - alpha / 2)
  p_case <- 1 / (1 + controls_per_case)
  if (is.null(n_cases)) {
    .validate_unit_interval(power, "power")
    n_raw <- (za + stats::qnorm(power))^2 / (beta^2 * r2 * p_case * (1 - p_case))
    n_cases <- ceiling(n_raw * p_case)
  } else {
    .validate_mr_n(n_cases, "n_cases")
  }
  n_controls <- ceiling(n_cases * controls_per_case)
  n_total <- n_cases + n_controls
  p <- n_cases / n_total
  new_ss_result(list(
    n_total = n_total,
    n_cases = n_cases,
    n_controls = n_controls,
    achieved_power = stats::pnorm(abs(beta) * sqrt(r2) * sqrt(n_total * p * (1 - p)) - za),
    inputs = list(or = or, r2 = r2, controls_per_case = controls_per_case, alpha = alpha, power = power)
  ))
}
