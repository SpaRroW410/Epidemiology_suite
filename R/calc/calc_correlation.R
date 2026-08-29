# Pure calculation function for Pearson correlation sample size.
# No Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps pwr::pwr.r.test() rather than reimplementing the
# underlying math (project convention).

#' Sample size to detect a Pearson correlation
#'
#' Wraps pwr::pwr.r.test() (Cohen 1988), using the Fisher z' transformation.
#'
#' @param r Expected correlation coefficient (-1, 1), != 0
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, inputs)
calc_correlation <- function(r, alpha = 0.05, power = 0.8,
                              alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  if (!is.numeric(r) || length(r) != 1 || is.na(r) || r <= -1 || r >= 1) {
    stop("r must be a single number strictly between -1 and 1.")
  }
  if (isTRUE(all.equal(r, 0))) stop("r must not be zero (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- pwr::pwr.r.test(r = r, sig.level = alpha, power = power,
                          alternative = alternative)

  list(
    n = ceiling(fit$n),
    inputs = list(r = r, alpha = alpha, power = power, alternative = alternative)
  )
}

#' Sample size to compare two independent Pearson correlations
#'
#' Closed-form (Cohen 1988): Cohen's q effect size via the Fisher z'
#' transformation of each correlation, then the standard two-sample
#' normal-test sample size formula for a known-variance difference. No
#' dedicated function exists in pwr for this two-sample case (only
#' pwr::pwr.r.test() for a single correlation against zero), so this is
#' reimplemented directly from the closed-form algebra rather than a
#' package wrap.
#'
#' @param r1 Expected correlation in group 1 (-1, 1)
#' @param r2 Expected correlation in group 2 (-1, 1); must differ from r1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, q, inputs)
calc_correlation_two_independent <- function(r1, r2, alpha = 0.05, power = 0.8,
                                              alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  if (!is.numeric(r1) || length(r1) != 1 || is.na(r1) || r1 <= -1 || r1 >= 1) {
    stop("r1 must be a single number strictly between -1 and 1.")
  }
  if (!is.numeric(r2) || length(r2) != 1 || is.na(r2) || r2 <= -1 || r2 >= 1) {
    stop("r2 must be a single number strictly between -1 and 1.")
  }
  if (isTRUE(all.equal(r1, r2))) stop("r1 and r2 must differ (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  q <- abs(atanh(r1) - atanh(r2))
  z_alpha <- if (identical(alternative, "two.sided")) qnorm(1 - alpha / 2) else qnorm(1 - alpha)
  z_beta <- qnorm(power)
  n <- ((z_alpha + z_beta) / q)^2 + 3

  list(
    n_per_group = ceiling(n),
    q = q,
    inputs = list(r1 = r1, r2 = r2, alpha = alpha, power = power, alternative = alternative)
  )
}
