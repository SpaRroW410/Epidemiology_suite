# Monte Carlo power/sample-size for two-level (generalized) linear mixed
# models -- the last item in this project's checklist, deliberately
# deferred to be built last: for cluster-randomized designs analyzed
# with a mixed model, no closed-form power formula generally exists
# (that's exactly why simulation-based tools like `simr` exist in the
# first place). `simr` itself is not installed and its GitHub CRAN
# mirror is unreachable, but the underlying technique it wraps --
# directly simulating data from a fitted/specified mixed model,
# refitting both a full and reduced model, and running a likelihood-
# ratio test, repeated many times to get an empirical power -- is a
# standard, well-established method in its own right (e.g. Bolker et
# al. 2009's GLMM FAQ; Judd, Westfall & Kenny 2017), directly usable
# with `lme4` (already an installed project dependency) with no
# reimplementation risk: this literally simulates and refits the ACTUAL
# model that would analyze real data, exactly as this project's other
# Monte Carlo designs (KS test, runs test, weighted log-rank, Cochran's
# Q) simulate the actual test rather than approximating a formula.
#
# Scope: a two-arm CLUSTER-RANDOMIZED trial (each cluster entirely
# treatment or control, e.g. clinics/schools/villages randomized, with
# individuals nested within cluster) -- the standard real-world
# application of this technique, and genuinely useful even though no
# closed-form formula covers it (this project's existing Cluster /
# Design Effect module's DEFF-based approach is an approximation for
# simple designs; this Monte Carlo approach handles the actual mixed-
# model test directly, including for a binary outcome where DEFF-style
# approximations are markedly less standard).
#
# Verified (see tests/testthat/test-calc_glmm.R): type-I error under the
# null is close to nominal alpha for both LMM (~0.06 at alpha=0.05,
# n=300 replicates) and GLMM (~0.035 at alpha=0.05, n=200 replicates) --
# both well within Monte Carlo noise and consistent with the well-
# documented finite-sample behavior of mixed-model likelihood-ratio
# tests; power increases monotonically with effect size, number of
# clusters, and cluster size; identical results under a fixed seed.

# Simulates one cluster-randomized trial with a continuous outcome under
# a random-intercept linear mixed model, and returns whether the
# treatment effect is detected (LRT p < alpha).
.simulate_crt_lmm <- function(n_clusters, cluster_size, icc, sigma_total, delta, alpha) {
  n <- n_clusters * cluster_size
  cluster_id <- rep(seq_len(n_clusters), each = cluster_size)
  n_treat <- round(n_clusters / 2)
  treat_assign <- sample(rep(c(0, 1), c(n_clusters - n_treat, n_treat)))
  treat <- treat_assign[cluster_id]

  sigma2_u <- icc * sigma_total^2
  sigma2_e <- (1 - icc) * sigma_total^2
  u <- rnorm(n_clusters, 0, sqrt(sigma2_u))[cluster_id]
  e <- rnorm(n, 0, sqrt(sigma2_e))
  y <- delta * treat + u + e

  df <- data.frame(y = y, treat = treat, cid = factor(cluster_id))
  fit_full <- suppressMessages(suppressWarnings(
    lme4::lmer(y ~ treat + (1 | cid), data = df, REML = FALSE)
  ))
  fit_null <- suppressMessages(suppressWarnings(
    lme4::lmer(y ~ 1 + (1 | cid), data = df, REML = FALSE)
  ))
  p_value <- suppressMessages(anova(fit_null, fit_full)$"Pr(>Chisq)"[2])
  isTRUE(p_value < alpha)
}

# Simulates one cluster-randomized trial with a binary outcome under a
# random-intercept logistic mixed model, and returns whether the
# treatment effect is detected (LRT p < alpha).
.simulate_crt_glmm_binary <- function(n_clusters, cluster_size, sigma_u, beta0, beta1, alpha) {
  n <- n_clusters * cluster_size
  cluster_id <- rep(seq_len(n_clusters), each = cluster_size)
  n_treat <- round(n_clusters / 2)
  treat_assign <- sample(rep(c(0, 1), c(n_clusters - n_treat, n_treat)))
  treat <- treat_assign[cluster_id]

  u <- rnorm(n_clusters, 0, sigma_u)[cluster_id]
  eta <- beta0 + beta1 * treat + u
  y <- rbinom(n, 1, stats::plogis(eta))

  df <- data.frame(y = y, treat = treat, cid = factor(cluster_id))
  fit_full <- tryCatch(
    suppressMessages(suppressWarnings(
      lme4::glmer(y ~ treat + (1 | cid), data = df, family = binomial, nAGQ = 1)
    )),
    error = function(e) NULL, warning = function(w) NULL
  )
  fit_null <- tryCatch(
    suppressMessages(suppressWarnings(
      lme4::glmer(y ~ 1 + (1 | cid), data = df, family = binomial, nAGQ = 1)
    )),
    error = function(e) NULL, warning = function(w) NULL
  )
  if (is.null(fit_full) || is.null(fit_null)) return(FALSE)
  p_value <- suppressMessages(anova(fit_null, fit_full)$"Pr(>Chisq)"[2])
  isTRUE(p_value < alpha)
}

#' Monte Carlo sample size (number of clusters) for a cluster-randomized
#' trial with a continuous outcome, analyzed via a random-intercept
#' linear mixed model
#'
#' Directly simulates the actual analysis (simulate data, fit a random-
#' intercept LMM with and without the treatment fixed effect, run a
#' likelihood-ratio test) many times at each candidate number of
#' clusters, searching for the smallest (even) number of clusters
#' achieving the target power. No closed-form formula is used --
#' `lme4::lmer()`/`refit()` machinery only.
#'
#' @param cluster_size Number of individuals per cluster (whole number >= 2)
#' @param icc Intraclass correlation (proportion of total variance due
#'   to between-cluster variation), \[0, 1)
#' @param sigma_total Total outcome standard deviation (> 0)
#' @param delta Treatment effect (difference in means) to detect (!= 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param nsim Number of Monte Carlo replicates per candidate n; default 50
#' @param seed Random seed for reproducibility; default 12345
#' @return list(n_clusters, n_total, achieved_power, inputs)
calc_glmm_lmm_power <- function(cluster_size, icc, sigma_total, delta,
                                 alpha = 0.05, power = 0.8, nsim = 50, seed = 12345) {
  if (!is.numeric(cluster_size) || length(cluster_size) != 1 || is.na(cluster_size) ||
        cluster_size < 2 || cluster_size != round(cluster_size)) {
    stop("cluster_size must be a single whole number >= 2.")
  }
  if (!is.numeric(icc) || length(icc) != 1 || is.na(icc) || icc < 0 || icc >= 1) {
    stop("icc must be a single number in [0, 1).")
  }
  .validate_positive(sigma_total, "sigma_total")
  if (!is.numeric(delta) || length(delta) != 1 || is.na(delta) || delta == 0) {
    stop("delta must be a single non-zero number.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 10 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 10.")
  }

  set.seed(seed)
  empirical_power <- function(n_clusters) {
    n_clusters <- max(4, round(n_clusters / 2) * 2)
    mean(replicate(nsim, .simulate_crt_lmm(n_clusters, cluster_size, icc, sigma_total, delta, alpha)))
  }

  n_clusters <- .mc_search_n1(empirical_power, target_power = power, n_lo = 5, n_hi = 10, n_max = 2000)
  n_clusters <- max(4, round(n_clusters / 2) * 2)
  achieved_power <- empirical_power(n_clusters)

  list(
    n_clusters = n_clusters, n_total = n_clusters * cluster_size, achieved_power = achieved_power,
    inputs = list(cluster_size = cluster_size, icc = icc, sigma_total = sigma_total, delta = delta,
                  alpha = alpha, power = power, nsim = nsim, seed = seed)
  )
}

#' Monte Carlo sample size (number of clusters) for a cluster-randomized
#' trial with a binary outcome, analyzed via a random-intercept logistic
#' mixed model (GLMM)
#'
#' Directly simulates the actual analysis (simulate binary outcomes from
#' a random-intercept logistic model, fit a GLMM with and without the
#' treatment fixed effect, run a likelihood-ratio test) many times at
#' each candidate number of clusters, searching for the smallest (even)
#' number of clusters achieving the target power. No closed-form formula
#' is used -- `lme4::glmer()` machinery only.
#'
#' @param cluster_size Number of individuals per cluster (whole number >= 2)
#' @param sigma_u Standard deviation of the random intercept (log-odds scale, > 0)
#' @param baseline_prob Expected outcome probability in the control arm at a
#'   typical (zero-random-effect) cluster (0,1); converted internally to
#'   the intercept beta0 = qlogis(baseline_prob)
#' @param or Odds ratio (treatment vs. control) to detect (> 0, != 1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param nsim Number of Monte Carlo replicates per candidate n; default 30
#'   (lower than the LMM design's default since each GLMM fit is
#'   substantially slower)
#' @param seed Random seed for reproducibility; default 12345
#' @return list(n_clusters, n_total, achieved_power, inputs)
calc_glmm_logistic_power <- function(cluster_size, sigma_u, baseline_prob, or,
                                      alpha = 0.05, power = 0.8, nsim = 30, seed = 12345) {
  if (!is.numeric(cluster_size) || length(cluster_size) != 1 || is.na(cluster_size) ||
        cluster_size < 2 || cluster_size != round(cluster_size)) {
    stop("cluster_size must be a single whole number >= 2.")
  }
  .validate_positive(sigma_u, "sigma_u")
  .validate_unit_interval(baseline_prob, "baseline_prob")
  if (!is.numeric(or) || length(or) != 1 || is.na(or) || or <= 0 || or == 1) {
    stop("or must be a single positive number != 1.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 10 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 10.")
  }

  beta0 <- stats::qlogis(baseline_prob)
  beta1 <- log(or)

  set.seed(seed)
  empirical_power <- function(n_clusters) {
    n_clusters <- max(4, round(n_clusters / 2) * 2)
    mean(replicate(nsim, .simulate_crt_glmm_binary(n_clusters, cluster_size, sigma_u, beta0, beta1, alpha)))
  }

  n_clusters <- .mc_search_n1(empirical_power, target_power = power, n_lo = 5, n_hi = 10, n_max = 2000)
  n_clusters <- max(4, round(n_clusters / 2) * 2)
  achieved_power <- empirical_power(n_clusters)

  list(
    n_clusters = n_clusters, n_total = n_clusters * cluster_size, achieved_power = achieved_power,
    inputs = list(cluster_size = cluster_size, sigma_u = sigma_u, baseline_prob = baseline_prob, or = or,
                  alpha = alpha, power = power, nsim = nsim, seed = seed)
  )
}
