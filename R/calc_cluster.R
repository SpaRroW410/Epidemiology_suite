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
#' so more total subjects are needed to reach the same precision/power. This
#' applies to any cluster design: a survey of villages or schools, a
#' cluster-randomised trial, or a quasi-experimental community trial.
#'
#' Give the design effect itself (`deff`), or the ICC and the average cluster size, or work it out from the variance between clusters
#' with [calc_cluster_deff_variance()]. When nothing is known, a design effect of 1.5 is commonly assumed, and 2 is also common; no source
#' for these values was checked.
#'
#' @param n_base Required sample size under simple random sampling (whole
#'   number >= 1), e.g. from a single-proportion or single-mean calculator
#' @param icc Intraclass correlation coefficient (ICC / rho) between
#'   subjects in the same cluster, \[0, 1)
#' @param cluster_size Average number of subjects sampled per cluster (>= 1)
#' @param deff The design effect itself (> 0), instead of `icc` and `cluster_size`
#' @return list(deff, n_effective, inputs)
#' @examples
#' calc_cluster_deff(n_base = 200, icc = 0.05, cluster_size = 10)
#' calc_cluster_deff(n_base = 200, deff = 1.5)
#' @export
calc_cluster_deff <- function(n_base, icc = NULL, cluster_size = NULL, deff = NULL) {
  if (!is.numeric(n_base) || length(n_base) != 1 || is.na(n_base) ||
        n_base < 1 || n_base != round(n_base)) {
    stop("n_base must be a single whole number >= 1.")
  }
  if (!is.null(deff)) {
    if (!is.null(icc) || !is.null(cluster_size)) stop("Give either the design effect, or the ICC and the cluster size, not both.", call. = FALSE)
    if (!is.numeric(deff) || length(deff) != 1 || is.na(deff) || !is.finite(deff) || deff <= 0) {
      stop("deff must be a single number greater than 0.", call. = FALSE)
    }
    return(new_ss_result(list(deff = deff, n_effective = ceiling(round(n_base * deff, 6)),
                              inputs = list(n_base = n_base, deff = deff))))
  }
  if (is.null(icc) || is.null(cluster_size)) stop("Give the ICC and the cluster size, or the design effect.", call. = FALSE)
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

#' Design effect from the variance between clusters
#'
#' Works out the design effect (DEFF) and the intracluster correlation (ICC) of a cluster design from variances, three ways. Give
#' exactly one set:
#' \itemize{
#'   \item **Variance components** (`var_between`, `var_within`): ICC = var_between / (var_between + var_within), DEFF = 1 + (m - 1) ICC.
#'   \item **Variance of the cluster means or proportions** (`var_means`, with the individual-level variance `var_total`, or for a
#'     proportion the overall proportion `p`), for clusters of about equal size m: the variance of a cluster mean is
#'     var_total (1 + (m - 1) ICC) / m, so DEFF = m var_means / var_total (and for a proportion var_total = p (1 - p)).
#'   \item **The variance of the estimate under the design and under simple random sampling** (`var_design`, `var_srs`): DEFF is their
#'     ratio (the definition of the design effect).
#' }
#' Applies to any cluster design: a survey of villages or schools, a cluster-randomised trial, or a quasi-experimental community trial.
#'
#' @param cluster_size Average number of subjects per cluster, m (>= 1); needed for the first two sets
#' @param var_between,var_within Between-cluster and within-cluster variance components (>= 0, > 0)
#' @param var_means Variance of the observed cluster means (or cluster proportions), >= 0
#' @param var_total Total (individual-level) variance of the outcome, > 0
#' @param p Overall proportion, in (0, 1), instead of `var_total` for a binary outcome
#' @param var_design,var_srs Variance of the estimate under the cluster design and under simple random sampling of the same total size
#' @param n_base Optional sample size under simple random sampling to inflate by the design effect
#' @return A named list of class `ss_result` with `deff`, `icc` (NA when it cannot be derived), `n_effective` (when `n_base` is
#'   given), `notes` (warnings) and `inputs`.
#' @examples
#' calc_cluster_deff_variance(cluster_size = 10, var_between = 2, var_within = 38)
#' calc_cluster_deff_variance(cluster_size = 20, var_means = 0.0125, p = 0.3)
#' @export
calc_cluster_deff_variance <- function(cluster_size = NULL, var_between = NULL, var_within = NULL, var_means = NULL, var_total = NULL, p = NULL,
                                       var_design = NULL, var_srs = NULL, n_base = NULL) {
  pos <- function(x, label, allow_zero = FALSE) {
    if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 0 || (!allow_zero && x == 0)) {
      stop(sprintf("%s must be a single number %s.", label, if (allow_zero) ">= 0" else "greater than 0"), call. = FALSE)
    }
    x
  }
  sets <- c(components = !is.null(var_between) || !is.null(var_within),
            means = !is.null(var_means) || !is.null(var_total) || !is.null(p),
            design = !is.null(var_design) || !is.null(var_srs))
  if (sum(sets) != 1) stop("Give exactly one set: the between- and within-cluster variances, the variance of the cluster means (with the total variance or p), or the variances under the design and under simple random sampling.", call. = FALSE)
  m <- if (!is.null(cluster_size)) {
    if (!is.numeric(cluster_size) || length(cluster_size) != 1 || is.na(cluster_size) || cluster_size < 1) stop("cluster_size must be a single number >= 1.", call. = FALSE)
    cluster_size
  }
  if (!is.null(n_base) && (!is.numeric(n_base) || length(n_base) != 1 || is.na(n_base) || n_base < 1 || n_base != round(n_base))) {
    stop("n_base must be a single whole number >= 1.", call. = FALSE)
  }
  notes <- character()
  if (sets[["components"]]) {
    if (is.null(var_between) || is.null(var_within)) stop("Give both the between-cluster and the within-cluster variance.", call. = FALSE)
    if (is.null(m)) stop("Give the average cluster size.", call. = FALSE)
    vb <- pos(var_between, "var_between", TRUE); vw <- pos(var_within, "var_within")
    icc <- vb / (vb + vw)
    deff <- 1 + (m - 1) * icc
    basis <- "variance components: ICC = between / (between + within), DEFF = 1 + (m - 1) ICC"
  } else if (sets[["means"]]) {
    if (is.null(var_means)) stop("Give the variance of the cluster means (or proportions).", call. = FALSE)
    if (is.null(m)) stop("Give the average cluster size.", call. = FALSE)
    if (!is.null(var_total) && !is.null(p)) stop("Give either the total variance or the overall proportion, not both.", call. = FALSE)
    if (is.null(var_total) && is.null(p)) stop("Give the total (individual-level) variance, or for a proportion the overall proportion p.", call. = FALSE)
    vt <- if (!is.null(p)) {
      if (!is.numeric(p) || length(p) != 1 || is.na(p) || p <= 0 || p >= 1) stop("p must be a single number strictly between 0 and 1.", call. = FALSE)
      p * (1 - p)
    } else pos(var_total, "var_total")
    deff <- m * pos(var_means, "var_means", TRUE) / vt
    icc <- if (m > 1) (deff - 1) / (m - 1) else NA_real_
    basis <- "variance of the cluster means: DEFF = m x var(cluster means) / total variance (clusters of about equal size)"
    if (!is.na(icc) && icc < 0) notes <- c(notes, "The variance of the cluster means is smaller than simple random sampling would give (DEFF < 1, a negative ICC): this can happen by chance with few clusters; a design effect below 1 is usually replaced by 1.")
  } else {
    if (is.null(var_design) || is.null(var_srs)) stop("Give both the variance under the cluster design and under simple random sampling.", call. = FALSE)
    deff <- pos(var_design, "var_design") / pos(var_srs, "var_srs")
    icc <- if (!is.null(m) && m > 1) (deff - 1) / (m - 1) else NA_real_
    basis <- "the ratio of the variance of the estimate under the design to that under simple random sampling (the definition of DEFF)"
  }
  if (!is.na(icc) && icc > 1) notes <- c(notes, "The implied ICC is above 1, which is not possible: check the variances and the cluster size.")
  if (deff < 1) notes <- c(notes, "The design effect is below 1 (the clusters are more varied than the population); it is usually taken as 1 when planning.")
  out <- list(deff = deff, icc = icc)
  if (!is.null(n_base)) out$n_effective <- ceiling(round(n_base * deff, 6))
  new_ss_result(c(out, list(basis = basis, notes = notes,
                            inputs = list(cluster_size = cluster_size, var_between = var_between, var_within = var_within, var_means = var_means,
                                          var_total = var_total, p = p, var_design = var_design, var_srs = var_srs, n_base = n_base))))
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
#' @param nonresponse Expected fraction of the individuals selected in each cluster who are not analyzable (non-response,
#'   refusal), in \[0, 1). The number of clusters is unchanged; each cluster selects b / (1 - nonresponse) individuals, rounded up.
#' @details The calculation is refused when the interval p +/- d would pass 0 or 1 (d >= p or d >= 1 - p, d = epsilon x p for a
#'   relative precision) or a relative precision is 100% or more; a relative precision above 20%, and a proportion below 10% (above
#'   90%) with d above one-fourth of p (of 1 - p), give a warning in `precision_notes`.
#' @return A named list of class `ss_result` with `n_psu` (clusters), `n_ssu` (individuals to analyze), `deff`, and when
#'   `nonresponse` > 0 `b_enrolled` (individuals to select per cluster) and `n_ssu_enrolled` (n_psu x b_enrolled), then
#'   `d_absolute`, `epsilon_relative`, `precision_notes` and `inputs`.
#' @examples
#' calc_cluster_survey_binary(b = 75, p = 0.46, epsilon = 0.1, error = "relative", 
#'     rho = 0.2, conf_level = 0.9)
#' @export
calc_cluster_survey_binary <- function(b, b_sd = NULL, p, epsilon,
                                        error = c("relative", "absolute"),
                                        rho, N_psu = NULL, conf_level = 0.95, nonresponse = 0) {
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
  .validate_nonresponse(nonresponse)
  chk <- .precision_checks_proportion(p, epsilon, error, "p")

  b_arg <- if (is.null(b_sd)) b else c(b, b_sd)

  fit <- .cf_ssclus2estb(
    N.psu = if (is.null(N_psu)) NA else N_psu,
    b = b_arg, Py = p, epsilon = epsilon, error = error, rho = rho,
    conf.level = conf_level
  )

  out <- list(n_psu = fit$n.psu, n_ssu = fit$n.ssu, deff = fit$DEF)
  if (nonresponse > 0) {
    out$b_enrolled <- .inflate_nonresponse(b, nonresponse)
    out$n_ssu_enrolled <- fit$n.psu * out$b_enrolled
  }
  new_ss_result(c(out, list(
    d_absolute = chk$d,
    epsilon_relative = chk$epsilon,
    precision_notes = chk$notes,
    inputs = list(b = b, b_sd = b_sd, p = p, epsilon = epsilon, error = error,
                  rho = rho, N_psu = N_psu, conf_level = conf_level, nonresponse = nonresponse)
  )))
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
