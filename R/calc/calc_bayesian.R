# Pure calculation function for a Bayesian assurance / averaged-power sample
# size (two-arm trial, log odds-ratio scale). No Shiny dependency here so
# this is directly unit-testable (see tests/testthat). Wraps
# Hmisc::gbayes2() rather than reimplementing the underlying integral
# (project convention).

#' Bayesian assurance (prior-averaged power) for a two-arm proportions trial
#'
#' Implements Spiegelhalter & Freedman (1986)'s Bayesian sample-size method:
#' rather than powering a trial against one fixed assumed effect, a prior
#' distribution is placed on the (unknown) true log odds ratio, and the
#' reported "assurance" is the power to observe a two-sided 1-alpha
#' confidence interval for the log odds ratio lying wholly above `delta_w`
#' (a minimally-worthwhile effect, 0 by default), averaged over that prior.
#' Wraps `Hmisc::gbayes2()` (already a project dependency), which performs
#' the averaging by numerical integration over an arbitrary prior density
#' -- here restricted to a single Normal or a Uniform prior on the log odds
#' ratio, the two shapes covering the package's own worked examples.
#'
#' The variance of the log odds ratio test statistic is approximated, as in
#' `gbayes2`'s own documented example, by the standard two-sample proportion
#' variance 1/(n1*p1*(1-p1)) + 1/(n2*p2*(1-p2)), evaluated at the
#' anticipated response rates `p1`/`p2`.
#'
#' @param p1 Anticipated response probability, group 1 (0,1)
#' @param p2 Anticipated response probability, group 2 (0,1)
#' @param prior_type "normal" (single Gaussian prior on the log odds ratio)
#'   or "uniform" (a flat prior between prior_lower and prior_upper)
#' @param prior_mean Prior mean of the log odds ratio (normal prior only)
#' @param prior_sd Prior SD of the log odds ratio, > 0 (normal prior only)
#' @param prior_lower,prior_upper Bounds of the log odds ratio prior
#'   (uniform prior only); prior_lower < prior_upper
#' @param delta_w Minimally worthwhile log odds ratio (default 0, i.e. any
#'   true improvement counts)
#' @param n_ratio Allocation ratio n2/n1 (> 0), default 1 (equal arms)
#' @param alpha Significance level for the two-sided credible interval (0,1)
#' @param power Target assurance (prior-averaged power) (0,1)
#' @return list(n1, n2, n_total, achieved_power, inputs)
calc_bayesian_assurance_or <- function(p1, p2,
                                        prior_type = c("normal", "uniform"),
                                        prior_mean = NULL, prior_sd = NULL,
                                        prior_lower = NULL, prior_upper = NULL,
                                        delta_w = 0, n_ratio = 1,
                                        alpha = 0.05, power = 0.8) {
  prior_type <- match.arg(prior_type)
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_number(delta_w, "delta_w")
  .validate_positive(n_ratio, "n_ratio")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  if (prior_type == "normal") {
    .validate_number(prior_mean, "prior_mean")
    .validate_positive(prior_sd, "prior_sd")
    prior <- function(delta) dnorm(delta, prior_mean, prior_sd)
  } else {
    .validate_number(prior_lower, "prior_lower")
    .validate_number(prior_upper, "prior_upper")
    if (prior_upper <= prior_lower) {
      stop("prior_upper must be greater than prior_lower.")
    }
    prior <- function(delta) dunif(delta, prior_lower, prior_upper)
  }

  v <- function(n1) 1 / (n1 * p1 * (1 - p1)) + 1 / (n1 * n_ratio * p2 * (1 - p2))
  assurance_given_n1 <- function(n1) {
    Hmisc::gbayes2(sqrt(v(n1)), prior, delta.w = delta_w, alpha = alpha)
  }

  n1_lower <- 2
  n1_upper <- 1e7
  if (!is.finite(assurance_given_n1(n1_upper)) || assurance_given_n1(n1_upper) < power) {
    stop("No feasible sample size for these inputs (prior/effect likely too weak or delta_w too large).")
  }

  n1 <- ceiling(uniroot(function(n1) assurance_given_n1(n1) - power, c(n1_lower, n1_upper))$root)
  n2 <- ceiling(n1 * n_ratio)

  list(
    n1 = n1,
    n2 = n2,
    n_total = n1 + n2,
    achieved_power = assurance_given_n1(n1),
    inputs = list(
      p1 = p1, p2 = p2, prior_type = prior_type,
      prior_mean = prior_mean, prior_sd = prior_sd,
      prior_lower = prior_lower, prior_upper = prior_upper,
      delta_w = delta_w, n_ratio = n_ratio, alpha = alpha, power = power
    )
  )
}
