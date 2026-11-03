# Pure calculation functions for proportion-based sample size.
# No Shiny dependency here so these are directly unit-testable (see tests/testthat).

#' Sample size for a single proportion vs. a known/reference value
#'
#' Wraps pwr::pwr.p.test (Cohen's arcsine-transformed effect size h).
#'
#' @param p0 Reference/hypothesized proportion (0,1)
#' @param p1 Expected/anticipated true proportion (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, h, inputs)
#' @examples
#' calc_proportion_1s(p0 = 0.3, p1 = 0.5, alpha = 0.05/3, power = 0.8)
#' @export
calc_proportion_1s <- function(p0, p1, alpha = 0.05, power = 0.8,
                                alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_unit_interval(p0, "p0")
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p0, p1))) {
    stop("p0 and p1 must differ (no effect to detect).")
  }

  h <- .cf_es_h(p1, p0)
  fit <- .cf_pwr_p_test(h = h, sig.level = alpha, power = power,
                          alternative = alternative)

  new_ss_result(list(
    n = ceiling(fit$n),
    h = h,
    inputs = list(p0 = p0, p1 = p1, alpha = alpha, power = power,
                  alternative = alternative)
  ))
}

#' Sample size for two independent proportions (equal allocation)
#'
#' Wraps pwr::pwr.2p.test (Cohen's arcsine-transformed effect size h).
#'
#' @param p1 Proportion in group 1 (0,1). Instead of `p1` give ONE of `OR`, `RR` or `RD`: group 2 is then the reference and `p1` is
#'   calculated from `p2` (as in OpenEpi's "fill in 1 of the following").
#' @param p2 Proportion in group 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @param OR Odds ratio of group 1 versus group 2, instead of `p1`
#' @param RR Risk ratio p1 / p2, instead of `p1`
#' @param RD Risk difference p1 - p2, instead of `p1`
#' @return list(n_per_group, n_total, h, p1, odds_ratio, inputs)
#' @examples
#' calc_proportion_2s(p1 = 0.1, p2 = 0.3, alpha = 0.05, power = 0.8, alternative = "two.sided")
#' @export
calc_proportion_2s <- function(p1 = NULL, p2, alpha = 0.05, power = 0.8,
                                alternative = c("two.sided", "less", "greater"),
                                OR = NULL, RR = NULL, RD = NULL) {
  alternative <- match.arg(alternative)

  .validate_unit_interval(p2, "p2")
  eff <- calc_es_proportions(p2, p1 = p1, OR = OR, RR = RR, RD = RD)
  given <- list(p1 = p1, OR = OR, RR = RR, RD = RD)
  p1 <- eff$p1
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p1, p2))) {
    stop("p1 and p2 must differ (no effect to detect).")
  }

  h <- .cf_es_h(p1, p2)
  fit <- .cf_pwr_2p_test(h = h, sig.level = alpha, power = power,
                           alternative = alternative)
  n_per_group <- ceiling(fit$n)

  new_ss_result(list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    h = h,
    p1 = p1,
    odds_ratio = eff$OR,
    inputs = c(Filter(Negate(is.null), given), list(p2 = p2, alpha = alpha, power = power,
                  alternative = alternative))
  ))
}

#' Sample size for a single proportion, precision-based (no reference value)
#'
#' Cochran's formula: estimates a proportion to within a desired precision (margin of error), with no hypothesis test and no
#' comparison group or reference value -- just "how many do I need to estimate my own prevalence within +/- d?". The precision is
#' absolute (d, on the 0-1 scale of p) or relative (epsilon, a fraction of p, so d = epsilon x p). Optionally applies the finite
#' population correction (FPC) when sampling from a population of known, limited size N (e.g. all students in one college) rather
#' than an effectively unlimited community, and inflates the result for non-response or loss to follow-up.
#'
#' The calculation is refused when the interval p +/- d would pass 0 or 1 (d >= p or d >= 1 - p) or a relative precision is 100% or
#' more. A relative precision above 20%, and a proportion below 10% (or above 90%) with d above one-fourth of p (of 1 - p), give a
#' warning in `precision_notes` (Pourhoseingholi et al. 2013 for the small-proportion rule).
#'
#' @param p Expected proportion (0,1). Use 0.5 if unknown (most conservative for absolute precision).
#' @param d Desired precision: the absolute margin of error (e.g. 0.05 for +/- 5 percentage points), or with `error = "relative"`
#'   the margin as a fraction of p (e.g. 0.1 for +/- 10% of p)
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @param N Optional finite population size (>= 1). NULL (default) = no
#'   correction, i.e. an effectively infinite population.
#' @param error "absolute" (default) or "relative"
#' @param nonresponse Expected fraction not analyzable (non-response, refusal or loss to follow-up), in \[0, 1); the number to enrol
#'   is n / (1 - nonresponse), rounded up
#' @return A named list of class `ss_result` with `n` (to analyze), `n_enrolled` (when `nonresponse` > 0), `n_unadjusted` (before the
#'   finite population correction), `d_absolute`, `epsilon_relative`, `z`, `N`, `precision_notes` (warnings) and `inputs`.
#' @examples
#' calc_proportion_precision(p = 0.5, d = 0.05, conf_level = 0.95)
#' calc_proportion_precision(p = 0.2, d = 0.1, error = "relative", nonresponse = 0.1)
#' @export
calc_proportion_precision <- function(p, d, conf_level = 0.95, N = NULL, error = c("absolute", "relative"), nonresponse = 0) {
  error <- match.arg(error)
  .validate_unit_interval(p, "p")
  .validate_unit_interval(conf_level, "conf_level")
  if (!is.numeric(d) || length(d) != 1 || is.na(d) || d <= 0 || (error == "absolute" && d >= 1)) {
    stop("d must be a single number strictly between 0 and 1.")
  }
  if (!is.null(N)) .validate_population(N)
  .validate_nonresponse(nonresponse)
  chk <- .precision_checks_proportion(p, d, error, "p")

  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  n0 <- (z^2 * p * (1 - p)) / chk$d^2
  n_adj <- if (is.null(N)) n0 else n0 / (1 + (n0 - 1) / N)
  n <- ceiling(n_adj)

  out <- list(n = n)
  if (nonresponse > 0) out$n_enrolled <- .inflate_nonresponse(n, nonresponse)
  new_ss_result(c(out, list(
    n_unadjusted = ceiling(n0),
    d_absolute = chk$d,
    epsilon_relative = chk$epsilon,
    z = z,
    N = N,
    precision_notes = chk$notes,
    inputs = list(p = p, d = d, error = error, conf_level = conf_level, N = N, nonresponse = nonresponse)
  )))
}

#' Sample size for a Bonferroni-adjusted post-hoc pairwise comparison of
#' two group proportions
#'
#' Wraps TrialSize::OneWayANOVA.PairwiseComparison() rather than
#' reimplementing the underlying math (project convention) -- TrialSize
#' already a zero-dependency project dependency. The formula is the
#' standard two-independent-proportions z-test sample size, with the
#' significance level Bonferroni-corrected for `tau` simultaneous
#' pairwise comparisons (alpha/tau in place of alpha) -- independently
#' re-derived here and confirmed to reproduce the package's own function
#' exactly, since its Rd file's own examples don't print a numeric
#' answer. See calc_means.R's calc_means_posthoc_pairwise() for the
#' continuous-outcome analog (same package, same correction logic).
#'
#' @param tau Number of pairwise comparisons planned across the whole
#'   study (whole number >= 1); e.g. tau = choose(k, 2) for all pairs
#'   among k groups, or a smaller number if only some pairs are planned
#' @param p1 Expected proportion in the first group of this specific pair (0,1)
#' @param p2 Expected proportion in the second group of this specific pair (0,1)
#' @param alpha Family-wise significance level (0,1), before Bonferroni
#'   correction
#' @param power Desired power (0,1)
#' @return list(n_per_group, inputs)
#' @examples
#' calc_proportion_posthoc_pairwise(tau = 2, p1 = 0.2, p2 = 0.4, alpha = 0.05, power = 0.8)
#' @export
calc_proportion_posthoc_pairwise <- function(tau, p1, p2, alpha = 0.05, power = 0.8) {
  if (!is.numeric(tau) || length(tau) != 1 || is.na(tau) || tau < 1 || tau != round(tau)) {
    stop("tau must be a single whole number >= 1.")
  }
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  if (isTRUE(all.equal(p1, p2))) {
    stop("p1 and p2 must differ (no effect to detect).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n_solved <- .cf_ts_anova_pairwise_prop(
    alpha = alpha, beta = 1 - power, tau = tau, p1 = p1, p2 = p2, delta = p1 - p2
  )

  new_ss_result(list(
    n_per_group = ceiling(n_solved),
    inputs = list(tau = tau, p1 = p1, p2 = p2, alpha = alpha, power = power)
  ))
}

# Shared .validate_unit_interval() / .validate_population() live in
# calc_utils.R (same package namespace).
