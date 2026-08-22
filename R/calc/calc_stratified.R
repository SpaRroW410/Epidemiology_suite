# Pure closed-form calculation function for stratified-sampling sample
# size (proportional or optimal/Neyman allocation). No Shiny dependency
# here so this is directly unit-testable (see tests/testthat).
#
# This is the standard Cochran-style stratified-sampling formula (as
# presented by Kauermann & Kuechenhoff 2011), reimplemented directly as
# closed-form R rather than taking a runtime dependency on the CRAN
# package that documents it (`samplingbook::stratasize()` /
# `stratasamp()`) -- that package's Depends: pps, sampling, survey chain
# is far heavier than this one formula needs (project convention: see
# the WebPower-avoidance precedent in calc_rate.R). The formula below was
# verified to reproduce that package's own documented examples exactly
# (see tests/testthat/test-calc_stratified.R).

#' Sample size for stratified sampling, given a target precision
#'
#' Computes the total sample size needed to estimate a population mean/
#' total to within a target absolute precision (margin of error), given
#' each stratum's population size and standard deviation, under either
#' proportional or optimal (Neyman) allocation -- then splits that total
#' across strata accordingly.
#'
#' @param Nh Numeric vector of population sizes in each stratum (each >= 2)
#' @param Sh Numeric vector of standard deviations in each stratum (each >= 0,
#'   same length as Nh)
#' @param e Desired absolute precision (margin of error), > 0
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @param type "proportional" (allocate in proportion to stratum size) or
#'   "optimal" (Neyman allocation: proportion to Nh x Sh, minimizing
#'   variance for a fixed total n)
#' @return list(n_total, nh, wh, inputs)
calc_stratified_sampling <- function(Nh, Sh, e, conf_level = 0.95,
                                      type = c("proportional", "optimal")) {
  type <- match.arg(type)

  if (!is.numeric(Nh) || length(Nh) < 2 || anyNA(Nh)) {
    stop("Nh must be a numeric vector of at least 2 stratum population sizes.")
  }
  if (any(Nh < 2)) stop("Each stratum population size (Nh) must be >= 2.")
  if (!is.numeric(Sh) || length(Sh) != length(Nh) || anyNA(Sh)) {
    stop("Sh must be a numeric vector the same length as Nh.")
  }
  if (any(Sh < 0)) stop("Each stratum standard deviation (Sh) must be >= 0.")
  .validate_positive(e, "e")
  .validate_unit_interval(conf_level, "conf_level")

  q <- stats::qnorm((1 + conf_level) / 2)
  N <- sum(Nh)
  wh <- Nh / N
  within_strata_term <- sum(wh^2 * Sh^2 / (Nh - 1))

  if (type == "proportional") {
    n_total <- sum(wh^2 * N / (Nh - 1) * Sh^2) / (e^2 / q^2 + within_strata_term)
    alloc_wh <- wh
  } else {
    nhss <- sum(Nh * Sh)
    n_total <- sum(wh^2 * nhss / (Nh - 1) * Sh) / (e^2 / q^2 + within_strata_term)
    alloc_wh <- if (nhss > 0) (Nh * Sh) / nhss else wh
  }
  n_total <- ceiling(n_total)
  nh <- round(n_total * alloc_wh)

  list(
    n_total = n_total,
    nh = nh,
    wh = alloc_wh,
    inputs = list(Nh = Nh, Sh = Sh, e = e, conf_level = conf_level, type = type)
  )
}
