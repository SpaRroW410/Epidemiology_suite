# Pure calculation functions for group-sequential trial design (interim
# analyses with efficacy/futility boundaries). No Shiny dependency here so
# these are directly unit-testable (see tests/testthat). Wraps
# clinfun::gsdesign.binomial()/gsdesign.normal()/gsdesign.survival() rather
# than reimplementing the underlying math (project convention) -- clinfun
# already a project dependency (used for Simon two-stage).
#
# Important implementation note: clinfun's gsdesign.*() functions compute
# their multivariate-normal boundary probabilities via mvtnorm::pmvnorm(),
# which uses randomized (quasi-Monte-Carlo) numerical integration
# internally. Without a fixed seed, calling the same function with the
# same inputs gives a slightly different answer each time (confirmed:
# +/-1 subject per arm across different seeds for the same inputs) --
# unacceptable for a deterministic web calculator where a user expects the
# same inputs to always return the same N. Every wrapper below sets a
# fixed seed immediately before calling into clinfun, so results are
# exactly reproducible across calls in this app (verified: identical
# results across repeated calls with the same seed).
#
# The boundary shape is parameterized by clinfun's own "power family"
# (delta.eb / delta.fb, 0 = Pocock to 0.5 = O'Brien-Fleming) -- a discrete
# reparameterization that reproduces the classic Pocock and O'Brien-Fleming
# boundary shapes at its two endpoints, not literally the Lan-DeMets
# alpha-spending-function approach (a related but distinct method); this
# app follows clinfun's own terminology rather than overclaiming.

.gsd_seed <- 20260830

#' Sample size and boundaries for a group-sequential trial, continuous outcome
#'
#' Wraps clinfun::gsdesign.normal(). At n_looks = 1 (a single, final
#' analysis -- i.e. no interim looks), this exactly reduces to the
#' standard fixed-sample two-sample z-test formula (verified: the
#' "drift" statistic equals Z_(1-alpha/2) + Z_(1-beta) exactly).
#'
#' @param delta Assumed true difference in means (!= 0)
#' @param sd Common standard deviation (> 0)
#' @param n_looks Number of planned analyses, including the final one
#'   (whole number >= 1); interim looks are assumed equally spaced
#'   (information fractions 1/n_looks, 2/n_looks, ..., 1)
#' @param r Allocation ratio, experimental:control (> 0); 1 = equal allocation
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided" or "one.sided"
#' @param boundary_shape Power-family boundary parameter, [0, 0.5]: 0 =
#'   Pocock (constant boundary across looks), 0.5 = O'Brien-Fleming
#'   (conservative early, liberal late) -- the two classic boundary shapes
#' @param futility If TRUE, also compute a (non-binding) futility boundary
#'   in the same power family
#' @return list(n_total, n_control, n_experimental, ifrac,
#'   efficacy_boundary, futility_boundary, inputs)
calc_group_sequential_normal <- function(delta, sd, n_looks, r = 1, alpha = 0.05, power = 0.8,
                                          alternative = c("two.sided", "one.sided"),
                                          boundary_shape = 0.5, futility = FALSE) {
  alternative <- match.arg(alternative)
  .validate_number(delta, "delta")
  if (isTRUE(all.equal(delta, 0))) stop("delta must differ from 0 (no effect to detect).")
  .validate_positive(sd, "sd")
  .validate_n_looks(n_looks)
  .validate_positive(r, "r")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_boundary_shape(boundary_shape)

  ifrac <- seq_len(n_looks) / n_looks
  delta_fb <- if (futility) boundary_shape else NULL

  set.seed(.gsd_seed)
  fit <- clinfun::gsdesign.normal(
    ifrac = ifrac, delta = delta, sd = sd, r = r, sig.level = alpha, power = power,
    delta.eb = boundary_shape, delta.fb = delta_fb, alternative = alternative
  )

  .gsd_result(fit, r, inputs = list(delta = delta, sd = sd, n_looks = n_looks, r = r,
                                     alpha = alpha, power = power, alternative = alternative,
                                     boundary_shape = boundary_shape, futility = futility))
}

#' Sample size and boundaries for a group-sequential trial, binary outcome
#'
#' Wraps clinfun::gsdesign.binomial(). Uses the Casagrande-Pike-Smith
#' continuity correction by default (`CPS = TRUE`, matching clinfun's own
#' default), the same correction commonly applied to two-proportion tests
#' elsewhere in the sample-size literature. At n_looks = 1 this reduces to
#' a standard fixed-sample two-proportion z-test sample size (cross-checked
#' against pwr::pwr.2p.test -- close but not identical, since the two use
#' different variance formulas: unpooled p(1-p) here vs. arcsine-
#' transformed h there, a known and expected difference in magnitude, not
#' a bug).
#'
#' @param pC Assumed event/success probability, control arm (0,1)
#' @param pE Assumed event/success probability, experimental arm (0,1)
#' @param n_looks Number of planned analyses, including the final one
#'   (whole number >= 1)
#' @param r Allocation ratio, experimental:control (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided" or "one.sided"
#' @param boundary_shape Power-family boundary parameter, [0, 0.5]
#' @param futility If TRUE, also compute a futility boundary
#' @return list(n_total, n_control, n_experimental, ifrac,
#'   efficacy_boundary, futility_boundary, inputs)
calc_group_sequential_binary <- function(pC, pE, n_looks, r = 1, alpha = 0.05, power = 0.8,
                                          alternative = c("two.sided", "one.sided"),
                                          boundary_shape = 0.5, futility = FALSE) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(pC, "pC")
  .validate_unit_interval(pE, "pE")
  if (isTRUE(all.equal(pC, pE))) stop("pC and pE must differ (no effect to detect).")
  .validate_n_looks(n_looks)
  .validate_positive(r, "r")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_boundary_shape(boundary_shape)

  ifrac <- seq_len(n_looks) / n_looks
  delta_fb <- if (futility) boundary_shape else NULL

  set.seed(.gsd_seed)
  fit <- clinfun::gsdesign.binomial(
    ifrac = ifrac, pC = pC, pE = pE, r = r, sig.level = alpha, power = power,
    delta.eb = boundary_shape, delta.fb = delta_fb, alternative = alternative
  )

  .gsd_result(fit, r, inputs = list(pC = pC, pE = pE, n_looks = n_looks, r = r,
                                     alpha = alpha, power = power, alternative = alternative,
                                     boundary_shape = boundary_shape, futility = futility))
}

#' Sample size (events) and boundaries for a group-sequential trial,
#' time-to-event outcome
#'
#' Wraps clinfun::gsdesign.survival(). At n_looks = 1 this exactly
#' reproduces the classic Schoenfeld (1983) log-rank event-count formula
#' (verified: exact match to 4*(Z_(1-alpha/2)+Z_(1-beta))^2/log(HR)^2 for
#' equal allocation). Returns the required number of EVENTS, not enrolled
#' subjects -- converting to an enrollment target needs a separate accrual
#' and censoring/follow-up assumption (see the Log-Rank/Survival module
#' for that fuller accrual-based calculation in the fixed-design, single-
#' look case).
#'
#' @param haz_ratio Assumed hazard ratio, experimental vs. control (> 0, != 1)
#' @param n_looks Number of planned analyses, including the final one
#'   (whole number >= 1)
#' @param r Allocation ratio, experimental:control (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param alternative "two.sided" or "one.sided"
#' @param boundary_shape Power-family boundary parameter, [0, 0.5]
#' @param futility If TRUE, also compute a futility boundary
#' @return list(n_events_total, ifrac, efficacy_boundary,
#'   futility_boundary, inputs)
calc_group_sequential_survival <- function(haz_ratio, n_looks, r = 1, alpha = 0.05, power = 0.8,
                                            alternative = c("two.sided", "one.sided"),
                                            boundary_shape = 0.5, futility = FALSE) {
  alternative <- match.arg(alternative)
  .validate_positive(haz_ratio, "haz_ratio")
  if (isTRUE(all.equal(haz_ratio, 1))) stop("haz_ratio must differ from 1 (no effect to detect).")
  .validate_n_looks(n_looks)
  .validate_positive(r, "r")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_boundary_shape(boundary_shape)

  ifrac <- seq_len(n_looks) / n_looks
  delta_fb <- if (futility) boundary_shape else NULL

  set.seed(.gsd_seed)
  fit <- clinfun::gsdesign.survival(
    ifrac = ifrac, haz.ratio = haz_ratio, r = r, sig.level = alpha, power = power,
    delta.eb = boundary_shape, delta.fb = delta_fb, alternative = alternative
  )

  new_ss_result(list(
    n_events_total = ceiling(fit$num.events),
    ifrac = fit$ifrac,
    efficacy_boundary = fit$effbdry,
    futility_boundary = fit$futbdry,
    inputs = list(haz_ratio = haz_ratio, n_looks = n_looks, r = r, alpha = alpha,
                  power = power, alternative = alternative,
                  boundary_shape = boundary_shape, futility = futility)
  ))
}

.validate_n_looks <- function(n_looks) {
  if (!is.numeric(n_looks) || length(n_looks) != 1 || is.na(n_looks) ||
        n_looks < 1 || n_looks != round(n_looks)) {
    stop("n_looks must be a single whole number >= 1.")
  }
}

.validate_boundary_shape <- function(boundary_shape) {
  if (!is.numeric(boundary_shape) || length(boundary_shape) != 1 || is.na(boundary_shape) ||
        boundary_shape < 0 || boundary_shape > 0.5) {
    stop("boundary_shape must be a single number between 0 (Pocock) and 0.5 (O'Brien-Fleming).")
  }
}

.gsd_result <- function(fit, r, inputs) {
  n_total <- ceiling(fit$sample.size)
  n_control <- ceiling(n_total * 1 / (r + 1))
  n_experimental <- n_total - n_control

  new_ss_result(list(
    n_total = n_total,
    n_control = n_control,
    n_experimental = n_experimental,
    ifrac = fit$ifrac,
    efficacy_boundary = fit$effbdry,
    futility_boundary = fit$futbdry,
    inputs = inputs
  ))
}
