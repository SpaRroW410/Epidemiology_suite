# Cohen's power functions that used to come from the `pwr` package (ROADMAP item 16, dependency reduction, second stage).
# Each is the textbook power function (Cohen J. Statistical Power Analysis for the Behavioral Sciences, 2nd ed.; Lawrence Erlbaum;
# 1988) written out, with the sample size found by `uniroot()` on the same interval and tolerance as pwr, so the sample sizes are
# identical to pwr's. tests/testthat/test-calc_closed_forms_pwr.R compares every function with pwr over grids of inputs (pwr is a
# verification oracle only, not a dependency).
# Only the two directions this app uses are supported: n from power (power given, n NULL) and power from n. The argument
# names follow pwr's so the call sites read the same. Internal (leading dot).
#   t tests         power = P(T' > t_crit) with the noncentral t, ncp = d sqrt(n / tsample); two-sided adds the lower tail.
#   ANOVA / F tests power = P(F'(df1, df2, lambda) > F_crit), lambda = k n f^2 (anova) or f2 (u + v + 1) (regression).
#   correlation     Fisher z with the bias term r / (2 (n - 1)), as in Cohen's tables as implemented by pwr.
#   chi-square      power = P(chi2'(df, ncp = N w^2) > chi2_crit).
#   proportions     arcsine effect size h = 2 asin(sqrt(p1)) - 2 asin(sqrt(p2)); normal approximation.

.cf_pwr_check <- function(sig.level, power, n_given, label) {
  if (!is.numeric(sig.level) || length(sig.level) != 1 || is.na(sig.level) || sig.level < 0 || sig.level > 1) stop("'sig.level' must be numeric in [0, 1]")
  if (!is.null(power) && (!is.numeric(power) || length(power) != 1 || is.na(power) || power < 0 || power > 1)) stop("'power' must be numeric in [0, 1]")
  if (is.null(power) == !n_given) stop(sprintf("exactly one of %s and power must be NULL", label))
}

# Solve for the sample size on pwr's interval, or return the power when the sample size is given.
.cf_pwr_run <- function(p_fn, n, power, lower, upper = 1e+09) {
  if (is.null(power)) return(list(n = n, power = p_fn(n)))
  list(n = stats::uniroot(function(x) p_fn(x) - power, c(lower, upper))$root, power = power)
}

.cf_pwr_t_test <- function(n = NULL, d, sig.level = 0.05, power = NULL, type = c("two.sample", "one.sample", "paired"),
                           alternative = c("two.sided", "less", "greater")) {
  type <- match.arg(type); alternative <- match.arg(alternative)
  .cf_pwr_check(sig.level, power, !is.null(n), "n")
  tsample <- if (type == "two.sample") 2 else 1
  tside <- if (alternative == "two.sided") 2 else 1
  if (alternative == "two.sided") d <- abs(d)
  p_fn <- function(n) {
    nu <- (n - 1) * tsample
    ncp <- sqrt(n / tsample) * d
    switch(alternative,
      less = stats::pt(stats::qt(sig.level / tside, nu, lower.tail = TRUE), nu, ncp = ncp, lower.tail = TRUE),
      two.sided = {
        qu <- stats::qt(sig.level / tside, nu, lower.tail = FALSE)
        stats::pt(qu, nu, ncp = ncp, lower.tail = FALSE) + stats::pt(-qu, nu, ncp = ncp, lower.tail = TRUE)
      },
      greater = stats::pt(stats::qt(sig.level / tside, nu, lower.tail = FALSE), nu, ncp = ncp, lower.tail = FALSE))
  }
  .cf_pwr_run(p_fn, n, power, 2 + 1e-10)
}

# Two groups of different sizes: given n1, the n2 that reaches the power (or the power for n1 and n2).
.cf_pwr_t2n_test <- function(n1, n2 = NULL, d, sig.level = 0.05, power = NULL, alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .cf_pwr_check(sig.level, power, !is.null(n2), "n2")
  if (n1 < 2 || (!is.null(n2) && n2 < 2)) stop("number of observations in each group must be at least 2")
  tside <- if (alternative == "two.sided") 2 else 1
  if (alternative == "two.sided") d <- abs(d)
  p_fn <- function(n2) {
    nu <- n1 + n2 - 2
    ncp <- d * (1 / sqrt(1 / n1 + 1 / n2))
    switch(alternative,
      less = stats::pt(stats::qt(sig.level / tside, nu, lower.tail = TRUE), nu, ncp = ncp, lower.tail = TRUE),
      two.sided = {
        qu <- stats::qt(sig.level / tside, nu, lower.tail = FALSE)
        stats::pt(qu, nu, ncp = ncp, lower.tail = FALSE) + stats::pt(-qu, nu, ncp = ncp, lower.tail = TRUE)
      },
      greater = stats::pt(stats::qt(sig.level / tside, nu, lower.tail = FALSE), nu, ncp = ncp, lower.tail = FALSE))
  }
  r <- .cf_pwr_run(p_fn, n2, power, 2 + 1e-10)
  list(n1 = n1, n2 = r$n, power = r$power)
}

# Balanced one-way ANOVA: k groups, Cohen's f; n is per group.
.cf_pwr_anova_test <- function(k, n = NULL, f, sig.level = 0.05, power = NULL) {
  .cf_pwr_check(sig.level, power, !is.null(n), "n")
  if (k < 2) stop("number of groups must be at least 2")
  p_fn <- function(n) {
    lambda <- k * n * f^2
    stats::pf(stats::qf(sig.level, k - 1, (n - 1) * k, lower.tail = FALSE), k - 1, (n - 1) * k, lambda, lower.tail = FALSE)
  }
  .cf_pwr_run(p_fn, n, power, 2 + 1e-10)
}

# Multiple regression / general linear model: u numerator df, v denominator df, f2 = R2 / (1 - R2); returns v (n = v + u + 1).
.cf_pwr_f2_test <- function(u, v = NULL, f2, sig.level = 0.05, power = NULL) {
  .cf_pwr_check(sig.level, power, !is.null(v), "v")
  if (u < 1) stop("degree of freedom 'u' for numerator must be at least 1")
  p_fn <- function(v) {
    lambda <- f2 * (u + v + 1)
    stats::pf(stats::qf(sig.level, u, v, lower.tail = FALSE), u, v, lambda, lower.tail = FALSE)
  }
  r <- .cf_pwr_run(p_fn, v, power, 1 + 1e-10)
  list(u = u, v = r$n, power = r$power)
}

.cf_pwr_r_test <- function(n = NULL, r, sig.level = 0.05, power = NULL, alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .cf_pwr_check(sig.level, power, !is.null(n), "n")
  if (!is.null(n) && n < 4) stop("number of observations must be at least 4")
  if (alternative == "two.sided") r <- abs(r)
  p_fn <- function(n) {
    rr <- if (alternative == "less") -r else r
    ttt <- stats::qt(if (alternative == "two.sided") sig.level / 2 else sig.level, df = n - 2, lower.tail = FALSE)
    rc <- sqrt(ttt^2 / (ttt^2 + n - 2))
    zr <- atanh(rr) + rr / (2 * (n - 1))
    zrc <- atanh(rc)
    if (alternative == "two.sided") stats::pnorm((zr - zrc) * sqrt(n - 3)) + stats::pnorm((-zr - zrc) * sqrt(n - 3))
    else stats::pnorm((zr - zrc) * sqrt(n - 3))
  }
  .cf_pwr_run(p_fn, n, power, 4 + 1e-10)
}

# Chi-square tests of goodness of fit / independence: Cohen's w, N total observations.
.cf_pwr_chisq_test <- function(w, N = NULL, df, sig.level = 0.05, power = NULL) {
  .cf_pwr_check(sig.level, power, !is.null(N), "N")
  if (w < 0) stop("effect size 'w' must be non-negative")
  p_fn <- function(N) {
    k <- stats::qchisq(sig.level, df = df, lower.tail = FALSE)
    stats::pchisq(k, df = df, ncp = N * w^2, lower.tail = FALSE)
  }
  r <- .cf_pwr_run(p_fn, N, power, 1 + 1e-10)
  list(N = r$n, df = df, power = r$power)
}

.cf_pwr_prop_p <- function(alternative, sig.level, h, scale) {
  function(n) {
    sq <- h * sqrt(n / scale)
    switch(alternative,
      two.sided = stats::pnorm(stats::qnorm(sig.level / 2, lower.tail = FALSE) - sq, lower.tail = FALSE) +
        stats::pnorm(stats::qnorm(sig.level / 2, lower.tail = TRUE) - sq, lower.tail = TRUE),
      greater = stats::pnorm(stats::qnorm(sig.level, lower.tail = FALSE) - sq, lower.tail = FALSE),
      less = stats::pnorm(stats::qnorm(sig.level, lower.tail = TRUE) - sq, lower.tail = TRUE))
  }
}

# One proportion against a value (arcsine h); n is the sample size.
.cf_pwr_p_test <- function(h, n = NULL, sig.level = 0.05, power = NULL, alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .cf_pwr_check(sig.level, power, !is.null(n), "n")
  if (alternative == "two.sided") h <- abs(h)
  .cf_pwr_run(.cf_pwr_prop_p(alternative, sig.level, h, 1), n, power, 2 + 1e-10)
}

# Two proportions with equal group sizes (arcsine h); n is per group.
.cf_pwr_2p_test <- function(h, n = NULL, sig.level = 0.05, power = NULL, alternative = c("two.sided", "less", "greater")) {
  alternative <- match.arg(alternative)
  .cf_pwr_check(sig.level, power, !is.null(n), "n")
  if (alternative == "two.sided") h <- abs(h)
  .cf_pwr_run(.cf_pwr_prop_p(alternative, sig.level, h, 2), n, power, 2 + 1e-10)
}

# Effect sizes.
.cf_es_h <- function(p1, p2) 2 * asin(sqrt(p1)) - 2 * asin(sqrt(p2))
.cf_es_w1 <- function(P0, P1) sqrt(sum((P1 - P0)^2 / P0))
.cf_es_w2 <- function(P) {
  P0 <- rowSums(P) %*% t(colSums(P))
  sqrt(sum((P - P0)^2 / P0))
}

# --- Logistic and Poisson regression sample sizes (replace powerMediation) ---------------------------------------------------
# Hsieh FY, Bloch DA, Larsen MD. A simple method of sample size calculation for linear and logistic regression. Stat Med 1998;17:1623-1634
# (formula 1: continuous predictor; formula 2: binary predictor) and Signorini DF. Sample size for Poisson regression. Biometrika
# 1991;78:446-450. Written out here; tests compare them with powerMediation::SSizeLogisticCon / SSizeLogisticBin / sizePoisson.
.cf_size_logistic_bin <- function(p1, p2, B, alpha = 0.05, power = 0.8) {
  za <- stats::qnorm(1 - alpha / 2); zb <- stats::qnorm(power)
  p <- (1 - B) * p1 + B * p2
  part1 <- za * sqrt(p * (1 - p) / B)
  part2 <- zb * sqrt(p1 * (1 - p1) + p2 * (1 - p2) * (1 - B) / B)
  part3 <- (p1 - p2)^2 * (1 - B)
  ceiling((part1 + part2)^2 / part3)
}
.cf_size_logistic_con <- function(p1, OR, alpha = 0.05, power = 0.8) {
  za <- stats::qnorm(1 - alpha / 2); zb <- stats::qnorm(power)
  ceiling((za + zb)^2 / (p1 * (1 - p1) * log(OR)^2))
}
.cf_size_poisson <- function(beta0, beta1, mu.x1, sigma2.x1, mu.T = 1, phi = 1, alpha = 0.05, power = 0.8) {
  za <- stats::qnorm(1 - alpha / 2); zb <- stats::qnorm(power)
  denom <- mu.T * exp(beta0) * beta1^2
  part1 <- beta1 * mu.x1 + beta1^2 * sigma2.x1 / 2
  vb1.a <- exp(-part1) / sigma2.x1
  vb1.0 <- 1 / sigma2.x1
  ceiling(phi * (za * sqrt(vb1.0) + zb * sqrt(vb1.a))^2 / denom)
}

# --- ROC curve sample sizes (replace pROC::power.roc.test) -----------------------------------------------------------------
# Obuchowski NA, McClish DK. Sample size determination for diagnostic accuracy studies involving binormal ROC curve indices.
# Stat Med 1997;16:1529-1542 (two curves, full or partial AUC); Obuchowski NA, Lieber ML, Wians FH Jr. ROC curves in clinical
# chemistry: uses, misuses, and possible solutions. Clin Chem 2004;50:1118-1125 (single curve against 0.5). The formulas are those
# of pROC's power.roc.test() (a two-sided test splits alpha in two); tests compare them with it over grids of inputs.
.cf_roc_expr1 <- function(A, B) exp(-A^2 / (2 * (1 + B^2)))
.cf_roc_cdagger <- function(A, B, fpr) (stats::qnorm(fpr) + A * B / (1 + B^2)) * sqrt(1 + B^2)
.cf_roc_f <- function(A, B, fpr1 = NULL, fpr2 = NULL) {
  base <- .cf_roc_expr1(A, B) * (2 * pi * (1 + B^2))^(-1 / 2)
  if (is.null(fpr1) || is.null(fpr2)) return(base)
  base * (stats::pnorm(.cf_roc_cdagger(A, B, fpr1)) - stats::pnorm(.cf_roc_cdagger(A, B, fpr2)))
}
.cf_roc_g <- function(A, B, fpr1 = NULL, fpr2 = NULL) {
  e1 <- .cf_roc_expr1(A, B); e2 <- 1 + B^2
  if (is.null(fpr1) || is.null(fpr2)) return(-e1 * A * B * (2 * pi * e2^3)^(-1 / 2))
  c1 <- .cf_roc_cdagger(A, B, fpr1); c2 <- .cf_roc_cdagger(A, B, fpr2)
  e3 <- stats::pnorm(c1) - stats::pnorm(c2)
  e4 <- exp(-c1^2 / 2) - exp(-c2^2 / 2)
  e1 * (2 * pi * e2)^(-1) * (-e4) - A * B * e1 * (2 * pi * e2^3)^(-1 / 2) * e3
}
.cf_roc_var <- function(A, B, kappa, fpr1 = NULL, fpr2 = NULL) {
  .cf_roc_f(A, B, fpr1, fpr2)^2 * (1 + B^2 / kappa + A^2 / 2) + .cf_roc_g(A, B, fpr1, fpr2)^2 * B^2 * (1 + kappa) / (2 * kappa)
}
.cf_roc_cov <- function(A1, B1, A2, B2, rn, ra, kappa, f11 = NULL, f12 = NULL, f21 = NULL, f22 = NULL) {
  fa <- .cf_roc_f(A1, B1, f11, f12); fb <- .cf_roc_f(A2, B2, f21, f22)
  ga <- .cf_roc_g(A1, B1, f11, f12); gb <- .cf_roc_g(A2, B2, f21, f22)
  fa * fb * (ra + rn * B1 * B2 / kappa + ra^2 * A1 * A2 / 2) + ga * gb * (B1 * B2 * (rn^2 + kappa * ra^2) / (2 * kappa)) +
    fa * gb * (ra^2 * A1 * B2 / 2) + fb * ga * (ra^2 * A2 * B1 / 2)
}

# Number of cases (controls = kappa x cases) for a single curve against AUC = 0.5.
.cf_pwr_roc_auc <- function(auc, sig.level = 0.05, power = 0.8, kappa = 1) {
  za <- stats::qnorm(1 - sig.level / 2); zb <- stats::qnorm(power)
  A <- stats::qnorm(auc) * 1.414
  Vtheta <- (0.0099 * exp(-A^2 / 2)) * ((5 * A^2 + 8) + (A^2 + 8) / kappa)
  nd <- (za * sqrt(0.0792 * (1 + 1 / kappa)) + zb * sqrt(Vtheta))^2 / (auc - 0.5)^2
  list(ncases = nd, ncontrols = kappa * nd)
}

# Number of cases for two correlated binormal curves (full AUC when the fpr* arguments are NULL).
.cf_pwr_roc_two <- function(A1, B1, A2, B2, rn, ra, delta, sig.level = 0.05, power = 0.8, kappa = 1,
                            fpr11 = NULL, fpr12 = NULL, fpr21 = NULL, fpr22 = NULL) {
  za <- stats::qnorm(1 - sig.level / 2); zb <- stats::qnorm(power)
  v1 <- .cf_roc_var(A1, B1, kappa, fpr11, fpr12)
  v2 <- .cf_roc_var(A2, B2, kappa, fpr21, fpr22)
  c12 <- .cf_roc_cov(A1, B1, A2, B2, rn, ra, kappa, fpr11, fpr12, fpr21, fpr22)
  v0 <- 2 * v1 - 2 * c12
  va <- v1 + v2 - 2 * c12
  nd <- (za * sqrt(v0) + zb * sqrt(va))^2 / delta^2
  list(ncases = nd, ncontrols = kappa * nd)
}
