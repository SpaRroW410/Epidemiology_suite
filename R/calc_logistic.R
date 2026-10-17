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

#' Sample size for ordinal (proportional odds) logistic regression,
#' comparing two groups
#'
#' Generalizes the binary-outcome case above to an ordinal outcome with 3
#' or more ordered categories (e.g. none/mild/moderate/severe), comparing
#' two groups via the proportional-odds model. Wraps
#' Hmisc::posamsize() (already installed; no new dependency), which
#' directly implements Whitehead (1993)'s formula -- exactly the method
#' checklist_by_test.md names for this item -- and is the same engine
#' this app would need for the "multinomial regression" half of that same
#' checklist item's title, except no closed-form/installed-package
#' formula was found for a genuinely unordered (nominal) multinomial
#' outcome, so only the ordinal/proportional-odds case is covered.
#'
#' Verified exactly against Hmisc's own documented example (its help page
#' for popower()/posamsize(), back-pain severity study): p =
#' c(0.1, 0.2, 0.4, 0.3) (4 ordered categories), odds ratio = 1.2 ->
#' posamsize() returns n = 3148.3 (this function's ceiling() gives 3149),
#' and popower() at n = 3148 reproduces power = 0.80 exactly, both
#' reproduced directly by running the installed package.
#'
#' @param p Vector of marginal probabilities for each ordered category,
#'   averaged over the two groups (must sum to 1; length >= 2, though 2
#'   categories reduces to the ordinary binary case covered above)
#' @param odds_ratio Expected odds ratio between the two groups (> 0, != 1)
#' @param fraction Proportion of the sample allocated to group 1 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, eff, inputs)
calc_ordinal_proportional_odds <- function(p, odds_ratio, fraction = 0.5,
                                            alpha = 0.05, power = 0.8) {
  if (!is.numeric(p) || length(p) < 2 || anyNA(p) || any(p <= 0) || any(p >= 1)) {
    stop("p must be a numeric vector of at least 2 category probabilities, each strictly between 0 and 1.")
  }
  if (!isTRUE(all.equal(sum(p), 1))) {
    stop("p must sum to 1 (the category probabilities are exhaustive).")
  }
  .validate_positive(odds_ratio, "odds_ratio")
  if (isTRUE(all.equal(odds_ratio, 1))) stop("odds_ratio must differ from 1 (no effect to detect).")
  .validate_unit_interval(fraction, "fraction")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- .cf_posamsize(p = p, odds.ratio = odds_ratio, fraction = fraction,
                       alpha = alpha, power = power)

  new_ss_result(list(
    n = ceiling(fit$n),
    eff = fit$eff,
    inputs = list(p = p, odds_ratio = odds_ratio, fraction = fraction,
                  alpha = alpha, power = power)
  ))
}

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

  new_ss_result(list(
    n = ceiling(n),
    inputs = list(p1 = p1, p2 = p2, prop_x1 = prop_x1, alpha = alpha, power = power)
  ))
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

  new_ss_result(list(
    n = ceiling(n),
    inputs = list(p1 = p1, or = or, alpha = alpha, power = power)
  ))
}

#' Sample size for multiple logistic regression (covariate-adjusted),
#' binary predictor of interest
#'
#' Hsieh, Bloch & Larsen (1998) -- the same paper `calc_logistic_binary()`
#' already wraps -- note that when the predictor of interest is one of
#' several covariates in a MULTIPLE logistic regression model, the simple
#' (single-predictor) sample size above must be inflated by the variance
#' inflation factor 1/(1 - R-squared), where R-squared is the squared
#' multiple correlation between the predictor of interest and the other
#' covariates in the model -- exactly the same style of adjustment already
#' used elsewhere in this app for Cox regression (Hsieh & Lavori 2000's
#' rho-squared term in `calc_cox_binary()`/`calc_cox_continuous()`), since
#' both derive from the identical general Wald-test variance-inflation
#' argument. This is a thin algebraic wrapper around `calc_logistic_binary()`
#' -- no new formula or verification risk beyond the inflation itself.
#'
#' @param p1 Event rate at X=0 (0,1)
#' @param p2 Event rate at X=1 (0,1)
#' @param prop_x1 Proportion of the sample with X=1 (0,1)
#' @param r2 Squared multiple correlation between the predictor of
#'   interest and the other covariates in the model \[0, 1)
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n, n_unadjusted, inputs)
calc_logistic_binary_adjusted <- function(p1, p2, prop_x1, r2, alpha = 0.05, power = 0.8) {
  if (!is.numeric(r2) || length(r2) != 1 || is.na(r2) || r2 < 0 || r2 >= 1) {
    stop("r2 must be a single number in [0, 1).")
  }

  base <- calc_logistic_binary(p1 = p1, p2 = p2, prop_x1 = prop_x1, alpha = alpha, power = power)

  new_ss_result(list(
    n = ceiling(base$n / (1 - r2)),
    n_unadjusted = base$n,
    inputs = list(p1 = p1, p2 = p2, prop_x1 = prop_x1, r2 = r2, alpha = alpha, power = power)
  ))
}

#' Sample size for multiple logistic regression (covariate-adjusted),
#' continuous predictor of interest
#'
#' Same variance-inflation adjustment as `calc_logistic_binary_adjusted()`
#' above, applied instead to `calc_logistic_continuous()`'s single-predictor
#' case.
#'
#' @param p1 Event rate at the mean of the predictor (0,1)
#' @param or Expected odds ratio per one-SD increase in the predictor, > 0, != 1
#' @param r2 Squared multiple correlation between the predictor of
#'   interest and the other covariates in the model \[0, 1)
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n, n_unadjusted, inputs)
calc_logistic_continuous_adjusted <- function(p1, or, r2, alpha = 0.05, power = 0.8) {
  if (!is.numeric(r2) || length(r2) != 1 || is.na(r2) || r2 < 0 || r2 >= 1) {
    stop("r2 must be a single number in [0, 1).")
  }

  base <- calc_logistic_continuous(p1 = p1, or = or, alpha = alpha, power = power)

  new_ss_result(list(
    n = ceiling(base$n / (1 - r2)),
    n_unadjusted = base$n,
    inputs = list(p1 = p1, or = or, r2 = r2, alpha = alpha, power = power)
  ))
}
