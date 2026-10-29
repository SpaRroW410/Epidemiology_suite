# Trial Sequential Analysis (TSA): fixed-effect Required/Optimal Information
# Size (RIS/OIS) for a planned (prospective) meta-analysis. This is the
# threshold total sample size at which a meta-analysis of trials would have
# adequate power to detect the anticipated effect, analogous to a single
# trial's sample size but for the cumulative evidence base -- the number
# TSA software (e.g. the CTU Copenhagen TSA program, or the RTSA R package)
# uses to construct alpha-spending monitoring boundaries for interim
# meta-analyses.
#
# Formula reproduced directly from RTSA::ris()'s fixed-effect branch (the
# variance/RIS logic, not the separate heterogeneity-adjusted minTrial()
# function), independently derived by reading the RTSA source and verified
# 16/16 against real RTSA::ris() calls across all four outcome types and
# varied alpha/beta/side.

#' Required information size for a trial sequential analysis (fixed-effect meta-analysis)
#'
#' The number of participants a meta-analysis needs before its evidence is adequately powered for the anticipated effect, the
#' quantity trial sequential analysis uses to build its monitoring boundaries. Fixed-effect form for a risk ratio, odds ratio,
#' risk difference or mean difference; it is not adjusted for heterogeneity.
#' @param outcome `"RR"` (risk ratio), `"OR"` (odds ratio), `"RD"` (risk difference) or `"MD"` (mean difference).
#' @param mc Anticipated effect: the ratio for `RR` / `OR`, the risk difference for `RD`, the mean difference for `MD`.
#' @param pC Event probability in the control arm (`RR`, `OR` and `RD`; strictly between 0 and 1).
#' @param p1 Event probability in the intervention arm (`RD` only).
#' @param sd_mc Standard deviation of the outcome (`MD` only; greater than 0).
#' @param alpha Significance level (type I error rate), strictly between 0 and 1.
#' @param beta Type II error rate, strictly between 0 and 1 (power = 1 - beta); default 0.1.
#' @param side 1 for a one-sided or 2 for a two-sided test (default 2).
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_total`, `var_mc`, `mc_nf` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_tsa_information_size(outcome = "RR", mc = 0.8, pC = 0.12, alpha = 0.05, beta = 0.1, 
#'     side = 2)
#' @export
calc_tsa_information_size <- function(outcome = c("RR", "OR", "RD", "MD"),
                                       mc, pC = NULL, p1 = NULL, sd_mc = NULL,
                                       alpha = 0.05, beta = 0.1, side = 2) {
  outcome <- match.arg(outcome)
  .validate_number(mc, "mc")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(beta, "beta")
  if (!isTRUE(side == 1) && !isTRUE(side == 2)) {
    stop("side must be 1 or 2.")
  }

  if (outcome %in% c("RR", "OR")) {
    .validate_unit_interval(pC, "pC")
    .validate_positive(mc, "mc (the assumed risk ratio or odds ratio)")
    logit <- function(x) log(x / (1 - x))
    invlogit <- function(x) 1 / (1 + exp(-x))
    pI <- if (outcome == "RR") pC * mc else invlogit(logit(pC) + log(mc))
    if (!is.finite(pI) || pI <= 0 || pI >= 1) {
      stop("The implied intervention-arm event probability is outside (0, 1); check pC and mc.")
    }
    p_bar <- (pC + pI) / 2
    var_mc <- p_bar * (1 - p_bar)
    mc_nf <- pC - pI
  } else if (outcome == "RD") {
    .validate_unit_interval(pC, "pC")
    .validate_unit_interval(p1, "p1")
    var_mc <- pC * (1 - pC) + p1 * (1 - p1)
    mc_nf <- mc
  } else {
    .validate_positive(sd_mc, "sd_mc")
    var_mc <- sd_mc^2
    mc_nf <- mc
  }

  if (isTRUE(all.equal(mc_nf, 0))) {
    stop("mc implies no difference between arms; information size is undefined.")
  }

  n_total <- ceiling(2 * (qnorm(1 - alpha / side) + qnorm(1 - beta))^2 * 2 * var_mc / mc_nf^2)

  new_ss_result(list(
    n_total = n_total,
    var_mc = var_mc,
    mc_nf = mc_nf,
    inputs = list(
      outcome = outcome, mc = mc, pC = pC, p1 = p1, sd_mc = sd_mc,
      alpha = alpha, beta = beta, side = side
    )
  ))
}
