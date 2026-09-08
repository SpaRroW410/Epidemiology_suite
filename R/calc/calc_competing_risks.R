# Pure calculation function for joint cause-specific/any-cause hazard
# testing in competing-risks data. No Shiny dependency here so this is
# directly unit-testable (see tests/testthat). Reimplements
# `powerCompRisk::powerCompRisk()`'s algorithm directly (Yang, Fung & Li
# 2017) rather than depending on the `powerCompRisk` package itself, which
# is not available from CRAN in this sandbox (no network access) -- the
# package's own source (a single self-contained file, MIT-licensed, on its
# public CRAN mirror) was read directly and transcribed here verbatim,
# then verified to reproduce the package's own documented example exactly
# before being wired into this app. Needs `mvtnorm::pmvnorm()` (already
# installed; a new project dependency) for the bivariate normal quadrant
# probability the chi-square/maximum joint tests are built on.

#' Sample size for jointly testing a cause-specific hazard and the
#' any-cause hazard in competing-risks data (Gray's-test-family designs)
#'
#' In competing-risks survival data (e.g. death from the disease of
#' interest vs. death from other causes), an analysis is sometimes
#' underpowered if it tests only the cause-specific hazard (does the
#' treatment change the rate of the event of interest, treating other
#' causes as censoring) or only the any-cause hazard (does the treatment
#' change overall mortality) alone. Yang, Fung & Li (2017) propose jointly
#' testing both, and give three ways to combine them into a single test
#' -- a chi-square joint test, a "maximum" joint test (rejects if EITHER
#' component statistic clears its own, jointly-calibrated threshold), and
#' a Bonferroni-corrected joint test -- each requiring somewhat different
#' numbers of cause-1 events (and hence total patients) to reach the
#' target power.
#'
#' @param lambda_11 Cause-1 (event of interest) cause-specific hazard in
#'   group 1 (> 0)
#' @param hr_1 Cause-1 cause-specific hazard ratio, group 1 vs. group 2
#'   (> 0, != 1)
#' @param hr_all Any-cause hazard ratio, group 1 vs. group 2 (> 0, != 1)
#' @param rr Relative risk of cause-1 failure vs. any-cause failure in
#'   group 1 (0,1) -- must satisfy hr_1 > rr * hr_all
#' @param accrual Length of the patient accrual (enrollment) period (>= 0)
#' @param follow_up Maximum follow-up period, measured from the start of
#'   accrual (> accrual)
#' @param attrition Attrition rate due to loss to follow-up [0,1)
#' @param a1 Allocation proportion to group 1 (0,1)
#' @param alpha Significance level, two-sided (0,1)
#' @param power Desired power (0,1)
#' @return list(chi2_events, chi2_n, max_events, max_n, bonferroni_events,
#'   bonferroni_n, inputs)
calc_competing_risks_joint <- function(lambda_11, hr_1, hr_all, rr, accrual, follow_up,
                                        attrition = 0, a1 = 0.5,
                                        alpha = 0.05, power = 0.8) {
  .validate_positive(lambda_11, "lambda_11")
  .validate_positive(hr_1, "hr_1")
  if (isTRUE(all.equal(hr_1, 1))) stop("hr_1 must differ from 1 (no effect to detect).")
  .validate_positive(hr_all, "hr_all")
  if (isTRUE(all.equal(hr_all, 1))) stop("hr_all must differ from 1 (no effect to detect).")
  .validate_unit_interval(rr, "rr")
  if (!is.numeric(accrual) || length(accrual) != 1 || is.na(accrual) || accrual < 0) {
    stop("accrual must be a single number >= 0.")
  }
  .validate_positive(follow_up, "follow_up")
  if (follow_up <= accrual) stop("follow_up must be greater than accrual.")
  if (!is.numeric(attrition) || length(attrition) != 1 || is.na(attrition) ||
    attrition < 0 || attrition >= 1) {
    stop("attrition must be a single number in [0, 1).")
  }
  .validate_unit_interval(a1, "a1")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  beta <- 1 - power
  a2 <- 1 - a1
  r <- accrual
  f <- follow_up

  lambda_a1 <- lambda_11 / rr * exp((log(hr_all) - log(hr_1)) / 2)
  lambda_12 <- lambda_11 / hr_1
  lambda_a2 <- lambda_a1 / hr_all

  if (lambda_a2 < lambda_12) {
    stop("Parameters do not meet the required constraint hr_1 > rr * hr_all.")
  }

  lambda_c <- attrition / (1 - attrition) * ((lambda_a1 + lambda_a2) / 2)

  corr <- matrix(c(1, sqrt(rr), sqrt(rr), 1), nrow = 2, ncol = 2)

  cv <- function(x) (1 - mvtnorm::pmvnorm(c(-x, -x), c(x, x), c(0, 0), corr)) - alpha
  c_m <- uniroot(cv, c(0, 3), tol = 0.0001)$root

  cv2 <- function(x) {
    beta - mvtnorm::pmvnorm(
      c(-c_m, -c_m), c(c_m, c_m),
      c(log(hr_1) * sqrt(a1 * a2 * x), log(hr_all) * sqrt(a1 * a2 * x / rr)),
      corr
    )
  }
  d_max <- ceiling(uniroot(cv2, c(0, 5000), tol = 0.0001)$root)

  c_chi <- qchisq(1 - alpha, 2, 0)
  cv_chisq <- function(x) {
    beta - pchisq(c_chi, 2, ncp = x * a1 * a2 *
      (log(hr_1)^2 - 2 * log(hr_1) * log(hr_all) + log(hr_all)^2 / rr) / (1 - rr))
  }
  d_chi <- ceiling(uniroot(cv_chisq, c(0, 5000), tol = 0.0001)$root)

  d1 <- ceiling((qnorm(1 - alpha / 4) + qnorm(1 - beta))^2 / (a1 * a2 * log(hr_1)^2))
  d2 <- ceiling((qnorm(1 - alpha / 4) + qnorm(1 - beta))^2 / (a1 * a2 * log(hr_all)^2))

  lambda_all1 <- lambda_a1 + lambda_c
  lambda_all2 <- lambda_a2 + lambda_c

  if (r == 0) {
    p_11 <- lambda_11 / lambda_all1 * (1 - exp(-lambda_all1 * f))
    p_a1 <- lambda_a1 / lambda_all1 * (1 - exp(-lambda_all1 * f))
    p_12 <- lambda_12 / lambda_all2 * (1 - exp(-lambda_all2 * f))
    p_a2 <- lambda_a2 / lambda_all2 * (1 - exp(-lambda_all2 * f))
  } else {
    p_11 <- lambda_11 / lambda_all1 * (1 - (exp(-lambda_all1 * (f - r)) - exp(-lambda_all1 * f)) / lambda_all1 * r)
    p_a1 <- lambda_a1 / lambda_all1 * (1 - (exp(-lambda_all1 * (f - r)) - exp(-lambda_all1 * f)) / lambda_all1 * r)
    p_12 <- lambda_12 / lambda_all2 * (1 - (exp(-lambda_all2 * (f - r)) - exp(-lambda_all2 * f)) / lambda_all2 * r)
    p_a2 <- lambda_a2 / lambda_all2 * (1 - (exp(-lambda_all2 * (f - r)) - exp(-lambda_all2 * f)) / lambda_all2 * r)
  }

  p_1 <- a1 * p_11 + a2 * p_12
  p_a <- a1 * p_a1 + a2 * p_a2
  n1 <- ceiling(d1 / p_1)
  n2 <- ceiling(d2 / p_a)

  samplesize_chi <- ceiling(d_chi / p_1)
  samplesize_max <- ceiling(d_max / p_1)
  samplesize_bon <- ceiling(min(n1, n2))
  d_bon <- ceiling(min(n1, n2) * p_1)

  list(
    chi2_events = ceiling(d_chi / 2) * 2,
    chi2_n = ceiling(samplesize_chi / 2) * 2,
    max_events = ceiling(d_max / 2) * 2,
    max_n = ceiling(samplesize_max / 2) * 2,
    bonferroni_events = ceiling(d_bon / 2) * 2,
    bonferroni_n = ceiling(samplesize_bon / 2) * 2,
    inputs = list(
      lambda_11 = lambda_11, hr_1 = hr_1, hr_all = hr_all, rr = rr,
      accrual = accrual, follow_up = follow_up, attrition = attrition,
      a1 = a1, alpha = alpha, power = power
    )
  )
}
