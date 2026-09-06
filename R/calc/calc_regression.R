# Pure calculation function for multiple linear regression sample size. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps pwr::pwr.f2.test() rather than reimplementing the
# underlying math (project convention).

#' Sample size for multiple linear regression, R-squared deviation from zero
#'
#' Tests whether the overall model R-squared is significantly greater than
#' zero, given a fixed number of predictors -- the "fixed model, R-squared
#' deviation from zero" case in Cohen (1988). Converts the user-facing R^2
#' to Cohen's f^2 = R^2 / (1 - R^2) before calling pwr::pwr.f2.test(),
#' same pattern as calc_means_2s_indep() converting raw means to Cohen's d.
#'
#' @param r2 Expected/anticipated R-squared (0,1)
#' @param num_predictors Number of candidate predictors in the model
#'   (whole number >= 1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, f2, v, inputs)
calc_regression_f2 <- function(r2, num_predictors, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(r2, "r2")
  if (!is.numeric(num_predictors) || length(num_predictors) != 1 || is.na(num_predictors) ||
      num_predictors < 1 || num_predictors != round(num_predictors)) {
    stop("num_predictors must be a single whole number >= 1.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  f2 <- r2 / (1 - r2)
  fit <- pwr::pwr.f2.test(u = num_predictors, v = NULL, f2 = f2,
                           sig.level = alpha, power = power)
  v <- ceiling(fit$v)
  n <- v + num_predictors + 1

  list(
    n = n,
    f2 = f2,
    v = v,
    inputs = list(r2 = r2, num_predictors = num_predictors, alpha = alpha, power = power)
  )
}

#' Sample size for hierarchical multiple regression, R-squared increase
#' from adding a set of predictors
#'
#' Tests whether adding a set of new predictors to an existing ("reduced")
#' model significantly increases R-squared -- Cohen (1988)'s "fixed
#' model, R-squared increase" case (section 9.7), the same general-linear-
#' model F-test framework as calc_regression_f2() above and
#' calc_anova_general(), just with a different effect-size/df mapping:
#' f2 = (R2_full - R2_reduced) / (1 - R2_full), tested with u = the
#' number of *added* predictors and v = n - (total predictors in the
#' full model) - 1 (the full model's residual degrees of freedom).
#' Verified by simulation (fitting nested lm() models and comparing via
#' anova(reduced, full), the actual F-test this design plans for): for
#' R2_reduced = 0.30 (3 predictors), R2_full = 0.40 (adding 2 more, 5
#' total), alpha = 0.05, power = 0.80, this returns n = 64, and 10,000
#' simulated replicates at that n give an empirical power of ~0.78-0.80 --
#' the same small (~2-3%) gap already seen when simulating this project's
#' existing calc_regression_f2() the same way (random, not fixed,
#' predictor draws), consistent with the well-known fixed- vs
#' random-regressor distinction in Cohen (1988), not a formula error.
#'
#' @param r2_reduced R-squared of the existing (reduced) model, without
#'   the new predictors (0,1)
#' @param r2_full R-squared of the full model, with the new predictors
#'   added (0,1), > r2_reduced
#' @param num_predictors_added Number of new predictors being added
#'   (whole number >= 1)
#' @param num_predictors_total Total number of predictors in the full
#'   model (whole number >= num_predictors_added + 1, since the reduced
#'   model needs at least 1 predictor)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, f2, v, inputs)
calc_regression_r2_increase <- function(r2_reduced, r2_full, num_predictors_added,
                                         num_predictors_total, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(r2_reduced, "r2_reduced")
  .validate_unit_interval(r2_full, "r2_full")
  if (r2_full <= r2_reduced) {
    stop("r2_full must be greater than r2_reduced (no improvement to detect).")
  }
  if (!is.numeric(num_predictors_added) || length(num_predictors_added) != 1 ||
      is.na(num_predictors_added) || num_predictors_added < 1 ||
      num_predictors_added != round(num_predictors_added)) {
    stop("num_predictors_added must be a single whole number >= 1.")
  }
  if (!is.numeric(num_predictors_total) || length(num_predictors_total) != 1 ||
      is.na(num_predictors_total) || num_predictors_total != round(num_predictors_total)) {
    stop("num_predictors_total must be a single whole number.")
  }
  if (num_predictors_total <= num_predictors_added) {
    stop("num_predictors_total must be greater than num_predictors_added (the reduced model needs at least 1 predictor).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  f2 <- (r2_full - r2_reduced) / (1 - r2_full)
  fit <- pwr::pwr.f2.test(u = num_predictors_added, v = NULL, f2 = f2,
                           sig.level = alpha, power = power)
  v <- ceiling(fit$v)
  n <- v + num_predictors_total + 1

  list(
    n = n,
    f2 = f2,
    v = v,
    inputs = list(r2_reduced = r2_reduced, r2_full = r2_full,
                  num_predictors_added = num_predictors_added,
                  num_predictors_total = num_predictors_total,
                  alpha = alpha, power = power)
  )
}
