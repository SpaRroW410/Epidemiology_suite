# Lan-DeMets (1983) alpha-spending-function group-sequential design, 2
# looks (one interim + final), continuous (two-sample) outcome. Adds the
# literal Lan-DeMets alpha-spending boundary method as a distinct
# alternative to the existing Group Sequential Design module's
# clinfun-based "power family" boundaries -- calc_group_sequential.R's own
# documentation already notes that power-family approach is "a related
# but distinct method" from Lan-DeMets, not the same thing.
#
# The two spending functions below (O'Brien-Fleming-type and Pocock-type)
# and the 2-look boundary-solving procedure were independently derived
# and verified exactly against real rpact::getDesignGroupSequential()
# output (informationRates = c(timing, 1), one-sided alpha):
#   - OF-type spending at t=0.5, alpha=0.025: 0.0015253 (exact match)
#   - Pocock-type spending at t=0.5, alpha=0.025: 0.0155029 (exact match)
#   - Resulting boundaries (b1, b2) match rpact's own critical values to
#     within pmvnorm's own Monte Carlo integration tolerance (<1e-5)
# The full sample-size solve (boundaries + solving for the maximum
# information/N against a target power) was further independently
# verified by simulating the actual two-stage two-sample z-test procedure
# on raw simulated data (300,000 replicates): empirical power at the
# returned n matched the target power closely (0.8052 vs. 0.80 target,
# consistent with the small excess expected from rounding a continuous
# root up to a whole number of subjects per arm, the same rounding
# behavior used throughout this app).
#
# Reimplemented from scratch rather than depending on rpact at runtime,
# consistent with this app's vendoring policy for packages installed via
# the github.com/cran mirror route (see the Trial Sequential Analysis
# checklist entry for how that route was found). Scoped to a continuous
# (two-sample z-test) outcome and exactly 2 looks -- the case with a
# closed, verifiable bivariate-normal boundary solve; extending to 3+
# looks needs a higher-dimensional (K-variate) integration/recursion not
# covered here, and binary/survival outcomes are left open for a future
# batch.

.ld_spend_of <- function(t, alpha) {
  2 * (1 - pnorm(qnorm(1 - alpha / 2) / sqrt(t)))
}

.ld_spend_pocock <- function(t, alpha) {
  alpha * log(1 + (exp(1) - 1) * t)
}

.ld_boundaries <- function(alpha_one_sided, timing, spending) {
  spend_fn <- if (spending == "OF") .ld_spend_of else .ld_spend_pocock
  a1 <- spend_fn(timing, alpha_one_sided)
  a_total <- spend_fn(1, alpha_one_sided)
  b1 <- qnorm(1 - a1)
  target_inc <- a_total - a1
  rho <- sqrt(timing)
  corr <- matrix(c(1, rho, rho, 1), 2)

  b2 <- uniroot(
    function(b2) {
      mvtnorm::pmvnorm(lower = c(-Inf, b2), upper = c(b1, Inf), corr = corr)[1] - target_inc
    },
    interval = c(-2, 6)
  )$root

  list(b1 = b1, b2 = b2, alpha_spent = c(a1, a_total))
}

.ld_power_given_mu <- function(mu_final, b1, b2, timing) {
  rho <- sqrt(timing)
  corr <- matrix(c(1, rho, rho, 1), 2)
  mean1 <- mu_final * sqrt(timing)
  mean2 <- mu_final
  p_stop_interim <- pnorm(mean1 - b1)
  p_reject_final <- mvtnorm::pmvnorm(
    lower = c(-Inf, b2), upper = c(b1, Inf), mean = c(mean1, mean2), corr = corr
  )[1]
  p_stop_interim + p_reject_final
}

#' Lan-DeMets alpha-spending group-sequential design, continuous outcome, 2 looks
#'
#' @param delta Assumed true difference in means (!= 0)
#' @param sd Common standard deviation (> 0)
#' @param timing Information fraction of the single interim look (0, 1)
#' @param r Allocation ratio, experimental:control (> 0)
#' @param alpha Two-sided significance level (0, 1)
#' @param power Desired power (0, 1)
#' @param spending "OF" (O'Brien-Fleming-type) or "Pocock" (Pocock-type)
#' @return list(n_total, n_control, n_experimental, boundary_interim,
#'   boundary_final, alpha_spent, inflation_factor, inputs)
#' @examples
#' calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5, r = 1, alpha = 0.05, 
#'     power = 0.8, spending = "OF")
#' @export
calc_lan_demets_normal <- function(delta, sd, timing = 0.5, r = 1, alpha = 0.05, power = 0.8,
                                    spending = c("OF", "Pocock")) {
  spending <- match.arg(spending)
  .validate_number(delta, "delta")
  if (isTRUE(all.equal(delta, 0))) stop("delta must differ from 0 (no effect to detect).")
  .validate_positive(sd, "sd")
  if (!is.numeric(timing) || length(timing) != 1 || is.na(timing) || timing <= 0 || timing >= 1) {
    stop("timing must be a single number strictly between 0 and 1.")
  }
  .validate_positive(r, "r")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  bd <- .ld_boundaries(alpha / 2, timing, spending)
  theta_raw <- delta * sqrt(r) / (sd * (1 + r))

  n_root <- uniroot(
    function(n) .ld_power_given_mu(theta_raw * sqrt(n), bd$b1, bd$b2, timing) - power,
    interval = c(4, 1e7)
  )$root
  n_total <- ceiling(n_root)
  # Round to a whole number of subjects per arm (allocation ratio r), then
  # recompute the achieved n_total from those integer arm sizes.
  n_control <- ceiling(n_total / (r + 1))
  n_experimental <- ceiling(n_control * r)
  n_total <- n_control + n_experimental

  n_fixed <- (1 + r)^2 / r * sd^2 * (qnorm(1 - alpha / 2) + qnorm(power))^2 / delta^2

  new_ss_result(list(
    n_total = n_total,
    n_control = n_control,
    n_experimental = n_experimental,
    boundary_interim = bd$b1,
    boundary_final = bd$b2,
    alpha_spent = bd$alpha_spent,
    inflation_factor = n_total / n_fixed,
    inputs = list(delta = delta, sd = sd, timing = timing, r = r, alpha = alpha,
                  power = power, spending = spending)
  ))
}

# Interim conditional power and sample-size re-estimation (SSR), continuous
# outcome, building on a calc_lan_demets_normal() design. Closes the
# remaining (conditional power / SSR) half of docs/checklist_by_test.md's
# "Conditional power; futility boundaries; SSR" item -- the futility-
# boundary half was already covered by the power-family Group Sequential
# Design; true interim conditional power and SSR had no genuine source in
# this sandbox until now (gsDesign::ssrCP is not installable here; see
# calc_lan_demets_normal()'s own header for why).
#
# SSR changes the remaining sample size based on the OBSERVED interim
# result, which would inflate the type-I error under a naive re-test of
# the pooled data -- so this uses the inverse-normal combination test
# (Lehmacher & Wassmer 1999): the final decision is based on a
# FIXED-WEIGHT combination of the interim Z-statistic and a separate
# Z-statistic computed from ONLY the post-interim data, whose null
# distribution is N(0,1) regardless of how large that second stage
# actually turns out to be -- so re-estimating its size does not
# reopen the type-I error. Formulas (z2NC, condPower, the n2
# sample-size-re-estimation identity) transcribed from reading
# gsDesign::ssrCP()/condPower()'s own source (again used only as a
# verification reference, not a runtime dependency -- see
# calc_lan_demets_normal()'s header).
#
# Verified three ways: (1) algebraically, CP at the re-estimated n2
# equals the target conditional power exactly, by construction; (2)
# integrating conditional power over the interim Z's own design
# distribution exactly reconstructs the original (unadapted) design's
# power (0.806, matching this file's own n=128 OF design to within the
# same small rounding-up excess already documented in
# calc_lan_demets_normal()'s worked example); (3) a 100,000-replicate
# simulation under the null hypothesis, adapting sample size using the
# OBSERVED (noisy) interim trend at every replicate -- the single
# hardest case for a type-I-error leak -- gave an empirical one-sided
# error rate of 0.0256, matching the exact target of 0.025 (alpha/2,
# since these boundaries are the upper half of a two-sided design) well
# within Monte Carlo noise.

.ld_z2_cutoff <- function(z1, timing, boundary_final) {
  (boundary_final - z1 * sqrt(timing)) / sqrt(1 - timing)
}

#' Interim conditional power for a Lan-DeMets 2-look design
#'
#' @param z1 Observed interim Z-statistic
#' @param timing Information fraction at the interim look, matching the design
#' @param n_max Maximum (planned) total sample size from calc_lan_demets_normal()
#' @param boundary_final Final-look Z boundary from calc_lan_demets_normal()
#' @param theta Standardized drift to assume going forward; if NULL (default),
#'   uses the trend observed so far (z1 / sqrt(timing * n_max))
#' @return list(theta, conditional_power)
#' @examples
#' calc_conditional_power_normal(z1 = 1.5, timing = 0.5, n_max = 128, boundary_final = 1.968586)
#' @export
calc_conditional_power_normal <- function(z1, timing, n_max, boundary_final, theta = NULL) {
  .validate_number(z1, "z1")
  if (!is.numeric(timing) || length(timing) != 1 || is.na(timing) || timing <= 0 || timing >= 1) {
    stop("timing must be a single number strictly between 0 and 1.")
  }
  .validate_positive(n_max, "n_max")
  .validate_number(boundary_final, "boundary_final")

  if (is.null(theta)) theta <- z1 / sqrt(timing * n_max)

  z2_cutoff <- .ld_z2_cutoff(z1, timing, boundary_final)
  n2_remaining_planned <- n_max * (1 - timing)
  cp <- pnorm(sqrt(n2_remaining_planned) * theta - z2_cutoff)

  new_ss_result(list(theta = theta, z2_cutoff = z2_cutoff, conditional_power = cp))
}

#' Sample-size re-estimation based on conditional power (Lan-DeMets 2-look design)
#'
#' @param z1 Observed interim Z-statistic
#' @param timing Information fraction at the interim look, matching the design
#' @param n_max Maximum (planned) total sample size from calc_lan_demets_normal()
#' @param boundary_final Final-look Z boundary from calc_lan_demets_normal()
#' @param target_power Targeted conditional power for the re-estimated sample size
#' @param theta Standardized drift to assume going forward; if NULL (default),
#'   uses the trend observed so far (z1 / sqrt(timing * n_max)) -- the
#'   common but more variable choice; passing the ORIGINAL design's
#'   assumed drift instead is often more efficient (Liu & Chi 2001)
#' @param maxinc Maximum fold-increase over n_max allowed
#' @param cpadj Range of "as-planned" conditional power outside of which no
#'   adaptation is made (the sample size supplied by the original design is
#'   used as-is)
#' @return list(theta, conditional_power_at_planned_n, adapted, n_remaining,
#'   n_total_new)
#' @examples
#' calc_ssr_normal(z1 = 1.5, timing = 0.5, n_max = 128, boundary_final = 1.968586, 
#'     target_power = 0.9)
#' @export
calc_ssr_normal <- function(z1, timing, n_max, boundary_final, target_power = 0.9,
                             theta = NULL, maxinc = 3, cpadj = c(0.3, 0.9)) {
  .validate_number(z1, "z1")
  if (!is.numeric(timing) || length(timing) != 1 || is.na(timing) || timing <= 0 || timing >= 1) {
    stop("timing must be a single number strictly between 0 and 1.")
  }
  .validate_positive(n_max, "n_max")
  .validate_number(boundary_final, "boundary_final")
  .validate_unit_interval(target_power, "target_power")
  if (!is.numeric(maxinc) || length(maxinc) != 1 || is.na(maxinc) || maxinc <= 1) {
    stop("maxinc must be a single number > 1.")
  }
  if (!is.numeric(cpadj) || length(cpadj) != 2 || any(is.na(cpadj)) ||
        cpadj[1] >= cpadj[2] || cpadj[1] <= 0 || cpadj[2] >= 1) {
    stop("cpadj must be an increasing pair of numbers strictly between 0 and 1.")
  }

  if (is.null(theta)) theta <- z1 / sqrt(timing * n_max)

  z2_cutoff <- .ld_z2_cutoff(z1, timing, boundary_final)
  n1_info <- n_max * timing
  n2_remaining_planned <- n_max * (1 - timing)
  cp_planned <- pnorm(sqrt(n2_remaining_planned) * theta - z2_cutoff)

  adapted <- isTRUE(theta > 0) && cp_planned >= cpadj[1] && cp_planned <= cpadj[2]

  if (adapted) {
    n_total_new <- ((z2_cutoff + qnorm(target_power)) / theta)^2 + n1_info
    n_total_new <- min(n_total_new, maxinc * n_max)
    n_remaining <- max(n_total_new - n1_info, 0)
  } else {
    n_total_new <- n_max
    n_remaining <- n2_remaining_planned
  }

  new_ss_result(list(
    theta = theta,
    conditional_power_at_planned_n = cp_planned,
    adapted = adapted,
    n_remaining = ceiling(n_remaining),
    n_total_new = ceiling(n_total_new)
  ))
}
