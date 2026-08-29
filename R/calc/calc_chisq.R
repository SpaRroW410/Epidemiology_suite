# Pure calculation functions for chi-squared test sample size (goodness of
# fit, and test of independence/association). No Shiny dependency here so
# these are directly unit-testable (see tests/testthat). Both wrap
# pwr::ES.w1()/ES.w2() + pwr::pwr.chisq.test() (Cohen 1988) rather than
# reimplementing the underlying math (project convention).

#' Sample size for a chi-squared goodness-of-fit test
#'
#' Wraps pwr::ES.w1() (effect size w) + pwr::pwr.chisq.test().
#'
#' @param P0 Numeric vector of null-hypothesis category proportions (length
#'   >= 2, each in (0,1), summing to 1)
#' @param P1 Numeric vector of alternative-hypothesis category proportions,
#'   same length as P0, summing to 1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(N, w, df, inputs)
calc_chisq_gof <- function(P0, P1, alpha = 0.05, power = 0.8) {
  .validate_prob_vector(P0, "P0")
  .validate_prob_vector(P1, "P1")
  if (length(P0) != length(P1)) stop("P0 and P1 must have the same length.")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  w <- pwr::ES.w1(P0, P1)
  if (isTRUE(all.equal(w, 0))) stop("P0 and P1 must differ (no effect to detect).")
  df <- length(P0) - 1

  fit <- pwr::pwr.chisq.test(w = w, df = df, sig.level = alpha, power = power)

  list(
    N = ceiling(fit$N),
    w = w,
    df = df,
    inputs = list(P0 = P0, P1 = P1, alpha = alpha, power = power)
  )
}

#' Sample size for a chi-squared test of independence/association
#'
#' Wraps pwr::ES.w2() (effect size w) + pwr::pwr.chisq.test().
#'
#' @param P A joint-probability matrix (rows x cols, all cells summing to 1)
#'   representing the alternative hypothesis
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(N, w, df, inputs)
calc_chisq_independence <- function(P, alpha = 0.05, power = 0.8) {
  if (!is.matrix(P) || nrow(P) < 2 || ncol(P) < 2) {
    stop("P must be a matrix with at least 2 rows and 2 columns.")
  }
  if (anyNA(P) || any(P <= 0) || any(P >= 1)) {
    stop("each cell of P must be strictly between 0 and 1.")
  }
  if (abs(sum(P) - 1) > 1e-6) {
    stop("P's cells must sum to 1.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  w <- pwr::ES.w2(P)
  if (isTRUE(all.equal(w, 0))) stop("P must not imply independence (no effect to detect).")
  df <- (nrow(P) - 1) * (ncol(P) - 1)

  fit <- pwr::pwr.chisq.test(w = w, df = df, sig.level = alpha, power = power)

  list(
    N = ceiling(fit$N),
    w = w,
    df = df,
    inputs = list(P = P, alpha = alpha, power = power)
  )
}

#' Sample size for McNemar's test (paired/matched proportions)
#'
#' Wraps TrialSize::McNemar.Test() -- TrialSize has zero package
#' dependencies, already used elsewhere in this app (Crossover Trial
#' module).
#'
#' @param p10 Expected proportion of pairs that switch from positive
#'   (before/exposed) to negative (after/unexposed) (0,1)
#' @param p01 Expected proportion of pairs that switch from negative to
#'   positive (0,1); p10 and p01 are the two off-diagonal ("discordant")
#'   cells of the 2x2 paired table, and must differ (p10 != p01) for
#'   there to be an effect to detect
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_mcnemar <- function(p10, p01, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p10, "p10")
  .validate_unit_interval(p01, "p01")
  if (p10 + p01 >= 1) stop("p10 + p01 (the discordant-pair proportion) must be less than 1.")
  if (isTRUE(all.equal(p10, p01))) stop("p10 and p01 must differ (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  psai <- p01 / p10
  paid <- p10 + p01

  n <- TrialSize::McNemar.Test(alpha = alpha, beta = 1 - power, psai = psai, paid = paid)

  list(
    n = ceiling(n),
    inputs = list(p10 = p10, p01 = p01, alpha = alpha, power = power)
  )
}

#' Sample size for a stratified (Mantel-Haenszel) comparison of two
#' proportions across J strata
#'
#' Wraps TrialSize::Propensity.Score.strata() (a weighted Mantel-Haenszel
#' test across J strata) and TrialSize::Propensity.Score.nostrata() (the
#' naive comparison that pools all strata together, ignoring them) --
#' TrialSize already a zero-dependency project dependency, used elsewhere
#' in this app (McNemar's test, non-inferiority OR/HR, non-parametric
#' tests). Despite the package's function names (written in the book's
#' propensity-score-stratification example), the underlying formula is
#' the general weighted-Mantel-Haenszel test for a stratified 2x2xJ
#' table, so this also serves as this app's Mantel-Haenszel / CMH
#' stratified-proportions calculator. Returning both figures side by side
#' shows how much larger a sample the naive (unadjusted, confounded)
#' comparison needs versus the correctly stratified one.
#'
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param a Numeric vector of length J (>= 2): proportion of the total
#'   sample falling in each stratum (must sum to 1)
#' @param b Numeric vector of length J: proportion of stratum j's
#'   subjects allocated to group 1 (the reference/control group), each in
#'   (0,1)
#' @param p1 Numeric vector of length J: expected response probability
#'   for group 1 in each stratum, each in (0,1)
#' @param phi Assumed common odds ratio of group 2 vs group 1 (> 0, != 1),
#'   applied identically in every stratum to derive that stratum's p2
#'   from its p1
#' @return list(n_stratified, n_pooled, inputs)
calc_mantelhaenszel <- function(alpha = 0.05, power = 0.8, a, b, p1, phi) {
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  J <- length(a)
  if (J < 2) stop("a, b, and p1 must each have at least 2 strata.")
  if (length(b) != J || length(p1) != J) {
    stop("a, b, and p1 must all have the same length (one value per stratum).")
  }
  if (any(a <= 0) || any(a >= 1)) stop("each value in a must be strictly between 0 and 1.")
  if (abs(sum(a) - 1) > 1e-6) stop("a (stratum allocation proportions) must sum to 1.")
  if (any(b <= 0) || any(b >= 1)) stop("each value in b must be strictly between 0 and 1.")
  if (any(p1 <= 0) || any(p1 >= 1)) stop("each value in p1 must be strictly between 0 and 1.")
  .validate_positive(phi, "phi")
  if (isTRUE(all.equal(phi, 1))) {
    stop("phi (assumed odds ratio) must differ from 1 -- otherwise there's no effect to detect.")
  }

  n_stratified <- TrialSize::Propensity.Score.strata(
    alpha = alpha, beta = 1 - power, J = J, a = a, b = b, p1 = p1, phi = phi
  )
  n_pooled <- TrialSize::Propensity.Score.nostrata(
    alpha = alpha, beta = 1 - power, J = J, a = a, b = b, p1 = p1, phi = phi
  )

  list(
    n_stratified = ceiling(n_stratified),
    n_pooled = ceiling(n_pooled),
    inputs = list(alpha = alpha, power = power, a = a, b = b, p1 = p1, phi = phi)
  )
}

.validate_prob_vector <- function(P, label) {
  if (!is.numeric(P) || length(P) < 2 || anyNA(P)) {
    stop(sprintf("%s must be a numeric vector of at least 2 values.", label))
  }
  if (any(P <= 0) || any(P >= 1)) {
    stop(sprintf("each value in %s must be strictly between 0 and 1.", label))
  }
  if (abs(sum(P) - 1) > 1e-6) {
    stop(sprintf("%s must sum to 1.", label))
  }
}
