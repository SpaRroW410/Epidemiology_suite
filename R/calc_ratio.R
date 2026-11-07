# Pure calculation functions for precision-based ratio estimation (risk
# ratio, odds ratio, rate ratio). No Shiny dependency here so these are
# directly unit-testable (see tests/testthat). All three wrap presize::
# functions rather than reimplementing the underlying math (project
# convention) -- presize is already a project dependency (used by the
# Agreement module's kappa/ICC/Cronbach/Bland-Altman designs).
#
# These are precision-based (CI-width) designs, like presize's other
# functions already wrapped in this app: no hypothesis test, no power
# target, just an estimation-precision target.

#' Sample size for estimating a risk ratio to a target precision
#'
#' Wraps presize::prec_riskratio() (Koopman 1984; Katz et al. 1978;
#' Fagerland, Lydersen & Laake 2015).
#'
#' @param p1 Expected risk (proportion) in the exposed group (0,1)
#' @param p2 Expected risk (proportion) in the unexposed group (0,1)
#' @param r Allocation ratio, n2/n1 (> 0)
#' @param conf_width Desired full width of the confidence interval for
#'   the risk ratio
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @param method "koopman" (default, recommended) or "katz"
#' @return list(n1, n2, n_total, achieved_width, inputs)
#' @examples
#' calc_precision_riskratio(p1 = 7/34, p2 = 1/34, r = 1, conf_width = 41.35486, method = "koopman")
#' @export
calc_precision_riskratio <- function(p1, p2, r = 1, conf_width = 1, conf_level = 0.95,
                                      method = c("koopman", "katz")) {
  method <- match.arg(method)
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_positive(r, "r")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")

  res <- .cf_prec_riskratio(p1 = p1, p2 = p2, n1 = NULL, r = r,
                                  conf.width = conf_width, conf.level = conf_level,
                                  method = method)
  n1 <- ceiling(res$n1)
  n2 <- ceiling(n1 * r)
  achieved <- .cf_prec_riskratio(p1 = p1, p2 = p2, n1 = n1, r = r,
                                       conf.level = conf_level, method = method)

  new_ss_result(list(
    n1 = n1, n2 = n2, n_total = n1 + n2,
    achieved_width = achieved$conf.width,
    inputs = list(p1 = p1, p2 = p2, r = r, conf_width = conf_width,
                  conf_level = conf_level, method = method)
  ))
}

#' Sample size for estimating an odds ratio to a target precision
#'
#' Wraps presize::prec_or() (Gart & Zweifel 1967; Woolf 1955; Fagerland,
#' Lydersen & Laake 2015).
#'
#' @param p1 Expected proportion with the outcome in group 1 (0,1)
#' @param p2 Expected proportion with the outcome in group 2 (0,1)
#' @param r Allocation ratio, n2/n1 (> 0)
#' @param conf_width Desired full width of the confidence interval for
#'   the odds ratio
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @param method "gart", "woolf", or "indip_smooth" (default)
#' @return list(n1, n2, n_total, achieved_width, inputs)
#' @examples
#' calc_precision_or(p1 = 0.1, p2 = 0.15, r = 1, conf_width = 1.207484, method = "indip_smooth")
#' @export
calc_precision_or <- function(p1, p2, r = 1, conf_width = 1, conf_level = 0.95,
                               method = c("indip_smooth", "gart", "woolf")) {
  method <- match.arg(method)
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_positive(r, "r")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")

  res <- .cf_prec_or(p1 = p1, p2 = p2, n1 = NULL, r = r,
                           conf.width = conf_width, conf.level = conf_level,
                           method = method)
  n1 <- ceiling(res$n1)
  n2 <- ceiling(n1 * r)
  achieved <- .cf_prec_or(p1 = p1, p2 = p2, n1 = n1, r = r,
                                conf.level = conf_level, method = method)

  new_ss_result(list(
    n1 = n1, n2 = n2, n_total = n1 + n2,
    achieved_width = achieved$conf.width,
    inputs = list(p1 = p1, p2 = p2, r = r, conf_width = conf_width,
                  conf_level = conf_level, method = method)
  ))
}

#' Sample size for estimating a rate ratio to a target precision
#'
#' Wraps presize::prec_rateratio() (Rothman & Greenland 2018). Precision
#' here is expressed as prec_level: the ratio of the upper to the lower
#' confidence limit of the rate ratio (e.g. 3.81 means the CI's upper
#' bound is 3.81 times its lower bound) -- rate ratios are typically
#' reported and reasoned about multiplicatively, so this app follows
#' presize's own convention rather than an additive CI width.
#'
#' @param rate1 Expected event rate in the exposed group (> 0)
#' @param rate2 Expected event rate in the unexposed group (> 0)
#' @param r Allocation ratio, n2/n1 (> 0)
#' @param prec_level Desired ratio of the CI's upper limit to its lower
#'   limit (> 1)
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n1, n2, n_total, achieved_prec_level, inputs)
#' @examples
#' calc_precision_rateratio(rate1 = 0.5, rate2 = 3, r = 1, prec_level = 3.814884)
#' @export
calc_precision_rateratio <- function(rate1, rate2, r = 1, prec_level = 2, conf_level = 0.95) {
  .validate_positive(rate1, "rate1")
  .validate_positive(rate2, "rate2")
  .validate_positive(r, "r")
  if (!is.numeric(prec_level) || length(prec_level) != 1 || is.na(prec_level) || prec_level <= 1) {
    stop("prec_level must be a single number greater than 1.")
  }
  .validate_unit_interval(conf_level, "conf_level")

  res <- .cf_prec_rateratio(n1 = NULL, rate1 = rate1, rate2 = rate2,
                                  prec.level = prec_level, r = r, conf.level = conf_level)
  n1 <- ceiling(res$n1)
  n2 <- ceiling(n1 * r)
  achieved <- .cf_prec_rateratio(n1 = n1, rate1 = rate1, rate2 = rate2,
                                       r = r, conf.level = conf_level)

  new_ss_result(list(
    n1 = n1, n2 = n2, n_total = n1 + n2,
    achieved_prec_level = achieved$prec.level,
    inputs = list(rate1 = rate1, rate2 = rate2, r = r, prec_level = prec_level,
                  conf_level = conf_level)
  ))
}
