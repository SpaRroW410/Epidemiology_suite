# Pure calculation functions for multiplicity-adjusted ("wrap any
# calculator with alpha/m") sample size. No Shiny dependency here so these
# are directly unit-testable (see tests/testthat). Depends on
# calc_proportion.R's calc_proportion_1s()/calc_proportion_2s() and
# calc_means.R's calc_means_1s()/calc_means_2s_indep() -- all already
# sourced into the same environment by global.R's R/calc loop.
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
