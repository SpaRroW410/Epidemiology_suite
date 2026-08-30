# Pure calculation functions for testing a single variance against a
# reference value, or comparing two variances. No package needed: these
# are closed-form (deterministic, no simulation) solves for n via
# uniroot() over the chi-squared/F power functions -- the same pattern
# already used elsewhere in this app (e.g. calc_rate.R's
# calc_rate_comparison()).
#
# TrialSize::ISV.Equality() and ISCV.Equality() were investigated as
# possible backends for the two-variance case (Chow, Shao & Wang 2003
# names them as intra-subject-variability tests, but their formula is
# the general two-variance F-test) and found to be genuinely broken in
# the installed package: ISV.Equality()'s for-loop never compares its
# computed ratio to anything and returns NULL; ISCV.Equality() has a
# literal missing multiplication operator ("(sigma1+sigma2)(...)",
# parsed as an attempt to call the sum as a function) and throws a
# runtime error on any input. Both are unusable without a from-scratch
# reimplementation this session couldn't verify against the broken
# function's intended behavior -- so this file reimplements the
# standard formulas directly instead, verified by Monte Carlo
# simulation (empirical power at the solved n matches the target power
# closely) since no citable package example was available to check
# against.

#' Sample size to test a single variance against a reference value
#'
#' Tests H0: sigma^2 = sigma0^2 vs. an alternative true sigma1^2, using
#' the standard result that (n-1)*S^2/sigma0^2 ~ chi-squared(n-1) under
#' H0. Solves for n via uniroot on the power function (no closed
#' algebraic form exists, but the power-as-a-function-of-n relationship
#' is deterministic and monotonic, so this is still an exact closed-form
#' solve, not a simulation).
#'
#' @param sigma0 Reference (null-hypothesis) standard deviation (> 0)
#' @param sigma1 Assumed true standard deviation (> 0), != sigma0
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "greater" (sigma1 > sigma0), or
#'   "less" (sigma1 < sigma0)
#' @return list(n, inputs)
calc_variance_single <- function(sigma0, sigma1, alpha = 0.05, power = 0.8,
                                  alternative = c("two.sided", "greater", "less")) {
  alternative <- match.arg(alternative)
  .validate_positive(sigma0, "sigma0")
  .validate_positive(sigma1, "sigma1")
  if (isTRUE(all.equal(sigma0, sigma1))) {
    stop("sigma0 and sigma1 must differ (no effect to detect).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (alternative == "greater" && sigma1 < sigma0) {
    stop("alternative = \"greater\" tests sigma1 > sigma0, but sigma1 < sigma0 here -- use \"less\" or \"two.sided\" instead.")
  }
  if (alternative == "less" && sigma1 > sigma0) {
    stop("alternative = \"less\" tests sigma1 < sigma0, but sigma1 > sigma0 here -- use \"greater\" or \"two.sided\" instead.")
  }

  ratio <- (sigma1 / sigma0)^2

  power_at_n <- function(n) {
    df <- n - 1
    if (alternative == "greater") {
      crit <- stats::qchisq(1 - alpha, df)
      1 - stats::pchisq(crit / ratio, df)
    } else if (alternative == "less") {
      crit <- stats::qchisq(alpha, df)
      stats::pchisq(crit / ratio, df)
    } else {
      crit_lo <- stats::qchisq(alpha / 2, df)
      crit_hi <- stats::qchisq(1 - alpha / 2, df)
      1 - (stats::pchisq(crit_hi / ratio, df) - stats::pchisq(crit_lo / ratio, df))
    }
  }

  n_solved <- stats::uniroot(function(n) power_at_n(n) - power, c(3, 1e6))$root

  list(
    n = ceiling(n_solved),
    inputs = list(sigma0 = sigma0, sigma1 = sigma1, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size to compare two variances (equal group sizes)
#'
#' Tests H0: sigma1^2 = sigma2^2 vs. a true ratio sigma1^2/sigma2^2,
#' using the standard result that S1^2/S2^2 / (sigma1^2/sigma2^2) ~
#' F(n-1, n-1) for equal group sizes n. Solves for the common per-group
#' n via uniroot on the power function, the two-variance analog of
#' calc_variance_single() above.
#'
#' @param sigma1 Assumed standard deviation, group 1 (> 0)
#' @param sigma2 Assumed standard deviation, group 2 (> 0), != sigma1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "greater" (sigma1 > sigma2), or
#'   "less" (sigma1 < sigma2)
#' @return list(n_per_group, n_total, inputs)
calc_variance_two <- function(sigma1, sigma2, alpha = 0.05, power = 0.8,
                               alternative = c("two.sided", "greater", "less")) {
  alternative <- match.arg(alternative)
  .validate_positive(sigma1, "sigma1")
  .validate_positive(sigma2, "sigma2")
  if (isTRUE(all.equal(sigma1, sigma2))) {
    stop("sigma1 and sigma2 must differ (no effect to detect).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (alternative == "greater" && sigma1 < sigma2) {
    stop("alternative = \"greater\" tests sigma1 > sigma2, but sigma1 < sigma2 here -- use \"less\" or \"two.sided\" instead.")
  }
  if (alternative == "less" && sigma1 > sigma2) {
    stop("alternative = \"less\" tests sigma1 < sigma2, but sigma1 > sigma2 here -- use \"greater\" or \"two.sided\" instead.")
  }

  rho <- (sigma1 / sigma2)^2

  power_at_n <- function(n) {
    df <- n - 1
    if (alternative == "greater") {
      crit <- stats::qf(1 - alpha, df, df)
      1 - stats::pf(crit / rho, df, df)
    } else if (alternative == "less") {
      crit <- stats::qf(alpha, df, df)
      stats::pf(crit / rho, df, df)
    } else {
      crit_lo <- stats::qf(alpha / 2, df, df)
      crit_hi <- stats::qf(1 - alpha / 2, df, df)
      1 - (stats::pf(crit_hi / rho, df, df) - stats::pf(crit_lo / rho, df, df))
    }
  }

  n_solved <- stats::uniroot(function(n) power_at_n(n) - power, c(3, 1e6))$root
  n_per_group <- ceiling(n_solved)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    inputs = list(sigma1 = sigma1, sigma2 = sigma2, alpha = alpha, power = power,
                  alternative = alternative)
  )
}
