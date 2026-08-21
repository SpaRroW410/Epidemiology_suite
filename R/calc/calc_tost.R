# Pure calculation function for equivalence testing (TOST) sample size. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps PowerTOST::sampleN.TOST() rather than
# reimplementing the underlying math (project convention).

#' Sample size for a two one-sided tests (TOST) equivalence trial on means
#'
#' Wraps PowerTOST::sampleN.TOST() on the *original* (untransformed) scale
#' (logscale = FALSE) with a parallel-groups design -- i.e. raw units, not
#' the log-ratio/CV framing used for pharmacokinetic bioequivalence
#' (PowerTOST's more common use case, and still available via this same
#' package for that more specialized design).
#'
#' @param mean_diff Expected/assumed difference in means (test - reference)
#' @param margin Equivalence margin (> 0); the true difference must fall
#'   within (-margin, +margin) to conclude equivalence
#' @param sd Common/pooled standard deviation (> 0)
#' @param alpha Significance level, one-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n_total, n_per_group, achieved_power, inputs)
calc_tost_means <- function(mean_diff, margin, sd, alpha = 0.05, power = 0.8) {
  .validate_number(mean_diff, "mean_diff")
  .validate_positive(margin, "margin")
  .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (abs(mean_diff) >= margin) {
    stop("mean_diff must fall strictly within (-margin, margin) -- otherwise equivalence can't be shown even with infinite sample size.")
  }

  fit <- PowerTOST::sampleN.TOST(
    alpha = alpha, targetpower = power, logscale = FALSE,
    theta0 = mean_diff, theta1 = -margin, theta2 = margin,
    CV = sd, design = "parallel", print = FALSE
  )

  n_total <- fit[["Sample size"]]
  n_per_group <- ceiling(n_total / 2)

  list(
    n_total = n_per_group * 2,
    n_per_group = n_per_group,
    achieved_power = fit[["Achieved power"]],
    inputs = list(mean_diff = mean_diff, margin = margin, sd = sd,
                  alpha = alpha, power = power)
  )
}
