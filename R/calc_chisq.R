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

  new_ss_result(list(
    N = ceiling(fit$N),
    w = w,
    df = df,
    inputs = list(P0 = P0, P1 = P1, alpha = alpha, power = power)
  ))
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

  new_ss_result(list(
    N = ceiling(fit$N),
    w = w,
    df = df,
    inputs = list(P = P, alpha = alpha, power = power)
  ))
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

  new_ss_result(list(
    n = ceiling(n),
    inputs = list(p10 = p10, p01 = p01, alpha = alpha, power = power)
  ))
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

  new_ss_result(list(
    n_stratified = ceiling(n_stratified),
    n_pooled = ceiling(n_pooled),
    inputs = list(alpha = alpha, power = power, a = a, b = b, p1 = p1, phi = phi)
  ))
}

#' Sample size for the Cochran-Armitage trend test (dose-response
#' proportions)
#'
#' Wraps TrialSize::Cochran.Armitage.Trend() (already a zero-dependency
#' project dependency) -- tests for a monotonic trend in response
#' proportion across k ordered dose/exposure groups (H0: p1=p2=...=pk vs.
#' Ha: a monotone trend), rather than the omnibus "any group differs"
#' question a plain chi-squared test of independence asks. The function
#' returns the required sample size for the *first* group; other groups'
#' sizes follow from the same allocation ratios (ni) the user supplies,
#' scaled by that reference n.
#'
#' Note: the closely related TrialSize::Dose.Response.binary() (also a
#' dose-response/Cochran-Armitage-style formula) was investigated for an
#' earlier batch and found to NOT reproduce its own package's documented
#' example -- this function is a different, independently verified
#' formula (Cochran.Armitage.Trend(), Chow, Shao & Wang (2003) section
#' 11.5) that DOES reproduce its own documented example exactly, so it
#' was adopted instead.
#'
#' @param pi Numeric vector (length >= 2) of assumed response
#'   proportions in each dose group, each in (0,1)
#' @param di Numeric vector, same length as pi: the dose/exposure level
#'   for each group (e.g. 1,2,3,4, or actual doses)
#' @param ni Numeric vector, same length as pi: the planned *relative*
#'   allocation across groups (e.g. all equal for equal allocation) --
#'   only the ratios ni/ni[1] matter, not the absolute values
#' @param delta Clinically meaningful minimal difference used in the
#'   formula's small-sample correction term (Chow, Shao & Wang 2003);
#'   0 is a reasonable default when no such minimal difference is known
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_group1, n_per_group, n_total, inputs)
calc_cochran_armitage_trend <- function(pi, di, ni, delta = 0, alpha = 0.05, power = 0.8) {
  if (!is.numeric(pi) || length(pi) < 2 || anyNA(pi) || any(pi <= 0) || any(pi >= 1)) {
    stop("pi must be a numeric vector of at least 2 values, each strictly between 0 and 1.")
  }
  k <- length(pi)
  if (!is.numeric(di) || length(di) != k || anyNA(di)) {
    stop("di must be a numeric vector of the same length as pi.")
  }
  if (!is.numeric(ni) || length(ni) != k || anyNA(ni) || any(ni <= 0)) {
    stop("ni must be a numeric vector of the same length as pi, each strictly positive.")
  }
  if (length(unique(pi)) < 2) {
    stop("pi must not be identical across all groups (no trend to detect).")
  }
  .validate_number(delta, "delta")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n1 <- TrialSize::Cochran.Armitage.Trend(alpha = alpha, beta = 1 - power,
                                           pi = pi, di = di, ni = ni, delta = delta)
  if (!is.finite(n1) || n1 <= 0) {
    stop("could not solve for a valid sample size with these inputs -- try adjusting pi, di, ni, or delta.")
  }

  ratios <- ni / ni[1]
  n_per_group <- ceiling(ratios * n1)

  new_ss_result(list(
    n_group1 = ceiling(n1),
    n_per_group = n_per_group,
    n_total = sum(n_per_group),
    inputs = list(pi = pi, di = di, ni = ni, delta = delta, alpha = alpha, power = power)
  ))
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

# Cochran's Q test (k >= 3 paired/repeated binary measurements per
# subject), sample size via Monte Carlo simulation.
#
# No installed package provides a sample-size/power function for
# Cochran's Q specifically (only analysis functions exist -- `rstatix`,
# already an installed dependency, has `cochran_qtest()`; CRAN-only
# alternatives like `RVAideMemoire`/`DescTools` are not installed and
# CRAN is unreachable). Rather than fabricate a closed-form approximation
# with no citable source, this directly simulates the actual test --
# `rstatix::cochran_qtest()` itself, called on real simulated data -- the
# same "no closed form/package exists, so simulate the real test" pattern
# already used for the Kolmogorov-Smirnov, Wald-Wolfowitz runs, and
# weighted log-rank designs elsewhere in this app.
#
# Correlated binary data across the k conditions are generated via a
# random-intercept logistic model (the standard generative model for
# correlated binary repeated measures): each subject gets a latent
# Normal(0, sigma2_subject) random intercept added to each condition's
# logit(p_j) before drawing a Bernoulli outcome -- i.e. exactly a
# mixed-effects logistic model with a random subject intercept.

.simulate_cochran_q <- function(n, p, sigma2_subject) {
  k <- length(p)
  latent <- rnorm(n, 0, sqrt(sigma2_subject))
  logit_p <- qlogis(p)
  Y <- vapply(seq_len(k), function(j) rbinom(n, 1, plogis(logit_p[j] + latent)), numeric(n))
  data.frame(
    id = rep(seq_len(n), k),
    cond = factor(rep(seq_len(k), each = n)),
    y = as.vector(Y)
  )
}

#' Sample size for Cochran's Q test (k >= 3 paired binary measurements),
#' via Monte Carlo simulation
#'
#' Solves for the number of subjects needed to detect a difference among
#' k related (repeated/paired) binary measurements' success proportions,
#' by directly simulating `rstatix::cochran_qtest()` -- the actual test
#' -- on correlated binary data generated from a random-intercept
#' logistic model.
#'
#' @param p Numeric vector (length >= 3) of the k conditions' success
#'   proportions to detect a difference among; each strictly in (0,1)
#' @param sigma2_subject Variance of the subject-level random intercept
#'   (logit scale) controlling within-subject correlation across the k
#'   measurements; > 0, larger = more consistent responses within a
#'   subject
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param nsim Monte Carlo replicates per sample-size candidate evaluated
#'   during the search (>= 100)
#' @param seed RNG seed for reproducibility
#' @return list(n, achieved_power, inputs)
calc_cochran_q <- function(p, sigma2_subject, alpha = 0.05, power = 0.8,
                            nsim = 80, seed = 20230914) {
  if (!is.numeric(p) || length(p) < 3 || anyNA(p)) {
    stop("p must be a numeric vector of at least 3 values (Cochran's Q needs k >= 3 conditions).")
  }
  if (any(p <= 0) || any(p >= 1)) stop("each value in p must be strictly between 0 and 1.")
  .validate_positive(sigma2_subject, "sigma2_subject")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 50 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 50.")
  }

  empirical_power <- function(n, reps) {
    set.seed(seed)
    rejections <- replicate(reps, {
      df <- .simulate_cochran_q(n, p, sigma2_subject)
      res <- .cf_cochran_q(df$y, df$id, df$cond)
      isTRUE(res$p < alpha)
    })
    mean(rejections)
  }

  n <- .mc_search_n1(function(x) empirical_power(x, nsim), power, n_lo = 10, n_hi = 20, n_max = 5000)

  new_ss_result(list(
    n = n,
    achieved_power = empirical_power(n, nsim * 3),
    inputs = list(p = p, sigma2_subject = sigma2_subject, alpha = alpha, power = power, nsim = nsim)
  ))
}
