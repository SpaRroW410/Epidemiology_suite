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
#' @examples
#' calc_rate_precision(rate = 2.5, conf_width = 2.243, conf_level = 0.95, method = "score")
#' @export
calc_rate_precision <- function(rate, conf_width, conf_level = 0.95,
                                 method = c("score", "vs", "exact", "wald")) {
  method <- match.arg(method)
  .validate_positive(rate, "rate")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")
  if (conf_width > 5 * rate) {
    stop("conf_width should not exceed 5 times rate (presize::prec_rate's own guidance).")
  }

  fit <- .cf_prec_rate(r = rate, conf.width = conf_width,
                             conf.level = conf_level, method = method)
  n_events <- ceiling(fit$x)
  achieved <- .cf_prec_rate(r = rate, x = n_events,
                                  conf.level = conf_level, method = method)

  new_ss_result(list(
    n_events = n_events,
    person_time = n_events / rate,
    achieved_conf_width = achieved$conf.width,
    inputs = list(rate = rate, conf_width = conf_width,
                  conf_level = conf_level, method = method)
  ))
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
#' @examples
#' calc_rate_comparison(rate_ref = 2.798, rate_ratio = 0.8938, prop_exposed = 0.53, 
#'     alpha = 0.05, power = 0.8)
#' @export
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

  new_ss_result(list(
    n_total = n_total,
    n_exposed = n_exposed,
    n_reference = n_total - n_exposed,
    inputs = list(rate_ref = rate_ref, rate_ratio = rate_ratio, prop_exposed = prop_exposed,
                  alpha = alpha, power = power, alternative = alternative)
  ))
}

#' Sample size for Poisson regression with a continuous, normally
#' distributed predictor
#'
#' The design above (calc_rate_comparison()) covers Poisson regression
#' with a single BINARY predictor (comparing two groups' rates); this
#' covers the continuous-predictor case named in the same
#' checklist_by_test.md item ("Poisson regression -- rate ratio, exposure
#' distribution"), for a normally distributed predictor (e.g. a
#' continuous exposure or biomarker level) rather than an exposed/
#' unexposed group indicator. Wraps powerMediation::sizePoisson() --
#' already a project dependency (used by the Logistic Regression module)
#' -- which directly implements Signorini (1991)'s closed-form Wald-test
#' formula, exactly the source this app's own docs/checklist_by_test.md
#' cites for this item (via `WebPower::wp.poisson`, which itself wraps
#' the same Signorini formula; `powerMediation` is used here instead
#' since it is already a project dependency with zero package
#' dependencies of its own).
#'
#' Verified exactly against the package's own documented example:
#' beta0 = 0.1, beta1 = 0.5, mu.x1 = 0, sigma2.x1 = 1, mu.T = 1, phi = 1,
#' alpha = 0.05, power = 0.80 -> n = 28, reproduced by directly running
#' the installed package.
#'
#' @param beta0 Intercept (log scale) of the Poisson regression
#' @param beta1 Slope (log rate ratio per unit increase in the
#'   predictor); the effect size being tested (!= 0)
#' @param mu_x1 Mean of the predictor (assumed normally distributed)
#' @param sigma2_x1 Variance of the predictor (> 0)
#' @param mu_T Mean exposure/follow-up time (> 0)
#' @param phi Over-dispersion parameter, var(y)/mean(y) (>= 1; 1 = no
#'   over-dispersion, i.e. a genuine Poisson distribution)
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n_total, inputs)
#' @examples
#' calc_poisson_regression_continuous(beta0 = 0.1, beta1 = 0.5, mu_x1 = 0, sigma2_x1 = 1, 
#'     mu_T = 1, phi = 1, alpha = 0.05, power = 0.8)
#' @export
calc_poisson_regression_continuous <- function(beta0, beta1, mu_x1, sigma2_x1,
                                                mu_T = 1, phi = 1,
                                                alpha = 0.05, power = 0.8) {
  .validate_number(beta0, "beta0")
  .validate_number(beta1, "beta1")
  if (isTRUE(all.equal(beta1, 0))) stop("beta1 must differ from 0 (no effect to detect).")
  .validate_number(mu_x1, "mu_x1")
  .validate_positive(sigma2_x1, "sigma2_x1")
  .validate_positive(mu_T, "mu_T")
  if (!is.numeric(phi) || length(phi) != 1 || is.na(phi) || phi < 1) {
    stop("phi must be a single number >= 1 (the over-dispersion parameter; 1 = no over-dispersion).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- .cf_size_poisson(beta0 = beta0, beta1 = beta1, mu.x1 = mu_x1,
                                    sigma2.x1 = sigma2_x1, mu.T = mu_T, phi = phi,
                                    alpha = alpha, power = power)

  new_ss_result(list(
    n_total = ceiling(n),
    inputs = list(beta0 = beta0, beta1 = beta1, mu_x1 = mu_x1, sigma2_x1 = sigma2_x1,
                  mu_T = mu_T, phi = phi, alpha = alpha, power = power)
  ))
}

# Comparison of two negative binomial rates, Zhu & Lakkis (2014).
#
# The checklist's named package for this item, `MKpower` (its function
# `power.nb.test()`), is not installed and CRAN is unreachable from this
# sandbox. Its source was read directly from its public GitHub CRAN
# mirror (https://raw.githubusercontent.com/cran/MKpower/master/R/
# powerNbinomTest.R) -- a single, self-contained closed-form function
# with no cross-file dependencies, unlike the large multi-file packages
# (`gsDesign`, `npsurvSS`) this session judged too complex to safely
# reimplement -- and transcribed directly below.
#
# This is a genuinely different method than the existing Poisson
# comparison-of-two-rates design (`calc_rate_comparison()`) and the
# Poisson regression design above (`calc_poisson_regression_continuous()`,
# whose `phi` over-dispersion parameter linearly inflates the Poisson
# variance, a quasi-Poisson-style adjustment) -- the negative binomial
# model instead has a quadratic mean-variance relationship (Var(Y) = mu +
# mu^2/theta), the standard model for count data whose over-dispersion
# grows with the mean rather than staying proportional to it.
#
# Verified two independent ways against the package's own worked example
# (mu0=10, RR=1.5, theta=1/5, duration=1, ssize.ratio=1.5, approach=3,
# target power=0.8 -> n0=405/n1=607): (1) reproducing the package's own
# defined test statistic exactly (Z = sqrt(n0)*log(mu1_hat/mu0_hat) /
# sqrt(V1), using the DESIGN-ASSUMED dispersion, matching how the formula
# itself is derived) on simulated MASS::rnegbin() data -> empirical power
# 0.814; (2) a genuinely independent check fitting MASS::glm.nb() (which
# ESTIMATES the dispersion from the data rather than assuming it known)
# on the same simulated data and using its own Wald test p-value ->
# empirical power 0.797 -- both close to the formula's own target of 0.8.

#' Sample size for comparing two negative binomial rates
#'
#' Wraps a direct transcription of `MKpower::power.nb.test()` (Zhu &
#' Lakkis 2014). Solves for the control-group sample size needed to
#' detect a given rate ratio between two groups whose event counts follow
#' negative binomial distributions (Var(Y) = mu + mu^2/theta -- constant-
#' over-dispersion count data, e.g. recurrent-event or exacerbation
#' counts), given a fixed treatment/follow-up duration.
#'
#' @param mu0 Expected event rate per time unit, group 0 (control) (> 0)
#' @param RR Rate ratio, group 1 (treatment) vs. group 0 (> 0, != 1)
#' @param theta Dispersion parameter of the negative binomial
#'   distribution, in the `MASS::rnegbin()` parameterization (Var(Y) =
#'   mu + mu^2/theta); > 0, smaller = more over-dispersion
#' @param duration Average treatment/follow-up duration (> 0)
#' @param ssize_ratio Ratio of group-1 to group-0 sample size (> 0),
#'   default 1 (equal allocation)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided" or "one.sided"
#' @param approach 1, 2, or 3 (three variance-estimator variants from Zhu
#'   & Lakkis 2014); default 3, one of the two the authors' own
#'   simulation study recommends (along with 2)
#' @return list(n0, n1, n_total, inputs)
#' @examples
#' calc_negative_binomial_rates(mu0 = 10, RR = 1.5, theta = 1/5, duration = 1, ssize_ratio = 3/2, 
#'     power = 0.8, approach = 3)
#' @export
calc_negative_binomial_rates <- function(mu0, RR, theta, duration = 1, ssize_ratio = 1,
                                          alpha = 0.05, power = 0.8,
                                          alternative = "two.sided", approach = 3) {
  .validate_positive(mu0, "mu0")
  .validate_positive(RR, "RR")
  if (isTRUE(all.equal(RR, 1))) stop("RR must differ from 1 (no effect to detect).")
  .validate_positive(theta, "theta")
  .validate_positive(duration, "duration")
  .validate_positive(ssize_ratio, "ssize_ratio")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!alternative %in% c("two.sided", "one.sided")) {
    stop('alternative must be "two.sided" or "one.sided".')
  }
  if (!approach %in% c(1, 2, 3)) stop("approach must be 1, 2, or 3.")

  mu1 <- mu0 * RR
  sided <- if (alternative == "one.sided") 1 else 2
  k <- 1 / theta

  if (approach == 1) {
    V0 <- (1 + ssize_ratio) / (duration * ssize_ratio * mu0) + (1 + ssize_ratio) * k / ssize_ratio
  } else if (approach == 2) {
    V0 <- 1 / duration * (1 / mu0 + 1 / (ssize_ratio * mu1)) + (1 + ssize_ratio) * k / ssize_ratio
  } else {
    V0 <- (1 + ssize_ratio)^2 / (duration * ssize_ratio * (mu0 + ssize_ratio * mu1)) +
      (1 + ssize_ratio) * k / ssize_ratio
  }
  V1 <- 1 / duration * (1 / mu0 + 1 / (ssize_ratio * mu1)) + (1 + ssize_ratio) * k / ssize_ratio

  beta <- 1 - power
  if (sided == 1) {
    n0 <- ((qnorm(1 - alpha) * sqrt(V0) + qnorm(1 - beta) * sqrt(V1)) / log(mu1 / mu0))^2
  } else {
    n0 <- ((qnorm(1 - alpha / 2) * sqrt(V0) + qnorm(1 - beta) * sqrt(V1)) / log(mu1 / mu0))^2
  }
  n1 <- ssize_ratio * n0

  new_ss_result(list(
    n0 = ceiling(n0), n1 = ceiling(n1), n_total = ceiling(n0) + ceiling(n1),
    inputs = list(mu0 = mu0, RR = RR, theta = theta, duration = duration,
                  ssize_ratio = ssize_ratio, alpha = alpha, power = power,
                  alternative = alternative, approach = approach)
  ))
}
