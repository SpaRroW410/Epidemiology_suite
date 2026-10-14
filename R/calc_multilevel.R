# Multilevel (mixed-model) longitudinal power: 2-level (subjects with
# repeated measures) and 3-level (subjects nested in clusters, e.g. a
# cluster-randomized trial with repeated measures) designs -- the
# "closed-form, equal group/cluster sizes, no missing data" case of
# `powerlmm::study_parameters()` + `get_power()`.
#
# Reimplemented from scratch by reading that package's own source
# (`get_se_classic()` and `var_T()` in R/power.R, and the var_ratio/icc_slope
# variance-component solving in R/setup.R) -- installed in this sandbox via
# the github.com/cran/powerlmm mirror (see the Trial Sequential Analysis
# entry in docs/checklist_by_design.md's Phase 6 batch 4 for how that route
# was found), then used purely as a verification oracle per this project's
# vendoring policy: no new runtime dependency is added.
#
# Verified exactly (bit-for-bit) against real `powerlmm::get_power()` calls
# for both the 2-level and 3-level cases, including confirming a genuine and
# non-obvious property of the underlying model: under `powerlmm`'s own
# default (uncorrelated random intercept/slope, `cor_subject = cor_cluster =
# 0`), icc_pre_subject and icc_pre_cluster have NO effect on the power of
# this slope-difference test -- confirmed directly by running the real
# package across 5 (2-level) and 6 (3-level) different ICC values with every
# other input held fixed and observing bit-identical power each time. Those
# two inputs describe baseline (intercept) variance, which this test's
# noncentrality parameter does not depend on -- so they are honestly left
# out of this calculator's inputs rather than included as inert decoration.
# `icc_slope` (the fraction of *slope* variance that is between-cluster, not
# between-subject) does matter for the 3-level case and is kept.
#
# Dropout/missing data is NOT covered -- that case abandons this closed
# form for a linear-algebra (matrix) solution in the real package that was
# judged too large a reimplementation surface to verify confidently in one
# batch; left open for a future batch.

.var_T <- function(n1, T_end) {
  T_end^2 * (n1 + 1) / (12 * (n1 - 1))
}

.noncentral_t_power_two_sided <- function(lambda, df, alpha) {
  crit <- qt(1 - alpha / 2, df)
  pt(crit, df, ncp = abs(lambda), lower.tail = FALSE) +
    pt(-crit, df, ncp = abs(lambda), lower.tail = TRUE)
}

calc_multilevel_two_level <- function(n1, T_end, var_ratio, delta, sigma_error = 10,
                                       alpha = 0.05, power = 0.8) {
  .validate_positive(n1, "n1 (number of measurement occasions)")
  if (n1 < 2) stop("n1 must be at least 2 (a baseline and at least one follow-up).")
  .validate_positive(T_end, "T_end (study duration)")
  .validate_positive(var_ratio, "var_ratio")
  .validate_number(delta, "delta")
  if (isTRUE(all.equal(delta, 0))) stop("delta must be nonzero.")
  .validate_positive(sigma_error, "sigma_error")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  u1 <- sqrt(var_ratio * sigma_error^2)
  sx <- .var_T(n1, T_end)
  slope_diff <- delta / T_end

  power_at_n2 <- function(n2) {
    var_arm <- (sigma_error^2 + n1 * u1^2 * sx) / (n1 * n2 * sx)
    se <- sqrt(2 * var_arm)
    df <- 2 * n2 - 2
    .noncentral_t_power_two_sided(slope_diff / se, df, alpha)
  }

  root <- uniroot(function(n2) power_at_n2(n2) - power, interval = c(3, 1e6))$root
  n2 <- ceiling(root)

  new_ss_result(list(
    n_per_arm = n2,
    n_total = 2 * n2,
    achieved_power = power_at_n2(n2),
    inputs = list(n1 = n1, T_end = T_end, var_ratio = var_ratio, delta = delta,
                  sigma_error = sigma_error, alpha = alpha, power = power)
  ))
}

calc_multilevel_three_level <- function(n1, n2, T_end, var_ratio, icc_slope, delta,
                                         sigma_error = 10, alpha = 0.05, power = 0.8) {
  .validate_positive(n1, "n1 (number of measurement occasions)")
  if (n1 < 2) stop("n1 must be at least 2 (a baseline and at least one follow-up).")
  .validate_positive(n2, "n2 (subjects per cluster)")
  .validate_positive(T_end, "T_end (study duration)")
  .validate_positive(var_ratio, "var_ratio")
  .validate_unit_interval(icc_slope, "icc_slope")
  .validate_number(delta, "delta")
  if (isTRUE(all.equal(delta, 0))) stop("delta must be nonzero.")
  .validate_positive(sigma_error, "sigma_error")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  u1 <- sqrt(var_ratio * sigma_error^2 * (1 - icc_slope))
  v1 <- sqrt(var_ratio * sigma_error^2 * icc_slope)
  sx <- .var_T(n1, T_end)
  slope_diff <- delta / T_end

  power_at_n3 <- function(n3) {
    var_arm <- (sigma_error^2 + n1 * u1^2 * sx + n1 * n2 * v1^2 * sx) / (n1 * n2 * n3 * sx)
    se <- sqrt(2 * var_arm)
    df <- 2 * n3 - 2
    .noncentral_t_power_two_sided(slope_diff / se, df, alpha)
  }

  root <- uniroot(function(n3) power_at_n3(n3) - power, interval = c(2, 1e5))$root
  n3 <- ceiling(root)

  new_ss_result(list(
    n_clusters_per_arm = n3,
    n_subjects_per_cluster = n2,
    n_total_clusters = 2 * n3,
    n_total_subjects = 2 * n3 * n2,
    achieved_power = power_at_n3(n3),
    inputs = list(n1 = n1, n2 = n2, T_end = T_end, var_ratio = var_ratio, icc_slope = icc_slope,
                  delta = delta, sigma_error = sigma_error, alpha = alpha, power = power)
  ))
}
