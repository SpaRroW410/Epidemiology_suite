# Pure calculation functions for case-control study sample size.
# No Shiny dependency here so these are directly unit-testable (see
# tests/testthat). Both wrap epiR::epi.sscc() (Dupont 1988) rather than
# reimplementing the underlying math (project convention).

#' Sample size for an unmatched case-control study
#'
#' Wraps epiR::epi.sscc(method = "unmatched").
#'
#' @param p0 Expected prevalence of exposure among controls (0,1)
#' @param OR Expected odds ratio (> 0, != 1)
#' @param power Desired power (0,1)
#' @param ratio Number of controls per case (> 0)
#' @param alpha Significance level (0,1)
#' @param alternative "two.sided" or one-sided ("less"/"greater" -- both map
#'   to the same one-sided critical value; epi.sscc doesn't distinguish
#'   direction, only one- vs two-sided)
#' @param N Optional finite eligible-population size. NULL (default) =
#'   effectively infinite population.
#' @return list(n_total, n_case, n_control, inputs)
calc_case_control_unmatched <- function(p0, OR, power = 0.8, ratio = 1,
                                         alpha = 0.05,
                                         alternative = c("two.sided", "less", "greater"),
                                         N = NULL) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p0, "p0")
  .validate_positive(OR, "OR")
  if (isTRUE(all.equal(OR, 1))) stop("OR must differ from 1 (no effect to detect).")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  if (!is.null(N)) .validate_population(N)

  sided <- if (identical(alternative, "two.sided")) 2 else 1

  res <- .cf_sscc_unmatched(N = if (is.null(N)) NA else N, OR = OR, p0 = p0, power = power,
                            r = ratio, design = 1, sided.test = sided, conf.level = 1 - alpha)

  new_ss_result(list(
    n_total = ceiling(res$n.total),
    n_case = ceiling(res$n.case),
    n_control = ceiling(res$n.control),
    inputs = list(p0 = p0, OR = OR, power = power, ratio = ratio, alpha = alpha,
                  alternative = alternative, N = N)
  ))
}

#' Sample size for a matched case-control study (1:1 or 1:m)
#'
#' Wraps epiR::epi.sscc(method = "matched").
#'
#' @param p0 Expected prevalence of exposure among controls (0,1)
#' @param OR Expected odds ratio (> 0, != 1)
#' @param phi_coef Correlation between case and control exposures for
#'   matched pairs (-1, 1); use ~0.2 (moderate) if no prior estimate is
#'   available, per Dupont (1988)
#' @param power Desired power (0,1)
#' @param ratio Number of controls per case (m in 1:m matching, >= 1)
#' @param alpha Significance level (0,1)
#' @param alternative "two.sided" or one-sided
#' @param N Optional finite eligible-population size
#' @return list(n_total, n_case, n_control, inputs)
calc_case_control_matched <- function(p0, OR, phi_coef = 0.2, power = 0.8, ratio = 1,
                                       alpha = 0.05,
                                       alternative = c("two.sided", "less", "greater"),
                                       N = NULL) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p0, "p0")
  .validate_positive(OR, "OR")
  if (isTRUE(all.equal(OR, 1))) stop("OR must differ from 1 (no effect to detect).")
  if (!is.numeric(phi_coef) || length(phi_coef) != 1 || is.na(phi_coef) ||
        phi_coef <= -1 || phi_coef >= 1) {
    stop("phi_coef must be a single number strictly between -1 and 1.")
  }
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  if (!is.null(N)) .validate_population(N)

  sided <- if (identical(alternative, "two.sided")) 2 else 1

  res <- .cf_sscc_matched(N = if (is.null(N)) NA else N, OR = OR, p0 = p0, power = power,
                          r = ratio, phi.coef = phi_coef, design = 1, sided.test = sided,
                          conf.level = 1 - alpha)

  new_ss_result(list(
    n_total = ceiling(res$n.total),
    n_case = ceiling(res$n.case),
    n_control = ceiling(res$n.control),
    inputs = list(p0 = p0, OR = OR, phi_coef = phi_coef, power = power,
                  ratio = ratio, alpha = alpha, alternative = alternative, N = N)
  ))
}

.validate_positive_integer <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 1 || x != round(x)) {
    stop(sprintf("%s must be a single positive integer.", label))
  }
}

#' Sample size for a nested case-control study, binary exposure
#'
#' Wraps powerSurvEpi::powerConLogistic.bin() (conditional logistic
#' regression for a matched/nested case-control set), rather than
#' reimplementing the underlying math (project convention -- powerSurvEpi
#' is already a project dependency, so this adds zero new packages).
#'
#' @param OR Expected odds ratio per unit change in the binary exposure (> 0, != 1)
#' @param pE Prevalence of exposure among the matched set (0,1)
#' @param nD Number of cases per matched set (>= 1)
#' @param nH Number of controls per matched set (>= 1)
#' @param R2 Proportion of variation in exposure explained by other covariates
#'   in the conditional logistic model (0,1); 0 = no adjustment covariates
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs) where n is the number of matched sets required
#'   (each set = nD cases + nH controls)
calc_case_control_nested_binary <- function(OR, pE, nD, nH, R2 = 0, alpha = 0.05,
                                             power = 0.8) {
  .validate_positive(OR, "OR")
  if (isTRUE(all.equal(OR, 1))) stop("OR must differ from 1 (no effect to detect).")
  .validate_unit_interval(pE, "pE")
  .validate_positive_integer(nD, "nD")
  .validate_positive_integer(nH, "nH")
  if (!is.numeric(R2) || length(R2) != 1 || is.na(R2) || R2 < 0 || R2 >= 1) {
    stop("R2 must be a single number in [0, 1).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- .cf_pse_conlogistic_bin(power = power, OR = OR, pE = pE,
                                           nD = nD, nH = nH, R2 = R2, alpha = alpha)

  new_ss_result(list(
    n_sets = ceiling(n),
    n_total = ceiling(n) * (nD + nH),
    inputs = list(OR = OR, pE = pE, nD = nD, nH = nH, R2 = R2, alpha = alpha, power = power)
  ))
}

#' Sample size for a nested case-control study, continuous exposure
#'
#' Wraps powerSurvEpi::powerConLogistic.con().
#'
#' @param OR Expected odds ratio per one-unit (one-SD, if standardized) change
#'   in the continuous exposure (> 0, != 1)
#' @param sigma Standard deviation of the exposure (> 0)
#' @param nD Number of cases per matched set (>= 1)
#' @param nH Number of controls per matched set (>= 1)
#' @param R2 Proportion of variation in exposure explained by other covariates (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_sets, n_total, inputs)
calc_case_control_nested_continuous <- function(OR, sigma, nD, nH, R2 = 0, alpha = 0.05,
                                                 power = 0.8) {
  .validate_positive(OR, "OR")
  if (isTRUE(all.equal(OR, 1))) stop("OR must differ from 1 (no effect to detect).")
  .validate_positive(sigma, "sigma")
  .validate_positive_integer(nD, "nD")
  .validate_positive_integer(nH, "nH")
  if (!is.numeric(R2) || length(R2) != 1 || is.na(R2) || R2 < 0 || R2 >= 1) {
    stop("R2 must be a single number in [0, 1).")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- .cf_pse_conlogistic_con(power = power, OR = OR, sigma = sigma,
                                           nD = nD, nH = nH, R2 = R2, alpha = alpha)

  new_ss_result(list(
    n_sets = ceiling(n),
    n_total = ceiling(n) * (nD + nH),
    inputs = list(OR = OR, sigma = sigma, nD = nD, nH = nH, R2 = R2, alpha = alpha, power = power)
  ))
}

#' Sample size (required subcohort size) for a case-cohort study
#'
#' Closed-form reimplementation of gap::ccsize()'s sample-size branch
#' (Cai & Zeng 2004, Biometrics 60(4):1015-1024, Equation 6), rather than
#' depending on the gap package -- gap::ccsize() itself is pure base-R
#' math (only qnorm), but gap's own Imports/Depends (dplyr, ggplot2,
#' plotly, Rdpack, gap.datasets) are far heavier than this one formula
#' needs.
#'
#' @param n Full cohort size, already assembled (> 0, integer)
#' @param pD Proportion of failures (events) in the full cohort (0,1)
#' @param p1 Proportion of the cohort in exposure/covariate group 1 (0,1);
#'   group 2 is 1 - p1
#' @param hr Hazard ratio to be detected between the two groups (> 0, != 1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(subcohort_n, full_cohort_n, inputs)
calc_case_control_case_cohort <- function(n, pD, p1, hr, alpha = 0.05, power = 0.8) {
  .validate_positive_integer(n, "n")
  .validate_unit_interval(pD, "pD")
  .validate_unit_interval(p1, "p1")
  .validate_positive(hr, "hr")
  if (isTRUE(all.equal(hr, 1))) stop("hr must differ from 1 (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  theta <- log(hr)
  z_alpha <- qnorm(alpha, lower.tail = FALSE)
  z_beta <- qnorm(1 - power, lower.tail = FALSE)
  B <- (z_alpha + z_beta)^2 / (theta^2 * p1 * (1 - p1) * pD)
  m <- n * B * pD / (n - B * (1 - pD))

  if (!is.finite(m) || m <= 0 || m > n) {
    stop(paste(
      "No feasible subcohort size for these inputs (the required subcohort",
      "would exceed the full cohort, or the configuration is otherwise",
      "infeasible) -- try a larger cohort, a larger hazard ratio, or lower power."
    ))
  }

  new_ss_result(list(
    subcohort_n = ceiling(m),
    full_cohort_n = n,
    inputs = list(n = n, pD = pD, p1 = p1, hr = hr, alpha = alpha, power = power)
  ))
}
