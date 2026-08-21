# Pure closed-form calculation functions for the "rule of three" -- the
# well-known approximation for bounding an unseen adverse-event rate (or
# solving the sample size to have a good chance of detecting at least one
# event of a given true rate). No package needed; the formulas are the
# exact/approximate zero-events binomial confidence bound derivations, per
# Hanley & Lippman-Hand (1983).

#' Upper confidence bound on a true event rate, having observed zero
#' events in n subjects
#'
#' If zero events are observed in n independent subjects/trials, the exact
#' upper (one-sided) confidence bound on the true event rate is
#' 1 - alpha^(1/n) (solved from P(zero events | p = bound, n) = alpha).
#' For alpha = 0.05 this is well approximated by -ln(0.05)/n ~ 3/n, the
#' "rule of three".
#'
#' @param n Number of subjects observed with zero events (whole number >= 1)
#' @param conf_level Confidence level (0,1); e.g. 0.95 for the classic "3/n" rule
#' @return list(approx_bound, exact_bound, inputs)
calc_rule_of_three_bound <- function(n, conf_level = 0.95) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1 || n != round(n)) {
    stop("n must be a single whole number >= 1.")
  }
  .validate_unit_interval(conf_level, "conf_level")

  alpha <- 1 - conf_level
  approx_bound <- -log(alpha) / n
  exact_bound <- 1 - alpha^(1 / n)

  list(
    approx_bound = approx_bound,
    exact_bound = exact_bound,
    inputs = list(n = n, conf_level = conf_level)
  )
}

#' Sample size to have a target probability of observing at least one
#' event, given an assumed true event rate
#'
#' The complement of calc_rule_of_three_bound(): if the true event rate is
#' p, the number of subjects needed so that P(at least one event) >=
#' conf_level solves (1-p)^n <= alpha, i.e. n >= log(alpha)/log(1-p).
#'
#' @param p Assumed true event rate (0,1)
#' @param conf_level Desired probability of observing at least one event (0,1)
#' @return list(n_exact, n_approx, inputs)
calc_rule_of_three_n <- function(p, conf_level = 0.95) {
  .validate_unit_interval(p, "p")
  .validate_unit_interval(conf_level, "conf_level")

  alpha <- 1 - conf_level
  n_exact <- ceiling(log(alpha) / log(1 - p))
  n_approx <- ceiling(-log(alpha) / p)

  list(
    n_exact = n_exact,
    n_approx = n_approx,
    inputs = list(p = p, conf_level = conf_level)
  )
}
