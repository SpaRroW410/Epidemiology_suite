# Pure calculation functions for exact tests on proportions (the G*Power
# "Exact" test family). No Shiny dependency here so these are directly
# unit-testable (see tests/testthat).
#
# Both designs search upward over n rather than solving a closed-form
# equation, because exact-test power is a genuinely non-monotonic
# ("sawtoothed") function of n -- adding one more subject can occasionally
# *lower* achieved power before it recovers (Chernick & Liu 2002). To avoid
# recommending a fragile single-n spike, both searches require power to
# stay at or above the target for a small run of consecutive n values
# before accepting it.

.STABILITY_WINDOW <- 0:2

#' Sample size for Fisher's exact test (two independent proportions)
#'
#' Wraps Exact::power.exact.test(method = "fisher") -- searches n1 upward
#' (with n2 = ceiling(n1 * ratio)) for the smallest n1 where achieved power
#' is at or above the target and stays there for a couple more steps.
#'
#' @param p1 Proportion in group 1 (0,1)
#' @param p2 Proportion in group 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param ratio Group 2 size divided by group 1 size (> 0)
#' @param alternative "two.sided", "less", or "greater"
#' @param n1_max Upper search bound on n1 (guards against a runaway search)
#' @return list(n1, n2, n_total, achieved_power, inputs)
calc_fisher_exact <- function(p1, p2, alpha = 0.05, power = 0.8, ratio = 1,
                               alternative = c("two.sided", "less", "greater"),
                               n1_max = 500) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  if (isTRUE(all.equal(p1, p2))) stop("p1 and p2 must differ (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")

  power_at <- function(n1) {
    n2 <- ceiling(n1 * ratio)
    Exact::power.exact.test(p1 = p1, p2 = p2, n1 = n1, n2 = n2,
                             alternative = alternative, alpha = alpha,
                             method = "fisher")$power
  }

  n1 <- 2
  repeat {
    stable <- all(vapply(n1 + .STABILITY_WINDOW, power_at, numeric(1)) >= power)
    if (stable) break
    n1 <- n1 + 1
    if (n1 > n1_max) {
      stop("No solution found up to n1 = ", n1_max,
           " -- try a larger effect size or a looser power/alpha.")
    }
  }
  n2 <- ceiling(n1 * ratio)

  list(
    n1 = n1, n2 = n2, n_total = n1 + n2,
    achieved_power = power_at(n1),
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power, ratio = ratio,
                  alternative = alternative)
  )
}

#' Sample size for the exact binomial test (single proportion)
#'
#' No package wraps this directly, so this orchestrates a search using base
#' R's own stats::binom.test() at every candidate (n, x) pair -- the
#' rejection region at each n is {x : binom.test(x, n, p0)$p.value <=
#' alpha}, and achieved power is the alternative-hypothesis probability mass
#' on that region. This calls binom.test() rather than re-deriving its
#' rejection rule, so it can only ever agree with what stats::binom.test()
#' itself would report at the returned n.
#'
#' @param p0 Reference/hypothesized proportion (0,1)
#' @param p1 Expected/anticipated true proportion (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @param n_max Upper search bound on n (guards against a runaway search)
#' @return list(n, achieved_power, inputs)
calc_binomial_exact <- function(p0, p1, alpha = 0.05, power = 0.8,
                                 alternative = c("two.sided", "less", "greater"),
                                 n_max = 2000) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p0, "p0")
  .validate_unit_interval(p1, "p1")
  if (isTRUE(all.equal(p0, p1))) stop("p0 and p1 must differ (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  power_at <- function(n) {
    x_vals <- 0:n
    pvals <- vapply(x_vals, function(x) {
      stats::binom.test(x, n, p0, alternative = alternative)$p.value
    }, numeric(1))
    reject <- x_vals[pvals <= alpha]
    if (length(reject) == 0) return(0)
    sum(stats::dbinom(reject, n, p1))
  }

  n <- 1
  repeat {
    stable <- all(vapply(n + .STABILITY_WINDOW, power_at, numeric(1)) >= power)
    if (stable) break
    n <- n + 1
    if (n > n_max) stop("No solution found up to n = ", n_max, ".")
  }

  list(
    n = n,
    achieved_power = power_at(n),
    inputs = list(p0 = p0, p1 = p1, alpha = alpha, power = power, alternative = alternative)
  )
}
