# Pure closed-form calculation function for a stepped-wedge cluster-
# randomized trial (continuous outcome). Reimplements the Hooper, Teerenstra,
# de Hoop & Woertman (2016) design-effect formula, which -- unlike the
# popular simplified restatements the methodological literature has flagged
# as sometimes diverging from the true GLS-derived variance (Kristunas et
# al., Trials) -- explicitly models the within-cluster correlation decaying
# over time (via the cluster autocorrelation rho_c) rather than assuming a
# single constant ICC across all time lags. Extracted from, and verified
# bit-for-bit against, clusterPower::cpa.sw.normal()'s own internal power
# computation (clusterPower installed via the github.com/cran mirror as a
# verification oracle only -- not a runtime dependency, per this project's
# vendoring policy). The companion binary-outcome function,
# clusterPower::cpa.sw.binary(), is a Gauss-Legendre-quadrature/Fortran-
# backed numerical GEE procedure with no closed form to extract -- out of
# scope for reimplementation here, so only the continuous-outcome case is
# covered.

#' Stepped-wedge cluster-randomized trial sample size (continuous outcome)
#'
#' Solves for the number of clusters crossing over to the intervention at
#' each step of a stepped-wedge design, given the per-cluster-per-time-point
#' sample size, the number of post-baseline time points, the ICC, the
#' cluster and individual autocorrelations, and the total outcome variance.
#'
#' @param nsubjects Number of subjects observed per cluster at each time
#'   point (> 0)
#' @param ntimes Number of post-baseline time points/steps in the trial
#'   (whole number >= 2)
#' @param d Expected (absolute) treatment effect (> 0)
#' @param icc Intracluster correlation coefficient, [0, 1)
#' @param rho_c Cluster autocorrelation: the correlation between two
#'   cluster-level means from the same cluster at different times, [0, 1]
#' @param rho_s Individual autocorrelation: the correlation between two
#'   outcome measurements on the same individual at different times, [0, 1]
#'   -- 0 for a cross-sectional design (new individuals sampled at each
#'   time point), > 0 for a closed-cohort design (the same individuals
#'   followed over time)
#' @param vart Total outcome variance (> 0)
#' @param alpha Two-sided type I error rate (0,1)
#' @param power Desired power (0,1)
#' @return list(nclusters, achieved_power, deff_cluster, deff_time, vif, inputs)
calc_stepped_wedge_normal <- function(nsubjects, ntimes, d, icc, rho_c, rho_s, vart,
                                       alpha = 0.05, power = 0.8) {
  .validate_positive(nsubjects, "nsubjects")
  if (!is.numeric(ntimes) || length(ntimes) != 1 || is.na(ntimes) ||
        ntimes < 2 || ntimes != round(ntimes)) {
    stop("ntimes must be a single whole number >= 2.")
  }
  .validate_positive(d, "d")
  if (!is.numeric(icc) || length(icc) != 1 || is.na(icc) || icc < 0 || icc >= 1) {
    stop("icc must be a single number in [0, 1).")
  }
  if (!is.numeric(rho_c) || length(rho_c) != 1 || is.na(rho_c) || rho_c < 0 || rho_c > 1) {
    stop("rho_c must be a single number in [0, 1].")
  }
  if (!is.numeric(rho_s) || length(rho_s) != 1 || is.na(rho_s) || rho_s < 0 || rho_s > 1) {
    stop("rho_s must be a single number in [0, 1].")
  }
  .validate_positive(vart, "vart")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  deff_cluster <- 1 + (nsubjects - 1) * icc
  r <- (nsubjects * icc * rho_c + (1 - icc) * rho_s) / deff_cluster
  deff_time <- 3 * ntimes * (1 - r) * (1 + ntimes * r) / ((ntimes^2 - 1) * (2 + ntimes * r))
  vif <- deff_time * deff_cluster

  power_at_n <- function(nclusters) {
    zcrit <- qnorm(alpha / 2, lower.tail = FALSE)
    zstat <- abs(d) / sqrt(4 * vart / (nclusters * nsubjects * ntimes) * vif)
    pnorm(zcrit, zstat, lower.tail = FALSE)
  }

  nclusters_raw <- tryCatch(
    stats::uniroot(function(n) power_at_n(n) - power,
                    interval = c(2 + 1e-10, 1e7), extendInt = "upX")$root,
    error = function(e) stop("No feasible design found -- try a larger effect size, more time points, or a less stringent power/alpha.")
  )
  nclusters <- ceiling(round(nclusters_raw, 6))

  list(
    nclusters = nclusters,
    achieved_power = power_at_n(nclusters),
    deff_cluster = deff_cluster,
    deff_time = deff_time,
    vif = vif,
    inputs = list(nsubjects = nsubjects, ntimes = ntimes, d = d, icc = icc,
                  rho_c = rho_c, rho_s = rho_s, vart = vart, alpha = alpha, power = power)
  )
}
