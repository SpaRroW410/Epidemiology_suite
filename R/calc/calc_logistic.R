# Pure calculation functions for simple logistic regression sample size
# (one binary or continuous predictor). No Shiny dependency here so these
# are directly unit-testable (see tests/testthat). Wraps
# powerMediation::SSizeLogisticBin()/SSizeLogisticCon() (Hsieh, Bloch &
# Larsen 1998) rather than reimplementing the underlying math (project
# convention) -- and rather than the checklist's suggested
# WebPower::wp.logistic, since powerMediation has zero package
# dependencies (Depends: R, stats only) versus WebPower's heavy
# lme4/lavaan/dplyr/PearsonDS chain (the same avoidance already applied
# to the Incidence Rate module's rate-comparison design).

#' Sample size for simple logistic regression with a binary predictor
#'
#' Wraps powerMediation::SSizeLogisticBin() (Hsieh et al. 1998, Formula 2).
#'
#' @param p1 Event rate at X=0 (0,1)
#' @param p2 Event rate at X=1 (0,1)
#' @param prop_x1 Proportion of the sample with X=1 (0,1)
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_logistic_binary <- function(p1, p2, prop_x1, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  if (isTRUE(all.equal(p1, p2))) stop("p1 and p2 must differ (no effect to detect).")
  .validate_unit_interval(prop_x1, "prop_x1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- powerMediation::SSizeLogisticBin(p1 = p1, p2 = p2, B = prop_x1, alpha = alpha, power = power)

  list(
    n = ceiling(n),
    inputs = list(p1 = p1, p2 = p2, prop_x1 = prop_x1, alpha = alpha, power = power)
  )
}

#' Sample size for simple logistic regression with a continuous predictor
#'
#' Wraps powerMediation::SSizeLogisticCon() (Hsieh et al. 1998, Formula 1).
#'
#' @param p1 Event rate at the mean of the predictor (0,1)
#' @param or Expected odds ratio per one-SD increase in the predictor, > 0, != 1
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_logistic_continuous <- function(p1, or, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p1, "p1")
  .validate_positive(or, "or")
  if (isTRUE(all.equal(or, 1))) stop("or must differ from 1 (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- powerMediation::SSizeLogisticCon(p1 = p1, OR = or, alpha = alpha, power = power)

  list(
    n = ceiling(n),
    inputs = list(p1 = p1, or = or, alpha = alpha, power = power)
  )
}
