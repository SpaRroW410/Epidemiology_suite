# Pure calculation function for Simon's two-stage Phase II design. No Shiny
# dependency here so this is directly unit-testable (see tests/testthat).
# Wraps clinfun::ph2simon() (the standard reference implementation of Simon
# 1989) rather than reimplementing the underlying search (project convention).

#' Simon's optimal and minimax two-stage Phase II designs
#'
#' Wraps clinfun::ph2simon(). Returns both the "minimax" design (smallest
#' maximum sample size n) and the "optimal" design (smallest expected sample
#' size under the unacceptable response rate, EN(pu)) -- these are usually
#' different designs, and the choice between them is a judgment call (fewer
#' patients if the drug turns out ineffective, vs. a smaller worst-case
#' trial).
#'
#' @param pu Unacceptable response rate (baseline to beat) (0,1)
#' @param pa Desirable response rate (0,1), must exceed pu
#' @param alpha Target type I error rate (probability of declaring an
#'   ineffective drug promising) (0,1)
#' @param beta Target type II error rate (probability of rejecting an
#'   effective drug) (0,1)
#' @param nmax Maximum total sample size to search (<= 1000)
#' @return list(minimax = list(r1,n1,r,n,EN,PET), optimal = list(...), inputs)
calc_simon <- function(pu, pa, alpha = 0.1, beta = 0.1, nmax = 100) {
  .validate_unit_interval(pu, "pu")
  .validate_unit_interval(pa, "pa")
  if (pa <= pu) stop("pa must be greater than pu.")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(beta, "beta")
  if (!is.numeric(nmax) || length(nmax) != 1 || is.na(nmax) || nmax < 10 || nmax > 1000) {
    stop("nmax must be a single number between 10 and 1000.")
  }

  fit <- clinfun::ph2simon(pu = pu, pa = pa, ep1 = alpha, ep2 = beta, nmax = nmax)

  .row_to_list <- function(row) {
    list(r1 = row[["r1"]], n1 = row[["n1"]], r = row[["r"]], n = row[["n"]],
         EN = row[["EN(p0)"]], PET = row[["PET(p0)"]])
  }

  minimax_row <- fit$out[1, ]
  optimal_row <- fit$out[which.min(fit$out[, "EN(p0)"]), ]

  list(
    minimax = .row_to_list(minimax_row),
    optimal = .row_to_list(optimal_row),
    inputs = list(pu = pu, pa = pa, alpha = alpha, beta = beta, nmax = nmax)
  )
}
