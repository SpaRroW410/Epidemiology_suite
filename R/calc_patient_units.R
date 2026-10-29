# Several measurements per patient (both eyes, several lesions, patches, teeth, split-face / split-body): how many PATIENTS are
# needed when each patient contributes m correlated units. Pure calculation functions, no Shiny, no package needed at run time.
#
# Two situations, which differ in what the correlation between a patient's units does:
#
# 1. Treatment varies BETWEEN patients (every unit of a patient gets the same treatment, e.g. both eyes get drops A, the next
#    patient's both eyes get drops B). The patient is a cluster and its units are the cluster members, so the design effect applies:
#    VIF = 1 + ((CV^2 + 1) m - 1) rho (Donner & Klar 2000; the coefficient-of-variation form is Eldridge, Ashby & Kerry 2006).
#    Patients per arm k solve: power = P(T'(df = 2(k - 1), ncp) > t_{1 - alpha/2}), ncp = sqrt(k m / VIF) * e, with
#    e = |delta| / sqrt(2 sigma^2) (continuous) or |p1 - p2| / sqrt(p1 q1 + p2 q2) (binary). This is the power function used by
#    clusterPower::cpa.normal(method = "weighted") and cpa.binary(), against which tests/testthat/test-calc_patient_units.R checks it
#    (clusterPower is a verification oracle only, never a dependency).
#    Letting m grow, m / VIF -> 1 / ((CV^2 + 1) rho): a patient is never worth more than 1 / ((CV^2 + 1) rho) independent units, so
#    there is a floor under the number of patients that no number of extra units per patient can go below.
#
# 2. Treatment varies WITHIN patients (split-face, split-body, one eye each arm, m units per arm in every patient). Each patient
#    gives a difference between the mean of its treated units and the mean of its control units. If any two units of the same patient
#    have correlation rho (compound symmetry), Var(difference) = 2 sigma^2 (1 - rho) / m, and the patients are compared with a paired
#    t-test on those differences (N patients, df = N - 1). The variance is a short derivation (stated in the Formula tab), checked by
#    simulation in the tests; it is NOT taken from a paper I could cite for this exact form (Murdoch et al. 1998 describe the idea of
#    using the fellow eye as a control, not this formula).

.pu_vif <- function(m, icc, cv) 1 + ((cv^2 + 1) * m - 1) * icc

.pu_validate_units <- function(m, icc, cv = 0) {
  if (!is.numeric(m) || length(m) != 1 || is.na(m) || m < 1) stop("units per patient must be a single number >= 1 (use the average if it varies).")
  if (!is.numeric(icc) || length(icc) != 1 || is.na(icc) || icc < 0 || icc >= 1) stop("The correlation between units of the same patient must be a single number in [0, 1).")
  if (!is.numeric(cv) || length(cv) != 1 || is.na(cv) || cv < 0) stop("cv (variation of the number of units per patient) must be a single number >= 0.")
}

# power of the between-patient comparison with k patients per arm; r = m / VIF (effective independent units per patient)
.pu_power_between <- function(k, r, e, alpha) {
  df <- 2 * (k - 1)
  stats::pt(stats::qt(alpha / 2, df, lower.tail = FALSE), df, sqrt(k * r) * e, lower.tail = FALSE)
}

# smallest k (patients per arm, not rounded) reaching `power`; at least 2 patients per arm are needed for a t-test
.pu_solve_k <- function(r, e, alpha, power) {
  f <- function(k) .pu_power_between(k, r, e, alpha) - power
  if (f(2) >= 0) return(2)
  if (f(1e7) < 0) stop("More than 10 million patients per arm would be needed: check the effect size and the correlation.")
  stats::uniroot(f, c(2, 1e7), tol = 1e-10)$root
}

.pu_ceil <- function(x) ceiling(round(x, 6))

# the shared part of both between-patient designs
.pu_between <- function(e, m, icc, cv, alpha, power, inputs) {
  .pu_validate_units(m, icc, cv)
  vif <- .pu_vif(m, icc, cv)
  r <- m / vif
  k_exact <- .pu_solve_k(r, e, alpha, power)
  k <- .pu_ceil(k_exact)
  # the same comparison if every unit were an independent person: that many units per arm, spread over patients of m units
  n_indep_units <- .pu_ceil(.pu_solve_k(1, e, alpha, power) * 1)
  r_inf <- if (icc > 0) 1 / ((cv^2 + 1) * icc) else Inf
  floor_k <- if (is.finite(r_inf)) .pu_ceil(.pu_solve_k(r_inf, e, alpha, power)) else NA_real_
  new_ss_result(list(
    n_patients_per_arm = k,
    n_patients_total = 2 * k,
    n_units_total = 2 * k * m,
    n_patients_per_arm_exact = k_exact,
    design_effect = vif,
    effective_units_per_patient = r,
    n_patients_per_arm_if_units_independent = .pu_ceil(n_indep_units / m),
    n_patients_per_arm_floor = floor_k,
    inputs = inputs
  ))
}

#' Patients needed to compare two means when every unit of a patient gets the same treatment
#'
#' @param delta Difference between the two group means to detect (not 0)
#' @param sd Standard deviation of a single unit's measurement (all patients and units together; > 0)
#' @param icc Correlation between two units of the same patient, \[0, 1)
#' @param units_per_patient Number of units per patient (average, >= 1), e.g. 2 for both eyes
#' @param cv Coefficient of variation of the number of units per patient (0 if every patient has the same number)
#' @param alpha Two-sided significance level
#' @param power Desired power
#' @return list(n_patients_per_arm, n_patients_total, n_units_total, design_effect, ...)
#' @examples
#' calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = 0, units_per_patient = 1)
#' @export
calc_patient_units_between_continuous <- function(delta, sd, icc, units_per_patient, cv = 0, alpha = 0.05, power = 0.8) {
  .validate_number(delta, "delta"); .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha"); .validate_unit_interval(power, "power")
  if (delta == 0) stop("delta must not be 0 (no effect to detect).")
  .pu_between(abs(delta) / sqrt(2 * sd^2), units_per_patient, icc, cv, alpha, power,
              list(delta = delta, sd = sd, icc = icc, units_per_patient = units_per_patient, cv = cv, alpha = alpha, power = power))
}

#' Patients needed to compare two proportions when every unit of a patient gets the same treatment
#'
#' @param p1,p2 Proportions of units with the outcome in the two groups (strictly between 0 and 1, different)
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_patients_per_arm`, `n_patients_total`, `n_units_total`, `n_patients_per_arm_exact`, `design_effect`, `effective_units_per_patient`, `n_patients_per_arm_if_units_independent`, `n_patients_per_arm_floor` and `inputs`, the arguments the result was calculated from.
#' @inheritParams calc_patient_units_between_continuous
#' @examples
#' calc_patient_units_between_binary(p1 = 0.4, p2 = 0.25, icc = 0.3, units_per_patient = 2)
#' @export
calc_patient_units_between_binary <- function(p1, p2, icc, units_per_patient, cv = 0, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p1, "p1"); .validate_unit_interval(p2, "p2")
  .validate_unit_interval(alpha, "alpha"); .validate_unit_interval(power, "power")
  if (p1 == p2) stop("p1 and p2 must differ (no effect to detect).")
  .pu_between(abs(p1 - p2) / sqrt(p1 * (1 - p1) + p2 * (1 - p2)), units_per_patient, icc, cv, alpha, power,
              list(p1 = p1, p2 = p2, icc = icc, units_per_patient = units_per_patient, cv = cv, alpha = alpha, power = power))
}

#' Patients needed when each patient receives both treatments (split-face / split-body / one eye per arm)
#'
#' Every patient has `units_per_arm` units on each treatment; the two arm means of a patient are compared with a paired t-test.
#' @param delta Difference between treatments to detect (not 0)
#' @param sd Standard deviation of a single unit's measurement (> 0)
#' @param icc Correlation between any two units of the same patient (compound symmetry), \[0, 1)
#' @param units_per_arm Units per treatment in every patient (>= 1), e.g. 1 for one eye per arm
#' @param alpha,power As above.
#' @return list(n_patients, n_units_total, sd_difference, ...)
#' @examples
#' calc_patient_units_within_continuous(delta = 0.5, sd = 1, icc = 0.5, units_per_arm = 1)
#' @export
calc_patient_units_within_continuous <- function(delta, sd, icc, units_per_arm, alpha = 0.05, power = 0.8) {
  .validate_number(delta, "delta"); .validate_positive(sd, "sd")
  .validate_unit_interval(alpha, "alpha"); .validate_unit_interval(power, "power")
  if (delta == 0) stop("delta must not be 0 (no effect to detect).")
  .pu_validate_units(units_per_arm, icc, 0)
  sd_diff <- sd * sqrt(2 * (1 - icc) / units_per_arm)
  n_exact <- .cf_pwr_t_test(d = abs(delta) / sd_diff, sig.level = alpha, power = power, type = "paired")$n
  n <- .pu_ceil(n_exact)
  # the same two treatments in separate patients (all units of a patient on one treatment) at the same correlation
  between <- .pu_between(abs(delta) / sqrt(2 * sd^2), units_per_arm, icc, 0, alpha, power, list())
  new_ss_result(list(
    n_patients = n,
    n_units_total = n * 2 * units_per_arm,
    n_patients_exact = n_exact,
    sd_difference = sd_diff,
    n_patients_if_treatments_in_separate_patients = between$n_patients_total,
    inputs = list(delta = delta, sd = sd, icc = icc, units_per_arm = units_per_arm, alpha = alpha, power = power)
  ))
}

#' How many units per patient are needed when the number of patients is fixed
#'
#' @param design "between_continuous", "between_binary" or "within_continuous"
#' @param patients Patients per arm (between designs, >= 2) or patients in total (within design, >= 2)
#' @return A named list of class `ss_result` with `n_units_per_patient` (whole units needed per patient, or per treatment in a patient for the
#'   within design), `achievable`, `n_units_per_patient_exact`, `n_units_total`, `n_patients_per_arm_floor` and `inputs`. If even unlimited
#'   units per patient cannot reach the power with this many patients, `achievable` is `FALSE`, `n_units_per_patient` is `NA` and
#'   `n_patients_per_arm_floor` says how many patients are the minimum.
#' @param p1 Proportion of units with the outcome in group 1 (`design = "between_binary"`; strictly between 0 and 1).
#' @param p2 Proportion of units with the outcome in group 2 (`design = "between_binary"`; different from `p1`).
#' @inheritParams calc_patient_units_between_continuous
#' @examples
#' calc_patient_units_needed("between_binary", patients = 150, p1 = 0.4, p2 = 0.25, 
#'     icc = 0.3, cv = 0.2)
#' @export
calc_patient_units_needed <- function(design = c("between_continuous", "between_binary", "within_continuous"), patients,
                                      delta = NULL, sd = NULL, p1 = NULL, p2 = NULL, icc, cv = 0, alpha = 0.05, power = 0.8) {
  design <- match.arg(design)
  if (!is.numeric(patients) || length(patients) != 1 || is.na(patients) || patients < 2 || patients != round(patients))
    stop("patients must be a single whole number >= 2.")
  .validate_unit_interval(alpha, "alpha"); .validate_unit_interval(power, "power")
  .pu_validate_units(1, icc, if (design == "within_continuous") 0 else cv)
  if (design == "within_continuous") {
    .validate_number(delta, "delta"); .validate_positive(sd, "sd")
    if (delta == 0) stop("delta must not be 0 (no effect to detect).")
    pw <- function(m) .cf_pwr_t_test(n = patients, d = abs(delta) / (sd * sqrt(2 * (1 - icc) / m)), sig.level = alpha, type = "paired")$power
    if (pw(1) >= power) { m_exact <- 1 } else {
      m_exact <- stats::uniroot(function(m) pw(m) - power, c(1, 1e9), tol = 1e-10)$root
    }
    m <- .pu_ceil(m_exact)
    return(new_ss_result(list(
      n_units_per_patient = m, achievable = TRUE, n_units_per_patient_exact = m_exact, n_units_total = patients * 2 * m,
      inputs = list(design = design, patients = patients, delta = delta, sd = sd, icc = icc, alpha = alpha, power = power))))
  }
  if (design == "between_continuous") {
    .validate_number(delta, "delta"); .validate_positive(sd, "sd")
    if (delta == 0) stop("delta must not be 0 (no effect to detect).")
    e <- abs(delta) / sqrt(2 * sd^2)
  } else {
    .validate_unit_interval(p1, "p1"); .validate_unit_interval(p2, "p2")
    if (p1 == p2) stop("p1 and p2 must differ (no effect to detect).")
    e <- abs(p1 - p2) / sqrt(p1 * (1 - p1) + p2 * (1 - p2))
  }
  r_inf <- if (icc > 0) 1 / ((cv^2 + 1) * icc) else Inf
  floor_k <- if (is.finite(r_inf)) .pu_ceil(.pu_solve_k(r_inf, e, alpha, power)) else NA_real_
  pw <- function(r) .pu_power_between(patients, r, e, alpha) - power
  inputs <- list(design = design, patients = patients, icc = icc, cv = cv, alpha = alpha, power = power,
                 delta = delta, sd = sd, p1 = p1, p2 = p2)
  r_max <- if (is.finite(r_inf)) r_inf else 1e9
  if (pw(r_max) < 0 && is.finite(r_inf)) {
    return(new_ss_result(list(n_units_per_patient = NA_real_, achievable = FALSE, n_patients_per_arm_floor = floor_k, inputs = inputs)))
  }
  r_exact <- if (pw(1) >= 0) 1 else stats::uniroot(pw, c(1, r_max * (1 - 1e-12)), tol = 1e-12)$root
  m_exact <- if (r_exact <= 1) 1 else r_exact * (1 - icc) / (1 - r_exact * (cv^2 + 1) * icc)
  m <- .pu_ceil(m_exact)
  new_ss_result(list(n_units_per_patient = m, achievable = TRUE, n_units_per_patient_exact = m_exact,
                     n_units_total = 2 * patients * m, n_patients_per_arm_floor = floor_k, inputs = inputs))
}
