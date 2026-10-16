# Analyze from summary counts: direct and indirect standardization (ROADMAP Track
# B1, item 13).
#
# DIRECT standardization. A study group has d_i events and T_i person-time (or
# population) in each of g strata (age bands...); a standard population supplies
# weights w_i = std_i / sum(std). The directly standardized rate is
#     DSR = sum_i w_i d_i / T_i,        Var(DSR) = v = sum_i w_i^2 d_i / T_i^2.
# Confidence interval: the gamma method of Fay MP, Feuer EJ. Stat Med 1997;16:791-801 --
#     lower = Gamma quantile(alpha/2; shape = DSR^2/v, scale = v/DSR),
#     upper = Gamma quantile(1 - alpha/2; shape = (DSR + wm)^2/(v + wm^2), scale = (v + wm^2)/(DSR + wm)),
# with wm = max_i (w_i / T_i) (as implemented in epiR::epi.directadj()). Two groups are compared
# by the ratio and difference of their DSRs on the normal scale: SE(ln ratio) = sqrt(vA/DSRA^2 +
# vB/DSRB^2), SE(difference) = sqrt(vA + vB) -- derived here by the delta method and checked by
# simulation, not taken from a cited source.
#
# INDIRECT standardization. The study group's person-time T_i in each stratum is multiplied by
# reference (standard) stratum rates r_i to give the expected number of events E = sum_i r_i T_i;
# with O observed events SMR = O / E. Interval: exact (Garwood; Ulm K. Am J Epidemiol
# 1990;131:373-375) and mid-P, treating E as fixed and O as Poisson; test of SMR = 1 by the exact
# Poisson test (Breslow NE, Day NE. Statistical Methods in Cancer Research, Vol II, IARC 1987).
#
# epiR::epi.directadj() and stats::poisson.test() are the verification oracles in
# tests/testthat/test-calc_analyze_standardization.R.

.std_validate_strata <- function(events, person_time, g_min = 2, g_max = 20) {
  g <- length(events)
  if (g < g_min || g > g_max) stop(sprintf("Use between %d and %d strata.", g_min, g_max))
  if (length(person_time) != g) stop("Events and person-time must be given for the same strata.")
  for (i in seq_len(g)) {
    .rate_validate_count(events[i], sprintf("Events in stratum %d", i))
    if (!is.numeric(person_time[i]) || is.na(person_time[i]) || !is.finite(person_time[i]) || person_time[i] < 0) {
      stop(sprintf("Person-time in stratum %d must be a non-negative number.", i))
    }
    if (events[i] > 0 && person_time[i] == 0) stop(sprintf("Stratum %d has events but no person-time.", i))
  }
  g
}

# Directly standardized rate of one group (per unit of person-time; scale afterwards).
.std_dsr <- function(events, person_time, weights, alpha) {
  if (any(weights > 0 & person_time == 0)) {
    stop("A stratum with a non-zero standard weight has no person-time: the rate cannot be standardized there.")
  }
  rate <- ifelse(person_time > 0, events / person_time, 0)
  dsr <- sum(weights * rate)
  v <- sum(ifelse(person_time > 0, weights^2 * events / person_time^2, 0))
  wm <- max(ifelse(person_time > 0, weights / person_time, 0))
  lo <- if (dsr > 0 && v > 0) stats::qgamma(alpha / 2, shape = dsr^2 / v, scale = v / dsr) else 0
  hi <- stats::qgamma(1 - alpha / 2, shape = (dsr + wm)^2 / (v + wm^2), scale = (v + wm^2) / (dsr + wm))
  list(dsr = dsr, v = v, lower = lo, upper = hi)
}

#' Directly standardized rate of one group (or two groups compared)
#'
#' @param events,person_time Events and person-time (or population) per stratum for the study group.
#' @param standard Standard population size per stratum (only the proportions matter).
#' @param events_b,person_time_b Optional second group over the same strata, to compare the two.
#' @param multiplier Rates are reported per this many units of person-time.
#' @param conf_level Confidence level.
calc_analyze_dsr <- function(events, person_time, standard, events_b = NULL, person_time_b = NULL,
                             multiplier = 1000, conf_level = 0.95) {
  g <- .std_validate_strata(events, person_time)
  if (length(standard) != g || any(!is.numeric(standard)) || any(is.na(standard)) || any(standard < 0) || sum(standard) <= 0) {
    stop("The standard population must be non-negative numbers, one per stratum, with a positive total.")
  }
  .rate_validate_time(multiplier, "The multiplier")
  .validate_unit_interval(conf_level, "Confidence level")
  two <- !is.null(events_b) || !is.null(person_time_b)
  if (two) {
    if (is.null(events_b) || is.null(person_time_b)) stop("Give both events and person-time for the second group.")
    .std_validate_strata(events_b, person_time_b)
    if (length(events_b) != g) stop("Both groups must have the same strata.")
  }
  alpha <- 1 - conf_level; z <- stats::qnorm(1 - alpha / 2)
  w <- standard / sum(standard); k <- multiplier

  one <- function(d, t, prefix) {
    a <- .std_dsr(d, t, w, alpha)
    crude <- calc_analyze_rate_single(sum(d), sum(t), multiplier, conf_level)
    out <- list()
    out[[paste0(prefix, "events")]] <- sum(d); out[[paste0(prefix, "person_time")]] <- sum(t)
    out[[paste0(prefix, "crude_rate")]] <- crude$rate
    out[[paste0(prefix, "crude_rate_lower")]] <- crude$exact_lower; out[[paste0(prefix, "crude_rate_upper")]] <- crude$exact_upper
    out[[paste0(prefix, "standardized_rate")]] <- a$dsr * k
    out[[paste0(prefix, "standardized_rate_lower")]] <- a$lower * k; out[[paste0(prefix, "standardized_rate_upper")]] <- a$upper * k
    list(fields = out, a = a)
  }
  ra <- one(events, person_time, "")
  res <- c(list(strata = g), ra$fields)
  if (two) {
    rb <- one(events_b, person_time_b, "b_")
    res <- c(res, rb$fields)
    da <- ra$a$dsr; db <- rb$a$dsr; va <- ra$a$v; vb <- rb$a$v
    ratio <- if (db > 0) da / db else NA_real_
    ratio_ci <- c(NA_real_, NA_real_); ratio_p <- NA_real_
    if (da > 0 && db > 0) {
      se <- sqrt(va / da^2 + vb / db^2)
      ratio_ci <- exp(log(ratio) + c(-1, 1) * z * se)
      ratio_p <- 2 * stats::pnorm(-abs(log(ratio) / se))
    }
    sd_diff <- sqrt(va + vb)
    res$standardized_rate_ratio <- ratio
    res$standardized_rate_ratio_lower <- ratio_ci[1]; res$standardized_rate_ratio_upper <- ratio_ci[2]
    res$standardized_rate_ratio_p <- ratio_p
    res$standardized_rate_difference <- (da - db) * k
    res$standardized_rate_difference_lower <- (da - db - z * sd_diff) * k
    res$standardized_rate_difference_upper <- (da - db + z * sd_diff) * k
  }
  res$multiplier <- multiplier
  res$inputs <- list(events = paste(events, collapse = ","), person_time = paste(person_time, collapse = ","),
                     standard = paste(standard, collapse = ","),
                     events_b = if (two) paste(events_b, collapse = ",") else NA,
                     person_time_b = if (two) paste(person_time_b, collapse = ",") else NA,
                     multiplier = multiplier, conf_level = conf_level)
  new_ss_result(res)
}

# Stratum-by-stratum table for display (rate, weight and contribution), group A only.
analyze_dsr_strata_table <- function(events, person_time, standard, multiplier = 1000) {
  w <- standard / sum(standard)
  rate <- ifelse(person_time > 0, events / person_time, NA_real_)
  data.frame(stratum = seq_along(events), events = events, person_time = person_time,
             rate = rate * multiplier, standard_weight = w, contribution = w * ifelse(is.na(rate), 0, rate) * multiplier)
}

#' Standardized mortality (morbidity) ratio from observed and expected events
#'
#' @param observed Observed number of events (a whole number).
#' @param expected Expected number of events (positive), e.g. from reference rates.
#' @param conf_level Confidence level.
calc_analyze_smr <- function(observed, expected, conf_level = 0.95) {
  .rate_validate_count(observed, "Observed events")
  .rate_validate_time(expected, "Expected events")
  .validate_unit_interval(conf_level, "Confidence level")
  alpha <- 1 - conf_level
  exact <- c(if (observed == 0) 0 else stats::qchisq(alpha / 2, 2 * observed) / 2,
             stats::qchisq(1 - alpha / 2, 2 * (observed + 1)) / 2) / expected
  midp <- .rate_midp_poisson(observed, alpha) / expected
  exact_p <- stats::poisson.test(observed, expected)$p.value
  # mid-P two-sided: twice the smaller one-sided mid-P tail
  up <- stats::ppois(observed, expected, lower.tail = FALSE) + 0.5 * stats::dpois(observed, expected)
  lo <- (if (observed == 0) 0 else stats::ppois(observed - 1, expected)) + 0.5 * stats::dpois(observed, expected)
  new_ss_result(list(
    observed = observed, expected = expected, smr = observed / expected,
    smr_exact_lower = exact[1], smr_exact_upper = exact[2],
    smr_mid_p_lower = midp[1], smr_mid_p_upper = midp[2],
    exact_test_p = exact_p, mid_p_test_p = min(1, 2 * min(up, lo)),
    inputs = list(observed = observed, expected = expected, conf_level = conf_level)
  ))
}

#' Indirect standardization: expected events from reference rates, then the SMR
#'
#' @param person_time Person-time (or population) of the study group per stratum.
#' @param reference_rates Reference (standard) rates per stratum, per `multiplier` units of person-time.
#' @param observed Total observed events in the study group.
#' @param multiplier The unit the reference rates are expressed in.
#' @param conf_level Confidence level.
calc_analyze_indirect <- function(person_time, reference_rates, observed, multiplier = 1000, conf_level = 0.95) {
  g <- length(person_time)
  if (g < 2 || g > 20) stop("Use between 2 and 20 strata.")
  if (length(reference_rates) != g) stop("Give a reference rate for every stratum.")
  for (i in seq_len(g)) {
    if (!is.numeric(person_time[i]) || is.na(person_time[i]) || !is.finite(person_time[i]) || person_time[i] < 0) {
      stop(sprintf("Person-time in stratum %d must be a non-negative number.", i))
    }
    if (!is.numeric(reference_rates[i]) || is.na(reference_rates[i]) || !is.finite(reference_rates[i]) || reference_rates[i] < 0) {
      stop(sprintf("The reference rate in stratum %d must be a non-negative number.", i))
    }
  }
  .rate_validate_time(multiplier, "The multiplier")
  expected_by_stratum <- reference_rates / multiplier * person_time
  e <- sum(expected_by_stratum)
  if (e <= 0) stop("The expected number of events is zero: check the reference rates and person-time.")
  r <- calc_analyze_smr(observed, e, conf_level)
  r$expected_by_stratum <- NULL
  r$strata <- g; r$multiplier <- multiplier
  r$inputs <- c(r$inputs, list(person_time = paste(person_time, collapse = ","),
                               reference_rates = paste(reference_rates, collapse = ","), multiplier = multiplier))
  r
}
