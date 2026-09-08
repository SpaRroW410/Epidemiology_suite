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
