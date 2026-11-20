# Analyze from summary counts: vaccine efficacy / effectiveness (ROADMAP Track B1, item 13,
# slice 9).
#
#   VE = 1 - RR = (ARU - ARV) / ARU      Orenstein WA, Bernier RH, Dondero TJ, et al.
#                                         Field evaluation of vaccine efficacy. Bull World
#                                         Health Organ 1985;63:1055-1068
# where RR is the ratio of the disease occurrence in the vaccinated to that in the
# unvaccinated group. The confidence interval of VE is 1 minus the interval of the ratio
# (the limits swap), so every ratio method of the app carries over unchanged:
#   "risk"  cases / participants   RR = risk ratio: Koopman score, Katz log, adjusted log
#                                  (calc_analyze_compare_proportions)
#   "rate"  cases / person-time    RR = incidence rate ratio: exact conditional, mid-P, Wald
#                                  (calc_analyze_rate_ratio)
#   "odds"  case-control (also the test-negative design): RR is replaced by the exposure odds
#           ratio OR = (a/b)/(c/d), a = vaccinated cases, b = unvaccinated cases,
#           c = vaccinated controls, d = unvaccinated controls: Woolf and conditional exact
#           (calc_analyze_compare_proportions). VE = 1 - OR estimates 1 - RR when controls
#           represent the source population (the OR approximates the RR for a rare disease or
#           with density sampling) -- the app states this.
# Efficacy (trial, ideal conditions) and effectiveness (observational, routine use) use the
# same arithmetic; the interpretation, not the formula, differs. Adjusted effectiveness from a
# regression model is outside this tool. No bias correction for waning, misclassification or
# confounding is applied.
# Verified: VE limits equal 1 - the limits of the ratio tools; the point estimate and the
# interval limits are checked against the definitions and against epiR::epi.2by2() in
# tests/testthat/test-calc_analyze_vaccine.R.

#' Vaccine efficacy (1 - relative risk) with confidence intervals
#'
#' @param design "risk" (cases and participants), "rate" (cases and person-time) or "odds"
#'   (case-control: vaccinated and unvaccinated cases and controls).
#' @param cases_vaccinated,cases_unvaccinated Cases ("risk", "rate") or vaccinated / unvaccinated cases ("odds").
#' @param n_vaccinated,n_unvaccinated Participants ("risk") or person-time ("rate").
#' @param controls_vaccinated,controls_unvaccinated Controls ("odds" only).
#' @param conf_level Confidence level.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `design`, `ratio`, `ve`, `ve_koopman_lower`, `ve_koopman_upper`, `ve_katz_lower`, `ve_katz_upper`, `ve_adjusted_log_lower`, `ve_adjusted_log_upper`, `attack_rate_vaccinated`, `attack_rate_unvaccinated`, `risk_difference`, `test_p` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_vaccine_efficacy("risk", 8, 160, 1000, 1000)
#' @export
calc_analyze_vaccine_efficacy <- function(design = c("risk", "rate", "odds"),
                                          cases_vaccinated, cases_unvaccinated,
                                          n_vaccinated = NULL, n_unvaccinated = NULL,
                                          controls_vaccinated = NULL, controls_unvaccinated = NULL,
                                          conf_level = 0.95) {
  design <- match.arg(design)
  .validate_unit_interval(conf_level, "Confidence level")
  if (design == "odds" && (is.null(controls_vaccinated) || is.null(controls_unvaccinated))) {
    stop("Give the numbers of vaccinated and unvaccinated controls.")
  }
  if (design != "odds" && (is.null(n_vaccinated) || is.null(n_unvaccinated))) {
    stop(if (design == "risk") "Give the number of participants in each group." else "Give the person-time in each group.")
  }
  flip <- function(lo, hi) c(1 - hi, 1 - lo)
  out <- list()
  add <- function(key, lo, hi) {
    ci <- flip(lo, hi)
    out[[paste0(key, "_lower")]] <<- ci[1]; out[[paste0(key, "_upper")]] <<- ci[2]
  }
  if (design == "risk") {
    r <- calc_analyze_compare_proportions(cases_vaccinated, n_vaccinated, cases_unvaccinated, n_unvaccinated, conf_level)
    ratio <- r$risk_ratio
    for (m in c("koopman", "katz", "adjusted_log")) add(paste0("ve_", m), r[[paste0("ratio_", m, "_lower")]], r[[paste0("ratio_", m, "_upper")]])
    out$attack_rate_vaccinated <- r$proportion_1; out$attack_rate_unvaccinated <- r$proportion_2
    out$risk_difference <- r$risk_difference
    p <- r$fisher_p
  } else if (design == "rate") {
    r <- calc_analyze_rate_ratio(cases_vaccinated, n_vaccinated, cases_unvaccinated, n_unvaccinated, multiplier = 1, conf_level = conf_level)
    ratio <- r$rate_ratio
    add("ve_exact", r$rate_ratio_exact_lower, r$rate_ratio_exact_upper)
    add("ve_mid_p", r$rate_ratio_mid_p_lower, r$rate_ratio_mid_p_upper)
    add("ve_wald", r$rate_ratio_wald_lower, r$rate_ratio_wald_upper)
    out$rate_vaccinated <- r$rate_exposed; out$rate_unvaccinated <- r$rate_unexposed
    p <- r$exact_test_p
  } else {
    r <- calc_analyze_compare_proportions(cases_vaccinated, cases_vaccinated + cases_unvaccinated,
                                          controls_vaccinated, controls_vaccinated + controls_unvaccinated, conf_level)
    ratio <- r$odds_ratio
    add("ve_woolf", r$odds_ratio_woolf_lower, r$odds_ratio_woolf_upper)
    add("ve_exact", r$odds_ratio_exact_lower, r$odds_ratio_exact_upper)
    out$odds_ratio_conditional <- r$odds_ratio_conditional
    p <- r$fisher_p
  }
  ve <- if (is.finite(ratio)) 1 - ratio else NA_real_
  if (design == "odds") out$ve_conditional <- 1 - r$odds_ratio_conditional
  out$test_p <- p
  inputs <- Filter(Negate(is.null), list(
    design = design, cases_vaccinated = cases_vaccinated, cases_unvaccinated = cases_unvaccinated,
    n_vaccinated = n_vaccinated, n_unvaccinated = n_unvaccinated,
    controls_vaccinated = controls_vaccinated, controls_unvaccinated = controls_unvaccinated, conf_level = conf_level))
  new_ss_result(c(list(design = design, ratio = ratio, ve = ve), out, list(inputs = inputs)))
}

# Display table: one row per interval method, VE as a percentage.
analyze_vaccine_table <- function(result) {
  d <- result$design
  m <- function(label, key, note, est = result$ve) {
    data.frame(method = label, estimate = est, lower = result[[paste0(key, "_lower")]],
               upper = result[[paste0(key, "_upper")]], note = note, stringsAsFactors = FALSE)
  }
  rows <- switch(d,
    risk = list(m("Koopman score (on the risk ratio)", "ve_koopman", "recommended"),
                m("Adjusted log, +1/2 (on the risk ratio)", "ve_adjusted_log", "defined when a count is zero"),
                m("Katz log (on the risk ratio)", "ve_katz", "poor for small samples")),
    rate = list(m("Exact conditional (on the rate ratio)", "ve_exact", "usual default; conservative"),
                m("Mid-P exact", "ve_mid_p", "less conservative"),
                m("Wald log", "ve_wald", "for comparison; poor for few cases")),
    odds = list(m("Woolf log (on the odds ratio)", "ve_woolf", "poor for small counts"),
                m("Conditional exact (Fisher)", "ve_exact", "conservative; estimate is the conditional MLE", est = result$ve_conditional)))
  do.call(rbind, rows)
}
