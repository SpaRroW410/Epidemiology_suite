# Pure calculation function for cohort/relative-risk study sample size.
# No Shiny dependency here so this is directly unit-testable (see
# tests/testthat). Wraps epiR::epi.sscohortc() rather than reimplementing
# the underlying math (project convention).

#' Sample size for a cohort study (relative risk / risk difference)
#'
#' Wraps epiR::epi.sscohortc(), which uses individual count data (as
#' opposed to person-time). Also applies to cross-sectional studies
#' estimating relative risk.
#'
#' @param p0 Expected incidence risk of the outcome in the unexposed group (0,1)
#' @param p1 Expected incidence risk of the outcome in the exposed group (0,1)
#' @param power Desired power (0,1)
#' @param ratio Number in the exposed group divided by the number in the
#'   unexposed group (> 0)
#' @param alpha Significance level (0,1)
#' @param alternative "two.sided" or one-sided
#' @param N Optional finite eligible-population size. NULL (default) =
#'   effectively infinite population.
#' @return list(n_total, n_exposed, n_unexposed, rr, inputs)
calc_cohort <- function(p0, p1, power = 0.8, ratio = 1, alpha = 0.05,
                         alternative = c("two.sided", "less", "greater"),
                         N = NULL) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p0, "p0")
  .validate_unit_interval(p1, "p1")
  if (isTRUE(all.equal(p0, p1))) stop("p0 and p1 must differ (no effect to detect).")
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  if (!is.null(N)) .validate_population(N)

  sided <- if (identical(alternative, "two.sided")) 2 else 1

  res <- epiR::epi.sscohortc(N = if (is.null(N)) NA else N, irexp1 = p1, irexp0 = p0,
                              pexp = NA, n = NA, power = power, r = ratio,
                              design = 1, sided.test = sided,
                              finite.correction = !is.null(N), nfractional = FALSE,
                              conf.level = 1 - alpha)

  list(
    n_total = ceiling(res$n.total),
    n_exposed = ceiling(res$n.exp1),
    n_unexposed = ceiling(res$n.exp0),
    rr = res$irr,
    inputs = list(p0 = p0, p1 = p1, power = power, ratio = ratio, alpha = alpha,
                  alternative = alternative, N = N)
  )
}
