# Pure calculation functions for agreement/reliability studies -- i.e. when
# there is no gold standard/reference test to compare against, so instead of
# sensitivity/specificity (R/calc/calc_diagnostic.R) you assess how well two
# raters or methods *agree* with each other.
#
# Both functions wrap validated presize:: functions rather than reimplementing
# the underlying math (project convention -- see docs/project-brief.md), so
# there is no local re-derivation of the confidence-interval formulas here.

#' Sample size for Cohen's kappa (categorical agreement, no gold standard)
#'
#' Wraps presize::prec_kappa(), which itself wraps the kappaSize package's
#' CI-width-based functions (Donner & Eliasziw 1987 for the 2-category case;
#' Rotondi & Donner 2012 for multi-category/multi-rater). Precision-based: no
#' hypothesis test, no power target -- just an expected kappa, a desired
#' confidence-interval width, and how the categories are expected to split.
#'
#' @param kappa Expected value of Cohen's kappa (-1, 1) -- in practice
#'   almost always reported as 0 to 1.
#' @param n_category Number of outcome categories (2-5)
#' @param raters Number of raters (2-6)
#' @param props Expected proportion of subjects in each category; length
#'   must equal n_category and sum to 1
#' @param conf_width Desired full width of the confidence interval for kappa
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, inputs)
calc_kappa <- function(kappa, n_category = 2, raters = 2, props,
                        conf_width = 0.15, conf_level = 0.95) {
  if (!is.numeric(kappa) || length(kappa) != 1 || is.na(kappa) || kappa <= -1 || kappa >= 1) {
    stop("kappa must be a single number strictly between -1 and 1.")
  }
  if (!is.numeric(n_category) || length(n_category) != 1 || !(n_category %in% 2:5)) {
    stop("n_category must be a single whole number between 2 and 5.")
  }
  if (!is.numeric(raters) || length(raters) != 1 || !(raters %in% 2:6)) {
    stop("raters must be a single whole number between 2 and 6.")
  }
  if (!is.numeric(props) || length(props) != n_category) {
    stop(sprintf("props must have exactly %d value(s), one per category.", n_category))
  }
  if (any(is.na(props)) || any(props <= 0) || any(props >= 1)) {
    stop("each value in props must be strictly between 0 and 1.")
  }
  if (abs(sum(props) - 1) > 1e-6) {
    stop("props must sum to 1.")
  }
  if (!is.numeric(conf_width) || length(conf_width) != 1 || is.na(conf_width) ||
        conf_width <= 0 || conf_width >= 2) {
    stop("conf_width must be a single number strictly between 0 and 2.")
  }
  .validate_unit_interval(conf_level, "conf_level")

  res <- presize::prec_kappa(kappa = kappa, conf.width = conf_width,
                              raters = raters, n_category = n_category,
                              props = props, conf.level = conf_level)

  list(
    n = ceiling(res$n),
    lwr = res$lwr,
    upr = res$upr,
    inputs = list(kappa = kappa, n_category = n_category, raters = raters,
                  props = props, conf_width = conf_width, conf_level = conf_level)
  )
}

#' Sample size for the intraclass correlation coefficient (continuous
#' agreement/reliability, no gold standard)
#'
#' Wraps presize::prec_icc() (Bonett 2002). Precision-based: no hypothesis
#' test, no power target -- just an expected ICC, the number of raters or
#' repeated measurements per subject, and a desired confidence-interval width.
#'
#' @param rho Expected intraclass correlation (0, 1)
#' @param k Number of raters/measurements per subject (>= 2)
#' @param conf_width Desired full width of the confidence interval for the ICC
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, inputs)
calc_icc <- function(rho, k, conf_width = 0.2, conf_level = 0.95) {
  .validate_unit_interval(rho, "rho")
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 2 || k != round(k)) {
    stop("k must be a single whole number >= 2.")
  }
  if (!is.numeric(conf_width) || length(conf_width) != 1 || is.na(conf_width) ||
        conf_width <= 0 || conf_width >= 2) {
    stop("conf_width must be a single number strictly between 0 and 2.")
  }
  .validate_unit_interval(conf_level, "conf_level")

  res <- presize::prec_icc(rho = rho, k = k, conf.width = conf_width,
                            conf.level = conf_level)

  list(
    n = ceiling(res$n),
    inputs = list(rho = rho, k = k, conf_width = conf_width, conf_level = conf_level)
  )
}

#' Sample size for Cronbach's alpha (scale internal consistency)
#'
#' Wraps presize::prec_cronb() (Bonett & Wright 2015).
#'
#' @param k Number of items/measurements in the scale (>= 2)
#' @param calpha Desired/expected Cronbach's alpha (0, 1)
#' @param conf_width Desired full width of the confidence interval for alpha
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, inputs)
calc_agreement_cronbach <- function(k, calpha, conf_width = 0.1, conf_level = 0.95) {
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 2 || k != round(k)) {
    stop("k must be a single whole number >= 2.")
  }
  .validate_unit_interval(calpha, "calpha")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")

  res <- presize::prec_cronb(k = k, calpha = calpha, n = NULL,
                              conf.level = conf_level, conf.width = conf_width)

  list(
    n = ceiling(res$n),
    lwr = res$lwr,
    upr = res$upr,
    inputs = list(k = k, calpha = calpha, conf_width = conf_width, conf_level = conf_level)
  )
}

#' Sample size for Lin's Concordance Correlation Coefficient (CCC)
#'
#' Closed-form, rather than a package wrap: no CRAN package implements a
#' dedicated CCC sample-size function (DescTools::CCC() and
#' epiR::epi.ccc() are estimation-only). Reimplements the asymptotic
#' variance formula for CCC that epiR::epi.ccc() itself uses internally
#' for its "asymptotic" confidence interval (Lin 1989; correction Lin
#' 2000) -- epiR is already a project dependency, so this formula was
#' extracted from, and cross-verified numerically against, its own
#' installed source (see tests/testthat) rather than reimplemented from
#' a secondary description.
#'
#' @param rho_c Expected/target CCC (-1, 1); |rho_c| must not exceed |rho|
#' @param rho Expected underlying Pearson correlation between the two
#'   measurements (-1, 1, and != 0)
#' @param u Expected location-shift parameter, i.e. the standardized mean
#'   difference between the two measurements: (mean2 - mean1) /
#'   (sd1 * sd2)^0.25. 0 (default) means no systematic bias between the
#'   two methods -- CCC driven purely by precision (correlation), the
#'   most common planning assumption when no pilot data exist.
#' @param conf_width Desired full width of the (symmetric, raw-scale)
#'   confidence interval for the CCC
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, inputs)
calc_agreement_ccc <- function(rho_c, rho, u = 0, conf_width = 0.2, conf_level = 0.95) {
  if (!is.numeric(rho_c) || length(rho_c) != 1 || is.na(rho_c) || rho_c <= -1 || rho_c >= 1) {
    stop("rho_c must be a single number strictly between -1 and 1.")
  }
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || rho <= -1 || rho >= 1 || rho == 0) {
    stop("rho must be a single number strictly between -1 and 1, and not 0.")
  }
  if (abs(rho_c) > abs(rho)) {
    stop("|rho_c| cannot exceed |rho| (the CCC can never exceed the underlying Pearson correlation in magnitude).")
  }
  if (!is.numeric(u) || length(u) != 1 || is.na(u)) {
    stop("u must be a single number.")
  }
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")

  A <- (1 - rho^2) * rho_c^2 * (1 - rho_c^2) / rho^2 +
    2 * rho_c^3 * (1 - rho_c) * u^2 / rho -
    0.5 * rho_c^4 * u^4 / rho^2

  if (!is.finite(A) || A <= 0) {
    stop("No feasible sample size for this combination of rho_c, rho, and u (the implied variance is non-positive) -- try a smaller u or check rho_c/rho.")
  }

  zv <- qnorm(1 - (1 - conf_level) / 2)
  n <- ceiling(2 + 4 * zv^2 * A / conf_width^2)
  achieved_width <- 2 * zv * sqrt(A / (n - 2))

  list(
    n = n,
    achieved_width = achieved_width,
    inputs = list(rho_c = rho_c, rho = rho, u = u, conf_width = conf_width, conf_level = conf_level)
  )
}

#' Sample size for Bland-Altman limits of agreement
#'
#' Wraps presize::prec_lim_agree() (Bland & Altman 1986). Precision is
#' expressed in SD-units of the paired differences, not the original
#' measurement units -- the confidence interval width for the *limit of
#' agreement itself*, not for the mean difference.
#'
#' @param conf_width Desired full width of the confidence interval for the
#'   limit of agreement, in SD-units of the paired differences
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(n, inputs)
calc_agreement_bland_altman <- function(conf_width = 1, conf_level = 0.95) {
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")

  res <- presize::prec_lim_agree(n = NULL, conf.width = conf_width, conf.level = conf_level)

  list(
    n = ceiling(res$n),
    inputs = list(conf_width = conf_width, conf_level = conf_level)
  )
}
