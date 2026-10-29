# Analyze from counts: outbreak investigation measures (ROADMAP Track B4, item 20): attack rates, the
# exposure-specific attack-rate table, secondary attack rate and case fatality. All are proportions, so the
# intervals reuse calc_analyze_ci_proportion() (Wald, Wilson, Clopper-Pearson, Agresti-Coull, Jeffreys, mid-P),
# and the exposure table reuses calc_analyze_2x2() (risk ratio with the Katz interval, risk difference, Fisher's
# exact test). Nothing new is estimated; what is added is the arrangement an outbreak investigation uses and the
# cautions that go with it.
#
#   Attack rate           cases / population at risk (a cumulative incidence over the outbreak period).
#   Exposure table        for each suspected exposure (food, event): attack rate among the exposed and the
#                         unexposed, risk ratio, risk difference, Fisher p and the share of all cases who were
#                         exposed. A vehicle is usually exposed by most cases and has a high risk ratio;
#                         this is a screening table: several exposures are tested at once and exposures are
#                         correlated, so p-values are descriptive.
#   Secondary attack rate secondary cases / susceptible contacts of the primary cases (primary cases and
#                         people already immune are not in the denominator). The interval treats contacts as
#                         independent; contacts within one household are not, so it is too narrow when many
#                         contacts share a household.
#   Case fatality         deaths / cases. While an outbreak is still running, some cases have not yet had time
#                         to die, so the crude ratio is biased low; the ratio among *resolved* cases,
#                         deaths / (deaths + recovered), is biased the other way early on (deaths are
#                         resolved sooner than recoveries). The app shows both and says so.
# Verification: the proportion intervals are those verified in test-calc_analyze_ci.R (against epiR, binom.test and
# prop.test); the exposure table rows equal calc_analyze_2x2() and fisher.test().

.ob_whole <- function(x, label, min = 0) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < min || x != round(x)) {
    stop(sprintf("%s must be a single whole number, %d or more.", label, as.integer(min)))
  }
}

#' Attack rate with confidence intervals
#' @param cases Number of cases.
#' @param at_risk Population at risk (>= cases).
#' @param conf_level Confidence level.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `cases`, `at_risk`, `attack_rate`, `attack_rate_per_100`, `wald_lower`, `wald_upper`, `wilson_lower`, `wilson_upper`, `exact_lower`, `exact_upper`, `agresti_coull_lower`, `agresti_coull_upper`, `jeffreys_lower`, `jeffreys_upper`, `mid_p_lower`, `mid_p_upper` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_attack_rate(30, 120)
#' @export
calc_analyze_attack_rate <- function(cases, at_risk, conf_level = 0.95) {
  .ob_whole(cases, "The number of cases"); .ob_whole(at_risk, "The population at risk", 1)
  if (cases > at_risk) stop("The number of cases cannot exceed the population at risk.")
  ci <- calc_analyze_ci_proportion(cases, at_risk, conf_level)
  out <- c(list(cases = cases, at_risk = at_risk, attack_rate = cases / at_risk,
                attack_rate_per_100 = 100 * cases / at_risk), ci[setdiff(names(ci), c("inputs", "proportion", "n_total", "successes"))])
  out$inputs <- list(cases = cases, at_risk = at_risk, conf_level = conf_level)
  new_ss_result(out)
}

#' Exposure-specific attack rates and risk ratios (food-specific attack-rate table)
#' @param exposures Matrix or data frame with one row per exposure and columns ill_exposed, total_exposed,
#'   ill_unexposed, total_unexposed.
#' @param labels Optional exposure labels.
#' @param conf_level Confidence level of the intervals reported for each exposure (default 0.95).
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_exposures`, `highest_risk_ratio`, `highest_risk_ratio_exposure` and `inputs`, the arguments the result was calculated from.
#' @examples
#' ex <- rbind(c(40, 50, 4, 30), c(25, 60, 19, 20), c(10, 12, 34, 68))   # per food: ill/total exposed, ill/total not exposed
#' calc_analyze_exposure_table(ex, labels = c("Salad", "Chicken", "Dessert"))
#' @export
calc_analyze_exposure_table <- function(exposures, labels = NULL, conf_level = 0.95) {
  m <- tryCatch(as.matrix(as.data.frame(exposures)), error = function(e) NULL)
  if (is.null(m) || ncol(m) < 4 || nrow(m) < 1) stop("Give one row per exposure with four counts: ill and total among the exposed, ill and total among the unexposed.")
  m <- m[, 1:4, drop = FALSE]; storage.mode(m) <- "double"
  if (nrow(m) > 20) stop("At most 20 exposures are supported.")
  k <- nrow(m)
  lab <- if (is.null(labels)) paste("Exposure", seq_len(k)) else as.character(labels)
  rows <- lapply(seq_len(k), function(i) {
    ie <- m[i, 1]; te <- m[i, 2]; iu <- m[i, 3]; tu <- m[i, 4]
    for (v in c(ie, te, iu, tu)) if (is.na(v) || v != round(v) || v < 0) stop(sprintf("Exposure %d: every count must be a non-negative whole number.", i))
    if (ie > te || iu > tu) stop(sprintf("Exposure %d: the number ill cannot exceed the total in the same group.", i))
    if (te < 1 || tu < 1) stop(sprintf("Exposure %d: each group (exposed, unexposed) needs at least one person.", i))
    r <- calc_analyze_2x2(ie, te - ie, iu, tu - iu, design = "cohort", conf_level = conf_level)
    data.frame(exposure = lab[i], ill_exposed = ie, total_exposed = te, attack_rate_exposed = ie / te,
               ill_unexposed = iu, total_unexposed = tu, attack_rate_unexposed = iu / tu,
               risk_ratio = r$risk_ratio, risk_ratio_lower = r$risk_ratio_lower, risk_ratio_upper = r$risk_ratio_upper,
               risk_difference = r$risk_difference, fisher_p = r$fisher_p,
               percent_of_cases_exposed = if (ie + iu > 0) 100 * ie / (ie + iu) else NA_real_, stringsAsFactors = FALSE)
  })
  tb <- do.call(rbind, rows)
  cand <- which(is.finite(tb$risk_ratio) & !is.na(tb$fisher_p))
  top <- if (length(cand)) cand[which.max(tb$risk_ratio[cand])] else NA_integer_
  out <- list(n_exposures = k, highest_risk_ratio = if (is.na(top)) NA_real_ else tb$risk_ratio[top],
              highest_risk_ratio_exposure = if (is.na(top)) NA_character_ else tb$exposure[top])
  out$inputs <- list(conf_level = conf_level)
  res <- new_ss_result(out)
  attr(res, "table") <- tb
  res
}

#' Secondary attack rate
#' @param secondary_cases Secondary cases among the contacts.
#' @param contacts Susceptible contacts exposed to the primary cases (not including the primary cases).
#' @param conf_level Confidence level of the interval for the secondary attack rate (default 0.95).
#' @return A named list of class `ss_result` (printed by `print()`) with the components `secondary_cases`, `contacts`, `secondary_attack_rate`, `secondary_attack_rate_per_100`, `wald_lower`, `wald_upper`, `wilson_lower`, `wilson_upper`, `exact_lower`, `exact_upper`, `agresti_coull_lower`, `agresti_coull_upper`, `jeffreys_lower`, `jeffreys_upper`, `mid_p_lower`, `mid_p_upper` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_secondary_attack(9, 60)
#' @export
calc_analyze_secondary_attack <- function(secondary_cases, contacts, conf_level = 0.95) {
  .ob_whole(secondary_cases, "The number of secondary cases"); .ob_whole(contacts, "The number of susceptible contacts", 1)
  if (secondary_cases > contacts) stop("Secondary cases cannot exceed the number of susceptible contacts.")
  ci <- calc_analyze_ci_proportion(secondary_cases, contacts, conf_level)
  out <- c(list(secondary_cases = secondary_cases, contacts = contacts, secondary_attack_rate = secondary_cases / contacts,
                secondary_attack_rate_per_100 = 100 * secondary_cases / contacts), ci[setdiff(names(ci), c("inputs", "proportion", "n_total", "successes"))])
  out$inputs <- list(secondary_cases = secondary_cases, contacts = contacts, conf_level = conf_level)
  new_ss_result(out)
}

#' Case fatality: crude and among resolved cases
#' @param deaths Deaths among the cases.
#' @param cases Total cases (>= deaths).
#' @param recovered Optional number recovered, to compute the ratio among resolved cases.
#' @param conf_level Confidence level of the interval for the case fatality (default 0.95).
#' @return A named list of class `ss_result` (printed by `print()`) with the components `deaths`, `cases`, `case_fatality`, `case_fatality_percent`, `crude_wald_lower`, `crude_wald_upper`, `crude_wilson_lower`, `crude_wilson_upper`, `crude_exact_lower`, `crude_exact_upper`, `crude_agresti_coull_lower`, `crude_agresti_coull_upper`, `crude_jeffreys_lower`, `crude_jeffreys_upper`, `crude_mid_p_lower`, `crude_mid_p_upper` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_case_fatality(6, 80)
#' @export
calc_analyze_case_fatality <- function(deaths, cases, recovered = NULL, conf_level = 0.95) {
  .ob_whole(deaths, "The number of deaths"); .ob_whole(cases, "The number of cases", 1)
  if (deaths > cases) stop("Deaths cannot exceed the number of cases.")
  crude <- calc_analyze_ci_proportion(deaths, cases, conf_level)
  out <- c(list(deaths = deaths, cases = cases, case_fatality = deaths / cases, case_fatality_percent = 100 * deaths / cases),
           setNames(crude[grep("_(lower|upper)$", names(crude))], paste0("crude_", grep("_(lower|upper)$", names(crude), value = TRUE))))
  if (!is.null(recovered) && !is.na(recovered)) {
    .ob_whole(recovered, "The number recovered")
    if (deaths + recovered > cases) stop("Deaths plus recovered cannot exceed the number of cases.")
    out$recovered <- recovered
    out$unresolved <- cases - deaths - recovered
    if (deaths + recovered >= 1) {
      res <- calc_analyze_ci_proportion(deaths, deaths + recovered, conf_level)
      out$case_fatality_resolved <- deaths / (deaths + recovered)
      out <- c(out, setNames(res[grep("_(lower|upper)$", names(res))], paste0("resolved_", grep("_(lower|upper)$", names(res), value = TRUE))))
    }
  }
  out$inputs <- list(deaths = deaths, cases = cases, recovered = if (is.null(recovered)) NA else recovered, conf_level = conf_level)
  new_ss_result(out)
}
