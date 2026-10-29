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
#' @examples
#' calc_rule_of_three_bound(n = 30, conf_level = 0.95)
#' @export
calc_rule_of_three_bound <- function(n, conf_level = 0.95) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1 || n != round(n)) {
    stop("n must be a single whole number >= 1.")
  }
  .validate_unit_interval(conf_level, "conf_level")

  alpha <- 1 - conf_level
  approx_bound <- -log(alpha) / n
  exact_bound <- 1 - alpha^(1 / n)

  new_ss_result(list(
    approx_bound = approx_bound,
    exact_bound = exact_bound,
    inputs = list(n = n, conf_level = conf_level)
  ))
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
#' @examples
#' calc_rule_of_three_n(p = 0.01, conf_level = 0.95)
#' @export
calc_rule_of_three_n <- function(p, conf_level = 0.95) {
  .validate_unit_interval(p, "p")
  .validate_unit_interval(conf_level, "conf_level")

  alpha <- 1 - conf_level
  n_exact <- ceiling(log(alpha) / log(1 - p))
  n_approx <- ceiling(-log(alpha) / p)

  new_ss_result(list(
    n_exact = n_exact,
    n_approx = n_approx,
    inputs = list(p = p, conf_level = conf_level)
  ))
}

#' Sample size to detect at least one case in a finite population, with
#' an imperfect diagnostic test (or two tests, combined in series or
#' parallel)
#'
#' Wraps epiR::epi.ssdetect() rather than reimplementing the underlying
#' math (project convention) -- epiR already a project dependency. This
#' generalizes calc_rule_of_three_n() above (which assumes a perfect
#' test and an effectively infinite population) to a known finite
#' population size (via the hypergeometric distribution, MacDiarmid
#' 1988) and a test with imperfect sensitivity/specificity -- the
#' standard "prove disease freedom" surveillance design (Cannon 2001).
#'
#' @param N Total population size (whole number >= 1), e.g. herd size or
#'   study-area size
#' @param prev Assumed true prevalence if the condition/disease were
#'   present (0,1)
#' @param se Sensitivity of the test, or a length-2 vector of two tests'
#'   sensitivities, each in (0,1\]
#' @param sp Specificity of the test, or a length-2 vector of two tests'
#'   specificities (same length as se), each in (0,1\]
#' @param interpretation For two tests, "series" (both must be positive
#'   to call a case positive -- higher combined specificity, lower
#'   sensitivity) or "parallel" (either positive suffices -- higher
#'   combined sensitivity, lower specificity); ignored for a single test
#' @param conf_level Desired confidence that, if the population is
#'   affected at the assumed prevalence, at least one case would be
#'   detected (0,1)
#' @return list(n_hypergeometric, n_binomial, combined_se, combined_sp, inputs)
#' @examples
#' calc_detect_event_imperfect_test(N = 1000, prev = 0.05, se = 0.9, sp = 1, conf_level = 0.95)
#' @export
calc_detect_event_imperfect_test <- function(N, prev, se, sp,
                                              interpretation = c("series", "parallel"),
                                              conf_level = 0.95) {
  interpretation <- match.arg(interpretation)
  .validate_population(N, "N")
  .validate_unit_interval(prev, "prev")
  if (!is.numeric(se) || length(se) < 1 || length(se) > 2 || anyNA(se) ||
        any(se <= 0) || any(se > 1)) {
    stop("se must be one or two numbers, each in (0, 1].")
  }
  if (!is.numeric(sp) || length(sp) != length(se) || anyNA(sp) ||
        any(sp <= 0) || any(sp > 1)) {
    stop("sp must have the same length as se, each in (0, 1].")
  }
  .validate_unit_interval(conf_level, "conf_level")

  fit <- .cf_ssdetect(
    N = N, prev = prev, se = se, sp = sp, interpretation = interpretation,
    conf.level = conf_level
  )

  new_ss_result(list(
    n_hypergeometric = unname(fit$sample.size["hypergeo"]),
    n_binomial = unname(fit$sample.size["binom"]),
    combined_se = fit$performance$se,
    combined_sp = fit$performance$sp,
    inputs = list(N = N, prev = prev, se = se, sp = sp,
                  interpretation = interpretation, conf_level = conf_level)
  ))
}
