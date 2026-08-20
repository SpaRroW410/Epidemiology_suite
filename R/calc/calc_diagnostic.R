# Pure calculation functions for diagnostic accuracy (sensitivity/specificity)
# sample size. No Shiny dependency here so these are directly unit-testable
# (see tests/testthat).

#' Sample size for sensitivity and specificity, given disease prevalence
#'
#' Buderer's method (Buderer 1996): sizes a diagnostic accuracy study to
#' achieve desired precision (confidence interval half-width) for both
#' sensitivity and specificity simultaneously. Only diseased subjects
#' contribute information to the sensitivity estimate, and only non-diseased
#' subjects to the specificity estimate -- so the prevalence of the target
#' condition determines how many *total* subjects are needed to obtain
#' enough of each. The larger of the two implied totals is returned, so
#' both targets are met in the same study.
#'
#' @param sens Expected sensitivity (0,1)
#' @param spec Expected specificity (0,1)
#' @param prevalence Expected prevalence of the target condition (0,1)
#' @param prec_sens Desired precision (CI half-width) for sensitivity (0,1)
#' @param prec_spec Desired precision (CI half-width) for specificity (0,1)
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, n_sens, n_spec, binding, n_diseased, n_healthy, z, inputs)
calc_diagnostic_accuracy <- function(sens, spec, prevalence,
                                      prec_sens = 0.05, prec_spec = 0.05,
                                      conf_level = 0.95) {
  .validate_unit_interval(sens, "sens")
  .validate_unit_interval(spec, "spec")
  .validate_unit_interval(prevalence, "prevalence")
  .validate_unit_interval(prec_sens, "prec_sens")
  .validate_unit_interval(prec_spec, "prec_spec")
  .validate_unit_interval(conf_level, "conf_level")

  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  n_sens <- (z^2 * sens * (1 - sens)) / (prec_sens^2 * prevalence)
  n_spec <- (z^2 * spec * (1 - spec)) / (prec_spec^2 * (1 - prevalence))

  n_sens_ceil <- ceiling(n_sens)
  n_spec_ceil <- ceiling(n_spec)
  n <- max(n_sens_ceil, n_spec_ceil)
  binding <- if (n_sens_ceil >= n_spec_ceil) "sensitivity" else "specificity"

  list(
    n = n,
    n_sens = n_sens_ceil,
    n_spec = n_spec_ceil,
    binding = binding,
    n_diseased = ceiling(n * prevalence),
    n_healthy = ceiling(n * (1 - prevalence)),
    z = z,
    inputs = list(sens = sens, spec = spec, prevalence = prevalence,
                  prec_sens = prec_sens, prec_spec = prec_spec,
                  conf_level = conf_level)
  )
}

# Z critical value for a hypothesis test, alpha split per alternative -- used
# by the three "Beam"-formula designs below (Buderer's Equation 1 above
# needs no such value, since it's a CI-width estimate with no hypothesis).
.z_alpha <- function(alpha, alternative) {
  if (identical(alternative, "two.sided")) stats::qnorm(1 - alpha / 2) else stats::qnorm(1 - alpha)
}

# Yates' continuity correction (Akoglu 2022, Table 2, Equation 5; originally
# Beam CA. Strategies for improving power in diagnostic radiology research.
# AJR 1992;159:631-7), applied to every "compare two proportions" formula
# below before any prevalence adjustment.
.yates_correction <- function(n, p_a, p_b) {
  delta <- abs(p_a - p_b)
  (n / 4) * (1 + sqrt(1 + 4 / (n * delta)))^2
}

#' Sample size for sensitivity and specificity vs. a known/reference value
#'
#' Akoglu (2022), Table 2, Equation 2: sizes a study to test whether a new
#' index test's sensitivity and specificity are statistically different from
#' pre-specified reference (null) values, with Yates' continuity correction
#' and prevalence adjustment (as for calc_diagnostic_accuracy()). Unlike the
#' precision-based design, this one is a hypothesis test and needs a power
#' target.
#'
#' @param sens0,sens1 Reference/null and expected sensitivity (0,1)
#' @param spec0,spec1 Reference/null and expected specificity (0,1)
#' @param prevalence Expected prevalence of the target condition (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, n_sens, n_spec, binding, n_diseased, n_healthy, inputs)
calc_diagnostic_vs_reference <- function(sens0, sens1, spec0, spec1, prevalence,
                                          alpha = 0.05, power = 0.9,
                                          alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(sens0, "sens0")
  .validate_unit_interval(sens1, "sens1")
  .validate_unit_interval(spec0, "spec0")
  .validate_unit_interval(spec1, "spec1")
  .validate_unit_interval(prevalence, "prevalence")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(sens0, sens1))) stop("sens0 and sens1 must differ (no effect to detect).")
  if (isTRUE(all.equal(spec0, spec1))) stop("spec0 and spec1 must differ (no effect to detect).")

  za <- .z_alpha(alpha, alternative)
  zb <- stats::qnorm(power)

  .raw_n <- function(p0, p1) (za * sqrt(p0 * (1 - p0)) + zb * sqrt(p1 * (1 - p1)))^2 / (p1 - p0)^2

  n_sens_yates <- .yates_correction(.raw_n(sens0, sens1), sens1, sens0)
  n_spec_yates <- .yates_correction(.raw_n(spec0, spec1), spec1, spec0)

  n_sens <- ceiling(n_sens_yates / prevalence)
  n_spec <- ceiling(n_spec_yates / (1 - prevalence))
  n <- max(n_sens, n_spec)
  binding <- if (n_sens >= n_spec) "sensitivity" else "specificity"

  list(
    n = n,
    n_sens = n_sens,
    n_spec = n_spec,
    binding = binding,
    n_diseased = ceiling(n * prevalence),
    n_healthy = ceiling(n * (1 - prevalence)),
    inputs = list(sens0 = sens0, sens1 = sens1, spec0 = spec0, spec1 = spec1,
                  prevalence = prevalence, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size to compare a metric (sensitivity or specificity) of two
#' independent (unpaired) diagnostic tests
#'
#' Akoglu (2022), Table 2, Equation 3a (Casagrande & Pike 1978's pooled
#' two-proportion formula, per Beam 1992's application to diagnostic
#' accuracy), with Yates' continuity correction. Compares the same metric
#' (e.g. both sensitivities, measured only in diseased subjects) between two
#' different tests applied to two independent groups of subjects -- no
#' prevalence adjustment applies here, since both p1/p2 are already
#' conditional on true disease status (unlike the single-test designs above).
#'
#' @param p1,p2 Expected value of the metric (sensitivity or specificity) for
#'   test 1 and test 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, n_total, inputs)
calc_diagnostic_two_indep <- function(p1, p2, alpha = 0.05, power = 0.8,
                                      alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p1, p2))) stop("p1 and p2 must differ (no effect to detect).")

  za <- .z_alpha(alpha, alternative)
  zb <- stats::qnorm(power)
  p_bar <- (p1 + p2) / 2

  n_raw <- (za * sqrt(2 * p_bar * (1 - p_bar)) +
              zb * sqrt(p1 * (1 - p1) + p2 * (1 - p2)))^2 / (p1 - p2)^2
  n_per_group <- ceiling(.yates_correction(n_raw, p1, p2))

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size to compare a metric (sensitivity or specificity) of two paired
#' (same-subjects) diagnostic tests
#'
#' Akoglu (2022), Table 2, Equation 3b (Connor 1987's McNemar-test-based
#' method), with Yates' continuity correction. Because the two tests are
#' compared within the same subjects, the required sample size depends on
#' how often the two tests *disagree* (probability of disagreement, Psi),
#' which isn't fully determined by p1 and p2 alone -- so this returns a
#' *range*: the minimum-disagreement bound (tests disagree only by the
#' minimum amount consistent with p1/p2) and the maximum-disagreement bound
#' (tests agree only by chance). No prevalence adjustment applies, for the
#' same reason as calc_diagnostic_two_indep().
#'
#' @param p1,p2 Expected value of the metric (sensitivity or specificity) for
#'   test 1 and test 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_min, n_max, psi_min, psi_max, inputs)
calc_diagnostic_two_paired <- function(p1, p2, alpha = 0.05, power = 0.8,
                                       alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p1, p2))) stop("p1 and p2 must differ (no effect to detect).")

  za <- .z_alpha(alpha, alternative)
  zb <- stats::qnorm(power)
  delta <- abs(p1 - p2)
  psi_min <- delta
  psi_max <- p1 * (1 - p2) + p2 * (1 - p1)

  .raw_n <- function(psi) (za * sqrt(psi) + zb * sqrt(psi - delta^2))^2 / delta^2

  n_min <- ceiling(.yates_correction(.raw_n(psi_min), p1, p2))
  n_max <- ceiling(.yates_correction(.raw_n(psi_max), p1, p2))

  list(
    n_min = n_min,
    n_max = n_max,
    psi_min = psi_min,
    psi_max = psi_max,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power,
                  alternative = alternative)
  )
}
