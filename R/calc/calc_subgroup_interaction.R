# Pure calculation function for the subgroup/interaction-test sample-size
# inflation rule (Brookes et al. 2004). No Shiny dependency here so this
# is directly unit-testable (see tests/testthat).
#
# Testing whether a treatment effect DIFFERS between two subgroups (a
# treatment-by-subgroup interaction) needs a much larger sample than
# testing the treatment effect itself. This is a general multiplier
# applicable to ANY two-group comparison already sized elsewhere in this
# app (means, proportions, survival, etc.) -- not a new statistical test,
# so no package is needed or exists for it; it's pure arithmetic on an
# already-computed main-effect sample size.
#
# Derivation (independently re-derived here, not just quoted): for a
# main-effect test comparing 2 groups with per-group n, the test
# statistic's variance is proportional to 1/n. For the interaction test
# (a difference-of-differences across 4 cells: 2 subgroups x 2 arms,
# each with the same per-cell n as the main-effect groups would have),
# the variance is exactly double that of a single group-difference
# variance (since it's a difference of two independent differences).
# Solving each design for the sample size needed to detect its own
# target effect size at the same alpha/power gives:
#   N_interaction_total / N_main_total = 4 * (delta_main / delta_interaction)^2
# At effect_ratio = delta_interaction/delta_main = 1 (an interaction of
# the same magnitude as the main effect), this gives exactly 4 --
# matching Brookes et al. (2004)'s own headline "~4x" result. At
# effect_ratio = 0.5 (an interaction half the main effect's magnitude),
# it gives exactly 16 -- matching the paper's own reported "16x for half
# the magnitude" finding. Both were independently verified via a direct
# z-based power-formula derivation before shipping (see
# tests/testthat/test-calc_subgroup_interaction.R).

#' Sample size needed to test a treatment-by-subgroup interaction, given
#' an already-computed main-effect sample size
#'
#' Inflates a main-effect total sample size (from any two-group
#' comparison already sized elsewhere -- e.g. this app's Means or
#' Proportions modules) to the total sample size needed to detect a
#' treatment-by-subgroup interaction of a given relative magnitude, at
#' the same alpha and power the main-effect calculation used.
#'
#' @param n_main_total Total sample size for the main-effect comparison
#'   (both arms combined), from an already-computed two-group design
#'   (whole number >= 2)
#' @param effect_ratio Ratio of the interaction effect's magnitude to
#'   the main effect's magnitude (> 0); default 1 (an interaction the
#'   same size as the main effect -- Brookes et al.'s headline scenario)
#' @return list(n_interaction_total, multiplier, inputs)
calc_subgroup_interaction <- function(n_main_total, effect_ratio = 1) {
  if (!is.numeric(n_main_total) || length(n_main_total) != 1 || is.na(n_main_total) ||
        n_main_total < 2 || n_main_total != round(n_main_total)) {
    stop("n_main_total must be a single whole number >= 2.")
  }
  .validate_positive(effect_ratio, "effect_ratio")

  multiplier <- 4 / effect_ratio^2
  n_interaction_total <- ceiling(n_main_total * multiplier)

  list(
    n_interaction_total = n_interaction_total,
    multiplier = multiplier,
    inputs = list(n_main_total = n_main_total, effect_ratio = effect_ratio)
  )
}
