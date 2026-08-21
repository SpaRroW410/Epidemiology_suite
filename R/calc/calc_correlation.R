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
