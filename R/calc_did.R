# Pure calculation for a difference-in-differences (controlled before-after) study with repeated measures of a continuous
# outcome on each unit: units needed, or power. No Shiny dependency (tests/testthat/test-calc_did.R).
#
# Source, read in full (PubMed Central PMC6663085, CC BY; the equations from the article's MathML): Hu Y, Hoover DR. Simple power
# and sample size estimation for non-randomized longitudinal difference in differences studies. J Biom Biostat 2018;9(5):415.
# Model (its equation 2): an arm effect, a common effect of each time point, and an immediate, lasting jump theta in the
# intervention arm after the start; b measures before and k after on every unit; compound-symmetry correlation rho between a
# unit's measures. Variance of the estimated effect (its equation 6):
#   Var(theta_hat) = (1/n0 + 1/n1) (1/b + 1/k) (1 - rho) sigma^2
# The same variance follows directly: one unit's (post mean - pre mean) has variance sigma^2 (1 - rho)(1/b + 1/k).
#
# NOTE on the source: its equation 7 and its worked example print n = (1/b + 1/k)(1 - rho)(z + z)^2 / delta^2 for n0 = n1 = n,
# which lacks the factor 2 that equation 6 gives with 1/n0 + 1/n1 = 2/n. A simulation here (20 000 runs each) agrees with
# equation 6: the paper's example (b = 1, k = 3, rho = 0.55, delta = 0.5) with its 19 units per arm has 49% power, and 38 per arm
# are needed for 80%. This file uses equation 6. Power is from the noncentral t distribution on n0 + n1 - 2 degrees of freedom
# (the analysis of each unit's post-minus-pre mean by a two-sample t-test), which the simulation matches to within 0.012.

.did_power <- function(n1, n0, delta, sd, rho, n_pre, n_post, alpha) {
  se <- sd * sqrt((1 / n0 + 1 / n1) * (1 / n_pre + 1 / n_post) * (1 - rho))
  df <- n0 + n1 - 2
  tcrit <- stats::qt(1 - alpha / 2, df)
  ncp <- abs(delta) / se
  list(power = stats::pt(tcrit, df, ncp = ncp, lower.tail = FALSE) + stats::pt(-tcrit, df, ncp = ncp), se = se, df = df)
}

#' Difference-in-differences (controlled before-after) study with repeated measures
#'
#' Number of units (people, facilities, districts) needed in the intervention and the comparison group, or the power with the
#' units available, to detect an effect by difference-in-differences when a continuous outcome is measured on every unit at
#' several time points before and after the intervention starts (Hu & Hoover 2018, equation 6).
#'
#' @param delta Effect to detect, in the units of the outcome: the change in the intervention group beyond the change in the
#'   comparison group (not 0).
#' @param sd Standard deviation of the outcome between units at one time point (greater than 0).
#' @param rho Correlation between two measurements of the same unit at different time points (compound symmetry), at least 0
#'   and below 1.
#' @param n_pre Number of time points before the intervention starts (whole number, at least 1).
#' @param n_post Number of time points after it starts (whole number, at least 1).
#' @param ratio Comparison units per intervention unit (greater than 0; default 1).
#' @param alpha Significance level, two-sided, strictly between 0 and 1.
#' @param power Desired power, strictly between 0 and 1 (ignored when `n_intervention` is given).
#' @param n_intervention Optional number of intervention units; when given, the power with that many (and `ratio` times as many
#'   comparison units) is returned instead of the sample size.
#' @return A named list of class `ss_result` with the components `n_total`, `n_intervention`, `n_comparison`, `achieved_power`,
#'   `se` (standard error of the effect), `df` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_did(delta = 0.5, sd = 1, rho = 0.55, n_pre = 1, n_post = 3)
#' calc_did(delta = 0.5, rho = 0.55, n_pre = 2, n_post = 2, n_intervention = 30)$achieved_power
#' @export
calc_did <- function(delta, sd = 1, rho, n_pre = 1, n_post = 1, ratio = 1, alpha = 0.05, power = 0.8, n_intervention = NULL) {
  .validate_number(delta, "delta")
  if (isTRUE(all.equal(delta, 0))) stop("delta must differ from 0 (no effect to detect).")
  .validate_positive(sd, "sd")
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || rho < 0 || rho >= 1) stop("rho must be a single number of at least 0 and below 1.")
  for (nm in c("n_pre", "n_post")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || v < 1 || v != round(v)) stop(nm, " must be a whole number of at least 1.")
  }
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  at <- function(n1) .did_power(n1, max(2, ceiling(n1 * ratio)), delta, sd, rho, n_pre, n_post, alpha)
  if (is.null(n_intervention)) {
    .validate_unit_interval(power, "power")
    hi <- 2
    while (at(hi)$power < power) { hi <- hi * 2; if (hi > 1e7) stop("The sample size exceeds 10 million units; check the inputs.") }
    lo <- max(hi %/% 2, 2)
    while (hi - lo > 1) { mid <- (lo + hi) %/% 2; if (at(mid)$power >= power) hi <- mid else lo <- mid }
    if (at(lo)$power >= power) hi <- lo
    n_intervention <- hi
  } else {
    if (!is.numeric(n_intervention) || length(n_intervention) != 1 || is.na(n_intervention) || n_intervention < 2) {
      stop("n_intervention must be a single number of at least 2.")
    }
  }
  res <- at(n_intervention)
  n_comparison <- max(2, ceiling(n_intervention * ratio))
  new_ss_result(list(
    n_total = n_intervention + n_comparison, n_intervention = n_intervention, n_comparison = n_comparison,
    achieved_power = res$power, se = res$se, df = res$df,
    inputs = list(delta = delta, sd = sd, rho = rho, n_pre = n_pre, n_post = n_post, ratio = ratio, alpha = alpha, power = power)
  ))
}
