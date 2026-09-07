# Restricted Mean Survival Time (RMST) two-arm comparison, sample size via
# Monte Carlo simulation.
#
# The SSRMST package (Horiguchi & Uno) is not installable from CRAN in this
# sandbox (no network access to cran.r-project.org), and its own power
# calculation (`ssrmst()`) calls `survRM2::rmst2()` internally, which is
# ALSO not installed. Rather than fabricate a formula or skip the item,
# `ssrmst()`'s actual algorithm was read directly from the package's own
# public source on its read-only GitHub CRAN mirror
# (https://raw.githubusercontent.com/cran/SSRMST/master/R/ssrmst.R), which
# already includes -- verbatim, with the package's own comment "-- from
# survRM2 (hidden) --" -- a self-contained one-arm RMST estimator
# (`rmst_1()`) built only on `survival::survfit()`.
#
# To close the `rmst2()` gap, `survRM2::rmst2.R` was independently fetched
# from its own GitHub CRAN mirror to confirm its "unadjusted" two-arm RMST
# difference test is exactly: `rmst.diff.10 = wk1$rmst[1] - wk0$rmst[1]`,
# `rmst.diff.10.se = sqrt(wk1$rmst.var + wk0$rmst.var)` -- i.e. the same
# per-arm `rmst_1()`-style estimator applied separately to each arm, with
# variances simply summed. So SSRMST's `power1` ("separate variance") and
# `power2` ("pooled variance") can both be reproduced exactly using only
# the `rmst_1()` code already embedded in SSRMST's own source -- no new
# package dependency at all, just `survival` (already a project
# dependency via other modules' Cox/log-rank designs).
#
# This method's whole design (per Uno et al. 2014, J Clin Oncol; Uno et
# al. 2015, Ann Intern Med) IS Monte Carlo -- the packages simulate the
# trial repeatedly and report the fraction of replicates whose RMST-
# difference confidence interval clears the margin -- so there is no
# closed form to fall back to; this reimplements that same simulation
# faithfully and wraps it in this app's usual exponential-search-then-
# bisection engine (`.mc_search_n1()`) to solve for the sample size that
# reaches a target power, since the original functions only go the other
# direction (sample size -> power).

#' One-arm restricted mean survival time (RMST) and its variance
#'
#' Transcribed verbatim (variable names aside) from SSRMST's own internal
#' `rmst_1()` helper, itself taken from `survRM2` -- the standard
#' Kaplan-Meier-area-under-the-curve RMST estimator with its
#' Greenwood-type variance.
#'
#' @param time Event/censoring times (numeric vector)
#' @param status Event indicator, 1 = event, 0 = censored (numeric vector)
#' @param tau Truncation time
#' @param alpha Two-sided alpha for the (unused here) CI -- kept for
#'   parity with the source; only the point estimate and variance are used
#' @return list(rmst, rmst.var)
.rmst_one_arm <- function(time, status, tau, alpha = 0.05) {
  ft  <- survival::survfit(survival::Surv(time, status) ~ 1)
  idx <- ft$time <= tau

  wk.time    <- sort(c(ft$time[idx], tau))
  wk.surv    <- ft$surv[idx]
  wk.n.risk  <- ft$n.risk[idx]
  wk.n.event <- ft$n.event[idx]

  time.diff <- diff(c(0, wk.time))
  areas     <- time.diff * c(1, wk.surv)
  rmst      <- sum(areas)

  wk.var <- ifelse((wk.n.risk - wk.n.event) == 0, 0,
                    wk.n.event / (wk.n.risk * (wk.n.risk - wk.n.event)))
  wk.var   <- c(wk.var, 0)
  rmst.var <- sum(cumsum(rev(areas[-1]))^2 * rev(wk.var)[-1])

  list(rmst = rmst, rmst.var = rmst.var)
}

# One Monte Carlo trial replicate set: simulate Weibull event times with
# staggered entry over [0, ac_period] and administrative censoring at
# tot_time, for both arms, then compute both of SSRMST's power
# definitions (separate-variance and pooled-variance) for the two-arm RMST
# difference test. Mirrors `ssrmst()`'s per-replicate loop exactly, with
# `rmst2()`'s call replaced by the equivalent direct `.rmst_one_arm()`
# computation confirmed above.
.rmst_simulate <- function(n0, n1, ac_period, tot_time, tau, shape0, scale0, shape1, scale1,
                            margin, one_sided_alpha, reps, seed) {
  set.seed(seed)
  answer1 <- answer2 <- numeric(reps)
  ev0 <- ev1 <- numeric(reps)

  for (w in seq_len(reps)) {
    E0 <- rweibull(n0, shape0, scale0); C0 <- tot_time - runif(n0, 0, ac_period)
    t0 <- pmin(E0, C0); s0 <- as.numeric(E0 <= C0)
    ev0[w] <- sum(t0[s0 == 1] <= tot_time)

    E1 <- rweibull(n1, shape1, scale1); C1 <- tot_time - runif(n1, 0, ac_period)
    t1 <- pmin(E1, C1); s1 <- as.numeric(E1 <= C1)
    ev1[w] <- sum(t1[s1 == 1] <= tot_time)

    keep0 <- t0 > 0; keep1 <- t1 > 0
    t0k <- t0[keep0]; s0k <- s0[keep0]; t1k <- t1[keep1]; s1k <- s1[keep1]

    tau_max <- min(max(t0k), max(t1k))
    if (tau > tau_max) {
      stop(sprintf(
        paste(
          "tau (%.4g) exceeds the largest observed time in a simulated",
          "trial (%.4g at this sample size); reduce tau, increase",
          "tot_time, or increase the sample size."
        ),
        tau, tau_max
      ))
    }

    wk0 <- .rmst_one_arm(t0k, s0k, tau, alpha = one_sided_alpha * 2)
    wk1 <- .rmst_one_arm(t1k, s1k, tau, alpha = one_sided_alpha * 2)
    diff10 <- wk1$rmst - wk0$rmst
    se_sep <- sqrt(wk1$rmst.var + wk0$rmst.var)
    lower1 <- diff10 - qnorm(1 - one_sided_alpha) * se_sep
    answer1[w] <- as.numeric(lower1 > -margin)

    all_arm <- .rmst_one_arm(c(t0k, t1k), c(s0k, s1k), tau, alpha = one_sided_alpha * 2)
    se_all <- sqrt(all_arm$rmst.var)
    se_pooled <- sqrt((se_all * sqrt(n0 + n1) / sqrt(n0))^2 + (se_all * sqrt(n0 + n1) / sqrt(n1))^2)
    lower2 <- diff10 - qnorm(1 - one_sided_alpha) * se_pooled
    answer2[w] <- as.numeric(lower2 > -margin)
  }

  list(power1 = mean(answer1), power2 = mean(answer2),
       n0_events = round(mean(ev0)), n1_events = round(mean(ev1)))
}

#' Sample size for a two-arm restricted mean survival time (RMST)
#' comparison, via Monte Carlo simulation
#'
#' Solves for the per-arm sample size needed for a target power in a
#' superiority (`margin = 0`) or non-inferiority (`margin > 0`) test of
#' the difference in RMST between two arms, each following a Weibull
#' survival distribution, under staggered accrual over `ac_period` and
#' administrative censoring at `tot_time` (Uno et al. 2014; Uno et al.
#' 2015). Reports both of the method's two variance estimators for the
#' RMST-difference confidence interval: "separate" (each arm's variance
#' estimated on its own data, then summed -- SSRMST's `power1`, the
#' package's primary/headline method, matching `survRM2::rmst2()`'s own
#' "unadjusted" test) and "pooled" (a single combined-arm variance
#' rescaled by each arm's size -- SSRMST's `power2`).
#'
#' @param ac_period Accrual period: time of last patient's enrollment (> 0)
#' @param tot_time Total study time: time of the final analysis (> 0)
#' @param tau RMST truncation time (0 < tau < tot_time)
#' @param shape0,shape1 Weibull shape parameters, arm 0 (control) and arm
#'   1 (treatment); default 1 (exponential)
#' @param scale0,scale1 Weibull scale parameters, arm 0 and arm 1. Under
#'   the proportional-hazards case (`shape0 == shape1`), `scale1` must be
#'   >= `scale0`, since the arm1-minus-arm0 RMST difference is of interest
#' @param margin Non-inferiority margin (>= 0); `margin = 0` (default)
#'   selects a superiority test
#' @param allocation1 Proportion of patients allocated to arm 1 (0,1),
#'   default 0.5
#' @param alpha Two-sided significance level (0,1), default 0.05 (used as
#'   `one_sided_alpha = alpha / 2`, matching the package's own convention)
#' @param power Desired power (0,1), default 0.8
#' @param nsim Monte Carlo replicates per sample-size candidate evaluated
#'   during the search (>= 50); the final reported result re-estimates
#'   power at 3x this count for a tighter estimate
#' @param seed RNG seed for reproducibility
#' @return list(n0, n1, n_total, n0_events, n1_events,
#'   achieved_power_separate, achieved_power_pooled, inputs)
calc_rmst_comparison <- function(ac_period, tot_time, tau, shape0 = 1, scale0, shape1 = 1, scale1,
                                  margin = 0, allocation1 = 0.5, alpha = 0.05, power = 0.8,
                                  nsim = 100, seed = 20140618) {
  .validate_positive(ac_period, "ac_period")
  .validate_positive(tot_time, "tot_time")
  .validate_positive(tau, "tau")
  if (tau >= tot_time) stop("tau must be less than tot_time.")
  .validate_positive(shape0, "shape0"); .validate_positive(shape1, "shape1")
  .validate_positive(scale0, "scale0"); .validate_positive(scale1, "scale1")
  if (!is.numeric(margin) || length(margin) != 1 || is.na(margin) || margin < 0) {
    stop("margin must be a single number >= 0.")
  }
  .validate_unit_interval(allocation1, "allocation1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (shape0 == shape1 && scale0 > scale1) {
    stop(paste(
      "Under the proportional-hazards assumption (shape0 == shape1), scale1",
      "must be >= scale0 (the arm1-minus-arm0 RMST difference is of interest)."
    ))
  }
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 50 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 50.")
  }

  one_sided_alpha <- alpha / 2
  ratio <- allocation1 / (1 - allocation1)

  empirical_power <- function(n0, reps) {
    n1 <- max(2, round(n0 * ratio))
    .rmst_simulate(n0, n1, ac_period, tot_time, tau, shape0, scale0, shape1, scale1,
                   margin, one_sided_alpha, reps, seed)$power1
  }

  n0 <- .mc_search_n1(function(n) empirical_power(n, nsim), power, n_lo = 10, n_hi = 20, n_max = 5000)
  n1 <- max(2, round(n0 * ratio))
  final <- .rmst_simulate(n0, n1, ac_period, tot_time, tau, shape0, scale0, shape1, scale1,
                          margin, one_sided_alpha, nsim * 3, seed)

  list(
    n0 = n0, n1 = n1, n_total = n0 + n1,
    n0_events = final$n0_events, n1_events = final$n1_events,
    achieved_power_separate = final$power1, achieved_power_pooled = final$power2,
    inputs = list(ac_period = ac_period, tot_time = tot_time, tau = tau,
                  shape0 = shape0, scale0 = scale0, shape1 = shape1, scale1 = scale1,
                  margin = margin, allocation1 = allocation1, alpha = alpha, power = power,
                  nsim = nsim)
  )
}
