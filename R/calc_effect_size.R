# Effect-size converters (owner's request of 2 Nov 2026): the quantity a sample-size calculator asks for (Cohen's d, f, h, w, an
# odds ratio, a hazard ratio) worked out from what people usually know (means and SDs or variances, proportions, test statistics,
# medians). Pure functions, no Shiny; the "Effect Size" calculator (mod_effect_size.R) wraps them.
#
# Sources and how each was verified (rule: no source is cited as read unless it was; the others are flagged):
#   * Cohen J. Statistical Power Analysis for the Behavioral Sciences, 2nd ed. 1988: d, f, h, w and his suggested conventions. The
#     book was not read in this session; the formulas are those pwr uses (pwr::ES.h, ES.w1, ES.w2) and are compared with it.
#   * Hedges LV. J Educ Stat 1981;6:107-128: the small-sample factor of Hedges' g (also used in calc_analyze_compare.R; "confirmed to
#     exist" there, not read); checked here by simulation (g is closer to unbiased than d).
#   * Chinn S. A simple method for converting an odds ratio to effect size for use in meta-analysis. Stat Med 2000;19:3127-31
#     (PMID 11113947, doi 10.1002/1097-0258(20001130)19:22<3127::aid-sim784>3.0.co;2-m): only the abstract was read ("a ln(odds
#     ratio) can be converted to effect size by dividing by 1.81", i.e. pi / sqrt(3) = 1.8138). An approximation.
#   * d <-> r: for two groups the point-biserial r and d give the same t, r = t / sqrt(t^2 + df); that identity is exact and is
#     checked against cor(). The textbook large-sample form (equal groups) is d = 2 r / sqrt(1 - r^2).
#   * Identities derived here and checked numerically: SD of paired differences, f from group means, eta^2 <-> f, the hazard ratio
#     from medians (exponential survival: hazard = log(2) / median), h from two proportions.

# --- Cohen's conventions, as a plain-language reading -----------------------------------------------
.es_cuts <- list(d = c(0.2, 0.5, 0.8), h = c(0.2, 0.5, 0.8), f = c(0.1, 0.25, 0.4), w = c(0.1, 0.3, 0.5), r = c(0.1, 0.3, 0.5))

# "small", "medium", ... for |value|; Cohen offered these as a last resort when nothing better is known, not as thresholds.
.es_interpret <- function(value, kind) {
  cut <- .es_cuts[[kind]]
  a <- abs(value)
  word <- if (a < cut[1]) "smaller than small" else if (a < cut[2]) "small" else if (a < cut[3]) "medium" else "large"
  sprintf("%s (Cohen's conventions for %s: small %s, medium %s, large %s)", word, kind, cut[1], cut[2], cut[3])
}

.es_num <- function(x, label, positive = FALSE) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x)) stop(sprintf("%s must be a single number.", label), call. = FALSE)
  if (positive && x <= 0) stop(sprintf("%s must be greater than 0.", label), call. = FALSE)
  x
}
.es_n <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 2) stop(sprintf("%s must be a single number >= 2.", label), call. = FALSE)
  x
}

# Hedges' small-sample correction J(df) (Hedges 1981), exact form with gamma functions.
.hedges_j <- function(df) exp(lgamma(df / 2) - lgamma((df - 1) / 2)) / sqrt(df / 2)

# --- Two independent means ---------------------------------------------------------------------------
#' Standardized difference between two means (Cohen's d, Hedges' g)
#'
#' Cohen's d = (mean1 - mean2) / pooled SD. Give the two means or their difference, and the standard deviations or the variances
#' (one value is taken as common to both groups). With the group sizes the pooled SD is weighted by degrees of freedom and Hedges'
#' g and a large-sample interval are added; without them equal group sizes are assumed.
#'
#' @param mean1,mean2 Group means (give these or `diff`)
#' @param diff Difference between the means (group 1 minus group 2), instead of the two means
#' @param sd1,sd2 Standard deviations (> 0); if `sd2` is NULL, `sd1` is common to both groups
#' @param var1,var2 Variances instead of standard deviations
#' @param n1,n2 Group sizes (optional, >= 2)
#' @param conf_level Confidence level of the interval for d, (0,1)
#' @return A named list of class `ss_result` with `difference`, `sd1`, `sd2`, `pooled_sd`, `d`, `interpretation` and, with group sizes,
#'   `hedges_g`, `se_d`, `d_lower`, `d_upper` and `inputs`.
#' @examples
#' calc_es_two_means(mean1 = 132.86, mean2 = 127.44, sd1 = 15.34, sd2 = 18.23, n1 = 50, n2 = 50)
#' calc_es_two_means(diff = 5, var1 = 225)
#' @export
calc_es_two_means <- function(mean1 = NULL, mean2 = NULL, diff = NULL, sd1 = NULL, sd2 = NULL, var1 = NULL, var2 = NULL,
                              n1 = NULL, n2 = NULL, conf_level = 0.95) {
  if (!is.null(diff)) {
    if (!is.null(mean1) || !is.null(mean2)) stop("Give either the two means or their difference, not both.", call. = FALSE)
    delta <- .es_num(diff, "diff")
  } else {
    if (is.null(mean1) || is.null(mean2)) stop("Give the two means, or their difference.", call. = FALSE)
    delta <- .es_num(mean1, "mean1") - .es_num(mean2, "mean2")
  }
  spread <- function(sd, var, label) {
    if (!is.null(sd) && !is.null(var)) stop(sprintf("Give either the SD or the variance of %s, not both.", label), call. = FALSE)
    if (!is.null(var)) sqrt(.es_num(var, paste("variance of", label), positive = TRUE))
    else if (!is.null(sd)) .es_num(sd, paste("SD of", label), positive = TRUE)
    else NULL
  }
  s1 <- spread(sd1, var1, "group 1")
  s2 <- spread(sd2, var2, "group 2")
  if (is.null(s1) && is.null(s2)) stop("Give the standard deviation (or variance) of at least one group.", call. = FALSE)
  if (is.null(s1)) s1 <- s2
  if (is.null(s2)) s2 <- s1
  .validate_unit_interval(conf_level, "conf_level")
  have_n <- !is.null(n1) && !is.null(n2)
  if (xor(is.null(n1), is.null(n2))) stop("Give both group sizes, or neither.", call. = FALSE)
  if (have_n) { .es_n(n1, "n1"); .es_n(n2, "n2") }
  sp <- if (have_n) sqrt(((n1 - 1) * s1^2 + (n2 - 1) * s2^2) / (n1 + n2 - 2)) else sqrt((s1^2 + s2^2) / 2)
  d <- delta / sp
  out <- list(difference = delta, sd1 = s1, sd2 = s2, pooled_sd = sp, d = d, interpretation = .es_interpret(d, "d"))
  if (have_n) {
    se <- sqrt((n1 + n2) / (n1 * n2) + d^2 / (2 * (n1 + n2)))
    z <- stats::qnorm(1 - (1 - conf_level) / 2)
    out <- c(out, list(hedges_g = .hedges_j(n1 + n2 - 2) * d, se_d = se, d_lower = d - z * se, d_upper = d + z * se))
  }
  new_ss_result(c(out, list(inputs = list(difference = delta, sd1 = s1, sd2 = s2, n1 = n1, n2 = n2, conf_level = conf_level))))
}

# --- From a t statistic ------------------------------------------------------------------------------
#' Cohen's d from a t statistic
#'
#' Two independent groups: d = t sqrt(1/n1 + 1/n2). One sample or paired data: d_z = t / sqrt(n). (Both follow from the definition of
#' the t statistic and are checked against `t.test()`.) For two groups Hedges' g is added.
#'
#' @param t The t statistic (any sign)
#' @param n1 Group 1 size, or the number of pairs / the sample size for a paired or one-sample test (>= 2)
#' @param n2 Group 2 size, for two independent groups; NULL for paired or one-sample data
#' @return A named list of class `ss_result` with `d`, `df`, `hedges_g` (two groups), `interpretation` and `inputs`.
#' @examples
#' calc_es_from_t(t = 2.4, n1 = 30, n2 = 30)
#' calc_es_from_t(t = 3.1, n1 = 25)
#' @export
calc_es_from_t <- function(t, n1, n2 = NULL) {
  .es_num(t, "t"); .es_n(n1, "n1")
  if (is.null(n2)) {
    d <- t / sqrt(n1); df <- n1 - 1; g <- NULL
  } else {
    .es_n(n2, "n2")
    d <- t * sqrt(1 / n1 + 1 / n2); df <- n1 + n2 - 2; g <- .hedges_j(df) * d
  }
  new_ss_result(c(list(d = d, df = df), if (!is.null(g)) list(hedges_g = g),
                  list(interpretation = .es_interpret(d, "d"), inputs = list(t = t, n1 = n1, n2 = n2))))
}

# --- Paired means -----------------------------------------------------------------------------------
#' Standardized difference for paired measurements (d_z)
#'
#' d_z = mean difference / SD of the paired differences, the effect size the paired t-test power calculation uses. The SD of the
#' differences can be given, or worked out from the two SDs and their correlation: SD_diff^2 = sd1^2 + sd2^2 - 2 r sd1 sd2. Given
#' both SDs and the SD of the differences, the implied correlation is returned.
#'
#' @param mean_diff Mean of the paired differences
#' @param sd_diff SD of the paired differences (> 0), or NULL to calculate it from `sd1`, `sd2` and `r`
#' @param sd1,sd2 SDs of the two measurements (> 0)
#' @param r Correlation between the two measurements, (-1, 1)
#' @return A named list of class `ss_result` with `mean_diff`, `sd_diff`, `d_z`, `interpretation`, `correlation` (given or implied,
#'   when both SDs are known) and `inputs`.
#' @examples
#' calc_es_paired(mean_diff = 4, sd1 = 12, sd2 = 14, r = 0.6)
#' @export
calc_es_paired <- function(mean_diff, sd_diff = NULL, sd1 = NULL, sd2 = NULL, r = NULL) {
  md <- .es_num(mean_diff, "mean_diff")
  if (!is.null(sd1)) .es_num(sd1, "sd1", positive = TRUE)
  if (!is.null(sd2)) .es_num(sd2, "sd2", positive = TRUE)
  corr <- r
  if (!is.null(sd_diff)) {
    sdd <- .es_num(sd_diff, "sd_diff", positive = TRUE)
    if (!is.null(sd1) && !is.null(sd2)) {
      corr <- (sd1^2 + sd2^2 - sdd^2) / (2 * sd1 * sd2)
      if (abs(corr) > 1) stop(sprintf("These SDs cannot go together: they imply a correlation of %.2f.", corr), call. = FALSE)
    }
  } else {
    if (is.null(sd1) || is.null(sd2) || is.null(r)) stop("Give the SD of the differences, or both SDs and their correlation.", call. = FALSE)
    if (!is.numeric(r) || length(r) != 1 || is.na(r) || abs(r) >= 1) stop("r must be a single number strictly between -1 and 1.", call. = FALSE)
    sdd <- sqrt(sd1^2 + sd2^2 - 2 * r * sd1 * sd2)
  }
  dz <- md / sdd
  new_ss_result(list(mean_diff = md, sd_diff = sdd, d_z = dz, interpretation = .es_interpret(dz, "d"),
                     correlation = corr, inputs = list(mean_diff = md, sd_diff = sd_diff, sd1 = sd1, sd2 = sd2, r = r)))
}

# --- Several groups: Cohen's f -----------------------------------------------------------------------
#' Cohen's f for comparing several means (one-way ANOVA)
#'
#' f = SD of the group means / common within-group SD. Give the group means and the SD, or eta-squared, or an F statistic with its
#' degrees of freedom, or (for two groups) Cohen's d. With unequal group sizes the SD of the means is weighted by group size.
#'
#' @param means Vector of group means (>= 2), with `sd`
#' @param sd Common within-group SD (> 0)
#' @param n Group sizes (same length as `means`), optional
#' @param eta2 Eta-squared (proportion of variance explained), in (0, 1)
#' @param F_stat,df1,df2 An F statistic and its numerator and denominator degrees of freedom
#' @param d Cohen's d of two groups
#' @return A named list of class `ss_result` with `f`, `f2`, `eta2`, `interpretation` and `inputs`.
#' @examples
#' calc_es_f(means = c(10, 12, 15), sd = 6)
#' calc_es_f(eta2 = 0.06)
#' @export
calc_es_f <- function(means = NULL, sd = NULL, n = NULL, eta2 = NULL, F_stat = NULL, df1 = NULL, df2 = NULL, d = NULL) {
  given <- c(means = !is.null(means), eta2 = !is.null(eta2), F = !is.null(F_stat), d = !is.null(d))
  if (sum(given) != 1) stop("Give exactly one of: the group means (with sd), eta2, an F statistic (with df1, df2), or d.", call. = FALSE)
  if (given[["means"]]) {
    if (!is.numeric(means) || length(means) < 2 || anyNA(means)) stop("means must be a vector of at least two numbers.", call. = FALSE)
    .es_num(sd, "sd", positive = TRUE)
    w <- if (is.null(n)) rep(1, length(means)) else {
      if (length(n) != length(means) || any(!is.finite(n)) || any(n <= 0)) stop("n must be positive, one per group.", call. = FALSE)
      n
    }
    w <- w / sum(w)
    f <- sqrt(sum(w * (means - sum(w * means))^2)) / sd
  } else if (given[["eta2"]]) {
    if (!is.numeric(eta2) || length(eta2) != 1 || is.na(eta2) || eta2 <= 0 || eta2 >= 1) stop("eta2 must be a single number strictly between 0 and 1.", call. = FALSE)
    f <- sqrt(eta2 / (1 - eta2))
  } else if (given[["F"]]) {
    .es_num(F_stat, "F_stat", positive = TRUE); .es_num(df1, "df1", positive = TRUE); .es_num(df2, "df2", positive = TRUE)
    f <- sqrt(F_stat * df1 / df2)
  } else {
    f <- abs(.es_num(d, "d")) / 2
  }
  new_ss_result(list(f = f, f2 = f^2, eta2 = f^2 / (1 + f^2), interpretation = .es_interpret(f, "f"),
                     inputs = list(means = means, sd = sd, n = n, eta2 = eta2, F_stat = F_stat, df1 = df1, df2 = df2, d = d)))
}

# --- Proportions: risk difference, ratio, odds ratio, Cohen's h --------------------------------------
#' Effect measures for two proportions, from any one of them
#'
#' Given the proportion with the outcome (or exposure) in the reference group, p0, and ONE of: the proportion in the other group
#' (p1), the odds ratio, the risk (prevalence) ratio, or the risk difference, all the others are calculated -- as in OpenEpi's
#' "fill in 1 of the following" forms. Also returns Cohen's h and the number needed to treat (1 / |risk difference|).
#' In a case-control study read p0 as the proportion of controls exposed and p1 as the proportion of cases exposed.
#'
#' @param p0 Proportion in the reference group, in (0, 1)
#' @param p1 Proportion in the other group, in (0, 1)
#' @param OR Odds ratio (> 0), group 1 versus group 0
#' @param RR Risk (prevalence) ratio (> 0)
#' @param RD Risk difference p1 - p0
#' @return A named list of class `ss_result` with `p0`, `p1`, `OR`, `RR`, `RD`, `NNT`, `h`, `interpretation` and `inputs`.
#' @examples
#' calc_es_proportions(p0 = 0.05, OR = 2)
#' @export
calc_es_proportions <- function(p0, p1 = NULL, OR = NULL, RR = NULL, RD = NULL) {
  .validate_unit_interval(p0, "p0")
  if (sum(!is.null(p1), !is.null(OR), !is.null(RR), !is.null(RD)) != 1) {
    stop("Give exactly one of: p1, the odds ratio, the risk ratio or the risk difference.", call. = FALSE)
  }
  entered <- list(p1 = p1, OR = OR, RR = RR, RD = RD)
  if (!is.null(p1)) {
    .validate_unit_interval(p1, "p1")
  } else if (!is.null(OR)) {
    .es_num(OR, "OR", positive = TRUE)
    odds <- OR * p0 / (1 - p0)
    p1 <- odds / (1 + odds)
  } else if (!is.null(RR)) {
    .es_num(RR, "RR", positive = TRUE)
    p1 <- RR * p0
    if (p1 >= 1) stop(sprintf("A risk ratio of %s with p0 = %s would give a proportion of %.3f, above 1.", format(RR), format(p0), p1), call. = FALSE)
  } else {
    p1 <- p0 + .es_num(RD, "RD")
    if (p1 <= 0 || p1 >= 1) stop(sprintf("A risk difference of %s with p0 = %s would give a proportion of %.3f, outside (0, 1).", format(RD), format(p0), p1), call. = FALSE)
  }
  h <- 2 * asin(sqrt(p1)) - 2 * asin(sqrt(p0))
  rd <- p1 - p0
  new_ss_result(list(p0 = p0, p1 = p1, OR = (p1 / (1 - p1)) / (p0 / (1 - p0)), RR = p1 / p0, RD = rd,
                     NNT = if (rd == 0) Inf else 1 / abs(rd), h = h, interpretation = .es_interpret(h, "h"),
                     inputs = c(list(p0 = p0), Filter(Negate(is.null), entered))))
}

# --- Chi-square: Cohen's w ---------------------------------------------------------------------------
#' Cohen's w for a chi-square test
#'
#' w = sqrt(chi-square / N) for a contingency table (uncorrected Pearson chi-square) or for a chi-square statistic with its N; or
#' w = sqrt(sum (p1 - p0)^2 / p0) from the proportions expected under the null (p0) and the alternative (p1) in each cell. For a
#' 2 x 2 table w equals the phi coefficient. Cramer's V is returned for a table.
#'
#' @param table A matrix of counts (at least 2 x 2)
#' @param chisq,n A chi-square statistic and the total N
#' @param p0,p1 Cell proportions under the null and the alternative (each sums to 1)
#' @return A named list of class `ss_result` with `w`, `df` (when known), `cramers_v` (for a table), `interpretation` and `inputs`.
#' @examples
#' calc_es_chisq_w(table = matrix(c(30, 20, 15, 35), 2))
#' calc_es_chisq_w(chisq = 8.5, n = 120)
#' @export
calc_es_chisq_w <- function(table = NULL, chisq = NULL, n = NULL, p0 = NULL, p1 = NULL) {
  if (sum(!is.null(table), !is.null(chisq), !is.null(p0)) != 1) stop("Give exactly one of: a table of counts, a chi-square statistic with n, or p0 and p1.", call. = FALSE)
  out <- list()
  if (!is.null(table)) {
    tab <- as.matrix(table)
    if (!is.numeric(tab) || any(dim(tab) < 2) || anyNA(tab) || any(tab < 0)) stop("table must be a matrix of non-negative counts, at least 2 x 2.", call. = FALSE)
    if (any(rowSums(tab) == 0) || any(colSums(tab) == 0)) stop("A row or column of the table is empty.", call. = FALSE)
    N <- sum(tab)
    expected <- outer(rowSums(tab), colSums(tab)) / N
    x2 <- sum((tab - expected)^2 / expected)
    w <- sqrt(x2 / N)
    out <- list(w = w, chisq = x2, n = N, df = (nrow(tab) - 1) * (ncol(tab) - 1), cramers_v = sqrt(x2 / (N * (min(dim(tab)) - 1))))
  } else if (!is.null(chisq)) {
    .es_num(chisq, "chisq"); if (chisq < 0) stop("chisq cannot be negative.", call. = FALSE)
    .es_num(n, "n", positive = TRUE)
    out <- list(w = sqrt(chisq / n), chisq = chisq, n = n)
  } else {
    if (is.null(p1) || length(p0) != length(p1) || length(p0) < 2) stop("p0 and p1 must be vectors of the same length (>= 2).", call. = FALSE)
    if (any(p0 <= 0) || any(p1 < 0) || abs(sum(p0) - 1) > 1e-6 || abs(sum(p1) - 1) > 1e-6) stop("p0 and p1 must be proportions that each sum to 1 (p0 > 0).", call. = FALSE)
    out <- list(w = sqrt(sum((p1 - p0)^2 / p0)), df = length(p0) - 1)
  }
  new_ss_result(c(out, list(interpretation = .es_interpret(out$w, "w"), inputs = list(chisq = chisq, n = n))))
}

# --- Survival: hazard ratio --------------------------------------------------------------------------
#' Hazard ratio from median survival times or survival probabilities
#'
#' With exponential survival (a constant hazard) the hazard is log(2) / median, so the hazard ratio of the experimental to the
#' control arm is median_control / median_experimental. From the survival probabilities (or event probabilities) at the same time
#' under proportional hazards, HR = log(S_e) / log(S_c). Give exactly one pair.
#'
#' @param median_e,median_c Median survival of the experimental and control arm (> 0, same time unit)
#' @param surv_e,surv_c Survival probabilities at the same time, in (0, 1)
#' @param pe,pc Cumulative event probabilities at the same time, in (0, 1)
#' @return A named list of class `ss_result` with `hr`, `log_hr`, `basis` and `inputs`.
#' @examples
#' calc_es_hazard_ratio(median_e = 18, median_c = 12)
#' @export
calc_es_hazard_ratio <- function(median_e = NULL, median_c = NULL, surv_e = NULL, surv_c = NULL, pe = NULL, pc = NULL) {
  pairs <- c(median = !is.null(median_e) || !is.null(median_c), surv = !is.null(surv_e) || !is.null(surv_c), p = !is.null(pe) || !is.null(pc))
  if (sum(pairs) != 1) stop("Give exactly one pair: the two medians, the two survival probabilities, or the two event probabilities.", call. = FALSE)
  unit <- function(x, label) { if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0 || x >= 1) stop(sprintf("%s must be a single number strictly between 0 and 1.", label), call. = FALSE); x }
  if (pairs[["median"]]) {
    if (is.null(median_e) || is.null(median_c)) stop("Give both medians.", call. = FALSE)
    hr <- .es_num(median_c, "median_c", positive = TRUE) / .es_num(median_e, "median_e", positive = TRUE)
    basis <- "medians, assuming exponential survival (hazard = log(2) / median)"
  } else if (pairs[["surv"]]) {
    if (is.null(surv_e) || is.null(surv_c)) stop("Give both survival probabilities.", call. = FALSE)
    hr <- log(unit(surv_e, "surv_e")) / log(unit(surv_c, "surv_c"))
    basis <- "survival probabilities at the same time, assuming proportional hazards"
  } else {
    if (is.null(pe) || is.null(pc)) stop("Give both event probabilities.", call. = FALSE)
    hr <- log(1 - unit(pe, "pe")) / log(1 - unit(pc, "pc"))
    basis <- "event probabilities over the same follow-up, assuming proportional hazards"
  }
  new_ss_result(list(hr = hr, log_hr = log(hr), basis = basis,
                     inputs = list(median_e = median_e, median_c = median_c, surv_e = surv_e, surv_c = surv_c, pe = pe, pc = pc)))
}

# --- Conversions among d, r, odds ratio, R-squared and f-squared -------------------------------------
#' Convert between d, r, an odds ratio, R-squared and f-squared
#'
#' Give ONE of `d`, `r`, `OR` (approximate), `r2` or `f2`:
#' \itemize{
#'   \item d and r (two groups): r = t / sqrt(t^2 + df) with t = d sqrt(n1 n2 / N), exact for the point-biserial correlation; without
#'     group sizes the large-sample equal-groups form d = 2 r / sqrt(1 - r^2) is used.
#'   \item d and the odds ratio: ln(OR) = d pi / sqrt(3) (Chinn 2000, who gives the divisor as 1.81); an approximation that
#'     assumes a logistic latent variable behind the outcome.
#'   \item R-squared and f-squared: f^2 = R^2 / (1 - R^2) (Cohen).
#' }
#'
#' @param d Cohen's d of two groups
#' @param r Correlation (point-biserial for two groups), in (-1, 1)
#' @param OR Odds ratio (> 0), converted to d by the approximation
#' @param r2 R-squared (or eta-squared), in (0, 1)
#' @param f2 Cohen's f-squared (> 0)
#' @param n1,n2 Group sizes for the exact d <-> r relation (optional)
#' @return A named list of class `ss_result` with `d`, `r`, `OR_approx`, `r2`, `f2`, `interpretation` and `inputs`.
#' @examples
#' calc_es_convert(d = 0.5)
#' calc_es_convert(r2 = 0.13)
#' @export
calc_es_convert <- function(d = NULL, r = NULL, OR = NULL, r2 = NULL, f2 = NULL, n1 = NULL, n2 = NULL) {
  if (sum(!is.null(d), !is.null(r), !is.null(OR), !is.null(r2), !is.null(f2)) != 1) stop("Give exactly one of: d, r, OR, r2 or f2.", call. = FALSE)
  have_n <- !is.null(n1) && !is.null(n2)
  if (xor(is.null(n1), is.null(n2))) stop("Give both group sizes, or neither.", call. = FALSE)
  if (have_n) { .es_n(n1, "n1"); .es_n(n2, "n2") }
  k <- pi / sqrt(3)
  d_to_r <- function(d) if (have_n) { t <- d * sqrt(n1 * n2 / (n1 + n2)); df <- n1 + n2 - 2; t / sqrt(t^2 + df) } else d / sqrt(d^2 + 4)
  r_to_d <- function(r) if (have_n) { df <- n1 + n2 - 2; r * sqrt(df) / sqrt(1 - r^2) / sqrt(n1 * n2 / (n1 + n2)) } else 2 * r / sqrt(1 - r^2)
  if (!is.null(r2) || !is.null(f2)) {
    if (!is.null(r2)) {
      if (!is.numeric(r2) || length(r2) != 1 || is.na(r2) || r2 <= 0 || r2 >= 1) stop("r2 must be a single number strictly between 0 and 1.", call. = FALSE)
      f2v <- r2 / (1 - r2); r2v <- r2
    } else {
      .es_num(f2, "f2", positive = TRUE); f2v <- f2; r2v <- f2 / (1 + f2)
    }
    return(new_ss_result(list(r2 = r2v, f2 = f2v, f = sqrt(f2v), interpretation = .es_interpret(sqrt(f2v), "f"),
                              inputs = list(r2 = r2, f2 = f2))))
  }
  if (!is.null(d)) dv <- .es_num(d, "d")
  else if (!is.null(r)) {
    if (!is.numeric(r) || length(r) != 1 || is.na(r) || abs(r) >= 1) stop("r must be a single number strictly between -1 and 1.", call. = FALSE)
    dv <- r_to_d(r)
  } else dv <- log(.es_num(OR, "OR", positive = TRUE)) / k
  rv <- d_to_r(dv)
  new_ss_result(list(d = dv, r = rv, OR_approx = exp(dv * k), r2 = rv^2, f2 = rv^2 / (1 - rv^2),
                     interpretation = .es_interpret(dv, "d"), inputs = list(d = d, r = r, OR = OR, n1 = n1, n2 = n2)))
}
