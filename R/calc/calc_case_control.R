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

  res <- epiR::epi.sscc(N = if (is.null(N)) NA else N, OR = OR, p1 = NA, p0 = p0,
                         n = NA, power = power, r = ratio, phi.coef = 0,
                         design = 1, sided.test = sided, nfractional = FALSE,
                         conf.level = 1 - alpha, method = "unmatched", fleiss = FALSE)

  list(
    n_total = ceiling(res$n.total),
    n_case = ceiling(res$n.case),
    n_control = ceiling(res$n.control),
    inputs = list(p0 = p0, OR = OR, power = power, ratio = ratio, alpha = alpha,
                  alternative = alternative, N = N)
  )
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

  res <- epiR::epi.sscc(N = if (is.null(N)) NA else N, OR = OR, p1 = NA, p0 = p0,
                         n = NA, power = power, r = ratio, phi.coef = phi_coef,
                         design = 1, sided.test = sided, nfractional = FALSE,
                         conf.level = 1 - alpha, method = "matched", fleiss = FALSE)

  list(
    n_total = ceiling(res$n.total),
    n_case = ceiling(res$n.case),
    n_control = ceiling(res$n.control),
    inputs = list(p0 = p0, OR = OR, phi_coef = phi_coef, power = power,
                  ratio = ratio, alpha = alpha, alternative = alternative, N = N)
  )
}
