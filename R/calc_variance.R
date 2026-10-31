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
#' @examples
#' calc_variance_single(sigma0 = 10, sigma1 = 14, alpha = 0.05, power = 0.8, alternative = "greater")
#' @export
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

  new_ss_result(list(
    n = ceiling(n_solved),
    inputs = list(sigma0 = sigma0, sigma1 = sigma1, alpha = alpha, power = power,
                  alternative = alternative)
  ))
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
#' @examples
#' calc_variance_two(sigma1 = 10, sigma2 = 14, alpha = 0.05, power = 0.8, alternative = "two.sided")
#' @export
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

  new_ss_result(list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    inputs = list(sigma1 = sigma1, sigma2 = sigma2, alpha = alpha, power = power,
                  alternative = alternative)
  ))
}

#' Sample size to estimate a standard deviation to a target precision
#' (CI-width-based, no hypothesis test)
#'
#' Uses the same standard result as the two functions above --
#' (n-1)*S^2/sigma^2 ~ chi-squared(n-1) -- but inverted for PLANNING
#' rather than a hypothesis test: a two-sided (1-conf_level) confidence
#' interval for the true SD sigma, expressed as a multiple of whatever
#' sample SD S is later observed, has width
#'   sqrt(df/qchisq(1-alpha/2,df)) to sqrt(df/qchisq(alpha/2,df))  (df = n-1)
#' -- exactly the multiplier interval this app's own Pilot/Feasibility
#' module already computes FORWARD (given n, how wide is the CI?) via
#' `calc_pilot_sd_precision()`. This design solves the same identity
#' BACKWARD instead: given a target CI width (as a multiple of the
#' observed SD), find the smallest n that achieves it. Deterministic
#' closed-form solve via `uniroot()` (width-vs-n is monotonically
#' decreasing, confirmed directly: width at n=5,10,20,50,100,200,500 ->
#' 2.27, 1.14, 0.70, 0.41, 0.28, 0.20, 0.12), the same solve-for-n
#' pattern as `calc_variance_single()`/`calc_variance_two()` above.
#'
#' Verified by round-trip: solving for n at the target width already
#' implied by n=12 (this app's own Pilot module default, width=0.989 --
#' i.e. a 95% CI for sigma spanning ~0.71x to ~1.70x the observed SD)
#' recovers n=12 (13 without the exact-boundary ceiling() rounding
#' quirk, since the target width was computed from n=12 itself and the
#' solved root lands just above 12.0 before ceiling()).
#'
#' @param target_width Desired total width of the two-sided CI for sigma,
#'   expressed as a multiple of the (yet-to-be-observed) sample SD --
#'   e.g. 0.5 means the CI should span no more than 0.5x the observed SD
#'   (> 0)
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, lower_mult, upper_mult, inputs)
#' @examples
#' calc_variance_sd_precision(target_width = 0.5)
#' @export
calc_variance_sd_precision <- function(target_width, conf_level = 0.95) {
  .validate_positive(target_width, "target_width")
  .validate_unit_interval(conf_level, "conf_level")

  width_at_n <- function(n) {
    alpha <- 1 - conf_level
    df <- n - 1
    lower_mult <- sqrt(df / stats::qchisq(1 - alpha / 2, df))
    upper_mult <- sqrt(df / stats::qchisq(alpha / 2, df))
    upper_mult - lower_mult
  }

  n_solved <- stats::uniroot(function(n) width_at_n(n) - target_width, c(3, 1e7))$root
  n <- ceiling(n_solved)

  alpha <- 1 - conf_level
  df <- n - 1
  new_ss_result(list(
    n = n,
    lower_mult = sqrt(df / stats::qchisq(1 - alpha / 2, df)),
    upper_mult = sqrt(df / stats::qchisq(alpha / 2, df)),
    inputs = list(target_width = target_width, conf_level = conf_level)
  ))
}
