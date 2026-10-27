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

# --- Survival and conditional-logistic sample sizes that used to come from `powerSurvEpi` --------------------------------------
# The sources are the ones named in the module content files (content_logrank.R, content_case_control.R) and the package's own
# documentation: Freedman 1982 (via Rosner 2006) for the two-group log-rank size, Latouche et al. 2004 and Hsieh & Lavori 2000 for
# the Cox-model covariate sizes, Palta & Amini 1985 for stratification, and the matched case-control power formulas of Dupont 1988.
# None of the originals was read here; the formulas are checked against the package, not against the papers.
# Tests compare each with the package (ssizeCT, ssizeEpi, ssizeEpiCont, ssize.stratify, powerConLogistic.bin / .con) over grids of inputs.

# Two groups, log-rank, equal follow-up: k = nE / nC; pE, pC = event probabilities; RR = hazard ratio.
.cf_pse_ssize_ct <- function(power, k, pE, pC, RR, alpha = 0.05) {
  za <- stats::qnorm(1 - alpha / 2); zb <- stats::qnorm(power)
  m <- ((k * RR + 1) / (RR - 1))^2 * (za + zb)^2 / k
  denom <- k * pE + pC
  c(nE = ceiling(m * k / denom), nC = ceiling(m / denom))
}
# Cox model, binary covariate: theta = hazard ratio, p = proportion exposed, psi = event proportion, rho2 = squared multiple correlation.
.cf_pse_ssize_epi <- function(power, theta, p, psi, rho2, alpha = 0.05) {
  ceiling((stats::qnorm(1 - alpha / 2) + stats::qnorm(power))^2 / (log(theta)^2 * p * (1 - p) * psi * (1 - rho2)))
}
# Cox model, continuous covariate with variance sigma2.
.cf_pse_ssize_epi_cont <- function(power, theta, sigma2, psi, rho2, alpha = 0.05) {
  ceiling((stats::qnorm(1 - alpha / 2) + stats::qnorm(power))^2 / (log(theta)^2 * sigma2 * psi * (1 - rho2)))
}
# Stratified log-rank (one-sided alpha, as in the package): strata weights gVec, exposed proportions PVec, baseline hazards lambda0Vec.
.cf_pse_ssize_stratify <- function(power, timeUnit, gVec, PVec, HR, lambda0Vec, alpha = 0.05) {
  lambda1Vec <- lambda0Vec * HR
  part1 <- PVec * (1 - (exp(-lambda1Vec * (timeUnit - 1)) - exp(-lambda1Vec * timeUnit)) / lambda1Vec)
  part2 <- (1 - PVec) * (1 - (exp(-lambda0Vec * (timeUnit - 1)) - exp(-lambda0Vec * timeUnit)) / lambda0Vec)
  Vs <- part1 + part2
  mu <- log(HR) * sqrt(sum(gVec * PVec * (1 - PVec) * Vs, na.rm = TRUE))
  ceiling((stats::qnorm(1 - alpha) + stats::qnorm(power))^2 / mu^2)
}
# Matched case-control (nD cases and nH controls per set): number of sets N for a binary exposure with prevalence pE.
.cf_pse_conlogistic_bin <- function(power = 0.8, OR, pE, nD, nH, R2 = 0, alpha = 0.05, nTests = 1) {
  za <- stats::qnorm(1 - (alpha / 2) / nTests)
  core <- log(OR)^2 * pE * (1 - pE) * (1 - R2) * nD * nH / (nD + nH)
  (stats::qnorm(power) + za)^2 / core
}
# ... and for a continuous exposure with standard deviation sigma.
.cf_pse_conlogistic_con <- function(power = 0.8, OR, sigma, nD, nH, R2 = 0, alpha = 0.05, nTests = 1) {
  za <- stats::qnorm(1 - (alpha / 2) / nTests)
  core <- log(OR)^2 * sigma^2 * nD * (1 - 1 / choose(nD + nH, nD)) * (1 - R2)
  (stats::qnorm(power) + za)^2 / core
}
