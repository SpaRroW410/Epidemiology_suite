# Pure calculation functions for proportion-based sample size.
# No Shiny dependency here so these are directly unit-testable (see tests/testthat).

#' Sample size for a single proportion vs. a known/reference value
#'
#' Wraps pwr::pwr.p.test (Cohen's arcsine-transformed effect size h).
#'
#' @param p0 Reference/hypothesized proportion (0,1)
#' @param p1 Expected/anticipated true proportion (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, h, inputs)
calc_proportion_1s <- function(p0, p1, alpha = 0.05, power = 0.8,
                                alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_prop(p0, "p0")
  .validate_prop(p1, "p1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p0, p1))) {
    stop("p0 and p1 must differ (no effect to detect).")
  }

  h <- pwr::ES.h(p1, p0)
  fit <- pwr::pwr.p.test(h = h, sig.level = alpha, power = power,
                          alternative = alternative)

  list(
    n = ceiling(fit$n),
    h = h,
    inputs = list(p0 = p0, p1 = p1, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size for two independent proportions (equal allocation)
#'
#' Wraps pwr::pwr.2p.test (Cohen's arcsine-transformed effect size h).
#'
#' @param p1 Proportion in group 1 (0,1)
#' @param p2 Proportion in group 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, n_total, h, inputs)
calc_proportion_2s <- function(p1, p2, alpha = 0.05, power = 0.8,
                                alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_prop(p1, "p1")
  .validate_prop(p2, "p2")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p1, p2))) {
    stop("p1 and p2 must differ (no effect to detect).")
  }

  h <- pwr::ES.h(p1, p2)
  fit <- pwr::pwr.2p.test(h = h, sig.level = alpha, power = power,
                           alternative = alternative)
  n_per_group <- ceiling(fit$n)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    h = h,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

.validate_prop <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0 || x >= 1) {
    stop(sprintf("%s must be a single number strictly between 0 and 1.", label))
  }
}

.validate_unit_interval <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0 || x >= 1) {
    stop(sprintf("%s must be a single number strictly between 0 and 1.", label))
  }
}
