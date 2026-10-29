# Analyze from summary counts: confidence intervals for a proportion and for a
# mean / standard deviation (ROADMAP Track B1, item 13).
#
# Proportion, x successes in n trials; six interval methods side by side:
#   Wald            p +/- z sqrt(p(1-p)/n), cut to [0, 1]. Known to behave poorly
#                   (Brown LD, Cai TT, DasGupta A. Stat Sci 2001;16:101-133); shown
#                   for comparison, not as a recommendation.
#   Wilson score    Wilson EB. J Am Stat Assoc 1927;22:209-212.
#   Clopper-Pearson Clopper CJ, Pearson ES. Biometrika 1934;26:404-413 (exact, via
#                   the beta distribution).
#   Agresti-Coull   Agresti A, Coull BA. Am Stat 1998;52:119-126.
#   Jeffreys        equal-tailed interval of the Beta(x + 1/2, n - x + 1/2)
#                   posterior (Brown, Cai & DasGupta 2001), with the usual
#                   conventions lower = 0 at x = 0 and upper = 1 at x = n.
#   Mid-P exact     Lancaster HO. J Am Stat Assoc 1961;56:223-234; Berry G, Armitage P.
#                   The Statistician 1995;44:417-423: the exact interval with half
#                   the probability of the observed count in each tail.
#
# Mean and standard deviation from summary statistics (n, mean, SD):
#   t interval      mean +/- t_{n-1, 1-alpha/2} SD/sqrt(n)  (Student 1908)
#   z interval      the same with the normal quantile (large n or known SD)
#   SD interval     chi-square: sqrt((n-1) s^2 / chi2_{1-alpha/2, n-1}) to
#                   sqrt((n-1) s^2 / chi2_{alpha/2, n-1}); exact for normal data.

.ci_validate_level <- function(conf_level) .validate_unit_interval(conf_level, "Confidence level")

# Exact mid-P interval for x successes in n trials: the p at which the mid-P
# tail probability equals alpha/2 on each side.
.ci_midp <- function(x, n, alpha) {
  upper_tail <- function(p) stats::pbinom(x, n, p, lower.tail = FALSE) + 0.5 * stats::dbinom(x, n, p) # P(X>x) + half P(X=x)
  lower_tail <- function(p) stats::pbinom(x - 1, n, p) + 0.5 * stats::dbinom(x, n, p)                   # P(X<x) + half P(X=x)
  # lower limit: P_p(X > x) + 0.5 P_p(X = x) = alpha/2 (increasing in p)
  lo <- if (x == 0) 0 else stats::uniroot(function(p) upper_tail(p) - alpha / 2, c(1e-12, 1 - 1e-12), tol = 1e-12)$root
  # upper limit: P_p(X < x) + 0.5 P_p(X = x) = alpha/2 (decreasing in p)
  hi <- if (x == n) 1 else stats::uniroot(function(p) lower_tail(p) - alpha / 2, c(1e-12, 1 - 1e-12), tol = 1e-12)$root
  c(lo, hi)
}

#' Confidence intervals for a proportion
#'
#' @param x Number of successes (events), a whole number between 0 and n.
#' @param n Number of trials (the sample size), a positive whole number.
#' @param conf_level Confidence level.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_total`, `successes`, `proportion`, `wald_lower`, `wald_upper`, `wilson_lower`, `wilson_upper`, `exact_lower`, `exact_upper`, `agresti_coull_lower`, `agresti_coull_upper`, `jeffreys_lower`, `jeffreys_upper`, `mid_p_lower`, `mid_p_upper` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_ci_proportion(0, 25)
#' @export
calc_analyze_ci_proportion <- function(x, n, conf_level = 0.95) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || !is.finite(n) || n < 1 || n != round(n)) {
    stop("n must be a single positive whole number.")
  }
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 0 || x != round(x)) {
    stop("x must be a single non-negative whole number.")
  }
  if (x > n) stop("x (successes) cannot exceed n (trials).")
  .ci_validate_level(conf_level)
  alpha <- 1 - conf_level
  z <- stats::qnorm(1 - alpha / 2)
  p <- x / n

  wald <- pmin(1, pmax(0, p + c(-1, 1) * z * sqrt(p * (1 - p) / n)))
  wilson <- {
    centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
    half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
    pmin(1, pmax(0, c(centre - half, centre + half)))
  }
  exact <- c(if (x == 0) 0 else stats::qbeta(alpha / 2, x, n - x + 1),
             if (x == n) 1 else stats::qbeta(1 - alpha / 2, x + 1, n - x))
  agresti <- {
    n_t <- n + z^2; p_t <- (x + z^2 / 2) / n_t
    pmin(1, pmax(0, p_t + c(-1, 1) * z * sqrt(p_t * (1 - p_t) / n_t)))
  }
  jeffreys <- c(if (x == 0) 0 else stats::qbeta(alpha / 2, x + 0.5, n - x + 0.5),
                if (x == n) 1 else stats::qbeta(1 - alpha / 2, x + 0.5, n - x + 0.5))
  midp <- .ci_midp(x, n, alpha)

  new_ss_result(list(
    n_total = n, successes = x, proportion = p,
    wald_lower = wald[1], wald_upper = wald[2],
    wilson_lower = wilson[1], wilson_upper = wilson[2],
    exact_lower = exact[1], exact_upper = exact[2],
    agresti_coull_lower = agresti[1], agresti_coull_upper = agresti[2],
    jeffreys_lower = jeffreys[1], jeffreys_upper = jeffreys[2],
    mid_p_lower = midp[1], mid_p_upper = midp[2],
    inputs = list(x = x, n = n, conf_level = conf_level)
  ))
}

#' Confidence intervals for a mean and a standard deviation from summary statistics
#'
#' @param n Sample size (a whole number of at least 2).
#' @param mean Sample mean.
#' @param sd Sample standard deviation (positive).
#' @param conf_level Confidence level.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_total`, `mean`, `sd`, `standard_error`, `mean_lower`, `mean_upper`, `mean_z_lower`, `mean_z_upper`, `sd_lower`, `sd_upper`, `t_quantile` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_ci_mean(30, 10, 2)
#' @export
calc_analyze_ci_mean <- function(n, mean, sd, conf_level = 0.95) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || !is.finite(n) || n < 2 || n != round(n)) {
    stop("n must be a single whole number of at least 2.")
  }
  if (!is.numeric(mean) || length(mean) != 1 || is.na(mean) || !is.finite(mean)) stop("The mean must be a single number.")
  if (!is.numeric(sd) || length(sd) != 1 || is.na(sd) || !is.finite(sd) || sd <= 0) {
    stop("The standard deviation must be a single positive number.")
  }
  .ci_validate_level(conf_level)
  alpha <- 1 - conf_level
  se <- sd / sqrt(n)
  tq <- stats::qt(1 - alpha / 2, n - 1)
  zq <- stats::qnorm(1 - alpha / 2)
  df <- n - 1
  new_ss_result(list(
    n_total = n, mean = mean, sd = sd, standard_error = se,
    mean_lower = mean - tq * se, mean_upper = mean + tq * se,
    mean_z_lower = mean - zq * se, mean_z_upper = mean + zq * se,
    sd_lower = sqrt(df * sd^2 / stats::qchisq(1 - alpha / 2, df)),
    sd_upper = sqrt(df * sd^2 / stats::qchisq(alpha / 2, df)),
    t_quantile = tq,
    inputs = list(n = n, mean = mean, sd = sd, conf_level = conf_level)
  ))
}

# Display table for the proportion methods (one row per method).
analyze_ci_proportion_table <- function(result) {
  m <- function(label, key) data.frame(
    method = label, lower = result[[paste0(key, "_lower")]], upper = result[[paste0(key, "_upper")]],
    stringsAsFactors = FALSE)
  do.call(rbind, list(
    m("Wilson score", "wilson"), m("Clopper-Pearson (exact)", "exact"),
    m("Agresti-Coull", "agresti_coull"), m("Jeffreys", "jeffreys"),
    m("Mid-P exact", "mid_p"), m("Wald (not recommended)", "wald")
  ))
}
