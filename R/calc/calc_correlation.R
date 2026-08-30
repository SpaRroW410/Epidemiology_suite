# Pure calculation function for Pearson correlation sample size.
# No Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps pwr::pwr.r.test() rather than reimplementing the
# underlying math (project convention).

#' Sample size to detect a Pearson correlation
#'
#' Wraps pwr::pwr.r.test() (Cohen 1988), using the Fisher z' transformation.
#'
#' @param r Expected correlation coefficient (-1, 1), != 0
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, inputs)
calc_correlation <- function(r, alpha = 0.05, power = 0.8,
                              alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  if (!is.numeric(r) || length(r) != 1 || is.na(r) || r <= -1 || r >= 1) {
    stop("r must be a single number strictly between -1 and 1.")
  }
  if (isTRUE(all.equal(r, 0))) stop("r must not be zero (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- pwr::pwr.r.test(r = r, sig.level = alpha, power = power,
                          alternative = alternative)

  list(
    n = ceiling(fit$n),
    inputs = list(r = r, alpha = alpha, power = power, alternative = alternative)
  )
}

#' Sample size to compare two independent Pearson correlations
#'
#' Closed-form (Cohen 1988): Cohen's q effect size via the Fisher z'
#' transformation of each correlation, then the standard two-sample
#' normal-test sample size formula for a known-variance difference. No
#' dedicated function exists in pwr for this two-sample case (only
#' pwr::pwr.r.test() for a single correlation against zero), so this is
#' reimplemented directly from the closed-form algebra rather than a
#' package wrap.
#'
#' @param r1 Expected correlation in group 1 (-1, 1)
#' @param r2 Expected correlation in group 2 (-1, 1); must differ from r1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, q, inputs)
calc_correlation_two_independent <- function(r1, r2, alpha = 0.05, power = 0.8,
                                              alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  if (!is.numeric(r1) || length(r1) != 1 || is.na(r1) || r1 <= -1 || r1 >= 1) {
    stop("r1 must be a single number strictly between -1 and 1.")
  }
  if (!is.numeric(r2) || length(r2) != 1 || is.na(r2) || r2 <= -1 || r2 >= 1) {
    stop("r2 must be a single number strictly between -1 and 1.")
  }
  if (isTRUE(all.equal(r1, r2))) stop("r1 and r2 must differ (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  q <- abs(atanh(r1) - atanh(r2))
  z_alpha <- if (identical(alternative, "two.sided")) qnorm(1 - alpha / 2) else qnorm(1 - alpha)
  z_beta <- qnorm(power)
  n <- ((z_alpha + z_beta) / q)^2 + 3

  list(
    n_per_group = ceiling(n),
    q = q,
    inputs = list(r1 = r1, r2 = r2, alpha = alpha, power = power, alternative = alternative)
  )
}

#' Sample size for a point-biserial correlation (continuous outcome vs. a
#' naturally dichotomous grouping variable)
#'
#' A point-biserial correlation is mathematically a Pearson correlation
#' between a continuous variable and a 0/1-coded variable, and testing it
#' against zero is equivalent to a two-independent-samples t-test on the
#' continuous variable across the two groups (Cohen 1988, ch. 2) -- so
#' this converts r to Cohen's d via the standard large-sample identity
#' d = 2r/sqrt(1-r^2) (equal group sizes) and reuses
#' pwr::pwr.t.test() -- already a project dependency (the Means module's
#' two-independent-means design) -- rather than a separate approximate
#' Fisher-z-based formula. Verified: the r <-> d conversion was
#' independently confirmed by simulating data at a target r and checking
#' that the resulting slope/correlation recover the intended value.
#'
#' @param r Expected point-biserial correlation (-1, 1), != 0
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n_per_group, n_total, d, inputs)
calc_correlation_point_biserial <- function(r, alpha = 0.05, power = 0.8,
                                             alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  if (!is.numeric(r) || length(r) != 1 || is.na(r) || r <= -1 || r >= 1) {
    stop("r must be a single number strictly between -1 and 1.")
  }
  if (isTRUE(all.equal(r, 0))) stop("r must not be zero (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  d <- 2 * r / sqrt(1 - r^2)
  fit <- pwr::pwr.t.test(d = abs(d), sig.level = alpha, power = power,
                          type = "two.sample", alternative = alternative)
  n_per_group <- ceiling(fit$n)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * 2,
    d = d,
    inputs = list(r = r, alpha = alpha, power = power, alternative = alternative)
  )
}

#' Sample size for a simple linear regression slope (bivariate regression
#' coefficient significantly different from zero)
#'
#' Testing whether a simple (one-predictor) linear regression slope
#' differs from zero is mathematically identical to testing whether the
#' Pearson correlation between the predictor and outcome differs from
#' zero -- the standard identity r = b*SDx/SDy (equivalently
#' b = r*SDy/SDx) connects the raw-scale slope to the standardized
#' correlation (see e.g. Kutner, Nachtsheim, Neter & Li, Applied Linear
#' Statistical Models). This converts the user's raw-scale inputs to r
#' and reuses pwr::pwr.r.test() -- already a project dependency -- rather
#' than a separate regression-specific formula, since the two tests are
#' exactly equivalent for a single predictor (not an approximation).
#' Verified by simulation: generating data with a known slope/SDx/SDy
#' recovers both the intended slope and the predicted r.
#'
#' @param slope Expected/assumed regression slope (!= 0)
#' @param sd_x Standard deviation of the predictor X (> 0)
#' @param sd_y Standard deviation of the outcome Y (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @return list(n, r, inputs)
calc_regression_slope <- function(slope, sd_x, sd_y, alpha = 0.05, power = 0.8,
                                   alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .validate_number(slope, "slope")
  if (isTRUE(all.equal(slope, 0))) stop("slope must not be zero (no effect to detect).")
  .validate_positive(sd_x, "sd_x")
  .validate_positive(sd_y, "sd_y")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  r <- slope * sd_x / sd_y
  if (abs(r) >= 1) {
    stop("the implied correlation r = slope * sd_x / sd_y must be strictly between -1 and 1 -- check that slope, sd_x and sd_y are on consistent scales.")
  }

  fit <- pwr::pwr.r.test(r = r, sig.level = alpha, power = power, alternative = alternative)

  list(
    n = ceiling(fit$n),
    r = r,
    inputs = list(slope = slope, sd_x = sd_x, sd_y = sd_y, alpha = alpha,
                  power = power, alternative = alternative)
  )
}
