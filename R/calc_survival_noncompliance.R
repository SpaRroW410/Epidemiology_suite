# Pure calculation function for a noncompliance/drop-in-adjusted log-rank
# (accrual + follow-up) survival sample size. No Shiny dependency here so
# this is directly unit-testable (see tests/testthat). Wraps
# Hmisc::cpower() rather than reimplementing the underlying formula
# (project convention).

#' Sample size for a Cox/log-rank two-sample survival test with accrual,
#' follow-up, and noncompliance (drop-in / non-adherence)
#'
#' Wraps `Hmisc::cpower()` (already a project dependency), which assumes
#' exponential survival in both arms and combines the George & Desu (1974)
#' expected-events method with Schoenfeld (1983)'s log hazard-ratio
#' variance, then applies the noncompliance correction of Lachin & Foulkes
#' (1986) -- allowing for both "drop-in" (control-arm subjects who take the
#' intervention) and "non-adherence" (intervention-arm subjects who don't)
#' -- while accounting for a non-instantaneous accrual period plus a
#' minimum follow-up time, exactly the "accrual + follow-up designs
#' (non-uniform entry)" checklist item's non-uniform-entry generalization
#' of the basic log-rank test already covered elsewhere in this app by the
#' Log-Rank / Survival module's simpler fixed-follow-up design.
#'
#' @param tref Time at which the reference (control-arm) mortality `mc` is
#'   measured
#' @param mc Reference-time mortality (event probability) in the control
#'   arm, in (0,1)
#' @param pct_reduction Percent reduction in `mc` produced by the
#'   intervention (e.g. 20 for a 20% relative reduction), in (0,100)
#' @param accrual Duration of the accrual (enrollment) period
#' @param tmin Minimum follow-up time (for the last-enrolled subject)
#' @param noncomp_c Percent of control-arm subjects who cross over to the
#'   intervention ("drop-ins"), in [0,100)
#' @param noncomp_i Percent of intervention-arm subjects who do not adhere
#'   to it, in [0,100)
#' @param alpha Two-sided significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_total, n_per_group, achieved_power, inputs)
calc_survival_noncompliance <- function(tref, mc, pct_reduction, accrual, tmin,
                                         noncomp_c = 0, noncomp_i = 0,
                                         alpha = 0.05, power = 0.8) {
  .validate_positive(tref, "tref")
  .validate_unit_interval(mc, "mc")
  if (!is.numeric(pct_reduction) || length(pct_reduction) != 1 || is.na(pct_reduction) ||
    pct_reduction <= 0 || pct_reduction >= 100) {
    stop("pct_reduction must be a single number strictly between 0 and 100.")
  }
  .validate_positive(accrual, "accrual")
  .validate_positive(tmin, "tmin")
  for (nm in c("noncomp_c", "noncomp_i")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || v < 0 || v >= 100) {
      stop(sprintf("%s must be a single number in [0, 100).", nm))
    }
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  power_given_n <- function(n) {
    .cf_cpower(
      tref = tref, n = n, mc = mc, r = pct_reduction,
      accrual = accrual, tmin = tmin,
      noncomp.c = noncomp_c, noncomp.i = noncomp_i,
      alpha = alpha
    )
  }

  n_lower <- 10
  n_upper <- 2e6
  if (!is.finite(power_given_n(n_upper)) || power_given_n(n_upper) < power) {
    stop("No feasible sample size for these inputs (effect likely too small or noncompliance too high).")
  }

  n_total <- ceiling(uniroot(function(n) power_given_n(n) - power, c(n_lower, n_upper))$root)
  n_total <- n_total + (n_total %% 2) # cpower splits n evenly between the two arms

  new_ss_result(list(
    n_total = n_total,
    n_per_group = n_total / 2,
    achieved_power = unname(power_given_n(n_total)),
    inputs = list(
      tref = tref, mc = mc, pct_reduction = pct_reduction,
      accrual = accrual, tmin = tmin,
      noncomp_c = noncomp_c, noncomp_i = noncomp_i,
      alpha = alpha, power = power
    )
  ))
}
