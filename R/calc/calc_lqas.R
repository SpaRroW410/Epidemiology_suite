# Pure calculation functions for Lot Quality Assurance Sampling (LQAS)
# sample size. No Shiny dependency here so these are directly
# unit-testable (see tests/testthat).

#' Sample size for a Lot Quality Assurance Sampling (LQAS) survey
#'
#' Finds the smallest sample size n and decision threshold d (accept the
#' "lot"/area as high-performing if X >= d successes are observed out of n)
#' such that both classification-error risks are controlled: the
#' probability of misclassifying a truly high-performing area (indicator
#' proportion = p_upper) as low-performing is at most alpha, and the
#' probability of misclassifying a truly low-performing area (indicator
#' proportion = p_lower) as high-performing is at most beta. This is the
#' standard binomial operating-characteristic-curve construction used
#' throughout the LQAS literature (Robertson & Valadez 2006; originally
#' from classical acceptance sampling). No R package implements this
#' (confirmed not installed / not on the reachable CRAN mirror), but the
#' method is a direct, exact application of the binomial CDF, so it is
#' implemented directly with base R's pbinom() rather than approximated.
#'
#' Verified against a real published worked example (the widely-used
#' "n=19" LQAS rule for a 50%/80% coverage threshold pair): at
#' alpha=beta=0.10 this search recovers exactly n=19, d=13, matching the
#' published rule's own reported classification-error figures (~6.8% and
#' ~8.4%, total ~15%, "below 20%") -- see tests/testthat/test-calc_lqas.R.
#'
#' @param p_upper Indicator proportion defining an acceptable/high-performing
#'   area (0,1); must exceed p_lower
#' @param p_lower Indicator proportion defining an unacceptable/low-performing
#'   area (0,1)
#' @param alpha Producer's risk: max acceptable probability of classifying a
#'   truly high-performing area (at p_upper) as low-performing; default 0.10
#' @param beta Consumer's risk: max acceptable probability of classifying a
#'   truly low-performing area (at p_lower) as high-performing; default 0.10
#' @param n_max Upper search bound on n; default 2000
#' @return list(n, d, alpha_achieved, beta_achieved, inputs)
calc_lqas <- function(p_upper, p_lower, alpha = 0.10, beta = 0.10, n_max = 2000) {
  .validate_unit_interval(p_upper, "p_upper")
  .validate_unit_interval(p_lower, "p_lower")
  if (p_upper <= p_lower) stop("p_upper must be strictly greater than p_lower.")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(beta, "beta")
  if (!is.numeric(n_max) || length(n_max) != 1 || is.na(n_max) || n_max < 2) {
    stop("n_max must be a single number >= 2.")
  }

  for (n in 2:n_max) {
    ds <- 1:n
    alpha_d <- pbinom(ds - 1, n, p_upper)      # P(X < d | p = p_upper)
    beta_d <- 1 - pbinom(ds - 1, n, p_lower)   # P(X >= d | p = p_lower)
    valid <- which(alpha_d <= alpha & beta_d <= beta)
    if (length(valid) > 0) {
      best <- valid[which.min(alpha_d[valid] + beta_d[valid])]
      return(list(
        n = n, d = ds[best],
        alpha_achieved = alpha_d[best], beta_achieved = beta_d[best],
        inputs = list(p_upper = p_upper, p_lower = p_lower, alpha = alpha, beta = beta)
      ))
    }
  }
  stop(sprintf("No feasible sample size found up to n_max=%d (thresholds likely too close together).", n_max))
}
