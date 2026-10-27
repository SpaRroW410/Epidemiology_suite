# Pure calculation function for the general linear model F-test, applied
# to factorial ANOVA (main effects and interactions) and ANCOVA. No Shiny
# dependency here so this is directly unit-testable (see tests/testthat).
# Wraps pwr::pwr.f2.test() rather than reimplementing the underlying math
# (project convention) -- this is the SAME general F-test engine already
# used by the Multiple Regression module (calc_regression.R), since Cohen
# (1988) treats ANOVA/ANCOVA (his Chapter 8) and multiple regression (his
# Chapter 9) as the same "F tests" family sharing one noncentral-F-based
# formula, differing only in what the numerator/denominator degrees of
# freedom represent. G*Power organizes its own "F tests" family the same
# way (docs/checklist_by_design.md's own scope-framing note).

#' Sample size for a factorial ANOVA effect (main effect or interaction)
#' or an ANCOVA effect, via the general linear model F-test
#'
#' The user supplies the numerator degrees of freedom for the specific
#' effect being tested (e.g. u = (a-1) for a main effect with a levels;
#' u = (a-1)(b-1) for an a x b interaction; u = (a-1) for an ANCOVA group
#' effect, same as a one-way ANOVA with that many groups) and an effect
#' size, either as Cohen's f-squared directly or as a partial eta-squared
#' (converted via f2 = eta2 / (1 - eta2)).
#'
#' @param u Numerator degrees of freedom for the effect being tested
#'   (whole number >= 1)
#' @param effect_size Effect size value, interpreted per effect_size_type
#' @param effect_size_type "f2" (Cohen's f-squared directly) or "eta2"
#'   (partial eta-squared, converted to f2)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_total, v, f2, inputs)
calc_anova_general <- function(u, effect_size, effect_size_type = c("f2", "eta2"),
                                alpha = 0.05, power = 0.8) {
  effect_size_type <- match.arg(effect_size_type)

  if (!is.numeric(u) || length(u) != 1 || is.na(u) || u < 1 || u != round(u)) {
    stop("u (numerator df) must be a single whole number >= 1.")
  }
  .validate_positive(effect_size, "effect_size")
  if (effect_size_type == "eta2" && effect_size >= 1) {
    stop("effect_size must be a single number strictly between 0 and 1 when effect_size_type is 'eta2'.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  f2 <- if (effect_size_type == "eta2") effect_size / (1 - effect_size) else effect_size

  fit <- .cf_pwr_f2_test(u = u, v = NULL, f2 = f2, sig.level = alpha, power = power)
  v <- ceiling(fit$v)
  n_total <- v + u + 1

  new_ss_result(list(
    n_total = n_total,
    v = v,
    f2 = f2,
    inputs = list(u = u, effect_size = effect_size, effect_size_type = effect_size_type,
                  alpha = alpha, power = power)
  ))
}
