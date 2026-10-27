# Closed-form sample-size formulas that used to come from the `TrialSize` package (ROADMAP item 16, dependency reduction, stage 2).
# TrialSize implements the formulas of Chow S-C, Shao J, Wang H. Sample Size Calculations in Clinical Research, 2nd ed.; Chapman &
# Hall/CRC; 2008 (the chapter for each is named in the module content files). They are one-line expressions; each is written out
# here and tests/testthat/test-calc_closed_forms_ts.R compares it with the TrialSize function over grids of inputs (TrialSize is a
# verification oracle only, not a dependency). The argument names follow TrialSize's.

# Chapter 5: McNemar's test for paired proportions, psai = p10 / p01 odds ratio of discordant pairs, paid = discordant proportion.
.cf_ts_mcnemar <- function(alpha, beta, psai, paid) {
  (stats::qnorm(1 - alpha / 2) * (psai + 1) + stats::qnorm(1 - beta) * sqrt((psai + 1)^2 - (psai - 1)^2 * paid))^2 / ((psai - 1)^2 * paid)
}

# Chapter 4: propensity-score strata (J strata; a = stratum weights, b = exposure proportions, p1, phi = odds ratio).
.cf_ts_ps_strata <- function(alpha, beta, J, a, b, p1, phi) {
  p2 <- phi * p1 / (phi * p1 + 1 - p1)
  delta <- sum(a * b * (1 - b) * (p1 - p2))
  sigma1 <- sum(a * b * (1 - b) * ((1 - b) * p1 * (1 - p1) + b * p2 * (1 - p2)))
  sigma0 <- sum(a * b * (1 - b) * (b * p1 + (1 - b) * p2) * (b * (1 - p1) + (1 - b) * (1 - p2)))
  (sqrt(sigma0) * stats::qnorm(1 - alpha / 2) + sqrt(sigma1) * stats::qnorm(1 - beta))^2 / delta^2
}
.cf_ts_ps_nostrata <- function(alpha, beta, J, a, b, p1, phi) {
  p2 <- phi * p1 / (phi * p1 + 1 - p1)
  p1star <- sum(a * b * p1) / sum(a * b)
  p2star <- sum(a * (1 - b) * p2) / sum(a * (1 - b))
  pstar <- sum(a * (b * p1 + (1 - b) * p2))
  b1 <- sum(a * b); b2 <- sum(a * (1 - b))
  sigma1star <- p1star * (1 - p1star) / b1 + p2star * (1 - p2star) / b2
  sigma0star <- pstar * (1 - pstar) * (1 / b1 + 1 / b2)
  (sqrt(sigma0star) * stats::qnorm(1 - alpha / 2) + sqrt(sigma1star) * stats::qnorm(1 - beta))^2 / (p1star - p2star)^2
}

# Chapter 5: Cochran-Armitage trend test (pi = group proportions, di = scores, ni = relative group sizes, delta = continuity term).
.cf_ts_cochran_armitage <- function(alpha, beta, pi, di, ni, delta) {
  qi <- 1 - pi
  N <- sum(ni)
  p <- sum(ni * pi) / N
  q <- 1 - p
  ri <- ni / ni[1]
  dmean <- sum(ni * di) / sum(ni)
  A <- sum(ri * pi * (di - dmean))
  n0 <- (stats::qnorm(1 - alpha) * sqrt(p * q * sum(ri * (di - dmean)^2)) +
           stats::qnorm(1 - beta) * sqrt(sum(pi * qi * ri * (di - dmean)^2)))^2 / A^2
  n0 * (1 + sqrt(1 + 2 * delta / (A * n0)))^2 / 4
}

# Chapter 9: 2 x 2 crossover, equivalence (n per sequence).
.cf_ts_crossover_equality <- function(alpha, beta, sigma, margin) {
  (stats::qnorm(1 - alpha / 2) + stats::qnorm(1 - beta))^2 * sigma^2 / (2 * margin^2)
}

# Chapter 6: linear dose-response contrast (ci = contrast coefficients, mui = group means, fi = relative group sizes).
.cf_ts_dose_response_linear <- function(alpha, beta, sigma, mui, ci, fi) {
  epsilon <- sum(ci * mui)
  (stats::qnorm(1 - alpha) + stats::qnorm(1 - beta))^2 * sigma^2 * sum(ci^2 / fi) / epsilon^2
}

# Chapter 6: pairwise comparisons in a one-way layout (tau = number of comparisons), means and proportions.
.cf_ts_anova_pairwise <- function(alpha, beta, tau, sigma, margin) {
  2 * (stats::qnorm(1 - alpha / (2 * tau)) + stats::qnorm(1 - beta))^2 * sigma^2 / margin^2
}
.cf_ts_anova_pairwise_prop <- function(alpha, beta, tau, p1, p2, delta) {
  (stats::qnorm(1 - alpha / (2 * tau)) + stats::qnorm(1 - beta))^2 * (p1 * (1 - p1) + p2 * (1 - p2)) / delta^2
}

# Chapter 4: non-inferiority on a (log) odds ratio and on a hazard ratio.
.cf_ts_rr_nis <- function(alpha, beta, or, k, pt, pc, margin) {
  (stats::qnorm(1 - alpha) + stats::qnorm(1 - beta))^2 * (1 / (k * pt * (1 - pt)) + 1 / (pc * (1 - pc))) / (log(or) - margin)^2
}
.cf_ts_cox_nis <- function(alpha, beta, loghr, p1, d, delta) {
  p2 <- 1 - p1
  (stats::qnorm(1 - alpha) + stats::qnorm(1 - beta))^2 / ((loghr - delta)^2 * p1 * p2 * d)
}

# Chapter 8: nonparametric (Wilcoxon-type) sample sizes.
.cf_ts_nonpara_two <- function(alpha, beta, k, p1, p2, p3) {
  (stats::qnorm(1 - alpha / 2) * sqrt(k * (k + 1) / 12) + stats::qnorm(1 - beta) * sqrt(k^2 * (p2 - p1^2) + k * (p3 - p1^2)))^2 / (k^2 * (1 / 2 - p1)^2)
}
.cf_ts_nonpara_one <- function(alpha, beta, p2, p3, p4) {
  (stats::qnorm(1 - alpha / 2) / sqrt(12) + stats::qnorm(1 - beta) * sqrt(p3 + 4 * p4 - 4 * p2^2))^2 / (1 / 4 - p2)^2
}
.cf_ts_nonpara_indep <- function(alpha, beta, p1, p2) {
  4 * (stats::qnorm(1 - alpha / 2) / 3 + stats::qnorm(1 - beta) * sqrt(2 * p2 - 1 - (2 * p1 - 1)^2))^2 / (2 * p1 - 1)^2
}
