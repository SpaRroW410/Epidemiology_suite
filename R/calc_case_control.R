# Pure calculation functions for case-control study sample size.
# No Shiny dependency here so these are directly unit-testable (see
# tests/testthat). Both wrap epiR::epi.sscc() (Dupont 1988) rather than
# reimplementing the underlying math (project convention).

# The effect of a case-control design given either as the odds ratio or as the proportion of cases exposed (p1). The two are tied
# by the definition of the odds ratio, p1 = OR p0 / (1 - p0 + OR p0), which is the relation the Dupont (1988) formulas use
# (.cf_sscc_unmatched / .cf_sscc_matched compute p1 this way from OR): OR = p1 (1 - p0) / (p0 (1 - p1)).
.cc_effect <- function(p0, OR, p1) {
  if (is.null(OR) == is.null(p1)) stop("Give either OR (the odds ratio) or p1 (the proportion of cases exposed), not both.")
  if (!is.null(p1)) {
    .validate_unit_interval(p1, "p1")
    if (isTRUE(all.equal(p1, p0))) stop("p1 must differ from p0 (no effect to detect).")
    OR <- p1 * (1 - p0) / (p0 * (1 - p1))
    given <- "p1"
  } else {
    .validate_positive(OR, "OR")
    if (isTRUE(all.equal(OR, 1))) stop("OR must differ from 1 (no effect to detect).")
    given <- "OR"
  }
  list(OR = OR, p1 = OR * p0 / (1 - p0 + OR * p0), given = given)
}

#' Sample size for an unmatched case-control study
#'
#' Wraps epiR::epi.sscc(method = "unmatched").
#'
#' @param p0 Expected prevalence of exposure among controls (0,1)
#' @param OR Expected odds ratio (> 0, != 1). Give either `OR` or `p1`.
#' @param power Desired power (0,1)
#' @param ratio Number of controls per case (> 0)
#' @param alpha Significance level (0,1)
#' @param alternative "two.sided" or one-sided ("less"/"greater" -- both map
#'   to the same one-sided critical value; epi.sscc doesn't distinguish
#'   direction, only one- vs two-sided)
#' @param N Optional finite eligible-population size. NULL (default) =
#'   effectively infinite population.
#' @param p1 Expected proportion of cases exposed (0,1), instead of `OR`: the odds ratio is then p1 (1 - p0) / (p0 (1 - p1)).
#' @return A named list of class `ss_result` with `n_total`, `n_case`, `n_control`, `OR` and `p1` (both, whichever was given) and
#'   `inputs`.
#' @examples
#' calc_case_control_unmatched(p0 = 0.3, OR = 2, power = 0.9, ratio = 1, alpha = 0.05, 
#'     alternative = "two.sided")
#' @export
calc_case_control_unmatched <- function(p0, OR = NULL, power = 0.8, ratio = 1,
                                         alpha = 0.05,
                                         alternative = c("two.sided", "less", "greater"),
                                         N = NULL, p1 = NULL) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p0, "p0")
  eff <- .cc_effect(p0, OR, p1)
  OR <- eff$OR
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  if (!is.null(N)) .validate_population(N)

  sided <- if (identical(alternative, "two.sided")) 2 else 1

  res <- .cf_sscc_unmatched(N = if (is.null(N)) NA else N, OR = OR, p0 = p0, power = power,
                            r = ratio, design = 1, sided.test = sided, conf.level = 1 - alpha)

  new_ss_result(list(
    n_total = ceiling(res$n.total),
    n_case = ceiling(res$n.case),
    n_control = ceiling(res$n.control),
    OR = eff$OR,
    p1 = eff$p1,
    inputs = list(p0 = p0, OR = if (eff$given == "OR") OR, p1 = p1, power = power, ratio = ratio, alpha = alpha,
                  alternative = alternative, N = N)
  ))
}

#' Sample size for a matched case-control study (1:1 or 1:m)
#'
#' Wraps epiR::epi.sscc(method = "matched").
#'
#' @param p0 Expected prevalence of exposure among controls (0,1)
#' @param OR Expected odds ratio (> 0, != 1). Give either `OR` or `p1`.
#' @param phi_coef Correlation between case and control exposures for
#'   matched pairs (-1, 1); use ~0.2 (moderate) if no prior estimate is
#'   available, per Dupont (1988). [calc_matched_pairs_phi()] calculates it from a table of matched pairs.
#' @param power Desired power (0,1)
#' @param ratio Number of controls per case (m in 1:m matching, >= 1)
#' @param alpha Significance level (0,1)
#' @param alternative "two.sided" or one-sided
#' @param N Optional finite eligible-population size
#' @param p1 Expected proportion of cases exposed (0,1), instead of `OR`: the odds ratio is then p1 (1 - p0) / (p0 (1 - p1)).
#' @return A named list of class `ss_result` with `n_total`, `n_case`, `n_control`, `OR` and `p1` (both, whichever was given) and
#'   `inputs`.
#' @examples
#' calc_case_control_matched(p0 = 0.6, OR = 3, phi_coef = 0.2, power = 0.8, ratio = 1, 
#'     alpha = 0.05, alternative = "two.sided")
#' @export
calc_case_control_matched <- function(p0, OR = NULL, phi_coef = 0.2, power = 0.8, ratio = 1,
                                       alpha = 0.05,
                                       alternative = c("two.sided", "less", "greater"),
                                       N = NULL, p1 = NULL) {
  alternative <- match.arg(alternative)
  .validate_unit_interval(p0, "p0")
  eff <- .cc_effect(p0, OR, p1)
  OR <- eff$OR
  if (!is.numeric(phi_coef) || length(phi_coef) != 1 || is.na(phi_coef) ||
        phi_coef <= -1 || phi_coef >= 1) {
    stop("phi_coef must be a single number strictly between -1 and 1.")
  }
  .validate_unit_interval(power, "power")
  .validate_positive(ratio, "ratio")
  .validate_unit_interval(alpha, "alpha")
  if (!is.null(N)) .validate_population(N)

  sided <- if (identical(alternative, "two.sided")) 2 else 1

  res <- .cf_sscc_matched(N = if (is.null(N)) NA else N, OR = OR, p0 = p0, power = power,
                          r = ratio, phi.coef = phi_coef, design = 1, sided.test = sided,
                          conf.level = 1 - alpha)

  new_ss_result(list(
    n_total = ceiling(res$n.total),
    n_case = ceiling(res$n.case),
    n_control = ceiling(res$n.control),
    OR = eff$OR,
    p1 = eff$p1,
    inputs = list(p0 = p0, OR = if (eff$given == "OR") OR, p1 = p1, phi_coef = phi_coef, power = power,
                  ratio = ratio, alpha = alpha, alternative = alternative, N = N)
  ))
}

#' Correlation of exposure within matched case-control pairs (phi), from a table of pairs
#'
#' Dupont (1988) sizes a matched case-control study with phi, the correlation between the exposure of a case and the exposure of
#' its matched control. For two yes/no variables this correlation is the phi coefficient of their 2 x 2 table, here the table of
#' matched pairs from a pilot study or a published one:
#' phi = (a d - b c) / sqrt((a + b)(c + d)(a + c)(b + d)), with a = pairs where both are exposed, b = only the case,
#' c = only the control, d = neither. The same table gives the proportions exposed among the cases, p1 = (a + b) / n, and among
#' the controls, p0 = (a + c) / n, the odds ratio between them, and the matched-pairs (McNemar) odds ratio b / c.
#'
#' @param both Pairs where both the case and the control were exposed (a)
#' @param case_only Pairs where only the case was exposed (b)
#' @param control_only Pairs where only the control was exposed (c)
#' @param neither Pairs where neither was exposed (d)
#' @return A named list of class `ss_result` with `phi`, `n_pairs`, `p0`, `p1`, `OR` (p1 (1 - p0) / (p0 (1 - p1))), `OR_matched`
#'   (b / c; `Inf` when c = 0) and `inputs`.
#' @examples
#' calc_matched_pairs_phi(both = 30, case_only = 25, control_only = 10, neither = 35)
#' @export
calc_matched_pairs_phi <- function(both, case_only, control_only, neither) {
  cnt <- c(both = both, case_only = case_only, control_only = control_only, neither = neither)
  if (!is.numeric(cnt) || length(cnt) != 4 || anyNA(cnt) || any(cnt < 0) || any(cnt != round(cnt))) {
    stop("The four counts of pairs must be whole numbers, 0 or more.")
  }
  a <- as.numeric(both); b <- as.numeric(case_only); c <- as.numeric(control_only); d <- as.numeric(neither)   # doubles: integer products overflow
  n <- a + b + c + d
  margins <- c(a + b, c + d, a + c, b + d)
  if (any(margins == 0)) {
    stop("phi is undefined when all cases, or all controls, have the same exposure (a row or column of the table is empty).")
  }
  p1 <- (a + b) / n
  p0 <- (a + c) / n
  new_ss_result(list(
    phi = (a * d - b * c) / sqrt(prod(margins)),
    n_pairs = n,
    p0 = p0,
    p1 = p1,
    OR = p1 * (1 - p0) / (p0 * (1 - p1)),
    OR_matched = if (c > 0) b / c else Inf,
    inputs = list(both = both, case_only = case_only, control_only = control_only, neither = neither)
  ))
}

.validate_positive_integer <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 1 || x != round(x)) {
    stop(sprintf("%s must be a single positive integer.", label))
  }
}

#' Sample size for matched sets (nested or matched case-control), binary exposure
#'
#' Number of matched sets, each of nD cases and nH controls, for the score test of a binary exposure in a conditional logistic
#' regression (Lachin 2008, eq. 25 and 35, with the information per set nD * nH / (nD + nH); see the comment above
#' `.cf_pse_conlogistic_bin()`). Applies to a nested case-control study and to any individually matched case-control study, 1:1 or
#' 1:m. Written out in the app; equal to powerSurvEpi::powerConLogistic.bin().
#'
#' @param OR Expected odds ratio, exposed vs unexposed (> 0, != 1)
#' @param pE Probability of exposure under the null hypothesis (0,1)
#' @param nD Number of cases per matched set (>= 1)
#' @param nH Number of controls per matched set (>= 1)
#' @param R2 Proportion of variation in exposure explained by other covariates
#'   in the conditional logistic model (0,1); 0 = no adjustment covariates
#' @param alpha Significance level (0,1), two-sided
#' @param power Desired power (0,1)
#' @return list(n_sets, n_cases, n_controls, n_total, inputs)
#' @references Lachin JM. Sample size evaluation for a multiply matched case-control study using the score test from a conditional
#'   logistic (discrete Cox PH) regression model. Stat Med 2008;27(14):2509-2523. doi:10.1002/sim.3057. Erratum: Stat Med
#'   2018;37(10):1765-1766. doi:10.1002/sim.7598.
#' @examples
#' calc_case_control_nested_binary(OR = 3.5, pE = 0.15, nD = 1, nH = 2, R2 = 0, alpha = 0.05,
#'     power = 0.8)
#' @export
calc_case_control_nested_binary <- function(OR, pE, nD, nH, R2 = 0, alpha = 0.05,
                                             power = 0.8) {
  .validate_positive(OR, "OR")
  if (isTRUE(all.equal(OR, 1))) stop("OR must differ from 1 (no effect to detect).")
  .validate_unit_interval(pE, "pE")
  .validate_positive_integer(nD, "nD")
  .validate_positive_integer(nH, "nH")
  .validate_r2(R2)
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- ceiling(.cf_pse_conlogistic_bin(power = power, OR = OR, pE = pE,
                                       nD = nD, nH = nH, R2 = R2, alpha = alpha))
  new_ss_result(list(
    n_sets = n, n_cases = n * nD, n_controls = n * nH,
    n_total = n * (nD + nH),
    inputs = list(OR = OR, pE = pE, nD = nD, nH = nH, R2 = R2, alpha = alpha, power = power)
  ))
}

.validate_r2 <- function(R2) {
  if (!is.numeric(R2) || length(R2) != 1 || is.na(R2) || R2 < 0 || R2 >= 1) {
    stop("R2 must be a single number in [0, 1).")
  }
}

#' Sample size for matched sets (nested or matched case-control), measured exposure
#'
#' Number of matched sets, each of nD cases and nH controls, for the score test of a measured (continuous) exposure in a
#' conditional logistic regression (Lachin 2008, eq. 25; eq. 27 and 34 for one case per set). Applies to a nested case-control study
#' and to any individually matched case-control study, 1:1 or 1:m: with one control per case it gives the z-test version of the paired
#' comparison of means, since the SD of the case-control differences is sigma * sqrt(2). For two or more cases per set the
#' information per set is nD * nH / (nD + nH), not the paper's nD * (1 - 1 / choose(nD + nH, nD)) (which powerSurvEpi's
#' powerConLogistic.con() uses): see the comment above `.cf_pse_conlogistic_bin()`.
#'
#' The effect is given in one of three ways (exactly one):
#' \itemize{
#'   \item `OR`, the odds ratio per one unit of the exposure (Lachin's O; theta = log(OR));
#'   \item `OR_sd`, the odds ratio per one standard deviation (theta = log(OR_sd) / sigma);
#'   \item `mean_diff`, the difference between the mean exposure of the cases and of their matched controls (theta =
#'     mean_diff / sigma^2, eq. 32; for several cases per set the paper's eq. 28-30 add a constant that comes from its information
#'     factor and is 1 with the factor used here).
#' }
#'
#' @param OR Odds ratio per one unit of the exposure (> 0, != 1), or NULL
#' @param sigma Standard deviation of the exposure within matched sets (> 0); without strong matching on factors related to the
#'   exposure, the SD among controls is a usual (slightly conservative) choice
#' @param nD Number of cases per matched set (>= 1)
#' @param nH Number of controls per matched set (>= 1)
#' @param R2 Proportion of variation in exposure explained by other covariates (0,1)
#' @param alpha Significance level (0,1), two-sided
#' @param power Desired power (0,1)
#' @param OR_sd Odds ratio per one standard deviation of the exposure, or NULL
#' @param mean_diff Mean exposure of cases minus that of their matched controls (!= 0), or NULL
#' @return list(n_sets, n_cases, n_controls, n_total, OR (per unit), OR_sd, theta, inputs)
#' @references Lachin JM. Stat Med 2008;27(14):2509-2523. doi:10.1002/sim.3057 (sec. 3.2, 4.1). Erratum: Stat Med
#'   2018;37(10):1765-1766. doi:10.1002/sim.7598.
#' @examples
#' # Lachin (2008), sec. 4.1: OR 1.39 per SD, 2 controls per case, 85% power -> 125 cases
#' calc_case_control_nested_continuous(OR_sd = 1.39, sigma = 8.41, nD = 1, nH = 2, power = 0.85)
#' # the same, from the means: cases 2.77 above their controls on a biomarker with SD 8.41
#' calc_case_control_nested_continuous(mean_diff = 2.77, sigma = 8.41, nD = 1, nH = 2, power = 0.85)
#' @export
calc_case_control_nested_continuous <- function(OR = NULL, sigma, nD, nH, R2 = 0, alpha = 0.05,
                                                 power = 0.8, OR_sd = NULL, mean_diff = NULL) {
  given <- !vapply(list(OR, OR_sd, mean_diff), is.null, logical(1))
  if (sum(given) != 1) stop("Give the effect one way: OR (per unit), OR_sd (per SD) or mean_diff.")
  .validate_positive(sigma, "sigma")
  .validate_positive_integer(nD, "nD")
  .validate_positive_integer(nH, "nH")
  .validate_r2(R2)
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  theta <- if (given[1]) {
    .validate_positive(OR, "OR"); log(OR)
  } else if (given[2]) {
    .validate_positive(OR_sd, "OR_sd"); log(OR_sd) / sigma
  } else {
    if (!is.numeric(mean_diff) || length(mean_diff) != 1 || !is.finite(mean_diff)) stop("mean_diff must be a single number.")
    mean_diff / sigma^2
  }
  if (abs(theta) < 1e-12) stop("The effect must differ from no effect (OR 1, mean difference 0).")

  n <- ceiling(.cf_pse_conlogistic_con(power = power, OR = exp(theta), sigma = sigma,
                                       nD = nD, nH = nH, R2 = R2, alpha = alpha))
  new_ss_result(list(
    n_sets = n, n_cases = n * nD, n_controls = n * nH,
    n_total = n * (nD + nH),
    OR = exp(theta), OR_sd = exp(theta * sigma), theta = theta,
    inputs = list(OR = OR, OR_sd = OR_sd, mean_diff = mean_diff, sigma = sigma, nD = nD, nH = nH, R2 = R2,
                  alpha = alpha, power = power)
  ))
}

#' Sample size (required subcohort size) for a case-cohort study
#'
#' Closed-form reimplementation of gap::ccsize()'s sample-size branch
#' (Cai & Zeng 2004, Biometrics 60(4):1015-1024, Equation 6), rather than
#' depending on the gap package -- gap::ccsize() itself is pure base-R
#' math (only qnorm), but gap's own Imports/Depends (dplyr, ggplot2,
#' plotly, Rdpack, gap.datasets) are far heavier than this one formula
#' needs.
#'
#' @param n Full cohort size, already assembled (> 0, integer)
#' @param pD Proportion of failures (events) in the full cohort (0,1)
#' @param p1 Proportion of the cohort in exposure/covariate group 1 (0,1);
#'   group 2 is 1 - p1
#' @param hr Hazard ratio to be detected between the two groups (> 0, != 1)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(subcohort_n, full_cohort_n, inputs)
#' @examples
#' calc_case_control_case_cohort(n = 15792, pD = 0.03, p1 = 0.25, hr = 1.35, alpha = 0.05, 
#'     power = 0.8)
#' @export
calc_case_control_case_cohort <- function(n, pD, p1, hr, alpha = 0.05, power = 0.8) {
  .validate_positive_integer(n, "n")
  .validate_unit_interval(pD, "pD")
  .validate_unit_interval(p1, "p1")
  .validate_positive(hr, "hr")
  if (isTRUE(all.equal(hr, 1))) stop("hr must differ from 1 (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  theta <- log(hr)
  z_alpha <- qnorm(alpha, lower.tail = FALSE)
  z_beta <- qnorm(1 - power, lower.tail = FALSE)
  B <- (z_alpha + z_beta)^2 / (theta^2 * p1 * (1 - p1) * pD)
  m <- n * B * pD / (n - B * (1 - pD))

  if (!is.finite(m) || m <= 0 || m > n) {
    stop(paste(
      "No feasible subcohort size for these inputs (the required subcohort",
      "would exceed the full cohort, or the configuration is otherwise",
      "infeasible) -- try a larger cohort, a larger hazard ratio, or lower power."
    ))
  }

  new_ss_result(list(
    subcohort_n = ceiling(m),
    full_cohort_n = n,
    inputs = list(n = n, pD = pD, p1 = p1, hr = hr, alpha = alpha, power = power)
  ))
}
