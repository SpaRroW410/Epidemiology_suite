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
