# Pure calculation function for repeated-measures / mixed (split-plot)
# ANOVA sample size. No Shiny dependency here so this is directly
# unit-testable (see tests/testthat).
#
# Closed-form reimplementation of WebPower::wp.rmanova()'s noncentral-F
# calculation (Cohen 1988), rather than depending on the WebPower package
# (project convention: prefer a lightweight reimplementation over a heavy
# dependency when the needed function is itself pure/light-dependency
# code). WebPower's own Depends (MASS, lme4, lavaan, PearsonDS) and
# Imports (dplyr) are far heavier than this one formula needs -- and
# wp.rmanova() itself never calls into any of them, only base stats
# (qf/pf/uniroot).

#' Sample size for repeated-measures / mixed (split-plot) ANOVA
#'
#' Solves for the total sample size needed to detect a between-subjects
#' group effect, a within-subjects (repeated-measures) effect, or their
#' interaction, using Cohen's (1988) noncentral-F approach -- the same
#' algorithm as WebPower::wp.rmanova().
#'
#' @param ng Number of between-subjects groups (>= 1; >= 2 required for
#'   "between" or "interaction", since a single group has no between-group
#'   effect to test)
#' @param nm Number of repeated measurements/occasions (>= 2)
#' @param f Cohen's f effect size (> 0)
#' @param nscor Nonsphericity correction coefficient in (0, 1]; 1 = sphericity
#'   assumption met (default)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param type One of "between", "within", "interaction"
#' @return list(n, inputs)
calc_rm_anova <- function(ng, nm, f, nscor = 1, alpha = 0.05, power = 0.8,
                           type = c("between", "within", "interaction")) {
  type <- match.arg(type)

  if (!is.numeric(ng) || length(ng) != 1 || is.na(ng) || ng < 1 || ng != round(ng)) {
    stop("ng must be a single positive integer.")
  }
  if (type %in% c("between", "interaction") && ng < 2) {
    stop("ng must be at least 2 to test a between-subjects effect or interaction.")
  }
  if (!is.numeric(nm) || length(nm) != 1 || is.na(nm) || nm < 2 || nm != round(nm)) {
    stop("nm must be a single integer >= 2 (at least two repeated measurements).")
  }
  .validate_positive(f, "f")
  if (!is.numeric(nscor) || length(nscor) != 1 || is.na(nscor) || nscor <= 0 || nscor > 1) {
    stop("nscor must be a single number in (0, 1].")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  power_given_n <- function(n) {
    if (type == "between") {
      df1 <- ng - 1
      df2 <- n - ng
    } else if (type == "within") {
      df1 <- (nm - 1) * nscor
      df2 <- (n - ng) * df1
    } else {
      df1 <- (ng - 1) * (nm - 1) * nscor
      df2 <- (n - ng) * (nm - 1) * nscor
    }
    if (df1 <= 0 || df2 <= 0) return(NA_real_)
    lambda <- f^2 * n * nscor
    pf(qf(alpha, df1, df2, lower.tail = FALSE), df1, df2, lambda, lower.tail = FALSE)
  }

  n_lower <- ng + 2
  n_upper <- 1e7
  if (!is.finite(power_given_n(n_upper)) || power_given_n(n_upper) < power) {
    stop("No feasible sample size for these inputs (effect size likely too small).")
  }

  n <- ceiling(uniroot(function(n) power_given_n(n) - power, c(n_lower, n_upper))$root)

  new_ss_result(list(
    n = n,
    achieved_power = power_given_n(n),
    inputs = list(ng = ng, nm = nm, f = f, nscor = nscor, alpha = alpha,
                  power = power, type = type)
  ))
}
