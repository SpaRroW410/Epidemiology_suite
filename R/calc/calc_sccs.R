# Pure calculation function for self-controlled case series (SCCS) sample
# size. No Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Reimplements SCCS::samplesize() (Musonda, Farrington &
# Whitaker 2006) as closed-form R rather than taking a runtime dependency on
# the SCCS package -- that package's Imports (survival, splines, corpcor,
# fda, R.methodsS3, gnm) are far heavier than this one function needs, and
# the function itself is pure base R (only qnorm/log/sqrt/sum), with no
# calls into any of those dependencies. Verified to reproduce the package's
# own documented examples exactly (see tests/testthat/test-calc_sccs.R).

#' Sample size for a self-controlled case series (SCCS) study
#'
#' Sizes an SCCS study -- each case serves as their own control, comparing
#' the rate of events during a defined "risk period" (e.g. shortly after a
#' vaccine/drug exposure) to the rate during the rest of an observation
#' period -- to detect a given exposure-associated relative incidence.
#' Optionally accounts for age-varying baseline incidence via age groups.
#'
#' @param eexpo Design value of the exposure-associated relative incidence, > 0, != 1
#' @param risk Duration of the risk period; must be less than the length of
#'   the shortest age group (or of the whole observation period if no age
#'   groups are given), > 0
#' @param astart Age at start of the observation period (>= 0)
#' @param aend Age at end of the observation period (> astart)
#' @param p Vector/scalar of proportions of the case population exposed in
#'   each age group (default 1: no age effects, everyone exposed); must sum
#'   to a value in (0, 1]
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @param eage Optional vector of age-group relative-incidence parameters
#'   (reference group is the first age group); required together with agegrp
#' @param agegrp Optional vector of age-group cut points (each value is the
#'   start of the next age category); required together with eage
#' @return list(n, inputs)
calc_sccs_samplesize <- function(eexpo, risk, astart, aend, p = 1, alpha = 0.05,
                                  power = 0.8, eage = NULL, agegrp = NULL) {
  .validate_positive(eexpo, "eexpo")
  if (isTRUE(all.equal(eexpo, 1))) stop("eexpo must differ from 1 (no effect to detect).")
  .validate_positive(risk, "risk")
  if (!is.numeric(astart) || length(astart) != 1 || is.na(astart) || astart < 0) {
    stop("astart must be a single number >= 0.")
  }
  if (!is.numeric(aend) || length(aend) != 1 || is.na(aend) || aend <= astart) {
    stop("aend must be a single number greater than astart.")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (!is.numeric(p) || anyNA(p) || any(p <= 0)) stop("p must be positive.")
  if (sum(p) > 1) stop("The sum of p must be <= 1.")
  if (is.null(agegrp) != is.null(eage)) {
    stop("eage and agegrp must both be supplied together, or both omitted.")
  }
  if (!is.null(eage) && (length(p) != length(eage) + 1 || length(p) != length(agegrp) + 1)) {
    stop("p must have exactly one more entry than eage and agegrp.")
  }

  eage_full <- c(1, eage)
  agecuts <- c(astart, agegrp, aend)
  es <- diff(agecuts)
  es[length(es)] <- es[length(es)] + 1
  if (risk >= min(es)) stop("risk must be less than the length of the shortest age group.")

  rho <- eexpo
  sss <- sum(eage_full * es)
  r <- (eage_full * risk) / sss

  pi_j <- (r * rho) / (r * rho + 1 - r)
  vj_den <- (1 - sum(p)) + sum(p * (r * rho + 1 - r))
  vj <- (p * (r * rho + 1 - r)) / vj_den

  A <- 2 * sum(vj * (pi_j * log(rho) - log(r * rho + 1 - r)))
  B <- ((log(rho))^2 / A) * sum(vj * pi_j * (1 - pi_j))

  za <- qnorm(alpha / 2, lower.tail = FALSE)
  zb <- qnorm(power, lower.tail = TRUE)
  n <- ((za + zb * sqrt(B))^2) / A

  new_ss_result(list(
    n = ceiling(n),
    inputs = list(eexpo = eexpo, risk = risk, astart = astart, aend = aend, p = p,
                  alpha = alpha, power = power, eage = eage, agegrp = agegrp)
  ))
}
