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
