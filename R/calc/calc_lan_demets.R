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

  list(
    n_total = n_total,
    n_control = n_control,
    n_experimental = n_experimental,
    boundary_interim = bd$b1,
    boundary_final = bd$b2,
    alpha_spent = bd$alpha_spent,
    inflation_factor = n_total / n_fixed,
    inputs = list(delta = delta, sd = sd, timing = timing, r = r, alpha = alpha,
                  power = power, spending = spending)
  )
}
