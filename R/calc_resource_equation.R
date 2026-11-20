# Pure calculation functions for the "resource equation" method (Mead
# 1988; Charan & Kantharia 2013) used to size small exploratory animal
# studies. No Shiny dependency here so this is directly unit-testable
# (see tests/testthat).
#
# Unlike every other calc_*.R file, this is guidance, not a formal power
# calculation: E = N - T (total experimental units minus total number of
# treatment groups) is a degrees-of-freedom heuristic, not derived from a
# type-I/type-II error target. Mead's rule of thumb: E between 10 and 20
# is adequate for detecting a difference if one exists, without wasting
# animals -- E<10 risks being underpowered, E>20 wastes animals with
# little further gain in the error degrees of freedom. This is pure
# arithmetic (E = N - T), so no package is needed or exists for it.

#' Recommended total sample size from the resource equation method
#'
#' Given a desired error degrees-of-freedom target E (Mead's rule of
#' thumb recommends 10-20) and the number of treatment groups, returns the
#' total number of experimental units (and implied per-group n) needed.
#'
#' @param k_groups Number of treatment groups (whole number >= 2)
#' @param e_target Desired error degrees of freedom E (whole number >= 1); default 10
#' @return list(n_total, n_per_group, e, inputs)
#' @examples
#' calc_resource_equation_size(k_groups = 5, e_target = 10)
#' @export
calc_resource_equation_size <- function(k_groups, e_target = 10) {
  if (!is.numeric(k_groups) || length(k_groups) != 1 || is.na(k_groups) ||
        k_groups < 2 || k_groups != round(k_groups)) {
    stop("k_groups must be a single whole number >= 2.")
  }
  if (!is.numeric(e_target) || length(e_target) != 1 || is.na(e_target) ||
        e_target < 1 || e_target != round(e_target)) {
    stop("e_target must be a single whole number >= 1.")
  }

  n_total <- e_target + k_groups
  n_per_group <- ceiling(n_total / k_groups)

  new_ss_result(list(
    n_total = n_total, n_per_group = n_per_group, e = e_target,
    inputs = list(k_groups = k_groups, e_target = e_target)
  ))
}

#' Check the adequacy of a chosen (or already-run) animal study's sample size
#'
#' Given the number of groups and the number of experimental units per
#' group, computes the resource-equation error degrees of freedom E and
#' classifies it against Mead's 10-20 rule of thumb.
#'
#' @param k_groups Number of treatment groups (whole number >= 2)
#' @param n_per_group Number of experimental units per group (whole number >= 1)
#' @return list(n_total, e, verdict, inputs) where verdict is one of
#'   "too low", "adequate", "more than needed"
#' @examples
#' calc_resource_equation_check(k_groups = 5, n_per_group = 10)
#' @export
calc_resource_equation_check <- function(k_groups, n_per_group) {
  if (!is.numeric(k_groups) || length(k_groups) != 1 || is.na(k_groups) ||
        k_groups < 2 || k_groups != round(k_groups)) {
    stop("k_groups must be a single whole number >= 2.")
  }
  if (!is.numeric(n_per_group) || length(n_per_group) != 1 || is.na(n_per_group) ||
        n_per_group < 1 || n_per_group != round(n_per_group)) {
    stop("n_per_group must be a single whole number >= 1.")
  }

  n_total <- n_per_group * k_groups
  e <- n_total - k_groups
  verdict <- if (e < 10) {
    "too low"
  } else if (e > 20) {
    "more than needed"
  } else {
    "adequate"
  }

  new_ss_result(list(
    n_total = n_total, e = e, verdict = verdict,
    inputs = list(k_groups = k_groups, n_per_group = n_per_group)
  ))
}
