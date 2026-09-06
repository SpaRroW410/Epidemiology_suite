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

  n <- powerMediation::sizePoisson(beta0 = beta0, beta1 = beta1, mu.x1 = mu_x1,
                                    sigma2.x1 = sigma2_x1, mu.T = mu_T, phi = phi,
                                    alpha = alpha, power = power)

  list(
    n_total = ceiling(n),
    inputs = list(beta0 = beta0, beta1 = beta1, mu_x1 = mu_x1, sigma2_x1 = sigma2_x1,
                  mu_T = mu_T, phi = phi, alpha = alpha, power = power)
  )
}
