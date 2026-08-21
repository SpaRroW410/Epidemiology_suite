# Pure calculation function for incidence-rate estimation precision. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps presize::prec_rate() rather than reimplementing
# the underlying math (project convention).

#' Precision-based sample size (number of events / person-time) for an
#' incidence rate estimate
#'
#' Solves for the number of events needed to achieve a target confidence
#' interval width for an incidence rate, then converts that to the
#' required person-time (since rate = events / person-time). Wraps
#' presize::prec_rate(), which itself uses `uniroot` to solve n from
#' conf.width.
#'
#' @param rate Expected rate (events per unit person-time, e.g. per
#'   person-year) (> 0)
#' @param conf_width Desired full width of the confidence interval, in the
#'   same units as `rate`. Per presize's own guidance this should not
#'   exceed 5 times `rate`.
#' @param conf_level Confidence level (0,1)
#' @param method One of "score", "vs" (variance-stabilizing), "exact", or
#'   "wald". "exact" is recommended when the expected number of events is
#'   small (< 5).
#' @return list(n_events, person_time, achieved_conf_width, inputs)
calc_rate_precision <- function(rate, conf_width, conf_level = 0.95,
                                 method = c("score", "vs", "exact", "wald")) {
  method <- match.arg(method)
  .validate_positive(rate, "rate")
  .validate_positive(conf_width, "conf_width")
  .validate_unit_interval(conf_level, "conf_level")
  if (conf_width > 5 * rate) {
    stop("conf_width should not exceed 5 times rate (presize::prec_rate's own guidance).")
  }

  fit <- presize::prec_rate(r = rate, conf.width = conf_width,
                             conf.level = conf_level, method = method)
  n_events <- ceiling(fit$x)
  achieved <- presize::prec_rate(r = rate, x = n_events,
                                  conf.level = conf_level, method = method)

  list(
    n_events = n_events,
    person_time = n_events / rate,
    achieved_conf_width = achieved$conf.width,
    inputs = list(rate = rate, conf_width = conf_width,
                  conf_level = conf_level, method = method)
  )
}
