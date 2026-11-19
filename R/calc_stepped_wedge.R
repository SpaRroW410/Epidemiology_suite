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
#' @param icc Intracluster correlation coefficient, \[0, 1)
#' @param rho_c Cluster autocorrelation: the correlation between two
#'   cluster-level means from the same cluster at different times, \[0, 1\]
#' @param rho_s Individual autocorrelation: the correlation between two
#'   outcome measurements on the same individual at different times, \[0, 1\]
#'   -- 0 for a cross-sectional design (new individuals sampled at each
#'   time point), > 0 for a closed-cohort design (the same individuals
#'   followed over time)
#' @param vart Total outcome variance (> 0)
#' @param alpha Two-sided type I error rate (0,1)
#' @param power Desired power (0,1)
#' @return list(nclusters, achieved_power, deff_cluster, deff_time, vif, inputs)
#' @examples
#' calc_stepped_wedge_normal(nsubjects = 50, ntimes = 5, d = 1.5, icc = 0.2, rho_c = 0.8, 
#'     rho_s = 0, vart = 16)
#' @export
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

  new_ss_result(list(
    nclusters = nclusters,
    achieved_power = power_at_n(nclusters),
    deff_cluster = deff_cluster,
    deff_time = deff_time,
    vif = vif,
    inputs = list(nsubjects = nsubjects, ntimes = ntimes, d = d, icc = icc,
                  rho_c = rho_c, rho_s = rho_s, vart = vart, alpha = alpha, power = power)
  ))
}

# Stepped-wedge cluster-randomised trial, binary outcome (CHECKLIST TRIAL-28). Logit link, random cluster intercept with
# standard deviation tau, cross-sectional sampling (new people in every period), one baseline period on control and a
# step to the intervention after each of the following periods. Method: Xia F, Hughes JP, Voldal EC, Heagerty PJ. Power and
# sample size calculation for stepped-wedge designs with discrete outcomes. Trials 2021;22:598 (PMC8419932,
# doi 10.1186/s13063-021-05542-9), which takes the covariance of the estimates from the Laplace approximation of Breslow and
# Clayton (1993); I read the paper's description, but its equations did not come through in the text I could get, so the
# computation below is checked against the authors' own function, swCRTdesign::swGlmPwr() (R package, Suggests only).
# Each cluster's working covariance is V = diag(1 / (n mu_t (1 - mu_t))) + tau^2 J with
# mu_t = expit(intercept + time effect + effect x treated_t); information = sum over clusters of X' V^-1 X; the variance of
# the treatment effect is the matching element of its inverse. Power = pnorm((b - z sd0) / sd1) + 1 - pnorm((b + z sd0) / sd1),
# sd0 under no effect and sd1 under the effect b. The tests match swGlmPwr's power to 10 digits over random settings and skip
# when the package is not installed.

#' Stepped-wedge cluster-randomised trial sample size (binary outcome)
#'
#' Clusters needed per step (or the power with the clusters available) for a binary outcome analysed on the log odds scale.
#'
#' @param p0 Outcome risk under control (0, 1)
#' @param p1 Outcome risk under the intervention (0, 1), not equal to p0
#' @param nsubjects People measured per cluster in each period (>= 1)
#' @param nsteps Number of steps (whole number >= 2); there are nsteps + 1 periods, the first on control for all clusters
#' @param tau Standard deviation of the cluster effect on the log odds scale (>= 0)
#' @param time_effect Change in log odds in every later period compared with the first (default 0)
#' @param nclusters Clusters crossing at each step; when NULL the smallest number giving the power is found
#' @param alpha Two-sided significance level
#' @param power Desired power (used when nclusters is NULL)
#' @return list(nclusters, total_clusters, achieved_power, odds_ratio, inputs)
#' @examples
#' calc_stepped_wedge_binary(p0 = 0.2, p1 = 0.14, nsubjects = 50, nsteps = 3, tau = 0.2)
#' @export
calc_stepped_wedge_binary <- function(p0, p1, nsubjects, nsteps, tau, time_effect = 0, nclusters = NULL,
                                      alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p0, "p0")
  .validate_unit_interval(p1, "p1")
  if (isTRUE(all.equal(p0, p1))) stop("p0 and p1 must differ: there is no effect to detect.")
  .validate_positive(nsubjects, "nsubjects")
  if (!is.numeric(nsteps) || length(nsteps) != 1 || is.na(nsteps) || nsteps < 2 || nsteps != round(nsteps))
    stop("nsteps must be a single whole number >= 2.")
  if (!is.numeric(tau) || length(tau) != 1 || is.na(tau) || tau < 0) stop("tau must be a single number >= 0.")
  if (!is.numeric(time_effect) || length(time_effect) != 1 || is.na(time_effect)) stop("time_effect must be a single number.")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!is.null(nclusters) && (!is.numeric(nclusters) || length(nclusters) != 1 || is.na(nclusters) ||
                              nclusters < 1 || nclusters != round(nclusters)))
    stop("nclusters must be a single whole number >= 1.")

  b0 <- stats::qlogis(p0)
  theta <- stats::qlogis(p1) - b0
  periods <- nsteps + 1
  tp <- diag(periods)[, -1, drop = FALSE]                          # period indicators, period 1 is the reference
  info <- function(th, k) {
    out <- matrix(0, periods + 1, periods + 1)
    for (s in seq_len(nsteps)) {
      trt <- as.numeric(seq_len(periods) > s)
      X <- cbind(1, tp, trt)
      mu <- stats::plogis(drop(X %*% c(b0, rep(time_effect, periods - 1), th)))
      V <- diag(1 / (nsubjects * mu * (1 - mu)), periods) + tau^2
      out <- out + k * crossprod(X, solve(V, X))
    }
    out
  }
  var_theta <- function(th, k) solve(info(th, k))[periods + 1, periods + 1]
  power_at <- function(k) {
    sd1 <- sqrt(var_theta(theta, k)); sd0 <- sqrt(var_theta(0, k)); z <- stats::qnorm(1 - alpha / 2)
    stats::pnorm((theta - z * sd0) / sd1) + 1 - stats::pnorm((theta + z * sd0) / sd1)
  }
  if (is.null(nclusters)) {
    k <- 1
    while (power_at(k) < power) {
      k <- k + 1
      if (k > 5000) stop("No feasible design found -- try a larger effect, more people per cluster or step, or a smaller tau.")
    }
  } else k <- nclusters
  new_ss_result(list(
    nclusters = k, total_clusters = k * nsteps, achieved_power = power_at(k), odds_ratio = exp(theta),
    inputs = list(p0 = p0, p1 = p1, nsubjects = nsubjects, nsteps = nsteps, tau = tau, time_effect = time_effect,
                  nclusters = nclusters, alpha = alpha, power = power)
  ))
}
