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

  new_ss_result(list(
    n1 = n1, n2 = n2, n_total = n1 + n2,
    achieved_power = power_at(n1),
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power, ratio = ratio,
                  alternative = alternative)
  ))
}

#' Sample size for Boschloo's exact test (two independent proportions,
#' unconditional exact)
#'
#' Wraps Exact::power.exact.test(method = "boschloo") -- the same package
#' and search strategy as calc_fisher_exact() above, just a different
#' method argument. Boschloo's test is the classic "unconditional" exact
#' test for two proportions (as opposed to Fisher's exact test, which
#' conditions on the observed margins) -- it maximizes the p-value over
#' the unknown common success probability rather than conditioning it
#' away, which makes it uniformly at least as powerful as Fisher's exact
#' test (Boschloo 1970). This app's own Fisher's exact design confirms
#' that relationship directly: for the same p1, p2, alpha and power,
#' Boschloo's test needs n1=44 (88 total) where Fisher's exact needs
#' n1=48 (96 total) -- verification by known theoretical relationship
#' rather than an external worked example, since none was available in
#' this sandboxed session.
#'
#' @param p1 Proportion in group 1 (0,1)
#' @param p2 Proportion in group 2 (0,1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param ratio Group 2 size divided by group 1 size (> 0)
#' @param alternative "two.sided", "less", or "greater"
#' @param n1_max Upper search bound on n1 (guards against a runaway search)
#' @return list(n1, n2, n_total, achieved_power, inputs)
calc_boschloo_exact <- function(p1, p2, alpha = 0.05, power = 0.8, ratio = 1,
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
                             method = "boschloo")$power
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

  new_ss_result(list(
    n1 = n1, n2 = n2, n_total = n1 + n2,
    achieved_power = power_at(n1),
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power, ratio = ratio,
                  alternative = alternative)
  ))
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

  new_ss_result(list(
    n = n,
    achieved_power = power_at(n),
    inputs = list(p0 = p0, p1 = p1, alpha = alpha, power = power, alternative = alternative)
  ))
}

#' Person-time needed for the exact Poisson test (single rate vs. a
#' reference/standard rate)
#'
#' The one-sample analog of calc_binomial_exact() above, but for count/rate
#' data instead of a proportion -- e.g. "is this population's incidence
#' rate different from a known background/standard rate?" No package
#' wraps this directly, so this orchestrates a search using base R's own
#' stats::poisson.test() at every candidate (T, x) pair -- the rejection
#' region at each person-time T is {x : poisson.test(x, T, r=rate0)$p.value
#' <= alpha}, and achieved power is the alternative-hypothesis (rate1)
#' Poisson probability mass on that region. This calls poisson.test()
#' rather than re-deriving its rejection rule, so it can only ever agree
#' with what stats::poisson.test() itself would report at the returned T.
#'
#' @param rate0 Reference/hypothesized rate (events per unit person-time,
#'   e.g. per person-year) (> 0)
#' @param rate1 Expected/anticipated true rate, same units as rate0 (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @param t_max Upper search bound on person-time T (guards against a
#'   runaway search)
#' @return list(person_time, expected_events, achieved_power, inputs)
calc_poisson_exact <- function(rate0, rate1, alpha = 0.05, power = 0.8,
                                alternative = c("two.sided", "less", "greater"),
                                t_max = 2000) {
  alternative <- match.arg(alternative)
  .validate_positive(rate0, "rate0")
  .validate_positive(rate1, "rate1")
  if (isTRUE(all.equal(rate0, rate1))) stop("rate0 and rate1 must differ (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  power_at <- function(t) {
    lambda1 <- rate1 * t
    x_max <- stats::qpois(0.99999, lambda1) + 10
    x_vals <- 0:x_max
    pvals <- vapply(x_vals, function(x) {
      stats::poisson.test(x, T = t, r = rate0, alternative = alternative)$p.value
    }, numeric(1))
    reject <- x_vals[pvals <= alpha]
    if (length(reject) == 0) return(0)
    sum(stats::dpois(reject, lambda1))
  }

  t <- 1
  repeat {
    stable <- all(vapply(t + .STABILITY_WINDOW, power_at, numeric(1)) >= power)
    if (stable) break
    t <- t + 1
    if (t > t_max) stop("No solution found up to person-time = ", t_max, ".")
  }

  new_ss_result(list(
    person_time = t,
    expected_events = rate1 * t,
    achieved_power = power_at(t),
    inputs = list(rate0 = rate0, rate1 = rate1, alpha = alpha, power = power,
                  alternative = alternative)
  ))
}

#' Sample size for the sign test (paired data, or one-sample median test)
#'
#' The sign test asks whether the population proportion of positive
#' differences (or values above a hypothesized median) is 0.5 -- which is
#' exactly an exact binomial test with p0 = 0.5. Rather than duplicating
#' the search logic, this is a thin wrapper around calc_binomial_exact()
#' with p0 fixed at 0.5, so it inherits that function's exact correctness
#' (base R's own stats::binom.test()) automatically -- no new math, just a
#' fixed special case exposed under the sign test's own name/framing
#' (project convention: don't duplicate an existing calculation under a
#' different label).
#'
#' @param p_pos Expected proportion of pairs with a positive difference
#'   (or values above the hypothesized median), (0,1), != 0.5
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided", "less", or "greater"
#' @param n_max Upper search bound on n
#' @return list(n, achieved_power, inputs)
calc_sign_test <- function(p_pos, alpha = 0.05, power = 0.8,
                            alternative = c("two.sided", "less", "greater"),
                            n_max = 2000) {
  alternative <- match.arg(alternative)
  if (isTRUE(all.equal(p_pos, 0.5))) stop("p_pos must differ from 0.5 (no effect to detect).")
  res <- calc_binomial_exact(p0 = 0.5, p1 = p_pos, alpha = alpha, power = power,
                              alternative = alternative, n_max = n_max)
  res$inputs <- list(p_pos = p_pos, alpha = alpha, power = power, alternative = alternative)
  res
}
