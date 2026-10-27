# Pure calculation function for a 2x2 crossover trial's sample size
# (continuous outcome, testing for a difference/superiority -- not
# equivalence, which is already covered by the Equivalence (TOST) module).
# No Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps TrialSize::TwoSampleCrossOver.Equality() rather
# than reimplementing the underlying math (project convention) -- TrialSize
# has zero package dependencies (Imports: only base R's stats functions),
# so no dependency-weight concern here.

#' Sample size for a 2x2 crossover trial, continuous outcome, testing
#' for a difference between treatments
#'
#' Each subject receives both treatments (in one of two sequences, AB or
#' BA, separated by a washout period), so the analysis uses each subject
#' as their own control. Sizes the trial to detect a given true mean
#' difference, given the within-subject standard deviation.
#'
#' @param delta True mean difference to detect (test minus control), != 0
#' @param sigma Within-subject standard deviation in the crossover design, > 0
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n_per_sequence, n_total, inputs)
calc_crossover_2x2 <- function(delta, sigma, alpha = 0.05, power = 0.8) {
  .validate_number(delta, "delta")
  if (isTRUE(all.equal(delta, 0))) stop("delta must differ from 0 (no effect to detect).")
  .validate_positive(sigma, "sigma")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n_per_sequence <- ceiling(.cf_ts_crossover_equality(
    alpha = alpha, beta = 1 - power, sigma = sigma, margin = delta
  ))

  new_ss_result(list(
    n_per_sequence = n_per_sequence,
    n_total = n_per_sequence * 2,
    inputs = list(delta = delta, sigma = sigma, alpha = alpha, power = power)
  ))
}
