# Pure calculation functions for an interrupted time series analysed by segmented regression with first-order autocorrelated
# (AR(1)) errors: power for a change in level or a change in slope at the interruption, and the number of time points needed.
# No Shiny dependency (tests/testthat/test-calc_its.R).
#
# Model (segmented regression; Bernal, Cummins & Gasparrini 2017, Int J Epidemiol 46:348-355, read in full):
#   Y_t = b0 + b1 t + b2 X_t + b3 (t - t0) X_t + e_t,   X_t = 1 after the interruption,   e_t = rho e_(t-1) + u_t
# Method: the generalised least squares variance of the coefficient tested, Var(b) = sigma^2 (X' R^-1 X)^-1 with R the AR(1)
# correlation matrix of the series (the standard result for regression with correlated errors), and power from the noncentral t
# distribution on n - p degrees of freedom. This is a calculation, not a simulation, so it treats the autocorrelation as known.
# Checked against published simulations: Beard, Brown & Shahab 2026 (Addiction 121:695-712, read in full), Table 1 (change in
# level) and Table 3 (change in slope), AR(1) = 0.5, white-noise SD 1, interruption at the midpoint, no baseline trend in the
# model; and against a simulation here that fits the model with stats::arima(). With short series the fitted test rejects too
# often when nothing changed (0.14-0.17 at 40 points in those tables), so the simulated "power" there is above this calculation.

.its_design <- function(n_pre, n_post, baseline_trend, both_changes, effect_type) {
  n <- n_pre + n_post
  t <- seq_len(n)
  post <- as.numeric(t > n_pre)
  cols <- list(intercept = rep(1, n))
  if (baseline_trend) cols$time <- t
  if (both_changes || effect_type == "level") cols$level <- post
  if (both_changes || effect_type == "slope") cols$slope <- post * (t - n_pre)
  do.call(cbind, cols)
}

# sigma^2 (X' R^-1 X)^-1 for AR(1) errors with marginal variance sd^2, using the closed-form inverse of the AR(1) correlation matrix
.its_gls_var <- function(X, rho, sd) {
  n <- nrow(X)
  Rinv <- diag(c(1, rep(1 + rho^2, n - 2), 1), n)
  idx <- cbind(seq_len(n - 1), seq_len(n - 1) + 1)
  Rinv[idx] <- -rho
  Rinv[idx[, 2:1]] <- -rho
  Rinv <- Rinv / (1 - rho^2)
  sd^2 * solve(crossprod(X, Rinv %*% X))
}

.validate_its_count <- function(x, label, min) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < min || x != round(x)) stop(label, " must be a whole number of at least ", min, ".")
  invisible(x)
}

.its_power <- function(n_pre, n_post, effect, effect_type, sd, rho, alpha, baseline_trend, both_changes) {
  X <- .its_design(n_pre, n_post, baseline_trend, both_changes, effect_type)
  df <- nrow(X) - ncol(X)
  se <- sqrt(.its_gls_var(X, rho, sd)[effect_type, effect_type])
  tcrit <- stats::qt(1 - alpha / 2, df)
  ncp <- abs(effect) / se
  list(power = stats::pt(tcrit, df, ncp = ncp, lower.tail = FALSE) + stats::pt(-tcrit, df, ncp = ncp), se = se, df = df)
}

#' Interrupted time series (segmented regression): power for a change in level or slope
#'
#' Power of a segmented regression with first-order autocorrelated errors to detect a change in level (an immediate step) or a
#' change in slope at an interruption, for a given number of time points before and after it.
#'
#' @param n_pre Number of time points before the interruption (whole number, at least 3).
#' @param n_post Number of time points after the interruption (whole number, at least 3).
#' @param effect Change to detect, in the units of the outcome: the step at the interruption (`effect_type = "level"`), or the
#'   change in slope per time point (`effect_type = "slope"`); not 0.
#' @param effect_type `"level"` for a change in level or `"slope"` for a change in slope.
#' @param sd Standard deviation of the series around its trend (the residual standard deviation of the outcome; greater than 0).
#'   For errors generated as AR(1) with white-noise standard deviation s, this is s / sqrt(1 - rho^2).
#' @param rho First-order autocorrelation of the errors, strictly between -1 and 1 (0 = independent time points).
#' @param alpha Significance level, two-sided, strictly between 0 and 1.
#' @param baseline_trend Whether the model includes a time trend before the interruption (default `TRUE`).
#' @param both_changes Whether the model estimates a change in level and a change in slope together (default `TRUE`, the usual
#'   segmented regression); `FALSE` fits only the change being tested.
#' @return A named list of class `ss_result` with the components `n_total`, `n_pre`, `n_post`, `achieved_power`, `se` (standard
#'   error of the change tested), `df` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_its_power(n_pre = 24, n_post = 24, effect = 2, effect_type = "level", sd = 1.5, rho = 0.3)
#' @export
calc_its_power <- function(n_pre, n_post, effect, effect_type = c("level", "slope"), sd = 1, rho = 0, alpha = 0.05,
                           baseline_trend = TRUE, both_changes = TRUE) {
  effect_type <- match.arg(effect_type)
  .validate_its_count(n_pre, "n_pre", 3)
  .validate_its_count(n_post, "n_post", 3)
  .validate_number(effect, "effect")
  if (isTRUE(all.equal(effect, 0))) stop("effect must differ from 0 (no change to detect).")
  .validate_positive(sd, "sd")
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || abs(rho) >= 1) stop("rho must be a single number strictly between -1 and 1.")
  .validate_unit_interval(alpha, "alpha")
  res <- .its_power(n_pre, n_post, effect, effect_type, sd, rho, alpha, isTRUE(baseline_trend), isTRUE(both_changes))
  new_ss_result(list(
    n_total = n_pre + n_post, n_pre = n_pre, n_post = n_post,
    achieved_power = res$power, se = res$se, df = res$df,
    inputs = list(effect = effect, effect_type = effect_type, sd = sd, rho = rho, alpha = alpha,
                  baseline_trend = isTRUE(baseline_trend), both_changes = isTRUE(both_changes))
  ))
}

#' Interrupted time series (segmented regression): number of time points needed
#'
#' Smallest number of time points at which a segmented regression with first-order autocorrelated errors reaches the power to
#' detect a change in level or slope, with a chosen share of the time points before the interruption.
#'
#' @inheritParams calc_its_power
#' @param power Desired power, strictly between 0 and 1.
#' @param pre_fraction Share of the time points that lie before the interruption, strictly between 0 and 1 (default 0.5, the
#'   interruption at the midpoint).
#' @param max_n Largest number of time points tried (default 2000); an error says so when the power is not reached by then.
#' @return A named list of class `ss_result` with the components `n_total`, `n_pre`, `n_post`, `achieved_power`, `se`, `df` and
#'   `inputs`.
#' @examples
#' calc_its_n(effect = 2, effect_type = "level", sd = 1.5, rho = 0.3)
#' @export
calc_its_n <- function(effect, effect_type = c("level", "slope"), sd = 1, rho = 0, alpha = 0.05, power = 0.8,
                       pre_fraction = 0.5, baseline_trend = TRUE, both_changes = TRUE, max_n = 2000) {
  effect_type <- match.arg(effect_type)
  .validate_unit_interval(power, "power")
  .validate_unit_interval(pre_fraction, "pre_fraction")
  .validate_its_count(max_n, "max_n", 8)
  split <- function(n) { pre <- min(max(round(n * pre_fraction), 3), n - 3); c(pre, n - pre) }
  at <- function(n) { s <- split(n); calc_its_power(s[1], s[2], effect, effect_type, sd, rho, alpha, baseline_trend, both_changes) }
  # power rises with the length of the series: double until reached, then bisect, then step back over any local unevenness
  hi <- 8
  while (at(hi)$achieved_power < power) {
    if (hi >= max_n) stop("The power is not reached with ", max_n, " time points; a larger change, a less variable series or a ",
                          "lower autocorrelation is needed.")
    hi <- min(hi * 2, max_n)
  }
  lo <- max(hi %/% 2, 6)
  while (hi - lo > 1) { mid <- (lo + hi) %/% 2; if (mid >= 6 && at(mid)$achieved_power >= power) hi <- mid else lo <- mid }
  while (hi > 6 && at(hi - 1)$achieved_power >= power) hi <- hi - 1
  res <- at(hi)
  res$inputs$power <- power
  res$inputs$pre_fraction <- pre_fraction
  res
}
