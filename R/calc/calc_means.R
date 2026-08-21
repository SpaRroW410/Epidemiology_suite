# Pure calculation functions for mean-comparison (t-test based) sample size.
# No Shiny dependency here so these are directly unit-testable (see tests/testthat).
#
# Inputs are raw means and SD (units the user actually has), converted
# internally to Cohen's d before calling pwr::pwr.t.test -- same pattern as
# calc_proportion.R converting raw proportions to Cohen's h.

#' Sample size for a single mean vs. a known/reference value (one-sample t-test)
#'
#' @param mu0 Reference/hypothesized mean
#' @param mu1 Expected/anticipated true mean
#' @param sd Expected standard deviation (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, d, inputs)
calc_means_1s <- function(mu0, mu1, sd, alpha = 0.05, power = 0.8,
                           alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_number(mu0, "mu0")
  .validate_number(mu1, "mu1")
  .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(mu0, mu1))) {
    stop("mu0 and mu1 must differ (no effect to detect).")
  }

  d <- (mu1 - mu0) / sd
  fit <- pwr::pwr.t.test(d = d, sig.level = alpha, power = power,
                          type = "one.sample", alternative = alternative)

  list(
    n = ceiling(fit$n),
    d = d,
    inputs = list(mu0 = mu0, mu1 = mu1, sd = sd, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size for two independent means (equal allocation, common SD)
#'
#' @param mu1 Expected mean in group 1
#' @param mu2 Expected mean in group 2
#' @param sd Common/pooled standard deviation (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, n_total, d, inputs)
calc_means_2s_indep <- function(mu1, mu2, sd, alpha = 0.05, power = 0.8,
                                 alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_number(mu1, "mu1")
  .validate_number(mu2, "mu2")
  .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(mu1, mu2))) {
    stop("mu1 and mu2 must differ (no effect to detect).")
  }

  d <- (mu1 - mu2) / sd
  fit <- pwr::pwr.t.test(d = d, sig.level = alpha, power = power,
                          type = "two.sample", alternative = alternative)
  n_per_group <- ceiling(fit$n)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    d = d,
    inputs = list(mu1 = mu1, mu2 = mu2, sd = sd, alpha = alpha, power = power,
                  alternative = alternative)
  )
}

#' Sample size for paired means (paired t-test, e.g. pre-post)
#'
#' @param mean_diff Expected mean of the paired differences
#' @param sd_diff Standard deviation of the paired differences (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, d, inputs)
calc_means_paired <- function(mean_diff, sd_diff, alpha = 0.05, power = 0.8,
                               alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_number(mean_diff, "mean_diff")
  .validate_positive(sd_diff, "sd_diff")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(mean_diff, 0))) {
    stop("mean_diff must not be zero (no effect to detect).")
  }

  d <- mean_diff / sd_diff
  fit <- pwr::pwr.t.test(d = d, sig.level = alpha, power = power,
                          type = "paired", alternative = alternative)

  list(
    n = ceiling(fit$n),
    d = d,
    inputs = list(mean_diff = mean_diff, sd_diff = sd_diff, alpha = alpha,
                  power = power, alternative = alternative)
  )
}

#' Sample size for three or more independent group means (one-way ANOVA)
#'
#' Wraps pwr::pwr.anova.test() (Cohen 1988). Converts raw group means and a
#' common/pooled SD to Cohen's f -- the population SD of the group means
#' divided by the common SD -- same pattern as calc_means_2s_indep()
#' converting raw means to Cohen's d.
#'
#' @param group_means Numeric vector of expected means, one per group (length >= 3)
#' @param sd Common/pooled standard deviation shared by all groups (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_per_group, n_total, f, inputs)
calc_means_anova <- function(group_means, sd, alpha = 0.05, power = 0.8) {
  if (!is.numeric(group_means) || length(group_means) < 3 || anyNA(group_means)) {
    stop("group_means must be a numeric vector of at least 3 values.")
  }
  .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(stats::sd(group_means), 0))) {
    stop("group_means must not all be equal (no effect to detect).")
  }

  k <- length(group_means)
  sigma_m <- sqrt(sum((group_means - mean(group_means))^2) / k)
  f <- sigma_m / sd

  fit <- pwr::pwr.anova.test(k = k, f = f, sig.level = alpha, power = power)
  n_per_group <- ceiling(fit$n)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * k,
    f = f,
    inputs = list(group_means = group_means, sd = sd, alpha = alpha, power = power)
  )
}

#' Sample size for a single mean, precision-based (no hypothesis test)
#'
#' Wraps epiR::epi.sssimpleestc() rather than reimplementing the underlying
#' math (project convention). Note this formula is built around a
#' *relative*-variance framing (Vsq = sigma^2/mean^2) and so requires a
#' non-zero mean -- appropriate for physical/clinical measurements that are
#' inherently positive (BP, Hb, BMI, weight), not for values that can
#' legitimately be zero or negative (e.g. a symmetric change score).
#'
#' @param mean Expected mean of the variable to be estimated (!= 0)
#' @param sd Expected standard deviation of the variable (> 0)
#' @param epsilon Desired precision: the maximum acceptable difference
#'   between the estimate and the true population value, in absolute or
#'   relative terms per `error`
#' @param error "relative" (epsilon as a fraction of mean) or "absolute"
#' @param conf_level Confidence level (0,1)
#' @param N Optional finite eligible-population size. NULL (default) =
#'   effectively infinite population.
#' @return list(n, N, inputs)
calc_means_single_precision <- function(mean, sd, epsilon,
                                         error = c("relative", "absolute"),
                                         conf_level = 0.95, N = NULL) {
  error <- match.arg(error)
  .validate_number(mean, "mean")
  if (isTRUE(all.equal(mean, 0))) {
    stop("mean must not be zero (this method's relative-variance formulation requires mean != 0).")
  }
  .validate_positive(sd, "sd")
  .validate_positive(epsilon, "epsilon")
  .validate_unit_interval(conf_level, "conf_level")
  if (!is.null(N)) .validate_population(N)

  n <- epiR::epi.sssimpleestc(
    N = if (is.null(N)) NA else N,
    xbar = mean, sigma = sd, epsilon = epsilon, error = error,
    nfractional = FALSE, conf.level = conf_level
  )

  list(
    n = n,
    N = N,
    inputs = list(mean = mean, sd = sd, epsilon = epsilon, error = error,
                  conf_level = conf_level, N = N)
  )
}

#' Sample size for two independent means with unequal group sizes
#'
#' Solves the required size of group 2 given group 1's size is already
#' fixed (e.g. a constrained comparison group) -- wraps
#' pwr::pwr.t2n.test().
#'
#' @param mu1 Expected mean in group 1
#' @param mu2 Expected mean in group 2
#' @param sd Common/pooled standard deviation (> 0)
#' @param n1 Fixed size of group 1 (whole number >= 2)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n1, n2, n_total, d, inputs)
calc_means_2s_unequal_n <- function(mu1, mu2, sd, n1, alpha = 0.05, power = 0.8,
                                     alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)

  .validate_number(mu1, "mu1")
  .validate_number(mu2, "mu2")
  .validate_positive(sd, "sd")
  if (!is.numeric(n1) || length(n1) != 1 || is.na(n1) || n1 < 2 || n1 != round(n1)) {
    stop("n1 must be a single whole number >= 2.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (isTRUE(all.equal(mu1, mu2))) {
    stop("mu1 and mu2 must differ (no effect to detect).")
  }

  d <- (mu1 - mu2) / sd
  fit <- pwr::pwr.t2n.test(n1 = n1, n2 = NULL, d = d, sig.level = alpha,
                            power = power, alternative = alternative)
  n2 <- ceiling(fit$n2)

  list(
    n1 = n1,
    n2 = n2,
    n_total = n1 + n2,
    d = d,
    inputs = list(mu1 = mu1, mu2 = mu2, sd = sd, n1 = n1, alpha = alpha,
                  power = power, alternative = alternative)
  )
}

# Shared .validate_number() / .validate_positive() / .validate_unit_interval()
# live in calc_utils.R (sourced alongside every file in R/calc/).
