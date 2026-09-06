# Pure closed-form calculation function for cluster/multistage sampling's
# design effect (DEFF) inflation. No package needed; DEFF = 1 + (m-1)*rho is
# a standard closed-form identity (Kish 1965), not something any CRAN
# package wraps in a dedicated function. Also includes
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
#'   subjects in the same cluster, [0, 1)
#' @param cluster_size Average number of subjects sampled per cluster (>= 1)
#' @return list(deff, n_effective, inputs)
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

  list(
    deff = deff,
    n_effective = n_effective,
    inputs = list(n_base = n_base, icc = icc, cluster_size = cluster_size)
  )
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
#' @param rho Intracluster correlation coefficient (ICC), [0, 1)
#' @param N_psu Optional total number of clusters (PSUs) in the source
#'   population, for a finite-population correction (NULL = effectively
#'   infinite, the usual case for a large community/region)
#' @param conf_level Confidence level (0,1)
#' @return list(n_psu, n_ssu, deff, inputs)
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

  fit <- epiR::epi.ssclus2estb(
    N.psu = if (is.null(N_psu)) NA else N_psu,
    b = b_arg, Py = p, epsilon = epsilon, error = error, rho = rho,
    conf.level = conf_level
  )

  list(
    n_psu = fit$n.psu,
    n_ssu = fit$n.ssu,
    deff = fit$DEF,
    inputs = list(b = b, b_sd = b_sd, p = p, epsilon = epsilon, error = error,
                  rho = rho, N_psu = N_psu, conf_level = conf_level)
  )
}
