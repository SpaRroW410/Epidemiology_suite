# Pure calculation functions for distribution-free (nonparametric) tests.
# No Shiny dependency here so these are directly unit-testable (see
# tests/testthat). All three wrap TrialSize:: functions (Chow, Shao & Wang
# 2003) rather than reimplementing the underlying math (project
# convention) -- TrialSize is already a project dependency (used by the
# Crossover Trial and Chi-Square Tests modules) with zero package
# dependencies of its own, so this adds no new dependency.

#' Sample size for the Wilcoxon rank-sum test (Mann-Whitney U), two
#' independent samples
#'
#' Wraps TrialSize::Nonpara.Two.Sample(). Tests the nonparametric location
#' shift between two independent samples without assuming normality.
#'
#' @param k Allocation ratio n1/n2 (> 0)
#' @param p1 P(Y >= X) for a random pair (one from each group) -- the
#'   probability a "Y" (group 2) observation exceeds an "X" (group 1)
#'   observation; 0.5 under the null of no shift
#' @param p2 P(Y_i >= X_j1 and Y_i >= X_j2) for one Y and two independent
#'   X's
#' @param p3 P(Y_i1 >= X_j and Y_i2 >= X_j) for two independent Y's and
#'   one X
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_wilcoxon_rank_sum <- function(k = 1, p1, p2, p3, alpha = 0.05, power = 0.8) {
  .validate_positive(k, "k")
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(p3, "p3")
  if (isTRUE(all.equal(p1, 0.5))) stop("p1 must differ from 0.5 (no location shift to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- TrialSize::Nonpara.Two.Sample(alpha = alpha, beta = 1 - power, k = k, p1 = p1, p2 = p2, p3 = p3)

  list(
    n = ceiling(n),
    inputs = list(k = k, p1 = p1, p2 = p2, p3 = p3, alpha = alpha, power = power)
  )
}

#' Sample size for the Wilcoxon signed-rank test, one sample (or paired
#' differences)
#'
#' Wraps TrialSize::Nonpara.One.Sample(). Tests whether the median of a
#' single (or paired-difference) distribution differs from zero, without
#' assuming normality.
#'
#' @param p2 P(|Z_i| >= |Z_j|, Z_i > 0) for two independent observations
#' @param p3 P(|Z_i| >= |Z_j1|, |Z_i| >= |Z_j2|, Z_i > 0) for three
#'   independent observations
#' @param p4 P(|Z_j1| >= |Z_i| >= |Z_j2|, Z_j1 > 0, Z_i > 0) for three
#'   independent observations
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_wilcoxon_signed_rank <- function(p2, p3, p4, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(p3, "p3")
  .validate_unit_interval(p4, "p4")
  if (isTRUE(all.equal(p2, 0.25))) stop("p2 must differ from 0.25 (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- TrialSize::Nonpara.One.Sample(alpha = alpha, beta = 1 - power, p2 = p2, p3 = p3, p4 = p4)

  list(
    n = ceiling(n),
    inputs = list(p2 = p2, p3 = p3, p4 = p4, alpha = alpha, power = power)
  )
}

#' Sample size for a nonparametric test of association (Kendall's tau)
#'
#' Wraps TrialSize::Nonpara.Independ(). Tests whether two continuous
#' variables are independent via concordance probability, without
#' assuming bivariate normality (unlike the Pearson-correlation test in
#' the Correlation module) -- p1 here is exactly the concordance
#' probability that defines Kendall's tau (tau = 2*p1 - 1).
#'
#' @param p1 P((X1-X2)(Y1-Y2) > 0) -- the probability that two
#'   independent pairs are "concordant"; 0.5 under independence
#'   (tau = 0)
#' @param p2 P((X1-X2)(Y1-Y2)(X1-X3)(Y1-Y3) > 0) for three independent
#'   pairs sharing the first pair's X1,Y1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, tau, inputs)
calc_kendall_tau <- function(p1, p2, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  if (isTRUE(all.equal(p1, 0.5))) stop("p1 must differ from 0.5 (no association to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- TrialSize::Nonpara.Independ(alpha = alpha, beta = 1 - power, p1 = p1, p2 = p2)

  list(
    n = ceiling(n),
    tau = 2 * p1 - 1,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power)
  )
}
