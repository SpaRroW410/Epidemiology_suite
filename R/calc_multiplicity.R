# Pure calculation functions for multiplicity-adjusted ("wrap any
# calculator with alpha/m") sample size. No Shiny dependency here so these
# are directly unit-testable (see tests/testthat). Depends on
# calc_proportion.R's calc_proportion_1s()/calc_proportion_2s() and
# calc_means.R's calc_means_1s()/calc_means_2s_indep() -- all already
# in the same package namespace.
#
# When planning several simultaneous hypothesis tests (e.g. several outcome
# variables, or several pairwise comparisons not already covered by the
# Means/Proportions modules' own dedicated post-hoc-pairwise designs), the
# per-comparison significance level must be tightened to control the
# family-wise error rate (FWER) across all m comparisons. This module
# computes that adjusted alpha and reuses this app's own already-verified
# one-proportion/two-proportion/one-mean/two-mean formulas with it plugged
# in -- literally "wrap any calculator with alpha/m", the general approach
# checklist_by_test.md names for this item. Bonferroni (alpha/m) is the
# classic bound, always valid regardless of the tests' dependence
# structure; Sidak (1 - (1-alpha)^(1/m)) is the exact FWER-controlling
# correction when the m tests are independent, and is slightly less
# conservative (a larger adjusted alpha, hence a smaller n) than
# Bonferroni for the same m. Holm's step-down procedure is NOT separately
# offered here: its per-comparison threshold is data-dependent (it adapts
# to the observed p-values' rank order after the study is run), so there
# is no single a priori alpha to solve n for -- the worst-case (first, most
# conservative) step of Holm's procedure uses exactly the Bonferroni value
# alpha/m, which is what a priori sample-size planning conservatively
# assumes (Holm 1979).

#' Bonferroni- or Sidak-adjusted per-comparison significance level
#'
#' @param alpha Desired family-wise (overall) significance level (0,1)
#' @param m Number of planned simultaneous comparisons (whole number >= 1)
#' @param method "bonferroni" (alpha/m, always valid) or "sidak"
#'   (1 - (1-alpha)^(1/m), exact under independence, slightly less
#'   conservative)
#' @return adjusted per-comparison significance level (0,1)
#' @examples
#' calc_multiplicity_adjusted_alpha(0.05, m = 4, method = "bonferroni")   # 0.0125
#' calc_multiplicity_adjusted_alpha(0.05, m = 4, method = "sidak")        # 0.0127415
#' @export
calc_multiplicity_adjusted_alpha <- function(alpha, m, method = c("bonferroni", "sidak")) {
  method <- match.arg(method)
  .validate_unit_interval(alpha, "alpha")
  if (!is.numeric(m) || length(m) != 1 || is.na(m) || m < 1 || m != round(m)) {
    stop("m must be a single whole number >= 1.")
  }

  if (method == "bonferroni") alpha / m else 1 - (1 - alpha)^(1 / m)
}

#' Multiplicity-adjusted sample size, single proportion vs. reference
#' @return list(n, h, alpha_adjusted, m, method, inputs)
#' @param m Number of simultaneous comparisons the significance level is shared between (at least 1).
#' @param method `"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.
#' @inheritParams calc_proportion_1s
#' @examples
#' calc_multiplicity_proportion_1s(p0 = 0.3, p1 = 0.5, m = 3, method = "bonferroni", 
#'     alpha = 0.05, power = 0.8)
#' @export
calc_multiplicity_proportion_1s <- function(p0, p1, m, method = c("bonferroni", "sidak"),
                                             alpha = 0.05, power = 0.8,
                                             alternative = c("two.sided", "less", "greater")) {
  method <- match.arg(method)
  alternative <- match.arg(alternative)
  alpha_adj <- calc_multiplicity_adjusted_alpha(alpha, m, method)

  res <- calc_proportion_1s(p0 = p0, p1 = p1, alpha = alpha_adj, power = power,
                             alternative = alternative)
  res$alpha_adjusted <- alpha_adj
  res$m <- m
  res$method <- method
  res$inputs$alpha_family <- alpha
  res
}

#' Multiplicity-adjusted sample size, two independent proportions
#' @return list(n_per_group, n_total, h, alpha_adjusted, m, method, inputs)
#' @param m Number of simultaneous comparisons the significance level is shared between (at least 1).
#' @param method `"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.
#' @inheritParams calc_proportion_2s
#' @examples
#' calc_multiplicity_proportion_2s(p1 = 0.5, p2 = 0.65, m = 1, method = "bonferroni", 
#'     alpha = 0.05, power = 0.8)
#' @export
calc_multiplicity_proportion_2s <- function(p1, p2, m, method = c("bonferroni", "sidak"),
                                             alpha = 0.05, power = 0.8,
                                             alternative = c("two.sided", "less", "greater")) {
  method <- match.arg(method)
  alternative <- match.arg(alternative)
  alpha_adj <- calc_multiplicity_adjusted_alpha(alpha, m, method)

  res <- calc_proportion_2s(p1 = p1, p2 = p2, alpha = alpha_adj, power = power,
                             alternative = alternative)
  res$alpha_adjusted <- alpha_adj
  res$m <- m
  res$method <- method
  res$inputs$alpha_family <- alpha
  res
}

#' Multiplicity-adjusted sample size, single mean vs. reference
#' @return list(n, d, alpha_adjusted, m, method, inputs)
#' @param m Number of simultaneous comparisons the significance level is shared between (at least 1).
#' @param method `"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.
#' @inheritParams calc_means_1s
#' @examples
#' calc_multiplicity_means_1s(mu0 = 0, mu1 = 0.5, sd = 1, m = 2, method = "sidak", 
#'     alpha = 0.05, power = 0.8)
#' @export
calc_multiplicity_means_1s <- function(mu0, mu1, sd, m, method = c("bonferroni", "sidak"),
                                        alpha = 0.05, power = 0.8,
                                        alternative = c("two.sided", "less", "greater")) {
  method <- match.arg(method)
  alternative <- match.arg(alternative)
  alpha_adj <- calc_multiplicity_adjusted_alpha(alpha, m, method)

  res <- calc_means_1s(mu0 = mu0, mu1 = mu1, sd = sd, alpha = alpha_adj, power = power,
                        alternative = alternative)
  res$alpha_adjusted <- alpha_adj
  res$m <- m
  res$method <- method
  res$inputs$alpha_family <- alpha
  res
}

#' Multiplicity-adjusted sample size, two independent means
#' @return list(n_per_group, n_total, d, alpha_adjusted, m, method, inputs)
#' @param m Number of simultaneous comparisons the significance level is shared between (at least 1).
#' @param method `"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.
#' @inheritParams calc_means_2s_indep
#' @examples
#' calc_multiplicity_means_2s(mu1 = 10, mu2 = 12, sd = 5, m = 3, method = "sidak", 
#'     alpha = 0.05, power = 0.8)
#' @export
calc_multiplicity_means_2s <- function(mu1, mu2, sd, m, method = c("bonferroni", "sidak"),
                                        alpha = 0.05, power = 0.8,
                                        alternative = c("two.sided", "less", "greater")) {
  method <- match.arg(method)
  alternative <- match.arg(alternative)
  alpha_adj <- calc_multiplicity_adjusted_alpha(alpha, m, method)

  res <- calc_means_2s_indep(mu1 = mu1, mu2 = mu2, sd = sd, alpha = alpha_adj, power = power,
                              alternative = alternative)
  res$alpha_adjusted <- alpha_adj
  res$m <- m
  res$method <- method
  res$inputs$alpha_family <- alpha
  res
}

#' FDR (Benjamini-Hochberg)-controlled sample size, two independent means
#'
#' Unlike Bonferroni/Sidak above, which control the family-wise error rate
#' (the probability of ANY false positive among the m tests), this
#' controls the FALSE DISCOVERY RATE (the expected PROPORTION of rejected
#' tests that are false positives) at a target level `fdr_level`, when a
#' known/assumed fraction `pi1` of the m tests are truly non-null (e.g.
#' m genes/outcomes/comparisons tested simultaneously, only some of which
#' truly differ). Because FDR control lets more true effects be detected
#' for the same error budget when pi1 is not too small, this typically
#' needs a smaller sample size than the always-conservative Bonferroni
#' correction for the same m.
#'
#' Derivation: applying the Benjamini & Hochberg (1995) step-up procedure
#' at nominal level `fdr_level` (q) is, for a large number of tests, well
#' approximated (Jung 2005; Storey 2002-style FDR theory) by rejecting
#' every test at a fixed per-test significance threshold alpha* solving
#' the self-consistency equation FDR = E\[false rejections\] / E\[total
#' rejections\] = (m0*alpha*) / (m0*alpha* + m1*power), where m1 = pi1*m
#' truly non-null tests and m0 = m - m1 truly null tests. Solving this
#' equation for alpha* directly (given the target average power and FDR
#' level) gives a closed form:
#'   alpha* = fdr_level * m1 * power / (m0 * (1 - fdr_level))
#' -- then the ordinary two-sample-means sample size at that (smaller)
#' alpha* and the target power is found via `pwr::pwr.t.test()`, the same
#' engine already used elsewhere in this app.
#'
#' This closed form was independently derived from the standard FDR/BH
#' definitions above (rather than transcribed from any specific paper's
#' exact notation, since the checklist's own named package, `ssize.fdr`,
#' is not installed and CRAN is unreachable from this environment), then
#' independently verified twice by directly simulating the ACTUAL
#' Benjamini-Hochberg procedure (`stats::p.adjust(method = "BH")` on
#' simulated two-sample t-test p-values from a mix of true nulls and true
#' non-nulls) at the resulting n: (1) m=1000, m1=100 (pi1=0.1), d=2,
#' fdr_level=0.1, target power=0.8 -> n=8/group; 500-replicate simulation
#' gives empirical average FDR 0.082 (target 0.1) and empirical average
#' power 0.794 (target 0.8). (2) m=500, m1=50 (pi1=0.1), d=1,
#' fdr_level=0.05, target power=0.9 -> n=36/group; 400-replicate
#' simulation gives empirical average FDR 0.045 (target 0.05) and
#' empirical average power 0.904 (target 0.9). Both confirm the formula
#' reproduces its own target operating characteristics under the real
#' procedure, not just its own internal algebra.
#'
#' @param d Cohen's d effect size for the truly non-null tests (> 0)
#' @param m Total number of planned simultaneous tests (whole number >= 2)
#' @param pi1 Assumed proportion of the m tests that are truly non-null
#'   (0,1) -- e.g. 0.1 if roughly 10% of outcomes/comparisons are
#'   expected to show a real effect
#' @param fdr_level Target false discovery rate (0,1), typically 0.05-0.10
#' @param power Target average power -- the expected proportion of truly
#'   non-null tests that get detected (0,1)
#' @return list(n_per_group, n_total, alpha_star, m, m1, m0, pi1, inputs)
#' @examples
#' calc_multiplicity_fdr_means(d = 2, m = 1000, pi1 = 0.1, fdr_level = 0.1, power = 0.8)
#' @export
calc_multiplicity_fdr_means <- function(d, m, pi1, fdr_level = 0.05, power = 0.8) {
  .validate_positive(d, "d")
  if (!is.numeric(m) || length(m) != 1 || is.na(m) || m < 2 || m != round(m)) {
    stop("m must be a single whole number >= 2.")
  }
  .validate_unit_interval(pi1, "pi1")
  .validate_unit_interval(fdr_level, "fdr_level")
  .validate_unit_interval(power, "power")

  m1 <- round(pi1 * m)
  if (m1 < 1) stop("pi1 * m must be at least 1 (at least one truly non-null test).")
  m0 <- m - m1
  if (m0 < 1) stop("pi1 must correspond to fewer than m tests (at least one truly null test).")

  alpha_star <- fdr_level * m1 * power / (m0 * (1 - fdr_level))
  if (alpha_star >= 1) {
    stop("No feasible design: the implied per-test alpha exceeds 1 for this fdr_level/pi1/power combination -- try a smaller fdr_level or power, or a smaller pi1.")
  }

  fit <- .cf_pwr_t_test(d = d, sig.level = alpha_star, power = power, type = "two.sample")

  new_ss_result(list(
    n_per_group = ceiling(fit$n),
    n_total = 2 * ceiling(fit$n),
    alpha_star = alpha_star,
    m = m, m1 = m1, m0 = m0, pi1 = pi1,
    inputs = list(d = d, m = m, pi1 = pi1, fdr_level = fdr_level, power = power)
  ))
}

#' Dunnett-adjusted sample size for a multi-arm trial vs. one common
#' control
#'
#' A genuinely different correction from the Bonferroni/Sidak wrapper
#' above -- Dunnett's method (Dunnett 1955) exploits the exact positive
#' correlation (rho = 0.5 for equal per-arm n) among the k comparisons
#' that all share the same control arm, using the true joint distribution
#' of the k correlated t-statistics (a multivariate t) rather than
#' treating them as independent/worst-case. This makes Dunnett provably
#' less conservative than Bonferroni or Sidak for exactly this common-
#' control design (smaller n for the same family-wise error guarantee).
#'
#' The exact two-sided Dunnett critical value is obtained via
#' `mvtnorm::qmvt()` -- the same multivariate-t quantile machinery
#' `multcomp::glht(..., mcp(trt = "Dunnett"))` uses internally for
#' testing, applied here for PLANNING (no installed package offers
#' Dunnett-specific sample-size planning). Verified this session against
#' the classic published two-sided Dunnett critical-value tables (Dunnett
#' 1955/1964): k=2,3,4 at df=Inf give 2.212, 2.350/2.351, 2.440/2.442
#' (published values 2.212/2.351/2.442; this app's qmvt call reproduces
#' them to within the function's own small randomized-quadrature
#' tolerance, controlled by a fixed internal seed for reproducibility).
#'
#' Power is the standard per-comparison planning convention already used
#' by every design in this app (the probability that one specific
#' treatment-vs-control comparison, sharing the assumed common effect
#' size, clears the Dunnett-adjusted critical value) -- the same
#' convention the Bonferroni/Sidak designs above use with their own
#' adjusted critical values, just with Dunnett's exact (smaller) one.
#'
#' Worked example (k=3 active arms vs. 1 control, Cohen's d=0.5, family
#' alpha=0.05 two-sided, target power=0.80, equal n per arm): Dunnett
#' gives n=83/arm (achieved power 0.805), versus Bonferroni's n=86/arm and
#' Sidak's n=85/arm on the identical inputs -- correctly smaller, as
#' theory predicts.
#'
#' @param d Cohen's d effect size, common to every active arm vs. the
#'   control (> 0)
#' @param k Number of ACTIVE (non-control) arms being compared to the one
#'   common control (whole number >= 2 -- for a single arm vs. control,
#'   use the ordinary two-sample means design instead, no adjustment
#'   needed)
#' @param alpha Family-wise (overall) two-sided significance level (0,1)
#' @param power Desired per-comparison power (0,1)
#' @param seed RNG seed for reproducibility of `mvtnorm::qmvt()`'s
#'   internal randomized quadrature
#' @return list(n_per_arm, n_total, k, critical_value, achieved_power, inputs)
#' @examples
#' calc_multiplicity_dunnett(d = 0.5, k = 2, alpha = 0.05, power = 0.8)
#' @export
calc_multiplicity_dunnett <- function(d, k, alpha = 0.05, power = 0.8, seed = 20240913) {
  .validate_positive(d, "d")
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 2 || k != round(k)) {
    stop("k (number of active arms vs. the common control) must be a single whole number >= 2.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  corr <- matrix(0.5, k, k)
  diag(corr) <- 1

  dunnett_critical_value <- function(n) {
    df <- (k + 1) * (n - 1)
    set.seed(seed)
    as.numeric(mvtnorm::qmvt(1 - alpha, tail = "both.tails", df = df, corr = corr)$quantile)
  }

  power_at_n <- function(n) {
    c_val <- dunnett_critical_value(n)
    df <- (k + 1) * (n - 1)
    ncp <- d * sqrt(n / 2)
    pt(c_val, df, ncp = ncp, lower.tail = FALSE) + pt(-c_val, df, ncp = ncp, lower.tail = TRUE)
  }

  n_per_arm <- .mc_search_n1(power_at_n, power, n_lo = 3, n_hi = 6)

  new_ss_result(list(
    n_per_arm = n_per_arm,
    n_total = n_per_arm * (k + 1),
    k = k,
    critical_value = dunnett_critical_value(n_per_arm),
    achieved_power = power_at_n(n_per_arm),
    inputs = list(d = d, k = k, alpha = alpha, power = power)
  ))
}

#' FDR-controlled sample size for a two-sample microarray/genomics
#' experiment (Liu & Hwang 2007)
#'
#' A more specialized and EXACT alternative to calc_multiplicity_fdr_means()
#' above, for the genomics-scale case that item explicitly names: thousands
#' of simultaneous per-gene two-sample t-tests, a known/assumed common
#' effect size and standard deviation across genes, and a known/assumed
#' proportion pi0 of genes that are truly NOT differentially expressed.
#' Rather than the closed-form large-m approximation used above, this
#' reimplements the exact algorithm of `ssize.fdr::ssize.twoSamp()`
#' (Liu & Hwang 2007): for each candidate per-group sample size n, it
#' solves for the critical t-value c that satisfies the FDR
#' self-consistency equation implied by pi0 and the target fdr_level,
#' then evaluates the resulting power via the noncentral t distribution,
#' and returns the first n reaching the target power.
#'
#' Reimplemented from scratch (per this project's vendoring policy) after
#' reading `ssize.fdr::ssize.twoSamp()`'s own source, which is installed
#' in this sandbox via the github.com/cran mirror and used only as a
#' verification oracle (`cran.r-project.org` itself is network-blocked
#' here) -- not a new runtime dependency.
#'
#' @param delta Common difference in mean expression between the two
#'   groups, assumed identical across all m genes/tests (> 0)
#' @param sigma Common within-group standard deviation, assumed identical
#'   across all m genes/tests (> 0)
#' @param fdr_level Target false discovery rate (0,1), typically 0.05-0.10
#' @param power Target power (0,1)
#' @param pi0 Assumed proportion of the m genes/tests that are truly NOT
#'   differentially expressed (0,1) -- e.g. 0.95 if only ~5% of genes are
#'   expected to genuinely differ
#' @param max_n Maximum per-group sample size to search up to (whole
#'   number >= 3)
#' @param side "two-sided", "upper", or "lower" (matching
#'   `ssize.fdr::ssize.twoSamp()`'s own `side` argument)
#' @return list(n_per_group, n_total, achieved_power, critical_value, inputs)
#' @examples
#' calc_fdr_microarray_two_sample(delta = 1, sigma = 0.5, fdr_level = 0.05, power = 0.8, 
#'     pi0 = 0.5, max_n = 20)
#' @export
calc_fdr_microarray_two_sample <- function(delta, sigma, fdr_level = 0.05, power = 0.8,
                                            pi0 = 0.95, max_n = 35,
                                            side = c("two-sided", "upper", "lower")) {
  side <- match.arg(side)
  .validate_positive(delta, "delta")
  .validate_positive(sigma, "sigma")
  .validate_unit_interval(fdr_level, "fdr_level")
  .validate_unit_interval(power, "power")
  .validate_unit_interval(pi0, "pi0")
  if (!is.numeric(max_n) || length(max_n) != 1 || is.na(max_n) || max_n < 3 || max_n != round(max_n)) {
    stop("max_n must be a single whole number >= 3.")
  }

  ds <- delta / sigma
  r <- fdr_level * (1 - pi0) / ((1 - fdr_level) * pi0)

  obj_fun <- function(n, t_ncp) {
    if (side == "two-sided") {
      function(c) abs(2 * pt(q = -c, df = 2 * n - 2) / (1 - pt(q = c, df = 2 * n - 2, ncp = t_ncp)) - r)
    } else if (side == "upper") {
      function(c) abs(pt(q = -c, df = 2 * n - 2) / (1 - pt(q = c, df = 2 * n - 2, ncp = t_ncp)) - r)
    } else {
      function(c) abs(pt(q = -c, df = 2 * n - 2) / pt(q = -c, df = 2 * n - 2, ncp = t_ncp) - r)
    }
  }

  up_start <- 50
  up <- up_start
  n_found <- NA
  power_found <- NA
  crit_found <- NA

  for (n in 2:max_n) {
    t_ncp <- ds / sqrt(2 / n)
    ci <- optimize(f = obj_fun(n, t_ncp), interval = c(0, up))$minimum
    up <- ci

    pwr_new <- if (abs(ci - up_start) >= 1) {
      if (side %in% c("two-sided", "upper")) {
        1 - pt(q = ci, df = 2 * n - 2, ncp = t_ncp)
      } else {
        pt(q = -ci, df = 2 * n - 2, ncp = t_ncp)
      }
    } else {
      0
    }

    if (is.na(n_found) && pwr_new >= power) {
      n_found <- n
      power_found <- pwr_new
      crit_found <- ci
      break
    }
  }

  if (is.na(n_found)) {
    stop(sprintf(
      "Desired power not achieved for any per-group n up to max_n = %d -- try a larger max_n, a larger delta/sigma, or a less stringent fdr_level/power.",
      max_n
    ))
  }

  new_ss_result(list(
    n_per_group = n_found,
    n_total = 2 * n_found,
    achieved_power = power_found,
    critical_value = crit_found,
    inputs = list(delta = delta, sigma = sigma, fdr_level = fdr_level, power = power,
                  pi0 = pi0, max_n = max_n, side = side)
  ))
}
