# Pure closed-form calculation functions for cluster/multistage sampling's
# design effect (DEFF) inflation. No package needed; DEFF = 1 + (m-1)*rho is
# a standard closed-form identity (Kish 1965), not something any CRAN
# package wraps in a dedicated function. calc_cluster_deff_variable()
# generalizes this to variable (unequal) cluster sizes via a
# coefficient-of-variation term; the formula was extracted from, and
# verified bit-for-bit against, clusterPower::cpa.binary()/cpa.normal()'s
# own internal DEFF/VIF computation (clusterPower installed via the
# github.com/cran mirror as a verification oracle only -- not a runtime
# dependency, per this project's vendoring policy). Also includes
# calc_cluster_survey_binary(), which DOES wrap a package function
# (epiR::epi.ssclus2estb()) directly, since that one solves the full
# WHO-EPI-style cluster survey design (PSU + SSU counts together), not
# just a DEFF multiplier on an externally-computed base n.

#' Design-effect-inflated sample size for a cluster/multistage sample
#'
#' Given a base sample size already computed under a simple-random-sampling
#' assumption (e.g. from the Proportions or Means modules), inflates it for
#' the loss of statistical efficiency from cluster sampling: subjects within
#' the same cluster tend to be more alike than subjects drawn independently,
#' so more total subjects are needed to reach the same precision/power.
#'
#' @param n_base Required sample size under simple random sampling (whole
#'   number >= 1), e.g. from a single-proportion or single-mean calculator
#' @param icc Intraclass correlation coefficient (ICC / rho) between
#'   subjects in the same cluster, \[0, 1)
#' @param cluster_size Average number of subjects sampled per cluster (>= 1)
#' @return list(deff, n_effective, inputs)
#' @examples
#' calc_cluster_deff(n_base = 200, icc = 0.05, cluster_size = 10)
#' @export
calc_cluster_deff <- function(n_base, icc, cluster_size) {
  if (!is.numeric(n_base) || length(n_base) != 1 || is.na(n_base) ||
        n_base < 1 || n_base != round(n_base)) {
    stop("n_base must be a single whole number >= 1.")
  }
  if (!is.numeric(icc) || length(icc) != 1 || is.na(icc) || icc < 0 || icc >= 1) {
    stop("icc must be a single number in [0, 1).")
  }
  if (!is.numeric(cluster_size) || length(cluster_size) != 1 || is.na(cluster_size) ||
        cluster_size < 1) {
    stop("cluster_size must be a single number >= 1.")
  }

  deff <- 1 + (cluster_size - 1) * icc
  n_effective <- ceiling(n_base * deff)

  new_ss_result(list(
    deff = deff,
    n_effective = n_effective,
    inputs = list(n_base = n_base, icc = icc, cluster_size = cluster_size)
  ))
}

#' Design-effect-inflated sample size allowing for variable cluster size
#'
#' Generalizes calc_cluster_deff() to the realistic case where cluster
#' sizes are not all identical: real clusters (villages, clinics, schools)
#' recruit different numbers of subjects, and that extra between-cluster
#' variability in size itself inflates the required sample size beyond the
#' constant-cluster-size Kish DEFF. Setting cv = 0 recovers
#' calc_cluster_deff()'s formula exactly, since the coefficient-of-variation
#' term then drops out.
#'
#' @param n_base Required sample size under simple random sampling (whole
#'   number >= 1), e.g. from a single-proportion or single-mean calculator
#' @param icc Intraclass correlation coefficient (ICC / rho) between
#'   subjects in the same cluster, \[0, 1)
#' @param cluster_size Average number of subjects sampled per cluster (>= 1)
#' @param cv Coefficient of variation of cluster sizes (SD / mean across
#'   clusters), >= 0; 0 means every cluster has the same size
#' @return list(deff, n_effective, inputs)
#' @examples
#' calc_cluster_deff_variable(n_base = 200, icc = 0.05, cluster_size = 10, cv = 0)
#' @export
calc_cluster_deff_variable <- function(n_base, icc, cluster_size, cv) {
  if (!is.numeric(n_base) || length(n_base) != 1 || is.na(n_base) ||
        n_base < 1 || n_base != round(n_base)) {
    stop("n_base must be a single whole number >= 1.")
  }
  if (!is.numeric(icc) || length(icc) != 1 || is.na(icc) || icc < 0 || icc >= 1) {
    stop("icc must be a single number in [0, 1).")
  }
  if (!is.numeric(cluster_size) || length(cluster_size) != 1 || is.na(cluster_size) ||
        cluster_size < 1) {
    stop("cluster_size must be a single number >= 1.")
  }
  if (!is.numeric(cv) || length(cv) != 1 || is.na(cv) || cv < 0) {
    stop("cv must be a single number >= 0.")
  }

  deff <- 1 + ((cv^2 + 1) * cluster_size - 1) * icc
  # round() before ceiling() guards against floating-point fuzz (e.g.
  # 100 * 2.2 landing a hair above 220.0) inflating an exact whole-number
  # result by one.
  n_effective <- ceiling(round(n_base * deff, 6))

  new_ss_result(list(
    deff = deff,
    n_effective = n_effective,
    inputs = list(n_base = n_base, icc = icc, cluster_size = cluster_size, cv = cv)
  ))
}

#' Sample size for a cluster survey estimating a proportion (WHO EPI-style)
#'
#' Wraps epiR::epi.ssclus2estb() rather than reimplementing the underlying
#' math (project convention) -- epiR already a project dependency. Solves
#' for both the number of clusters (primary sampling units / PSUs) and
#' the total number of individuals (secondary sampling units / SSUs)
#' needed to estimate a population proportion to a target precision,
#' given the intracluster correlation (ICC) -- the closed-form basis of
#' WHO's classic 30-cluster survey methodology (Henderson & Sundaresan
#' 1982), generalized to any number of clusters/precision target.
#'
#' Note: epiR::epi.ssclus1estb() ("one-stage" cluster sampling, where
#' every individual in a sampled cluster is enumerated) is, on inspection
#' of both functions' source code, byte-for-byte identical to
#' epi.ssclus2estb() ("two-stage", where a subsample of b individuals is
#' drawn from each cluster) -- the package provides two identically-
#' behaving functions under different names for this case (only their
#' continuous-outcome siblings, epi.ssclus1estc()/epi.ssclus2estc(),
#' genuinely differ, in how a finite total-population size is applied).
#' This calculator therefore covers both the one-stage and two-stage
#' binary-outcome cases; `b` should be read as "individuals examined per
#' cluster" either way.
#'
#' @param b Average number of individuals sampled/examined per cluster (> 0)
#' @param b_sd Optional standard deviation of the number of individuals
#'   sampled per cluster, if cluster size varies (NULL = constant cluster size)
#' @param p Expected proportion (prevalence) being estimated (0,1)
#' @param epsilon Desired precision / margin of error (> 0)
#' @param error "relative" (epsilon as a fraction of p) or "absolute"
#'   (epsilon on the same 0-1 scale as p)
#' @param rho Intracluster correlation coefficient (ICC), \[0, 1)
#' @param N_psu Optional total number of clusters (PSUs) in the source
#'   population, for a finite-population correction (NULL = effectively
#'   infinite, the usual case for a large community/region)
#' @param conf_level Confidence level (0,1)
#' @return list(n_psu, n_ssu, deff, inputs)
#' @examples
#' calc_cluster_survey_binary(b = 75, p = 0.46, epsilon = 0.1, error = "relative", 
#'     rho = 0.2, conf_level = 0.9)
#' @export
calc_cluster_survey_binary <- function(b, b_sd = NULL, p, epsilon,
                                        error = c("relative", "absolute"),
                                        rho, N_psu = NULL, conf_level = 0.95) {
  error <- match.arg(error)
  .validate_positive(b, "b")
  if (!is.null(b_sd)) .validate_positive(b_sd, "b_sd")
  .validate_unit_interval(p, "p")
  .validate_positive(epsilon, "epsilon")
  if (!is.numeric(rho) || length(rho) != 1 || is.na(rho) || rho < 0 || rho >= 1) {
    stop("rho must be a single number in [0, 1).")
  }
  if (!is.null(N_psu)) .validate_population(N_psu, "N_psu")
  .validate_unit_interval(conf_level, "conf_level")

  b_arg <- if (is.null(b_sd)) b else c(b, b_sd)

  fit <- .cf_ssclus2estb(
    N.psu = if (is.null(N_psu)) NA else N_psu,
    b = b_arg, Py = p, epsilon = epsilon, error = error, rho = rho,
    conf.level = conf_level
  )

  new_ss_result(list(
    n_psu = fit$n.psu,
    n_ssu = fit$n.ssu,
    deff = fit$DEF,
    inputs = list(b = b, b_sd = b_sd, p = p, epsilon = epsilon, error = error,
                  rho = rho, N_psu = N_psu, conf_level = conf_level)
  ))
}

#' Optimal two-stage (PPS) cluster sample allocation: PSUs and take-b
#'
#' Solves the classic Hansen, Hurwitz & Madow (1953) cost-optimization
#' problem for a two-stage sample selected PPS (probability-proportional-
#' to-size) at the first stage and SRS within each sampled cluster at the
#' second: given the relative cost of adding a cluster (PSU) vs. adding an
#' element within an already-sampled cluster, and the intracluster
#' homogeneity (delta/ICC), what "take" (elements per cluster, b) MINIMIZES
#' variance for a fixed budget, or MINIMIZES cost for a target precision
#' (CV)? This directly answers the item this app's checklist names:
#' the optimal take b depends only on the cost ratio and delta -- NOT on
#' the number of PSUs -- while the number of PSUs (m) is then whatever the
#' budget or target CV implies once b is fixed. This is the standard
#' methodology behind DHS-style survey sample design (DHS Sampling and
#' Household Listing Manual, Working Paper 30).
#'
#' Reimplemented from, and verified bit-for-bit against,
#' `PracTools::clusOpt2()`'s own source (`PracTools` installed via the
#' github.com/cran mirror as a verification oracle only -- not a runtime
#' dependency, per this project's vendoring policy).
#'
#' @param cost_psu Cost of adding one more cluster (PSU) to the sample (> 0)
#' @param cost_element Cost of adding one more element within an already-
#'   sampled cluster (> 0)
#' @param delta Intracluster homogeneity measure (ICC-like), (0, 1)
#' @param unit_relvar Unit relvariance of the variable being measured
#'   (> 0; 1 if unknown -- a conservative/neutral default)
#' @param k Ratio of (between-PSU + within-PSU variance) to the unit
#'   relvariance (> 0; 1 if unknown)
#' @param mode "budget" (solve for the number of PSUs and achieved CV
#'   given a fixed total budget) or "precision" (solve for the number of
#'   PSUs and resulting cost given a target CV)
#' @param total_budget Total variable-cost budget (> 0; required if
#'   mode = "budget")
#' @param target_cv Target coefficient of variation (> 0; required if
#'   mode = "precision")
#' @return list(n_opt, m_opt, cv, cost, inputs)
#' @examples
#' calc_cluster_pps_optimal_allocation(cost_psu = 750, cost_element = 100, delta = 0.05, 
#'     unit_relvar = 1, k = 1, mode = "budget", total_budget = 1e+05)
#' @export
calc_cluster_pps_optimal_allocation <- function(cost_psu, cost_element, delta,
                                                 unit_relvar = 1, k = 1,
                                                 mode = c("budget", "precision"),
                                                 total_budget = NULL, target_cv = NULL) {
  mode <- match.arg(mode)
  .validate_positive(cost_psu, "cost_psu")
  .validate_positive(cost_element, "cost_element")
  if (!is.numeric(delta) || length(delta) != 1 || is.na(delta) || delta <= 0 || delta >= 1) {
    stop("delta must be a single number in (0, 1).")
  }
  .validate_positive(unit_relvar, "unit_relvar")
  .validate_positive(k, "k")

  n_opt <- sqrt((cost_psu / cost_element) * (1 - delta) / delta)

  if (mode == "budget") {
    .validate_positive(total_budget, "total_budget")
    m_opt <- total_budget / (cost_psu + cost_element * n_opt)
    if (m_opt < 0) stop("Computed m_opt is negative -- check inputs.")
    cv <- sqrt(unit_relvar / m_opt / n_opt * k * (1 + delta * (n_opt - 1)))
    cost <- total_budget
  } else {
    .validate_positive(target_cv, "target_cv")
    m_opt <- unit_relvar * k * (1 + delta * (n_opt - 1)) / n_opt / target_cv^2
    if (m_opt < 0) stop("Computed m_opt is negative -- check inputs.")
    cv <- target_cv
    cost <- cost_psu * m_opt + cost_element * m_opt * n_opt
  }

  new_ss_result(list(
    n_opt = n_opt,
    m_opt = m_opt,
    cv = cv,
    cost = cost,
    inputs = list(cost_psu = cost_psu, cost_element = cost_element, delta = delta,
                  unit_relvar = unit_relvar, k = k, mode = mode,
                  total_budget = total_budget, target_cv = target_cv)
  ))
}
