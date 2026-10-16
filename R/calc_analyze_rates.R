# Analyze from summary counts: person-time rates and rate ratios (ROADMAP Track
# B1, item 13).
#
# Single rate, d events in T person-time units (events per `multiplier` units):
#   rate = d / T; four interval methods for the Poisson mean:
#   Exact (Garwood)  lower = chi2_{a/2, 2d} / (2T), upper = chi2_{1-a/2, 2(d+1)} / (2T);
#                    Garwood F. Biometrika 1936;28:437-442; Ulm K. Am J Epidemiol
#                    1990;131:373-375 (the form used by epiR::epi.conf()).
#   Mid-P exact      the exact interval with half the probability of the observed
#                    count in each tail (Lancaster 1961; Berry & Armitage 1995).
#   Byar             a' (1 - 1/(9a') -/+ z/(3 sqrt a'))^3 with a' = d + 1/2, Byar's cube-root
#                    approximation in the form given by Rothman KJ, Epidemiology: An
#                    Introduction, 2nd ed., 2012, as in epiR::epi.conf(ctype = "inc.rate",
#                    method = "byar"). (Byar's original, in Breslow & Day 1987, uses d and d + 1
#                    and tracks the exact limits more closely; that form is not offered.)
#   Wald             rate +/- z sqrt(d) / T, cut at 0 (shown for comparison).
#
# Two rates (exposed d1 / T1, unexposed d0 / T0):
#   Rate ratio   IRR = (d1/T1) / (d0/T0). Exact CI: condition on D = d1 + d0, then d1 is
#                Binomial(D, T1 / (T1 + T0 IRR^-1...)): a Clopper-Pearson interval for
#                p = d1/D is mapped to IRR = p/(1-p) T0/T1 (Kirkwood & Sterne 2003; same
#                as stats::poisson.test()). Mid-P conditional CI likewise. Wald (log) CI:
#                exp(ln IRR +/- z sqrt(1/d1 + 1/d0)).
#   Rate difference  RD = d1/T1 - d0/T0, Wald CI with SE sqrt(d1/T1^2 + d0/T0^2).
#   Attributable fraction among the exposed (IRR - 1)/IRR (CI from the exact IRR limits).
#   Population attributable fraction (Ipop - I0)/Ipop with Ipop = D/(T1 + T0): by the delta
#                method Var(ln(Ipop/I0)) = 1/d0 - 1/D (the covariance of the two rates is
#                included), CI = 1 - exp(-(ln(Ipop/I0) +/- z se)). Valid when the study's
#                exposed share of person-time represents the population.
#   Tests        exact conditional test (binom.test, two-sided), its mid-P version, and the
#                score z-test (d1 - D p)^2 / (D p (1 - p)), p = T1/(T1 + T0).
# epiR::epi.conf(), epiR::epi.2by2(method = "cohort.time"), stats::poisson.test() and
# stats::prop.test() are the verification oracles in tests/testthat/test-calc_analyze_rates.R.

.rate_validate_count <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 0 || x != round(x)) {
    stop(sprintf("%s must be a single non-negative whole number.", label))
  }
}
.rate_validate_time <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x <= 0) {
    stop(sprintf("%s must be a single positive number.", label))
  }
}

# Mid-P exact interval for a Poisson mean given d events (limits for the expected count).
.rate_midp_poisson <- function(d, alpha) {
  hi_bound <- 10 * (d + 1) + 50
  lo <- if (d == 0) 0 else stats::uniroot(
    function(l) stats::ppois(d, l, lower.tail = FALSE) + 0.5 * stats::dpois(d, l) - alpha / 2,
    c(1e-12, hi_bound), tol = 1e-12)$root
  hi <- stats::uniroot(
    function(l) (if (d == 0) 0 else stats::ppois(d - 1, l)) + 0.5 * stats::dpois(d, l) - alpha / 2,
    c(1e-12, hi_bound), tol = 1e-12)$root
  c(lo, hi)
}

#' Confidence intervals for one incidence rate
#'
#' @param events Number of events (a whole number, 0 or more).
#' @param person_time Person-time at risk (positive), in any unit.
#' @param multiplier Rates are reported per this many person-time units (for example 1000).
#' @param conf_level Confidence level.
calc_analyze_rate_single <- function(events, person_time, multiplier = 1000, conf_level = 0.95) {
  .rate_validate_count(events, "Events")
  .rate_validate_time(person_time, "Person-time")
  .rate_validate_time(multiplier, "The multiplier")
  .validate_unit_interval(conf_level, "Confidence level")
  alpha <- 1 - conf_level; z <- stats::qnorm(1 - alpha / 2)
  d <- events; k <- multiplier / person_time   # converts an expected count to a rate per `multiplier`

  exact <- c(if (d == 0) 0 else stats::qchisq(alpha / 2, 2 * d) / 2, stats::qchisq(1 - alpha / 2, 2 * (d + 1)) / 2)
  midp <- .rate_midp_poisson(d, alpha)
  ap <- d + 0.5  # Rothman's a + 1/2 form of Byar's cube-root approximation
  byar <- c(if (d == 0) 0 else max(0, ap * (1 - 1 / (9 * ap) - z / (3 * sqrt(ap)))^3),
            ap * (1 - 1 / (9 * ap) + z / (3 * sqrt(ap)))^3)
  wald <- pmax(0, d + c(-1, 1) * z * sqrt(d))

  new_ss_result(list(
    events = d, person_time = person_time, rate = d * k,
    exact_lower = exact[1] * k, exact_upper = exact[2] * k,
    mid_p_lower = midp[1] * k, mid_p_upper = midp[2] * k,
    byar_lower = byar[1] * k, byar_upper = byar[2] * k,
    wald_lower = wald[1] * k, wald_upper = wald[2] * k,
    multiplier = multiplier,
    inputs = list(events = d, person_time = person_time, multiplier = multiplier, conf_level = conf_level)
  ))
}

#' Compare two incidence rates (rate ratio, rate difference, attributable fractions)
#'
#' @param events_exposed,person_time_exposed Events and person-time in the exposed group.
#' @param events_unexposed,person_time_unexposed Events and person-time in the unexposed group.
#' @param multiplier Rates and the rate difference are reported per this many person-time units.
#' @param conf_level Confidence level.
calc_analyze_rate_ratio <- function(events_exposed, person_time_exposed, events_unexposed, person_time_unexposed,
                                    multiplier = 1000, conf_level = 0.95) {
  .rate_validate_count(events_exposed, "Events (exposed)")
  .rate_validate_count(events_unexposed, "Events (unexposed)")
  .rate_validate_time(person_time_exposed, "Person-time (exposed)")
  .rate_validate_time(person_time_unexposed, "Person-time (unexposed)")
  .rate_validate_time(multiplier, "The multiplier")
  .validate_unit_interval(conf_level, "Confidence level")
  d1 <- events_exposed; d0 <- events_unexposed; t1 <- person_time_exposed; t0 <- person_time_unexposed
  dd <- d1 + d0
  if (dd == 0) stop("At least one event is needed to compare two rates.")
  alpha <- 1 - conf_level; z <- stats::qnorm(1 - alpha / 2)
  k <- multiplier

  r1 <- d1 / t1; r0 <- d0 / t0
  one <- calc_analyze_rate_single
  s1 <- one(d1, t1, multiplier, conf_level); s0 <- one(d0, t0, multiplier, conf_level)

  # Rate ratio: conditional on D = d1 + d0, d1 ~ Binomial(D, p) with p = IRR T1 / (IRR T1 + T0)
  # => IRR = p/(1 - p) * T0/T1.
  to_irr <- function(p) p / (1 - p) * t0 / t1
  irr <- if (d0 > 0) r1 / r0 else NA_real_
  exact_p <- as.numeric(stats::binom.test(d1, dd, conf.level = conf_level)$conf.int)
  midp_p <- .ci_midp(d1, dd, alpha)
  exact_ci <- to_irr(exact_p); midp_ci <- to_irr(midp_p)
  wald_ci <- if (d1 > 0 && d0 > 0) exp(log(irr) + c(-1, 1) * z * sqrt(1 / d1 + 1 / d0)) else c(NA_real_, NA_real_)

  # Rate difference (Wald)
  rd <- (r1 - r0) * k
  rd_se <- sqrt(d1 / t1^2 + d0 / t0^2) * k

  # Attributable fractions
  af_e <- if (is.finite(irr) && irr > 0) (irr - 1) / irr else NA_real_
  af_ci <- (exact_ci - 1) / exact_ci
  ipop <- dd / (t1 + t0)
  paf <- (ipop - r0) / ipop
  paf_ci <- c(NA_real_, NA_real_)
  if (d0 > 0) {
    ln_ratio <- log(ipop / r0); se_ln <- sqrt(1 / d0 - 1 / dd)
    paf_ci <- 1 - exp(-(ln_ratio + c(-1, 1) * z * se_ln))
  }

  # Tests of H0: IRR = 1
  p0 <- t1 / (t1 + t0)
  exact_test <- stats::binom.test(d1, dd, p = p0)$p.value
  # mid-P two-sided: twice the smaller one-sided mid-P tail
  tail_up <- stats::pbinom(d1, dd, p0, lower.tail = FALSE) + 0.5 * stats::dbinom(d1, dd, p0)
  tail_lo <- stats::pbinom(d1 - 1, dd, p0) + 0.5 * stats::dbinom(d1, dd, p0)
  midp_test <- min(1, 2 * min(tail_up, tail_lo))
  score_chisq <- (d1 - dd * p0)^2 / (dd * p0 * (1 - p0))
  score_p <- stats::pchisq(score_chisq, 1, lower.tail = FALSE)

  new_ss_result(list(
    events_total = dd, person_time_total = t1 + t0,
    rate_exposed = r1 * k, rate_exposed_lower = s1$exact_lower, rate_exposed_upper = s1$exact_upper,
    rate_unexposed = r0 * k, rate_unexposed_lower = s0$exact_lower, rate_unexposed_upper = s0$exact_upper,
    rate_ratio = irr,
    rate_ratio_exact_lower = exact_ci[1], rate_ratio_exact_upper = exact_ci[2],
    rate_ratio_mid_p_lower = midp_ci[1], rate_ratio_mid_p_upper = midp_ci[2],
    rate_ratio_wald_lower = wald_ci[1], rate_ratio_wald_upper = wald_ci[2],
    rate_difference = rd, rate_difference_lower = rd - z * rd_se, rate_difference_upper = rd + z * rd_se,
    attributable_fraction_exposed = af_e,
    attributable_fraction_exposed_lower = af_ci[1], attributable_fraction_exposed_upper = af_ci[2],
    population_attributable_fraction = paf,
    population_attributable_fraction_lower = paf_ci[1], population_attributable_fraction_upper = paf_ci[2],
    exact_test_p = exact_test, mid_p_test_p = midp_test, score_chisq = score_chisq, score_test_p = score_p,
    multiplier = multiplier,
    inputs = list(events_exposed = d1, person_time_exposed = t1, events_unexposed = d0,
                  person_time_unexposed = t0, multiplier = multiplier, conf_level = conf_level)
  ))
}

# Display table for the single-rate methods.
analyze_rate_single_table <- function(result) {
  m <- function(label, key) data.frame(method = label, lower = result[[paste0(key, "_lower")]],
                                       upper = result[[paste0(key, "_upper")]], stringsAsFactors = FALSE)
  do.call(rbind, list(m("Exact (Garwood)", "exact"), m("Mid-P exact", "mid_p"), m("Byar approximation (a + 1/2 form)", "byar"),
                      m("Wald (not recommended)", "wald")))
}
