# Pure calculation function for incidence-rate estimation precision. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps presize::prec_rate() rather than reimplementing
# the underlying math (project convention).

#' Precision-based sample size (number of events / person-time) for an
#' incidence rate estimate
#'
#' Solves for the number of events needed to achieve a target confidence
#' interval width for an incidence rate, then converts that to the
#' required person-time (since rate = events / person-time). Wraps
#' presize::prec_rate(), which itself uses `uniroot` to solve n from
#' conf.width.
#'
#' @param rate Expected rate (events per unit person-time, e.g. per
#'   person-year) (> 0)
#' @param conf_width Desired full width of the confidence interval, in the
#'   same units as `rate`. Per presize's own guidance this should not
#'   exceed 5 times `rate`.
#' @param conf_level Confidence level (0,1)
#' @param method One of "score", "vs" (variance-stabilizing), "exact", or
#'   "wald". "exact" is recommended when the expected number of events is
#'   small (< 5).
#' @return list(n_events, person_time, achieved_conf_width, inputs)
calc_rate_precision <- function(rate, conf_width, conf_level = 0.95,
                                 method = c("score", "vs", "exact", "wald")) {
  method <- match.arg(method)
  .validate_positive(rate, "rate")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")
  if (conf_width > 5 * rate) {
    stop("conf_width should not exceed 5 times rate (presize::prec_rate's own guidance).")
  }

  fit <- presize::prec_rate(r = rate, conf.width = conf_width,
                             conf.level = conf_level, method = method)
  n_events <- ceiling(fit$x)
  achieved <- presize::prec_rate(r = rate, x = n_events,
                                  conf.level = conf_level, method = method)

  list(
    n_events = n_events,
    person_time = n_events / rate,
    achieved_conf_width = achieved$conf.width,
    inputs = list(rate = rate, conf_width = conf_width,
                  conf_level = conf_level, method = method)
  )
}

#' Sample size to compare two incidence rates (Poisson regression, single
#' binary predictor)
#'
#' Comparing two group incidence rates via person-time is algebraically a
#' Poisson regression with one Bernoulli-distributed predictor (the group
#' indicator) -- Demidenko (2007)'s Wald-test power formula for Poisson
#' regression, specialised to that one-predictor case. This closed-form
#' implementation reproduces the WebPower::wp.poisson(family = "Bernoulli")
#' formula exactly (verified against its own documented example) without
#' taking a dependency on the WebPower package, whose Depends: (lme4,
#' lavaan, dplyr, PearsonDS) are far heavier than this one formula needs --
#' consistent with this project's "wrap a real package, but not at the cost
#' of a disproportionate dependency tree" practice (see e.g. PowerTOST over
#' TOSTER, powerSurvEpi over gsDesign elsewhere in this app).
#'
#' @param rate_ref Expected incidence rate in the reference (unexposed) group
#'   (events per unit person-time, > 0)
#' @param rate_ratio Expected rate ratio (exposed group's rate divided by
#'   the reference group's rate, > 0, != 1)
#' @param prop_exposed Proportion of the total sample in the exposed group
#'   (0,1); 0.5 = equal allocation
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_total, n_exposed, n_reference, inputs)
calc_rate_comparison <- function(rate_ref, rate_ratio, prop_exposed = 0.5,
                                  alpha = 0.05, power = 0.8,
                                  alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_positive(rate_ref, "rate_ref")
  .validate_positive(rate_ratio, "rate_ratio")
  if (isTRUE(all.equal(rate_ratio, 1))) stop("rate_ratio must differ from 1 (no effect to detect).")
  .validate_unit_interval(prop_exposed, "prop_exposed")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  beta0 <- log(rate_ref)
  beta1 <- log(rate_ratio)
  B <- prop_exposed
  a <- (1 - B) * exp(beta0) + B * exp(beta0 + beta1)
  b <- B * exp(beta0 + beta1)
  v1 <- a / (a * b - b^2)

  tside <- switch(alternative, less = 1, two.sided = 2, greater = 3)
  if (tside == 1) { s <- 1; t <- 0; a_used <- alpha }
  if (tside == 2) { s <- 1; t <- 1; a_used <- alpha / 2 }
  if (tside == 3) { s <- 0; t <- 1; a_used <- alpha }

  power_at_n <- function(n) {
    s * stats::pnorm(-stats::qnorm(1 - a_used) - sqrt(n) / sqrt(v1) * beta1) +
      t * stats::pnorm(-stats::qnorm(1 - a_used) + sqrt(n) / sqrt(v1) * beta1)
  }

  n_solved <- stats::uniroot(function(n) power_at_n(n) - power, c(4 + 1e-8, 1e7))$root
  n_total <- ceiling(n_solved)
  n_exposed <- ceiling(n_total * prop_exposed)

  list(
    n_total = n_total,
    n_exposed = n_exposed,
    n_reference = n_total - n_exposed,
    inputs = list(rate_ref = rate_ref, rate_ratio = rate_ratio, prop_exposed = prop_exposed,
                  alpha = alpha, power = power, alternative = alternative)
  )
}
