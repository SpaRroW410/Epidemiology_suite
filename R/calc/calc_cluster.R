# Pure closed-form calculation function for cluster/multistage sampling's
# design effect (DEFF) inflation. No package needed; DEFF = 1 + (m-1)*rho is
# a standard closed-form identity (Kish 1965), not something any CRAN
# package wraps in a dedicated function.

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
