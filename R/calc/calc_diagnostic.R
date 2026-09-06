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

#' Sample size for predictive values (PPV/NPV), precision-based
#'
#' Extends Buderer's method (already used by calc_diagnostic_accuracy()) to
#' predictive values: PPV and NPV are themselves proportions (P(disease |
#' test positive) and P(no disease | test negative) respectively -- Altman &
#' Bland 1994), so the number of test-positive (or test-negative) subjects
#' needed for a target CI half-width follows the same z^2*p(1-p)/d^2 formula
#' as any other proportion. Since only a `P(test positive)` (or negative)
#' fraction of everyone screened actually tests positive (or negative), the
#' *total* number needed to screen is that per-outcome count divided by the
#' probability of that outcome -- exactly the same prevalence-adjustment
#' logic Buderer (1996) uses for sensitivity/specificity, just applied to
#' the predictive values instead.
#'
#' @param sens Expected sensitivity (0,1)
#' @param spec Expected specificity (0,1)
#' @param prevalence Expected prevalence of the target condition (0,1)
#' @param prec_ppv Desired precision (CI half-width) for PPV (0,1)
#' @param prec_npv Desired precision (CI half-width) for NPV (0,1)
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, n_ppv, n_npv, binding, ppv, npv, z, inputs)
calc_diagnostic_ppv_npv <- function(sens, spec, prevalence,
                                     prec_ppv = 0.05, prec_npv = 0.05,
                                     conf_level = 0.95) {
  .validate_unit_interval(sens, "sens")
  .validate_unit_interval(spec, "spec")
  .validate_unit_interval(prevalence, "prevalence")
  .validate_unit_interval(prec_ppv, "prec_ppv")
  .validate_unit_interval(prec_npv, "prec_npv")
  .validate_unit_interval(conf_level, "conf_level")

  p_pos <- sens * prevalence + (1 - spec) * (1 - prevalence)
  p_neg <- (1 - sens) * prevalence + spec * (1 - prevalence)
  ppv <- (sens * prevalence) / p_pos
  npv <- (spec * (1 - prevalence)) / p_neg

  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  n_pos <- (z^2 * ppv * (1 - ppv)) / prec_ppv^2
  n_neg <- (z^2 * npv * (1 - npv)) / prec_npv^2

  n_ppv_total <- ceiling(n_pos / p_pos)
  n_npv_total <- ceiling(n_neg / p_neg)
  n <- max(n_ppv_total, n_npv_total)
  binding <- if (n_ppv_total >= n_npv_total) "PPV" else "NPV"

  list(
    n = n,
    n_ppv = n_ppv_total,
    n_npv = n_npv_total,
    binding = binding,
    ppv = ppv,
    npv = npv,
    z = z,
    inputs = list(sens = sens, spec = spec, prevalence = prevalence,
                  prec_ppv = prec_ppv, prec_npv = prec_npv, conf_level = conf_level)
  )
}

#' Sample size to test a diagnostic odds ratio (DOR) against 1 (no
#' discrimination)
#'
#' The diagnostic odds ratio is DOR = [Se/(1-Se)] / [(1-Sp)/Sp] -- the odds
#' of a positive test result in diseased subjects relative to the odds of
#' a positive result in non-diseased subjects. Testing H0: DOR=1 given an
#' assumed sensitivity and specificity is mathematically identical to
#' comparing the test-positive rate between two independent groups
#' (diseased vs. non-diseased subjects, p1=Se and p2=1-Sp respectively) --
#' exactly the same comparison calc_diagnostic_two_indep() above already
#' performs, just with a different pair of inputs and a DOR summary added,
#' so this is a thin wrapper (no new formula, no new verification risk),
#' the same pattern used for the Sign test's wrap around the binomial
#' test.
#'
#' @param sens Expected sensitivity (0,1)
#' @param spec Expected specificity (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_diseased, n_healthy, n_total, dor, inputs)
calc_diagnostic_odds_ratio <- function(sens, spec, alpha = 0.05, power = 0.8,
                                        alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(sens, "sens")
  .validate_unit_interval(spec, "spec")

  p1 <- sens
  p2 <- 1 - spec
  if (isTRUE(all.equal(p1, p2))) {
    stop("sensitivity and (1 - specificity) must differ -- otherwise DOR = 1 (no effect to detect).")
  }

  base <- calc_diagnostic_two_indep(p1 = p1, p2 = p2, alpha = alpha, power = power,
                                     alternative = alternative)
  dor <- (p1 / (1 - p1)) / (p2 / (1 - p2))

  list(
    n_diseased = base$n_per_group,
    n_healthy = base$n_per_group,
    n_total = base$n_total,
    dor = dor,
    inputs = list(sens = sens, spec = spec, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size for a likelihood ratio (LR+ or LR-), precision-based
#'
#' Wraps presize::prec_pos_lr() / prec_neg_lr() (Simel, Samsa & Matchar
#' 1991, formula 10). Precision-based: no hypothesis test, just an expected
#' Se/Sp/prevalence and a desired confidence-interval width for whichever
#' likelihood ratio is requested.
#'
#' @param sens Expected sensitivity (0,1)
#' @param spec Expected specificity (0,1)
#' @param prevalence Expected prevalence of the target condition (0,1)
#' @param type "positive" for LR+ or "negative" for LR-
#' @param conf_width Desired full width of the confidence interval for the LR
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, n_diseased, n_healthy, lr, lwr, upr, inputs)
calc_diagnostic_likelihood_ratio <- function(sens, spec, prevalence,
                                              type = c("positive", "negative"),
                                              conf_width, conf_level = 0.95) {
  type <- match.arg(type)
  .validate_unit_interval(sens, "sens")
  .validate_unit_interval(spec, "spec")
  .validate_unit_interval(prevalence, "prevalence")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")

  res <- if (type == "positive") {
    presize::prec_pos_lr(prev = prevalence, sens = sens, spec = spec,
                          n = NULL, conf.width = conf_width, conf.level = conf_level)
  } else {
    presize::prec_neg_lr(prev = prevalence, sens = sens, spec = spec,
                          n = NULL, conf.width = conf_width, conf.level = conf_level)
  }

  list(
    n = ceiling(res$n),
    n_diseased = ceiling(res$n1),
    n_healthy = ceiling(res$n2),
    lr = res$lr,
    lwr = res$lwr,
    upr = res$upr,
    inputs = list(sens = sens, spec = spec, prevalence = prevalence, type = type,
                  conf_width = conf_width, conf_level = conf_level)
  )
}
