# Pure closed-form (one 1-D numerical integral) calculation functions for
# meta-analysis power: the probability that a planned meta-analysis of k
# studies, each of a given per-study size, detects a true summary effect
# under a fixed-effect OR random-effects model, accounting for between-
# study heterogeneity (I-squared). Reimplements the Hedges & Pigott (2004)/
# Jackson & Turner (2017) power formulas underlying `metapower::mpower()`,
# read from that package's own source (installed via the github.com/cran
# mirror as a verification oracle only -- not a runtime dependency, per
# this project's vendoring policy) and verified bit-for-bit against it
# across all three effect-size types it supports (Cohen's d, correlation
# r, and odds ratio via a 2x2 table) and both one- and two-tailed tests.

#' Per-study sampling variance for a meta-analysis effect size
#' @keywords internal
#' @noRd
.meta_power_variance <- function(study_size, effect_size, es_type, con_table = NULL) {
  if (es_type == "d") {
    (study_size / 2 + study_size / 2) / ((study_size / 2) * (study_size / 2)) +
      (effect_size^2) / (2 * (study_size / 2 + study_size / 2))
  } else if (es_type == "r") {
    1 / (study_size - 3)
  } else {
    (1 / con_table[1]) + (1 / con_table[2]) + (1 / con_table[3]) + (1 / con_table[4])
  }
}

#' @keywords internal
.meta_power_integrand <- function(x, z, df, ncp, i2) {
  x * pnorm(z * x - ncp * sqrt(1 - i2)) * dchisq(df * x^2, df)
}

#' CDF of the random-effects summary-effect test statistic (Jackson & Turner 2017)
#' @keywords internal
#' @noRd
.meta_power_cdf <- function(t, k, ncp, i2) {
  df <- k - 1
  constant <- sqrt(1 - i2)
  part1 <- pgamma(df * (1 - i2) / 2, df / 2) * pnorm((t - ncp) * constant)
  part2 <- 2 * df * stats::integrate(.meta_power_integrand, z = t, df = df, ncp = ncp, i2 = i2,
                                      lower = constant, upper = Inf, rel.tol = 1e-14)$value
  part1 + part2
}

#' Fixed- and random-effects power for a planned meta-analysis
#'
#' Computes the probability of detecting a true summary effect of the
#' given size in a meta-analysis of k studies, each contributing the given
#' per-study sample size, under both a fixed-effect model (assumes zero
#' between-study heterogeneity) and a random-effects model (accounts for
#' heterogeneity via I-squared) -- Hedges & Pigott (2004) and its
#' random-effects generalization, Jackson & Turner (2017).
#'
#' @param effect_size True summary effect size. For es_type = "d", Cohen's
#'   d; for "r", the correlation coefficient (-1, 1) (internally converted
#'   to Fisher's z); ignored for "or" (derived instead from con_table)
#' @param study_size Number of participants per study (> 3 for es_type =
#'   "r"; split evenly between two arms for "d")
#' @param k Total number of studies in the meta-analysis (whole number >= 2)
#' @param i2 Heterogeneity (I-squared), the proportion of total variance
#'   due to between-study differences, \[0, 1)
#' @param es_type Effect size metric: "d" (Cohen's d), "r" (correlation),
#'   or "or" (odds ratio, requires con_table)
#' @param test_type "two-tailed" or "one-tailed"
#' @param alpha Significance level (Type I error), (0,1)
#' @param con_table For es_type = "or" only: a length-4 numeric vector
#'   c(a,b,c,d) for a single representative 2x2 table (exposed-with-event,
#'   unexposed-with-event, exposed-without-event, unexposed-without-event),
#'   used to derive the log odds ratio and its variance
#' @return list(fixed_power, random_power, effect_size_used, variance, inputs)
#' @examples
#' calc_meta_analysis_power(effect_size = 0.2, study_size = 10, k = 10, i2 = 0.5, 
#'     es_type = "d")
#' @export
calc_meta_analysis_power <- function(effect_size = NULL, study_size, k, i2, es_type = c("d", "r", "or"),
                                      test_type = c("two-tailed", "one-tailed"),
                                      alpha = 0.05, con_table = NULL) {
  es_type <- match.arg(es_type)
  test_type <- match.arg(test_type)

  .validate_positive(study_size, "study_size")
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 2 || k != round(k)) {
    stop("k (number of studies) must be a single whole number >= 2.")
  }
  if (!is.numeric(i2) || length(i2) != 1 || is.na(i2) || i2 < 0 || i2 >= 1) {
    stop("i2 must be a single number in [0, 1).")
  }
  .validate_unit_interval(alpha, "alpha")

  if (es_type == "or") {
    if (is.null(con_table) || length(con_table) != 4 || any(is.na(con_table)) || any(con_table <= 0)) {
      stop("con_table must be a length-4 vector of positive cell counts c(a, b, c, d) for es_type = 'or'.")
    }
    if (round(study_size) != sum(con_table)) {
      stop("study_size must equal the sum of con_table's four cells for es_type = 'or'.")
    }
    effect_size_used <- log((con_table[1] * con_table[4]) / (con_table[2] * con_table[3]))
    variance <- round(.meta_power_variance(study_size, effect_size_used, es_type, con_table), 3)
  } else if (es_type == "r") {
    if (is.null(effect_size) || !is.numeric(effect_size) || length(effect_size) != 1 ||
          is.na(effect_size) || effect_size <= -1 || effect_size >= 1) {
      stop("effect_size must be a single number in (-1, 1) for es_type = 'r'.")
    }
    if (study_size <= 3) stop("study_size must be > 3 for es_type = 'r'.")
    effect_size_used <- round(0.5 * log((1 + effect_size) / (1 - effect_size)), 2)
    variance <- .meta_power_variance(study_size, effect_size_used, es_type)
  } else {
    if (is.null(effect_size) || !is.numeric(effect_size) || length(effect_size) != 1 || is.na(effect_size)) {
      stop("effect_size must be a single number for es_type = 'd'.")
    }
    effect_size_used <- effect_size
    variance <- .meta_power_variance(study_size, effect_size_used, es_type)
  }

  c_alpha <- if (test_type == "two-tailed") qnorm(1 - alpha / 2) else qnorm(1 - alpha)
  ncp <- effect_size_used / sqrt(variance / k)

  if (test_type == "two-tailed") {
    fixed_power <- (1 - pnorm(c_alpha - ncp)) + pnorm(-c_alpha - ncp)
    random_power <- 1 - (.meta_power_cdf(c_alpha, k, ncp, i2) - .meta_power_cdf(-c_alpha, k, ncp, i2))
  } else {
    fixed_power <- 1 - pnorm(c_alpha - ncp)
    random_power <- 1 - .meta_power_cdf(c_alpha, k, ncp, i2)
  }

  new_ss_result(list(
    fixed_power = fixed_power,
    random_power = random_power,
    effect_size_used = effect_size_used,
    variance = variance,
    inputs = list(effect_size = effect_size, study_size = study_size, k = k, i2 = i2,
                  es_type = es_type, test_type = test_type, alpha = alpha, con_table = con_table)
  ))
}

#' Required number of studies (k) for a target meta-analysis power
#'
#' Searches for the smallest k reaching the target power, under either the
#' fixed-effect or random-effects model, holding effect size, per-study
#' size, and heterogeneity fixed.
#'
#' @param power Target power (0,1)
#' @param model "random" (accounts for heterogeneity -- the more realistic,
#'   typically conservative default) or "fixed" (assumes zero heterogeneity)
#' @return list(k, achieved_power, model, inputs)
#' @inheritParams calc_meta_analysis_power
#' @examples
#' calc_meta_analysis_k(effect_size = 0.3, study_size = 25, i2 = 0.4, es_type = "d", 
#'     power = 0.8, model = "random")
#' @export
calc_meta_analysis_k <- function(effect_size = NULL, study_size, i2, es_type = c("d", "r", "or"),
                                  test_type = c("two-tailed", "one-tailed"),
                                  alpha = 0.05, power = 0.8, con_table = NULL,
                                  model = c("random", "fixed")) {
  es_type <- match.arg(es_type)
  test_type <- match.arg(test_type)
  model <- match.arg(model)
  .validate_unit_interval(power, "power")

  power_at_k <- function(k) {
    res <- calc_meta_analysis_power(effect_size = effect_size, study_size = study_size, k = k,
                                     i2 = i2, es_type = es_type, test_type = test_type,
                                     alpha = alpha, con_table = con_table)
    if (model == "random") res$random_power else res$fixed_power
  }

  k_lo <- 2
  k_hi <- 4
  while (power_at_k(k_hi) < power) {
    k_lo <- k_hi
    k_hi <- k_hi * 2
    if (k_hi > 2000) {
      stop("No feasible number of studies found up to 2000 -- the effect size is likely too small relative to the heterogeneity and per-study size.")
    }
  }
  for (i in 1:14) {
    mid <- round((k_lo + k_hi) / 2)
    if (mid == k_lo || mid == k_hi) break
    if (power_at_k(mid) >= power) k_hi <- mid else k_lo <- mid
  }

  new_ss_result(list(
    k = k_hi,
    achieved_power = power_at_k(k_hi),
    model = model,
    inputs = list(effect_size = effect_size, study_size = study_size, i2 = i2, es_type = es_type,
                  test_type = test_type, alpha = alpha, power = power, con_table = con_table)
  ))
}
