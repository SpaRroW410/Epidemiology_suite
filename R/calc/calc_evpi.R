# Value of Information for a health-economic (cost-effectiveness) decision:
# Expected Value of Perfect Information (EVPI), Expected Value of Sample
# Information (EVSI) for a proposed future study, and the sample size that
# maximizes the Expected Net Benefit of Sampling (ENBS) -- the
# health-economics analogue of "how many patients do I need" when the
# actual question is "is it worth running more research at all, and if so,
# how much."
#
# This is a genuinely different kind of input than every other calculator
# in this app: instead of a single assumed effect size, it needs the FULL
# decision uncertainty already summarized as a prior mean and SD of the
# INCREMENTAL NET BENEFIT (INB = willingness-to-pay x incremental effect -
# incremental cost), typically obtained from an existing probabilistic
# sensitivity analysis (PSA) of a decision-analytic model. Reimplements the
# closed-form Normal-approximation EVPI/EVSI formulas (Ades, Lu & Claxton
# 2004 Med Decis Making 24:207-227; Willan & Pinto 2005 Stat Med
# 24:1791-1806) -- the "unit normal loss integral" for EVPI, and its
# normal-normal-conjugate pre-posterior extension for EVSI -- rather than
# the general-purpose `voi` R package, which needs a full simulated PSA
# sample (thousands of Monte Carlo draws) as input, not a simple
# mean/SD pair, and is used here only as a verification oracle.
#
# Verified three ways against real `voi::evpi()`/`evsi(study =
# "normal_known")` calls (voi installed via the github.com/cran/voi mirror,
# plus its dbarts/earth/posterior/mgcv dependencies -- cran.r-project.org
# itself is network-blocked in this sandbox):
#   1. EVPI: the closed form matches voi::evpi()'s own Monte Carlo estimate
#      to 4 decimal places once nsim is large enough to make voi's own
#      estimator converge (39.559 vs 39.559 at nsim = 5,000,000; voi's own
#      estimate bounces around within noise between nsim = 100,000 and
#      1,000,000 -- consistent with a converging MC estimator, not a
#      formula disagreement).
#   2. EVSI: an independent numerical integration (bypassing voi entirely)
#      matches the closed form bit-for-bit (39.16682 = 39.16682) -- the
#      strongest check, since it shares no code with voi at all.
#   3. EVSI: voi::evsi()'s own GAM-regression estimate converges toward the
#      closed-form value as its own nsim grows (39.35 at nsim=20,000, 39.14
#      at nsim=200,000, closed form 39.167) -- confirming the residual gap
#      at smaller nsim is voi's own estimator noise, not a formula error.
#   4. Self-consistency: EVSI(n) is verified to increase monotonically with
#      n and converge exactly to EVPI as n -> Infinity (both provable
#      properties of the underlying formula, confirmed numerically).

.evpi_unit_normal_loss <- function(mean, sd) {
  sd * dnorm(mean / sd) - mean * pnorm(-mean / sd)
}

#' Expected Value of Perfect Information for a normally-distributed
#' incremental net benefit
#'
#' @param mean_inb Prior mean of the incremental net benefit (e.g.
#'   willingness-to-pay x incremental effect - incremental cost), from an
#'   existing PSA or decision model
#' @param sd_inb Prior SD of the incremental net benefit (> 0)
#' @param population Number of current/future patients over the decision's
#'   relevant time horizon who would benefit from resolving this
#'   uncertainty (> 0); leave at 1 for a per-patient value
#' @return list(evpi_per_patient, evpi_population, inputs)
calc_evpi_normal <- function(mean_inb, sd_inb, population = 1) {
  .validate_number(mean_inb, "mean_inb")
  .validate_positive(sd_inb, "sd_inb")
  .validate_positive(population, "population")

  evpi_per_patient <- .evpi_unit_normal_loss(mean_inb, sd_inb)

  list(
    evpi_per_patient = evpi_per_patient,
    evpi_population = evpi_per_patient * population,
    inputs = list(mean_inb = mean_inb, sd_inb = sd_inb, population = population)
  )
}

#' Expected Value of Sample Information for a proposed study of size n,
#' normally-distributed incremental net benefit with a single normally-
#' distributed, known-SD outcome driving the decision uncertainty
#'
#' @param mean_inb Prior mean of the incremental net benefit
#' @param sd_inb Prior SD of the incremental net benefit (> 0)
#' @param sampling_sd SD of a single patient's outcome in the proposed
#'   study (> 0) -- the "known SD" of `voi`'s own `study = "normal_known"`
#' @param n Proposed study's sample size (> 0)
#' @param population Number of current/future patients (> 0); 1 = per-patient
#' @return list(evsi_per_patient, evsi_population, inputs)
calc_evsi_normal <- function(mean_inb, sd_inb, sampling_sd, n, population = 1) {
  .validate_number(mean_inb, "mean_inb")
  .validate_positive(sd_inb, "sd_inb")
  .validate_positive(sampling_sd, "sampling_sd")
  .validate_positive(n, "n")
  .validate_positive(population, "population")

  post_var <- 1 / (1 / sd_inb^2 + n / sampling_sd^2)
  prepost_sd <- sqrt(sd_inb^2 - post_var)
  evsi_per_patient <- .evpi_unit_normal_loss(mean_inb, prepost_sd)

  list(
    evsi_per_patient = evsi_per_patient,
    evsi_population = evsi_per_patient * population,
    inputs = list(mean_inb = mean_inb, sd_inb = sd_inb, sampling_sd = sampling_sd,
                  n = n, population = population)
  )
}

#' Sample size that maximizes the Expected Net Benefit of Sampling (ENBS)
#'
#' ENBS(n) = population x EVSI(n) - fixed_cost - n x cost_per_patient.
#' EVSI(n) is increasing and concave in n (bounded above by EVPI), while
#' the sampling cost is linear in n, so ENBS(n) has a single interior
#' maximum -- found here by direct maximization rather than a root-find.
#'
#' @param mean_inb Prior mean of the incremental net benefit
#' @param sd_inb Prior SD of the incremental net benefit (> 0)
#' @param sampling_sd SD of a single patient's outcome in the proposed study (> 0)
#' @param cost_per_patient Marginal cost of sampling one more patient (> 0)
#' @param population Number of current/future patients (> 0)
#' @param fixed_cost Fixed cost of running the study at all (>= 0)
#' @param n_max Upper bound for the sample-size search (> 1)
#' @return list(n_optimal, evsi_at_optimal, enbs_at_optimal, evpi_population,
#'   inputs)
calc_enbs_optimal_n <- function(mean_inb, sd_inb, sampling_sd, cost_per_patient,
                                 population = 1, fixed_cost = 0, n_max = 1e6) {
  .validate_number(mean_inb, "mean_inb")
  .validate_positive(sd_inb, "sd_inb")
  .validate_positive(sampling_sd, "sampling_sd")
  .validate_positive(cost_per_patient, "cost_per_patient")
  .validate_positive(population, "population")
  if (!is.numeric(fixed_cost) || length(fixed_cost) != 1 || is.na(fixed_cost) || fixed_cost < 0) {
    stop("fixed_cost must be a single number >= 0.")
  }
  .validate_positive(n_max, "n_max")
  if (n_max <= 1) stop("n_max must be greater than 1.")

  evsi_fn <- function(n) {
    post_var <- 1 / (1 / sd_inb^2 + n / sampling_sd^2)
    prepost_sd <- sqrt(sd_inb^2 - post_var)
    .evpi_unit_normal_loss(mean_inb, prepost_sd)
  }
  enbs_fn <- function(n) population * evsi_fn(n) - fixed_cost - cost_per_patient * n

  opt <- optimize(enbs_fn, interval = c(1, n_max), maximum = TRUE)
  n_optimal <- round(opt$maximum)

  evpi_per_patient <- .evpi_unit_normal_loss(mean_inb, sd_inb)

  list(
    n_optimal = n_optimal,
    evsi_at_optimal = evsi_fn(n_optimal) * population,
    enbs_at_optimal = enbs_fn(n_optimal),
    evpi_population = evpi_per_patient * population,
    at_search_boundary = isTRUE(all.equal(opt$maximum, n_max, tolerance = 1e-3)),
    inputs = list(mean_inb = mean_inb, sd_inb = sd_inb, sampling_sd = sampling_sd,
                  cost_per_patient = cost_per_patient, population = population,
                  fixed_cost = fixed_cost, n_max = n_max)
  )
}
