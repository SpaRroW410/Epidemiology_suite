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

  h <- pwr::ES.h(p1, p0)
  fit <- pwr::pwr.p.test(h = h, sig.level = alpha, power = power,
                          alternative = alternative)

  list(
    n = ceiling(fit$n),
    h = h,
    inputs = list(p0 = p0, p1 = p1, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size for two independent proportions (equal allocation)
#'
#' Wraps pwr::pwr.2p.test (Cohen's arcsine-transformed effect size h).
#'
#' @param p1 Proportion in group 1 (0,1)
#' @param p2 Proportion in group 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, n_total, h, inputs)
calc_proportion_2s <- function(p1, p2, alpha = 0.05, power = 0.8,
                                alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(p1, p2))) {
    stop("p1 and p2 must differ (no effect to detect).")
  }

  h <- pwr::ES.h(p1, p2)
  fit <- pwr::pwr.2p.test(h = h, sig.level = alpha, power = power,
                           alternative = alternative)
  n_per_group <- ceiling(fit$n)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    h = h,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size for a single proportion, precision-based (no reference value)
#'
#' Cochran's formula: estimates a proportion to within a desired absolute
#' precision (margin of error), with no hypothesis test and no comparison
#' group or reference value -- just "how many do I need to estimate my own
#' prevalence within +/- d?". Optionally applies the finite population
#' correction (FPC) when sampling from a population of known, limited size N
#' (e.g. all students in one college) rather than an effectively unlimited
#' community.
#'
#' @param p Expected proportion (0,1). Use 0.5 if unknown (most conservative).
#' @param d Desired absolute precision / margin of error (0,1), e.g. 0.05
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @param N Optional finite population size (>= 1). NULL (default) = no
#'   correction, i.e. an effectively infinite population.
#' @return list(n, n_unadjusted, z, N, inputs)
calc_proportion_precision <- function(p, d, conf_level = 0.95, N = NULL) {
  .validate_unit_interval(p, "p")
  .validate_unit_interval(conf_level, "conf_level")
  if (!is.numeric(d) || length(d) != 1 || is.na(d) || d <= 0 || d >= 1) {
    stop("d must be a single number strictly between 0 and 1.")
  }
  if (!is.null(N)) .validate_population(N)

  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  n0 <- (z^2 * p * (1 - p)) / d^2
  n_adj <- if (is.null(N)) n0 else n0 / (1 + (n0 - 1) / N)

  list(
    n = ceiling(n_adj),
    n_unadjusted = ceiling(n0),
    z = z,
    N = N,
    inputs = list(p = p, d = d, conf_level = conf_level, N = N)
  )
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

  n_solved <- TrialSize::OneWayANOVA.PairwiseComparison(
    alpha = alpha, beta = 1 - power, tau = tau, p1 = p1, p2 = p2, delta = p1 - p2
  )

  list(
    n_per_group = ceiling(n_solved),
    inputs = list(tau = tau, p1 = p1, p2 = p2, alpha = alpha, power = power)
  )
}

# Shared .validate_unit_interval() / .validate_population() live in
# calc_utils.R (sourced alongside every file in R/calc/).
