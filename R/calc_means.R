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
  fit <- .cf_pwr_t_test(d = d, sig.level = alpha, power = power,
                          type = "one.sample", alternative = alternative)

  new_ss_result(list(
    n = ceiling(fit$n),
    d = d,
    inputs = list(mu0 = mu0, mu1 = mu1, sd = sd, alpha = alpha, power = power,
                  alternative = alternative)
  ))
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
  fit <- .cf_pwr_t_test(d = d, sig.level = alpha, power = power,
                          type = "two.sample", alternative = alternative)
  n_per_group <- ceiling(fit$n)

  new_ss_result(list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    d = d,
    inputs = list(mu1 = mu1, mu2 = mu2, sd = sd, alpha = alpha, power = power,
                  alternative = alternative)
  ))
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
  fit <- .cf_pwr_t_test(d = d, sig.level = alpha, power = power,
                          type = "paired", alternative = alternative)

  new_ss_result(list(
    n = ceiling(fit$n),
    d = d,
    inputs = list(mean_diff = mean_diff, sd_diff = sd_diff, alpha = alpha,
                  power = power, alternative = alternative)
  ))
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

  fit <- .cf_pwr_anova_test(k = k, f = f, sig.level = alpha, power = power)
  n_per_group <- ceiling(fit$n)

  new_ss_result(list(
    n_per_group = n_per_group,
    n_total = n_per_group * k,
    f = f,
    inputs = list(group_means = group_means, sd = sd, alpha = alpha, power = power)
  ))
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

  n <- .cf_sssimpleestc(
    N = if (is.null(N)) NA else N,
    xbar = mean, sigma = sd, epsilon = epsilon, error = error,
    conf.level = conf_level
  )

  new_ss_result(list(
    n = n,
    N = N,
    inputs = list(mean = mean, sd = sd, epsilon = epsilon, error = error,
                  conf_level = conf_level, N = N)
  ))
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
  fit <- .cf_pwr_t2n_test(n1 = n1, n2 = NULL, d = d, sig.level = alpha,
                            power = power, alternative = alternative)
  n2 <- ceiling(fit$n2)

  new_ss_result(list(
    n1 = n1,
    n2 = n2,
    n_total = n1 + n2,
    d = d,
    inputs = list(mu1 = mu1, mu2 = mu2, sd = sd, n1 = n1, alpha = alpha,
                  power = power, alternative = alternative)
  ))
}

#' Sample size for a planned linear contrast among k group means
#'
#' Wraps TrialSize::Dose.Response.Linear() rather than reimplementing the
#' underlying math (project convention) -- TrialSize already a
#' zero-dependency project dependency, used elsewhere in this app
#' (McNemar's test, Mantel-Haenszel, non-inferiority OR/HR,
#' non-parametric tests). Despite the package's function name (written
#' for a dose-response trial), the underlying formula is the general
#' sample size for testing a single pre-specified ("planned") linear
#' contrast of k group means against zero -- e.g. a linear dose-response
#' trend, or any other a priori weighted comparison across groups -- not
#' the k-group omnibus F-test the ANOVA design above already covers.
#'
#' Note: the closely related TrialSize::Dose.Response.binary() (the
#' proportions/Cochran-Armitage-trend analog) was investigated for this
#' app and found NOT to reproduce its own package's documented example
#' from its own source code under any tested variant (its doc claims
#' n=382, but running the function on that exact example gives n=337) --
#' so it is deliberately not wrapped here, consistent with this
#' project's practice of skipping formulas that can't be confidently
#' verified (see also TrialSize::Stuart.Maxwell.Test(), which is
#' similarly unusable).
#'
#' @param mu Numeric vector of length k (>= 2): the assumed/expected mean
#'   for each group
#' @param sigma Common/pooled standard deviation (> 0)
#' @param ci Numeric vector of length k: the contrast coefficients,
#'   summing to 0 (e.g. c(-3,-1,1,3) for an equally-spaced linear trend
#'   across 4 ordered groups)
#' @param fi Numeric vector of length k: each group's share of the total
#'   sample (ni/n), summing to 1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_total, n_per_group, inputs)
calc_means_planned_contrast <- function(mu, sigma, ci, fi, alpha = 0.05, power = 0.8) {
  k <- length(mu)
  if (!is.numeric(mu) || k < 2 || anyNA(mu)) {
    stop("mu must be a numeric vector of at least 2 values.")
  }
  if (length(ci) != k || length(fi) != k) {
    stop("mu, ci, and fi must all have the same length (one value per group).")
  }
  .validate_positive(sigma, "sigma")
  if (abs(sum(ci)) > 1e-6) stop("ci (contrast coefficients) must sum to 0.")
  if (isTRUE(all.equal(sum(ci * mu), 0))) {
    stop("the contrast sum(ci * mu) must differ from 0 (no effect to detect).")
  }
  if (any(fi <= 0) || any(fi >= 1)) stop("each value in fi must be strictly between 0 and 1.")
  if (abs(sum(fi) - 1) > 1e-6) stop("fi (group sample-size fractions) must sum to 1.")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n_solved <- .cf_ts_dose_response_linear(
    alpha = alpha, beta = 1 - power, sigma = sigma, mui = mu, ci = ci, fi = fi
  )
  n_total <- ceiling(n_solved)

  new_ss_result(list(
    n_total = n_total,
    n_per_group = ceiling(n_total * fi),
    inputs = list(mu = mu, sigma = sigma, ci = ci, fi = fi, alpha = alpha, power = power)
  ))
}

#' Sample size for a Bonferroni-adjusted post-hoc pairwise comparison of
#' two group means
#'
#' Wraps TrialSize::OneWayANOVA.pairwise() rather than reimplementing the
#' underlying math (project convention) -- TrialSize already a
#' zero-dependency project dependency. The formula is the standard
#' two-sample z-test sample size, with the significance level Bonferroni-
#' corrected for `tau` simultaneous pairwise comparisons (alpha/tau in
#' place of alpha) -- independently re-derived here and confirmed to
#' reproduce the package's own function exactly, since its Rd file's own
#' examples don't print a numeric answer.
#'
#' This is the multiplicity-adjusted complement to the "Planned linear
#' contrast" design above: that design tests one pre-specified
#' combination of all k means, while this one sizes one specific pairwise
#' comparison (mean i vs. mean j) out of `tau` such comparisons planned
#' across the study, correcting for running several tests at once.
#'
#' @param tau Number of pairwise comparisons planned across the whole
#'   study (whole number >= 1); e.g. tau = choose(k, 2) for all pairs
#'   among k groups, or a smaller number if only some pairs are planned
#' @param sigma Common/pooled standard deviation (> 0)
#' @param margin Assumed true difference between the two group means
#'   being compared in this specific pair (!= 0)
#' @param alpha Family-wise significance level (0,1), before Bonferroni
#'   correction
#' @param power Desired power (0,1)
#' @return list(n_per_group, inputs)
calc_means_posthoc_pairwise <- function(tau, sigma, margin, alpha = 0.05, power = 0.8) {
  if (!is.numeric(tau) || length(tau) != 1 || is.na(tau) || tau < 1 || tau != round(tau)) {
    stop("tau must be a single whole number >= 1.")
  }
  .validate_positive(sigma, "sigma")
  .validate_number(margin, "margin")
  if (isTRUE(all.equal(margin, 0))) {
    stop("margin must differ from 0 (no effect to detect).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n_solved <- .cf_ts_anova_pairwise(
    alpha = alpha, beta = 1 - power, tau = tau, sigma = sigma, margin = margin
  )

  new_ss_result(list(
    n_per_group = ceiling(n_solved),
    inputs = list(tau = tau, sigma = sigma, margin = margin, alpha = alpha, power = power)
  ))
}

#' Sample size for two independent means with unequal variances (Welch's
#' t-test)
#'
#' No installed package wraps Welch's (unequal-variance) two-sample t-test
#' sample size directly (MESS::power_t_test would, but MESS is not
#' installed in this sandbox and has no CRAN access to add it). This
#' implements the standard large-sample normal approximation used
#' throughout the sample-size literature (e.g. Julious 2004, Stat Med;
#' Rosner, Fundamentals of Biostatistics): unlike the pooled-variance
#' formula in calc_means_2s_indep()/TrialSize::TwoSampleMean.Equality(),
#' this keeps the two group variances separate in the noncentrality
#' calculation rather than pooling them, exactly the same way Welch's
#' t-test itself keeps them separate (Satterthwaite-adjusted df) rather
#' than assuming equal variances. When sigma1 = sigma2, this formula
#' reduces algebraically to exactly the pooled-variance formula (confirmed
#' directly: sigma1=sigma2=0.1, ratio=1, margin=0.05, alpha=0.05, power=
#' 0.8 reproduces TrialSize::TwoSampleMean.Equality()'s own documented
#' example, n=63, exactly). For genuinely unequal variances, verified by
#' simulation using R's own Welch t-test (stats::t.test(var.equal=FALSE)):
#' mean1=0, mean2=0.5, sd1=1, sd2=2, alpha=0.05, power=0.8, equal
#' allocation -> n=157/group, empirical Welch-test power 0.793 (closely
#' matching the 0.80 target).
#'
#' @param mu1 Expected mean in group 1
#' @param mu2 Expected mean in group 2
#' @param sd1 Expected standard deviation in group 1 (> 0)
#' @param sd2 Expected standard deviation in group 2 (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param ratio Group 2 size divided by group 1 size (> 0)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n1, n2, n_total, inputs)
calc_means_welch <- function(mu1, mu2, sd1, sd2, alpha = 0.05, power = 0.8,
                              ratio = 1,
                              alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_number(mu1, "mu1")
  .validate_number(mu2, "mu2")
  .validate_positive(sd1, "sd1")
  .validate_positive(sd2, "sd2")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")
  if (isTRUE(all.equal(mu1, mu2))) {
    stop("mu1 and mu2 must differ (no effect to detect).")
  }

  za <- if (identical(alternative, "two.sided")) stats::qnorm(1 - alpha / 2) else stats::qnorm(1 - alpha)
  zb <- stats::qnorm(power)
  delta <- mu1 - mu2

  n1 <- ceiling((za + zb)^2 * (sd1^2 + sd2^2 / ratio) / delta^2)
  n2 <- ceiling(ratio * n1)

  new_ss_result(list(
    n1 = n1,
    n2 = n2,
    n_total = n1 + n2,
    inputs = list(mu1 = mu1, mu2 = mu2, sd1 = sd1, sd2 = sd2, alpha = alpha,
                  power = power, ratio = ratio, alternative = alternative)
  ))
}

# Shared .validate_number() / .validate_positive() / .validate_unit_interval()
# live in calc_utils.R (same package namespace).
