# Analyze from summary counts: paired binary data (McNemar), agreement (Cohen's
# kappa) and trend across ordered groups (chi-square for trend) -- ROADMAP Track
# B1, item 13.
#
# McNemar / matched pairs. 2x2 table of paired results (test 1 rows, test 2 columns):
#     a  b      a = both positive, b = test 1 + / test 2 -, c = test 1 - / test 2 +,
#     c  d      d = both negative. Only the discordant pairs b and c carry information.
#   McNemar chi-square (b - c)^2 / (b + c), 1 df, also with Edwards' continuity correction
#   (|b - c| - 1)^2 / (b + c) (McNemar Q. Psychometrika 1947;12:153-157). Exact test: b ~
#   Binomial(b + c, 1/2) under H0. Matched-pair odds ratio b/c with an exact CI (Clopper-Pearson
#   on b/(b + c), mapped to p/(1 - p)) and a Wald-log CI. Difference in the two marginal
#   proportions (b - c)/N with SE sqrt((b + c) - (b - c)^2/N)/N (Fleiss, Levin & Paik.
#   Statistical Methods for Rates and Proportions, 3rd ed., Wiley 2003).
#
# Cohen's kappa from a k x k table of two raters (Cohen J. Educ Psychol Meas 1960;20:37-46):
#   kappa = (po - pe)/(1 - pe). Confidence interval from the large-sample standard error
#   of Fleiss, Cohen & Everitt (Psychol Bull 1969;72:323-327), also for weighted kappa with
#   linear or quadratic agreement weights (Cohen J. Psychol Bull 1968;70:213-220); test of
#   kappa = 0 with the standard error under H0 (Fleiss 1981). PABAK = (k po - 1)/(k - 1)
#   (Byrt T, Bishop J, Carlin JB. J Clin Epidemiol 1993;46:423-429).
#
# Chi-square test for trend (Cochran-Armitage) across g ordered groups with r_i events out of
# n_i and scores x_i: chi2 = {sum x_i (r_i - n_i pbar)}^2 / {pbar (1 - pbar) [sum n_i x_i^2 -
# (sum n_i x_i)^2 / N]}, 1 df (Cochran WG. Biometrics 1954;10:417-451; Armitage P. Biometrics
# 1955;11:375-386).
#
# stats::mcnemar.test(), stats::binom.test(), stats::prop.trend.test(), DescTools::CohenKappa()
# and epiR::epi.kappa() are the verification oracles in tests/testthat/test-calc_analyze_tests.R.

.tt_count <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 0 || x != round(x)) {
    stop(sprintf("%s must be a single non-negative whole number.", label))
  }
}

#' McNemar's test and matched-pair estimates from a 2x2 table of paired results
#'
#' @param a,b,c,d Both positive (a), test 1 positive / test 2 negative (b), test 1 negative /
#'   test 2 positive (c), both negative (d).
#' @param conf_level Confidence level for every interval.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_pairs`, `discordant_pairs`, `positive_test1`, `positive_test2`, `mcnemar_chisq`, `mcnemar_p`, `mcnemar_chisq_corrected`, `mcnemar_p_corrected`, `exact_p`, `mid_p`, `matched_odds_ratio`, `matched_odds_ratio_exact_lower`, `matched_odds_ratio_exact_upper`, `matched_odds_ratio_wald_lower`, `matched_odds_ratio_wald_upper`, `paired_difference`, `paired_difference_lower`, `paired_difference_upper` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_mcnemar(20, 0, 0, 30)
#' @export
calc_analyze_mcnemar <- function(a, b, c, d, conf_level = 0.95) {
  .tt_count(a, "Cell a"); .tt_count(b, "Cell b"); .tt_count(c, "Cell c"); .tt_count(d, "Cell d")
  .validate_unit_interval(conf_level, "Confidence level")
  n <- a + b + c + d
  if (n == 0) stop("The table is empty.")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  disc <- b + c
  chi <- if (disc > 0) (b - c)^2 / disc else NA_real_
  chi_cc <- if (disc > 0) max(abs(b - c) - 1, 0)^2 / disc else NA_real_
  p <- function(x) if (is.na(x)) NA_real_ else stats::pchisq(x, 1, lower.tail = FALSE)
  exact_p <- if (disc > 0) stats::binom.test(b, disc, 0.5)$p.value else NA_real_
  midp <- if (disc > 0) max(0, exact_p - stats::dbinom(b, disc, 0.5)) else NA_real_

  or <- if (c > 0) b / c else NA_real_
  or_exact <- if (disc > 0) {
    ci <- as.numeric(stats::binom.test(b, disc, conf.level = conf_level)$conf.int); ci / (1 - ci)
  } else c(NA_real_, NA_real_)
  or_wald <- if (b > 0 && c > 0) exp(log(b / c) + c(-1, 1) * z * sqrt(1 / b + 1 / c)) else c(NA_real_, NA_real_)

  diff <- (b - c) / n
  se <- sqrt(disc - (b - c)^2 / n) / n
  new_ss_result(list(
    n_pairs = n, discordant_pairs = disc,
    positive_test1 = (a + b) / n, positive_test2 = (a + c) / n,
    mcnemar_chisq = chi, mcnemar_p = p(chi),
    mcnemar_chisq_corrected = chi_cc, mcnemar_p_corrected = p(chi_cc),
    exact_p = exact_p, mid_p = midp,
    matched_odds_ratio = or, matched_odds_ratio_exact_lower = or_exact[1], matched_odds_ratio_exact_upper = or_exact[2],
    matched_odds_ratio_wald_lower = or_wald[1], matched_odds_ratio_wald_upper = or_wald[2],
    paired_difference = diff, paired_difference_lower = diff - z * se, paired_difference_upper = diff + z * se,
    inputs = list(a = a, b = b, c = c, d = d, conf_level = conf_level)
  ))
}

#' Cohen's kappa (unweighted or weighted) from a square table of two raters' classifications
#'
#' @param table A square numeric matrix of counts (rows = rater 1, columns = rater 2), 2 to 6 categories.
#' @param weights "unweighted", "linear" (equal-spacing) or "quadratic" (Fleiss-Cohen) agreement weights.
#' @param conf_level Confidence level.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_total`, `categories`, `weights`, `kappa`, `kappa_se`, `kappa_lower`, `kappa_upper`, `observed_agreement`, `expected_agreement`, `z_test_kappa0`, `p_value_kappa0`, `pabak` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_kappa(matrix(c(30, 0, 0, 70), 2, byrow = TRUE))
#' @export
calc_analyze_kappa <- function(table, weights = c("unweighted", "linear", "quadratic"), conf_level = 0.95) {
  weights <- match.arg(weights)
  x <- tryCatch(as.matrix(table), error = function(e) NULL)
  if (is.null(x) || !is.numeric(x) || nrow(x) != ncol(x)) stop("The table must be a square matrix of counts.")
  k <- nrow(x)
  if (k < 2 || k > 6) stop("Use between 2 and 6 categories.")
  if (any(is.na(x)) || any(!is.finite(x)) || any(x < 0) || any(x != round(x))) {
    stop("Every cell must be a non-negative whole number.")
  }
  n <- sum(x)
  if (n == 0) stop("The table is empty.")
  .validate_unit_interval(conf_level, "Confidence level")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)

  pm <- x / n
  row_f <- rowSums(pm); col_f <- colSums(pm)
  w <- switch(weights,
    unweighted = diag(k),
    linear = 1 - abs(outer(1:k, 1:k, "-")) / (k - 1),
    quadratic = 1 - (abs(outer(1:k, 1:k, "-")) / (k - 1))^2)
  po <- sum(w * pm); pe <- sum(w * outer(row_f, col_f))
  if (isTRUE(all.equal(pe, 1))) {
    kappa <- NA_real_; se <- NA_real_
  } else {
    kappa <- (po - pe) / (1 - pe)
    # Fleiss, Cohen & Everitt (1969) large-sample variance (not assuming kappa = 0)
    # the (i, j) term is w_ij - (wbar_i. + wbar_.j)(1 - kappa), with wbar_i. = sum_j w_ij p_.j and wbar_.j = sum_i w_ij p_i.
    inner <- w - outer(as.vector(w %*% col_f), as.vector(t(w) %*% row_f), "+") * (1 - kappa)
    var <- (sum(pm * inner^2) - (kappa - pe * (1 - kappa))^2) / ((1 - pe)^2 * n)
    se <- sqrt(max(var, 0))
  }
  # standard error under H0: kappa = 0 (unweighted: Fleiss 1981)
  se0 <- NA_real_
  if (weights == "unweighted" && !is.na(kappa)) {
    s <- sum(row_f * col_f * (row_f + col_f))
    se0 <- sqrt(max(pe + pe^2 - s, 0) / (n * (1 - pe)^2))
  }
  z0 <- if (!is.na(se0) && se0 > 0) kappa / se0 else NA_real_
  pabak <- if (weights == "unweighted") (k * po - 1) / (k - 1) else NA_real_

  new_ss_result(list(
    n_total = n, categories = k, weights = weights,
    kappa = kappa, kappa_se = se, kappa_lower = kappa - z * se, kappa_upper = kappa + z * se,
    observed_agreement = po, expected_agreement = pe,
    z_test_kappa0 = z0, p_value_kappa0 = if (is.na(z0)) NA_real_ else 2 * stats::pnorm(-abs(z0)),
    pabak = pabak,
    inputs = list(table = paste(as.vector(t(x)), collapse = ","), conf_level = conf_level)
  ))
}

# Landis & Koch's (1977, Biometrics 33:159-174) verbal labels for kappa -- a convention, not a test.
analyze_kappa_label <- function(kappa) {
  if (is.na(kappa)) return("n/a")
  if (kappa < 0) "poor" else if (kappa <= 0.2) "slight" else if (kappa <= 0.4) "fair"
  else if (kappa <= 0.6) "moderate" else if (kappa <= 0.8) "substantial" else "almost perfect"
}

#' Chi-square test for trend in proportions across ordered groups (Cochran-Armitage)
#'
#' @param events,totals Events and group sizes, one per group (2 to 8 groups).
#' @param scores Group scores (default 1, 2, ..., g): equally spaced unless you supply doses.
#' @param conf_level Confidence level for the per-group Wilson intervals.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_total`, `events_total`, `overall_proportion`, `groups`, `trend_chisq`, `trend_p`, `trend_direction`, `group1_proportion`, `group1_wilson_lower`, `group1_wilson_upper`, `group2_proportion`, `group2_wilson_lower`, `group2_wilson_upper`, `group3_proportion`, `group3_wilson_lower`, `group3_wilson_upper`, `group4_proportion`, `group4_wilson_lower`, `group4_wilson_upper` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_trend(c(10, 20, 35, 50), rep(100, 4))
#' @export
calc_analyze_trend <- function(events, totals, scores = seq_along(events), conf_level = 0.95) {
  g <- length(events)
  if (g < 2 || g > 8) stop("Use between 2 and 8 groups.")
  if (length(totals) != g || length(scores) != g) stop("Events, group sizes and scores must have the same length.")
  for (i in seq_len(g)) {
    .tt_count(events[i], sprintf("Events in group %d", i)); .tt_count(totals[i], sprintf("Group size %d", i))
    if (totals[i] < 1) stop(sprintf("Group size %d must be at least 1.", i))
    if (events[i] > totals[i]) stop(sprintf("Group %d has more events than subjects.", i))
  }
  if (!is.numeric(scores) || any(!is.finite(scores))) stop("Scores must be numbers.")
  if (length(unique(scores)) < 2) stop("The scores must not all be equal.")
  .validate_unit_interval(conf_level, "Confidence level")

  n <- sum(totals); r <- sum(events); pbar <- r / n
  stat <- NA_real_; pval <- NA_real_
  if (r > 0 && r < n) {
    tnum <- sum(scores * (events - totals * pbar))
    v <- pbar * (1 - pbar) * (sum(totals * scores^2) - sum(totals * scores)^2 / n)
    stat <- tnum^2 / v
    pval <- stats::pchisq(stat, 1, lower.tail = FALSE)
  }
  direction <- if (is.na(stat)) NA_character_ else {
    slope <- sum(scores * (events - totals * pbar))
    if (slope > 0) "increasing" else if (slope < 0) "decreasing" else "flat"
  }
  res <- list(n_total = n, events_total = r, overall_proportion = pbar, groups = g,
              trend_chisq = stat, trend_p = pval, trend_direction = direction)
  for (i in seq_len(g)) {
    ci <- calc_analyze_ci_proportion(events[i], totals[i], conf_level)
    res[[paste0("group", i, "_proportion")]] <- events[i] / totals[i]
    res[[paste0("group", i, "_wilson_lower")]] <- ci$wilson_lower
    res[[paste0("group", i, "_wilson_upper")]] <- ci$wilson_upper
  }
  res$inputs <- list(events = paste(events, collapse = ","), totals = paste(totals, collapse = ","),
                     scores = paste(scores, collapse = ","), conf_level = conf_level)
  new_ss_result(res)
}
