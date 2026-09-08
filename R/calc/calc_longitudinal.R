# Longitudinal group-slope-difference sample size, Liu & Liang (1997).
#
# The checklist's named source for the "GEE-based tests" item is
# `longpower::liu.liang.linear.power`. `longpower` is not installed and
# CRAN is unreachable from this sandbox, so its source was read directly
# from its public GitHub CRAN mirror
# (https://raw.githubusercontent.com/cran/longpower/master/R/
# liu.liang.linear.power.R) -- a single, self-contained function with no
# cross-file dependencies (pure base-R linear algebra: matrix inversion
# and a `uniroot()` call), unlike the large multi-file packages this
# session judged too complex to safely reimplement (`gsDesign`,
# `npsurvSS`).
#
# Liu & Liang's general method (a GLS/GEE-style approach for correlated
# repeated measures) accepts arbitrary covariate matrices for the
# parameter of interest and nuisance parameters, which is too general
# for a simple form UI. This wraps its single most common real-world use
# -- the difference in LINEAR SLOPES (rate of change) between two groups
# over repeated visits, under a random-intercept + random-slope +
# residual-error covariance structure -- exactly the construction used
# in the function's own documented Alzheimer's-disease worked example.
#
# Verified by reproducing that example exactly: 7 visits over 18 months
# (t = 0, 0.25, ..., 1.5), effect size (slope difference) = 1.5, random-
# intercept variance = 55, random-slope variance = 24, residual variance
# = 10, intercept-slope correlation = 0.8, alpha = 0.05, power = 0.80 ->
# N = 414.62 total (207.31/arm), matching the `longpower` package's own
# vignette statement ("the study would require about 207 subjects per
# arm") exactly.

# Builds the within-subject covariance matrix for a random-intercept +
# random-slope + independent-residual-error longitudinal model, exactly
# as in longpower's own Alzheimer's-disease vignette example (its
# `cov.t()` helper).
.random_slope_cov <- function(visit_times, sigma2_intercept, sigma2_slope,
                               cov_intercept_slope, sigma2_residual) {
  n <- length(visit_times)
  R <- outer(visit_times, visit_times, function(t1, t2) {
    sigma2_intercept + t1 * t2 * sigma2_slope + (t1 + t2) * cov_intercept_slope
  })
  R + diag(sigma2_residual, n, n)
}

# Direct transcription of longpower::liu.liang.linear.power(), restricted
# to the two-group, N-unknown case this app uses (the general function
# also solves for delta/power/sigma2/sig.level given N, and supports a
# list of R matrices differing by group -- not needed here).
.liu_liang_n <- function(delta, u, v, R, Pi, alpha, power, alternative) {
  Rinv <- solve(R)
  Ipl <- Pi[1] * t(u[[1]]) %*% Rinv %*% v[[1]] + Pi[2] * t(u[[2]]) %*% Rinv %*% v[[2]]
  Ill <- Pi[1] * t(v[[1]]) %*% Rinv %*% v[[1]] + Pi[2] * t(v[[2]]) %*% Rinv %*% v[[2]]
  Illinv <- solve(Ill)
  Sigma1 <- Pi[1] * (t(u[[1]]) - Ipl %*% Illinv %*% t(v[[1]])) %*% Rinv %*% (u[[1]] - v[[1]] %*% Illinv %*% t(Ipl)) +
    Pi[2] * (t(u[[2]]) - Ipl %*% Illinv %*% t(v[[2]])) %*% Rinv %*% (u[[2]] - v[[2]] %*% Illinv %*% t(Ipl))

  z_alpha <- if (alternative == "two.sided") qnorm(1 - alpha / 2) else qnorm(1 - alpha)
  (z_alpha + qnorm(power))^2 / (delta^2 * Sigma1[1, 1])
}

#' Sample size for a longitudinal group-difference-in-slopes test
#' (Liu & Liang 1997)
#'
#' Solves for the total sample size needed to detect a given difference
#' in linear slopes (rate of change over time) between two groups
#' measured repeatedly at the same visit times, under a random-intercept
#' + random-slope + independent-residual-error covariance structure --
#' the standard linear mixed model for longitudinal data, and the
#' scenario `longpower::liu.liang.linear.power()`'s own documented
#' example uses. This is the GLS/GEE-style method of Liu & Liang (1997).
#'
#' @param visit_times Numeric vector of visit times (length >= 2)
#' @param delta Slope difference between the two groups to detect (!= 0)
#' @param sigma2_intercept Variance of the random intercept (> 0)
#' @param sigma2_slope Variance of the random slope (> 0)
#' @param cov_intercept_slope Covariance between the random intercept and
#'   random slope
#' @param sigma2_residual Residual (within-subject) error variance (> 0)
#' @param allocation1 Proportion of subjects in group 1 (the group whose
#'   slope is being compared against group 0's), (0,1), default 0.5
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided" or "one.sided"
#' @return list(n_total, n1, n0, inputs)
calc_longitudinal_slope_diff <- function(visit_times, delta, sigma2_intercept, sigma2_slope,
                                          cov_intercept_slope, sigma2_residual,
                                          allocation1 = 0.5, alpha = 0.05, power = 0.8,
                                          alternative = "two.sided") {
  if (!is.numeric(visit_times) || length(visit_times) < 2 || any(is.na(visit_times))) {
    stop("visit_times must be a numeric vector of at least 2 values.")
  }
  if (!is.numeric(delta) || length(delta) != 1 || is.na(delta) || delta == 0) {
    stop("delta must be a single non-zero number.")
  }
  .validate_positive(sigma2_intercept, "sigma2_intercept")
  .validate_positive(sigma2_slope, "sigma2_slope")
  .validate_number(cov_intercept_slope, "cov_intercept_slope")
  .validate_positive(sigma2_residual, "sigma2_residual")
  .validate_unit_interval(allocation1, "allocation1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!alternative %in% c("two.sided", "one.sided")) {
    stop('alternative must be "two.sided" or "one.sided".')
  }
  if (cov_intercept_slope^2 > sigma2_intercept * sigma2_slope) {
    stop("cov_intercept_slope is not a valid covariance: its square cannot exceed sigma2_intercept * sigma2_slope.")
  }

  n <- length(visit_times)
  R <- .random_slope_cov(visit_times, sigma2_intercept, sigma2_slope, cov_intercept_slope, sigma2_residual)
  u <- list(u1 = visit_times, u2 = rep(0, n))
  v <- list(v1 = cbind(1, 1, visit_times), v2 = cbind(1, 0, visit_times))
  Pi <- c(allocation1, 1 - allocation1)

  N <- .liu_liang_n(delta = delta, u = u, v = v, R = R, Pi = Pi,
                     alpha = alpha, power = power, alternative = alternative)

  list(
    n_total = ceiling(N), n1 = ceiling(N * allocation1), n0 = ceiling(N * (1 - allocation1)),
    inputs = list(visit_times = visit_times, delta = delta, sigma2_intercept = sigma2_intercept,
                  sigma2_slope = sigma2_slope, cov_intercept_slope = cov_intercept_slope,
                  sigma2_residual = sigma2_residual, allocation1 = allocation1,
                  alpha = alpha, power = power, alternative = alternative)
  )
}

# MMRM (mixed model repeated measures) with missing data, AR(1) structure,
# Lu, Luo & Chen (2008).
#
# The checklist's named source is `longpower::power.mmrm`/`power.mmrm.ar1`
# -- from the same `longpower` package already used above for the slope-
# difference design. Its source was read directly from the package's
# public GitHub CRAN mirror (https://raw.githubusercontent.com/cran/
# longpower/master/R/power_mmrm.R) -- again a single, self-contained
# function with no cross-file dependencies. This wraps `power.mmrm.ar1()`
# (the AR(1)-correlation variant, one of the two input styles --
# "correlation matrix or AR(1) rho" -- the checklist item itself lists,
# and simpler for a form UI than supplying a full correlation matrix).
#
# Verified against the package's own documented "approximate simulation
# results from Table 5" of Lu, Luo & Chen (2008): rho=0.6, per-visit
# retention ra=(1,0.76,0.63,0.52), rb=(1,0.87,0.81,0.78), sigma=1,
# delta=0.9, lambda=sqrt(1.25/1.75), target power=0.904 -> this
# reimplementation gives N=80.61 (ceiling 81), matching the package's own
# companion example, which fixes N=81 to solve back for rho and expects
# to recover ~0.6 -- confirmed directly: solving for rho at N=81 recovers
# rho=0.585 (close to 0.6, the small gap explained by N=81 being a
# rounded integer, not the exact unrounded root 80.61). A second
# round-trip (N=87, rho=0.6, lambda=1.25/1.75, power=0.910, solve for
# delta) recovers delta=0.891 (close to the documented delta=0.9), the
# same rounding-explained gap.

#' Sample size for a mixed model of repeated measures (MMRM) with
#' AR(1)-correlated, missing/dropout-affected repeated measures
#' (Lu, Luo & Chen 2008)
#'
#' Solves for the total sample size needed to detect a between-arm
#' difference `delta` in a repeated-measures trial where observations
#' within a subject follow an AR(1) correlation structure and subjects
#' may drop out (retention < 1) at later visits.
#'
#' @param rho AR(1) correlation parameter (0,1) -- correlation between
#'   adjacent visits; correlation between visits j and k is
#'   rho^(2*|times_j - times_k|)
#' @param ra Numeric vector of cumulative retention proportions in arm 1
#'   at each visit (non-increasing, first value typically 1); length
#'   equals the number of visits
#' @param rb Retention vector for arm 2; defaults to `ra` (equal
#'   retention in both arms)
#' @param sigma Residual standard deviation of the outcome at a single
#'   visit (> 0)
#' @param times Visit indices/times, same length as `ra`; defaults to
#'   1, 2, ..., length(ra) (equally spaced visits)
#' @param lambda Allocation ratio, n2/n1 (> 0), default 1
#' @param delta Between-arm difference to detect (!= 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided" or "one.sided"
#' @return list(n1, n2, n_total, inputs)
calc_mmrm_ar1 <- function(rho, ra, rb = NULL, sigma, times = seq_along(ra), lambda = 1,
                           delta, alpha = 0.05, power = 0.8, alternative = "two.sided") {
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || rho <= 0 || rho >= 1) {
    stop("rho must be a single number strictly between 0 and 1.")
  }
  if (!is.numeric(ra) || length(ra) < 2 || anyNA(ra) || any(ra <= 0) || any(ra > 1)) {
    stop("ra must be a numeric vector of at least 2 retention proportions, each in (0, 1].")
  }
  if (any(diff(ra) > 0)) stop("ra must be non-increasing (retention cannot improve over time).")
  if (!is.null(rb)) {
    if (!is.numeric(rb) || length(rb) != length(ra) || anyNA(rb) || any(rb <= 0) || any(rb > 1)) {
      stop("rb must be a numeric vector the same length as ra, each in (0, 1].")
    }
    if (any(diff(rb) > 0)) stop("rb must be non-increasing (retention cannot improve over time).")
  }
  .validate_positive(sigma, "sigma")
  if (!is.numeric(times) || length(times) != length(ra) || anyNA(times)) {
    stop("times must be a numeric vector the same length as ra.")
  }
  .validate_positive(lambda, "lambda")
  if (!is.numeric(delta) || length(delta) != 1 || is.na(delta) || delta == 0) {
    stop("delta must be a single non-zero number.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!alternative %in% c("two.sided", "one.sided")) {
    stop('alternative must be "two.sided" or "one.sided".')
  }

  J <- length(ra)
  phia <- 1 / ra[J] - sum(rho^(2 * (times[J] - times[-J])) * (1 / ra[-1] - 1 / ra[-J]))
  if (!is.null(rb)) {
    phib <- 1 / rb[J] - sum(rho^(2 * (times[J] - times[-J])) * (1 / rb[-1] - 1 / rb[-J]))
  } else {
    rb <- ra
    phib <- phia
  }

  z_alpha <- if (alternative == "two.sided") qnorm(1 - alpha / 2) else qnorm(1 - alpha)
  n1 <- (phia + lambda * phib) * (z_alpha + qnorm(power))^2 * sigma^2 / delta^2
  n2 <- n1 / lambda

  list(
    n1 = ceiling(n1), n2 = ceiling(n2), n_total = ceiling(n1) + ceiling(n2),
    inputs = list(rho = rho, ra = ra, rb = rb, sigma = sigma, times = times, lambda = lambda,
                  delta = delta, alpha = alpha, power = power, alternative = alternative)
  )
}
