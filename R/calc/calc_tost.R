# Pure calculation function for equivalence testing (TOST) sample size. No
# Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps PowerTOST::sampleN.TOST() rather than
# reimplementing the underlying math (project convention).

#' Sample size for a two one-sided tests (TOST) equivalence trial on means
#'
#' Wraps PowerTOST::sampleN.TOST() on the *original* (untransformed) scale
#' (logscale = FALSE) with a parallel-groups design -- i.e. raw units, not
#' the log-ratio/CV framing used for pharmacokinetic bioequivalence
#' (PowerTOST's more common use case, and still available via this same
#' package for that more specialized design).
#'
#' @param mean_diff Expected/assumed difference in means (test - reference)
#' @param margin Equivalence margin (> 0); the true difference must fall
#'   within (-margin, +margin) to conclude equivalence
#' @param sd Common/pooled standard deviation (> 0)
#' @param alpha Significance level, one-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(n_total, n_per_group, achieved_power, inputs)
calc_tost_means <- function(mean_diff, margin, sd, alpha = 0.05, power = 0.8) {
  .validate_number(mean_diff, "mean_diff")
  .validate_positive(margin, "margin")
  .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (abs(mean_diff) >= margin) {
    stop("mean_diff must fall strictly within (-margin, margin) -- otherwise equivalence can't be shown even with infinite sample size.")
  }

  fit <- PowerTOST::sampleN.TOST(
    alpha = alpha, targetpower = power, logscale = FALSE,
    theta0 = mean_diff, theta1 = -margin, theta2 = margin,
    CV = sd, design = "parallel", print = FALSE
  )

  n_total <- fit[["Sample size"]]
  n_per_group <- ceiling(n_total / 2)

  list(
    n_total = n_per_group * 2,
    n_per_group = n_per_group,
    achieved_power = fit[["Achieved power"]],
    inputs = list(mean_diff = mean_diff, margin = margin, sd = sd,
                  alpha = alpha, power = power)
  )
}

#' Sample size for a pharmacokinetic bioequivalence crossover trial
#'
#' Wraps PowerTOST::sampleN.TOST() on the *log-transformed* scale
#' (logscale = TRUE) -- the classic pharmacokinetic bioequivalence
#' framing (comparing a test and reference formulation's AUC or Cmax via
#' a ratio, not a raw difference), for a standard 2x2 crossover or a
#' replicate design (2x2x4 or the partial-replicate 2x3x3), used to
#' support reference-scaled average bioequivalence (RSABE) / average
#' bioequivalence with expanding limits (ABEL) approaches that need
#' repeated within-subject measurements of the reference product.
#'
#' @param cv Expected intra-subject coefficient of variation (> 0), on
#'   the log scale (e.g. 0.3 for 30% CV)
#' @param theta0 Assumed true ratio of test/reference (e.g. 0.95); must
#'   fall strictly within (theta1, theta2)
#' @param theta1 Lower bioequivalence limit (default 0.8, i.e. 80%)
#' @param theta2 Upper bioequivalence limit (default 1.25, i.e. 125%)
#' @param alpha Significance level, one-sided (0,1)
#' @param power Desired power (0,1)
#' @param design One of "2x2" (classical 2x2x2 crossover), "2x2x4"
#'   (full replicate), or "2x3x3" (partial replicate)
#' @return list(n_total, achieved_power, inputs)
calc_tost_bioequivalence <- function(cv, theta0 = 0.95, theta1 = 0.8, theta2 = 1.25,
                                      alpha = 0.05, power = 0.8,
                                      design = c("2x2", "2x2x4", "2x3x3")) {
  design <- match.arg(design)
  .validate_positive(cv, "cv")
  .validate_positive(theta0, "theta0")
  .validate_positive(theta1, "theta1")
  .validate_positive(theta2, "theta2")
  if (!(theta0 > theta1 && theta0 < theta2)) {
    stop("theta0 must fall strictly within (theta1, theta2) -- otherwise bioequivalence can't be shown even with infinite sample size.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- PowerTOST::sampleN.TOST(
    alpha = alpha, targetpower = power, logscale = TRUE,
    theta0 = theta0, theta1 = theta1, theta2 = theta2,
    CV = cv, design = design, print = FALSE
  )

  list(
    n_total = fit[["Sample size"]],
    achieved_power = fit[["Achieved power"]],
    inputs = list(cv = cv, theta0 = theta0, theta1 = theta1, theta2 = theta2,
                  alpha = alpha, power = power, design = design)
  )
}

#' Sample size for a two one-sided tests (TOST) equivalence trial on proportions
#'
#' Wraps epiR::epi.ssequb(type = "equivalence") rather than reimplementing
#' the underlying math (project convention) -- no lightweight package with
#' a dedicated proportions-TOST function was found (PowerTOST/TOSTER are
#' both means/log-ratio focused), but epiR's non-inferiority/equivalence
#' family covers this directly.
#'
#' @param p_new Expected proportion of successes in the new-treatment group (0,1)
#' @param p_standard Expected proportion of successes in the standard-treatment group (0,1)
#' @param margin Equivalence margin (0,1); the true difference must fall
#'   within (-margin, +margin) to conclude equivalence
#' @param alpha One-sided significance level (0,1)
#' @param power Desired power (0,1)
#' @param ratio Number in the new-treatment group divided by the number in
#'   the standard-treatment group (> 0)
#' @return list(n_total, n_new, n_standard, inputs)
calc_tost_proportions <- function(p_new, p_standard, margin,
                                   alpha = 0.05, power = 0.8, ratio = 1) {
  .validate_unit_interval(p_new, "p_new")
  .validate_unit_interval(p_standard, "p_standard")
  .validate_unit_interval(margin, "margin")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")

  fit <- epiR::epi.ssequb(treat = p_new, control = p_standard, delta = margin,
                           n = NA, power = power, r = ratio, type = "equivalence",
                           nfractional = FALSE, alpha = alpha)

  list(
    n_total = fit$n.total,
    n_new = fit$n.treat,
    n_standard = fit$n.control,
    inputs = list(p_new = p_new, p_standard = p_standard, margin = margin,
                  alpha = alpha, power = power, ratio = ratio)
  )
}
