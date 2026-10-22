# Pure calculation function for pilot/feasibility study guidance. No Shiny
# dependency here so this is directly unit-testable (see tests/testthat).
#
# Unlike every other calc_*.R file, this is guidance, not a sample-size
# formula: there is no accepted closed-form "solve for n" method for pilot
# studies (Julious 2005's own recommendation is a fixed rule of thumb, not a
# formula). What IS closed-form, and what this wraps, is how precisely a
# given pilot n will estimate the standard deviation you'll feed into your
# main trial's sample size calculation -- the "precision about the mean and
# variance" rationale Julious cites for the 12-per-arm rule. This uses plain
# chi-squared confidence-interval theory for a normal variance (no external
# package; there's nothing to wrap).

#' Confidence interval multiplier for a variance/SD estimate at a given n
#'
#' At a chosen pilot sample size, shows how wide the confidence interval for
#' the *true* SD would be, expressed as a multiple of the pilot's own sample
#' SD (e.g. "0.71x to 1.70x your observed SD"). Illustrates why a small pilot
#' only loosely informs the variance estimate used to size the main trial.
#'
#' @param n Pilot sample size per arm (>= 2)
#' @param conf_level Confidence level (0,1), e.g. 0.95
#' @return list(lower_mult, upper_mult, inputs)
calc_pilot_sd_precision <- function(n, conf_level = 0.95) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 2 || n != round(n)) {
    stop("n must be a single whole number >= 2.")
  }
  .validate_unit_interval(conf_level, "conf_level")

  alpha <- 1 - conf_level
  df <- n - 1
  lower_mult <- sqrt(df / stats::qchisq(1 - alpha / 2, df))
  upper_mult <- sqrt(df / stats::qchisq(alpha / 2, df))

  new_ss_result(list(
    lower_mult = lower_mult,
    upper_mult = upper_mult,
    inputs = list(n = n, conf_level = conf_level)
  ))
}
