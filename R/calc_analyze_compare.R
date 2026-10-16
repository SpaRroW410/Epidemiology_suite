# Analyze from summary counts: comparing two independent groups -- proportions
# (difference, ratio, odds ratio) and means (difference, standardized difference)
# -- ROADMAP Track B1, item 13.
#
# Several confidence-interval methods are computed side by side because they can differ
# materially (Newcombe 1998; Fagerland, Lydersen & Laake, Stat Methods Med Res 2015;24:224-254;
# online 2011) and the choice is the user's; the module says what each assumes.
#
# DIFFERENCE of proportions d = p1 - p2 (p_i = x_i/n_i):
#   Wald               d +/- z sqrt(p1 q1/n1 + p2 q2/n2); with continuity correction (1/n1 + 1/n2)/2 added
#   Agresti-Caffo      the Wald form on (x_i + 1)/(n_i + 2)  (Agresti & Caffo, Am Stat 2000;54:280-288)
#   Newcombe hybrid score (method 10) and its continuity-corrected form (method 11): the Wilson
#                      limits l_i, u_i of each proportion combined as d -/+ sqrt((p1 - l1)^2 + (u2 - p2)^2)
#                      etc. (Newcombe, Stat Med 1998;17:873-890; Wilson 1927; Newcombe, Stat Med
#                      1998;17:857-872 for the continuity-corrected Wilson limits)
#   Miettinen-Nurminen score  delta such that (d - delta)^2 / [v~(delta) N/(N - 1)] = z^2, with v~ the
#                      variance at the restricted maximum-likelihood estimates (Miettinen & Nurminen,
#                      Stat Med 1985;4:213-226); Mee (Biometrics 1984;40:1175-1176; Farrington & Manning,
#                      Stat Med 1990;9:1447-1454) is the same without the N/(N - 1) factor.
# RATIO p1/p2:  Katz log (Katz et al., Biometrics 1978;34:469-474); adjusted log, the Katz form on
#   (x_i + 1/2)/(n_i + 1/2) (Walter 1975; Pettigrew et al. 1986, as in DescTools::BinomRatioCI);
#   Koopman score (Koopman, Biometrics 1984;40:513-517; Miettinen & Nurminen 1985).
# ODDS RATIO: Woolf (1955) log interval; conditional exact (Fisher; stats::fisher.test()).
# MEANS from (n, mean, SD): Welch (Satterthwaite df) and Student pooled-variance t intervals for the
#   difference; F interval for the variance ratio; Cohen's d and Hedges' g (Hedges, J Educ Stat
#   1981;6:107-128) with noncentral-t confidence limits (Cumming & Finch, Educ Psychol Meas
#   2001;61:532-574).
# DescTools::BinomDiffCI(), DescTools::BinomRatioCI(), stats::fisher.test(), stats::t.test() and
# stats::var.test() are the verification oracles in tests/testthat/test-calc_analyze_compare.R.

.cmp_wilson <- function(x, n, z, cc = FALSE) {
  p <- x / n
  if (!cc) {
    centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
    half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
    return(c(max(0, centre - half), min(1, centre + half)))
  }
  q <- 1 - p
  lo <- if (x == 0) 0 else max(0, (2 * n * p + z^2 - 1 - z * sqrt(z^2 - 2 - 1 / n + 4 * p * (n * q + 1))) / (2 * (n + z^2)))
  hi <- if (x == n) 1 else min(1, (2 * n * p + z^2 + 1 + z * sqrt(z^2 + 2 - 1 / n + 4 * p * (n * q - 1))) / (2 * (n + z^2)))
  c(lo, hi)
}

# Restricted maximum-likelihood estimates of (p1, p2) under p1 - p2 = delta (Miettinen & Nurminen 1985).
.cmp_mle_diff <- function(p1, n1, p2, n2, delta) {
  theta <- n2 / n1
  a <- 1 + theta
  b <- -(1 + theta + p1 + theta * p2 + delta * (theta + 2))
  c <- delta^2 + delta * (2 * p1 + theta + 1) + p1 + theta * p2
  d <- -p1 * delta * (1 + delta)
  v <- (b / (3 * a))^3 - b * c / (6 * a^2) + d / (2 * a)
  u <- sign(v) * sqrt((b / (3 * a))^2 - c / (3 * a))
  if (!is.finite(u) || u == 0) u <- 1e-12
  w <- (pi + acos(max(-1, min(1, v / u^3)))) / 3
  r1 <- 2 * u * cos(w) - b / (3 * a)
  c(r1, r1 - delta)
}

# Score limits for the difference: MN (factor N/(N-1)) or Mee (no factor).
.cmp_score_diff <- function(x1, n1, x2, n2, z, mee = FALSE) {
  p1 <- x1 / n1; p2 <- x2 / n2; d <- p1 - p2; n <- n1 + n2
  fac <- if (mee) 1 else n / (n - 1)
  f <- function(delta) {
    r <- .cmp_mle_diff(p1, n1, p2, n2, delta)
    v <- r[1] * (1 - r[1]) / n1 + r[2] * (1 - r[2]) / n2
    (d - delta)^2 / (v * fac) - z^2
  }
  root <- function(lo, hi, side) {
    eps <- 1e-10
    flo <- f(lo + eps); fhi <- f(hi - eps)
    if (!is.finite(flo) || !is.finite(fhi) || flo * fhi > 0) return(if (side == "lower") -1 else 1)
    stats::uniroot(f, c(lo + eps, hi - eps), tol = 1e-12)$root
  }
  c(root(-1, d, "lower"), root(d, 1, "upper"))
}

# Koopman score limits for the ratio theta = p1/p2.
.cmp_score_ratio <- function(x1, n1, x2, n2, z) {
  p1 <- x1 / n1; p2 <- x2 / n2; n <- n1 + n2
  if (x1 == 0 || x2 == 0) return(c(NA_real_, NA_real_))
  est <- p1 / p2
  f <- function(theta) {
    aa <- n * theta; bb <- -(n1 * theta + x1 + n2 + x2 * theta); cc <- x1 + x2
    r2 <- (-bb - sqrt(max(bb^2 - 4 * aa * cc, 0))) / (2 * aa)
    r1 <- theta * r2
    v <- r1 * (1 - r1) / n1 + theta^2 * r2 * (1 - r2) / n2
    (p1 - theta * p2)^2 / v - z^2
  }
  lo <- tryCatch(stats::uniroot(f, c(1e-8, est), tol = 1e-12)$root, error = function(e) NA_real_)
  hi_end <- est * 10
  while (is.finite(hi_end) && f(hi_end) < 0 && hi_end < 1e8) hi_end <- hi_end * 10
  hi <- tryCatch(stats::uniroot(f, c(est, hi_end), tol = 1e-12)$root, error = function(e) NA_real_)
  c(lo, hi)
}

#' Compare two independent proportions: difference, ratio and odds ratio, several interval methods
#'
#' @param x1,n1 Events and sample size in group 1 (the "exposed" / treatment group).
#' @param x2,n2 Events and sample size in group 2 (the comparison group).
#' @param conf_level Confidence level.
calc_analyze_compare_proportions <- function(x1, n1, x2, n2, conf_level = 0.95) {
  for (nm in c("x1", "x2")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < 0 || v != round(v)) {
      stop(sprintf("%s must be a single non-negative whole number.", nm))
    }
  }
  for (nm in c("n1", "n2")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < 1 || v != round(v)) {
      stop(sprintf("%s must be a single positive whole number.", nm))
    }
  }
  if (x1 > n1 || x2 > n2) stop("The number of events cannot exceed the sample size.")
  .validate_unit_interval(conf_level, "Confidence level")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  p1 <- x1 / n1; p2 <- x2 / n2; d <- p1 - p2
  clamp <- function(v, lo, hi) pmin(hi, pmax(lo, v))

  wald_se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
  wald <- clamp(d + c(-1, 1) * z * wald_se, -1, 1)
  wald_cc <- clamp(d + c(-1, 1) * (z * wald_se + (1 / n1 + 1 / n2) / 2), -1, 1)
  q1 <- (x1 + 1) / (n1 + 2); q2 <- (x2 + 1) / (n2 + 2)
  ac <- clamp((q1 - q2) + c(-1, 1) * z * sqrt(q1 * (1 - q1) / (n1 + 2) + q2 * (1 - q2) / (n2 + 2)), -1, 1)
  w1 <- .cmp_wilson(x1, n1, z); w2 <- .cmp_wilson(x2, n2, z)
  newcombe <- c(d - sqrt((p1 - w1[1])^2 + (w2[2] - p2)^2), d + sqrt((w1[2] - p1)^2 + (p2 - w2[1])^2))
  c1 <- .cmp_wilson(x1, n1, z, cc = TRUE); c2 <- .cmp_wilson(x2, n2, z, cc = TRUE)
  newcombe_cc <- c(d - sqrt((p1 - c1[1])^2 + (c2[2] - p2)^2), d + sqrt((c1[2] - p1)^2 + (p2 - c2[1])^2))
  mn <- .cmp_score_diff(x1, n1, x2, n2, z, mee = FALSE)
  mee <- .cmp_score_diff(x1, n1, x2, n2, z, mee = TRUE)

  # ratio
  rr <- if (p2 > 0) p1 / p2 else NA_real_
  katz <- if (x1 > 0 && x2 > 0) exp(log(rr) + c(-1, 1) * z * sqrt(1 / x1 - 1 / n1 + 1 / x2 - 1 / n2)) else c(NA_real_, NA_real_)
  adj_rr <- ((x1 + 0.5) / (n1 + 0.5)) / ((x2 + 0.5) / (n2 + 0.5))
  adj_var <- 1 / (x1 + 0.5) - 1 / (n1 + 0.5) + 1 / (x2 + 0.5) - 1 / (n2 + 0.5)
  adjlog <- adj_rr * exp(c(-1, 1) * z * sqrt(adj_var))
  koopman <- .cmp_score_ratio(x1, n1, x2, n2, z)

  # odds ratio and tests
  tbl <- matrix(c(x1, n1 - x1, x2, n2 - x2), 2, byrow = TRUE)
  or <- if ((n1 - x1) > 0 && x2 > 0) (x1 * (n2 - x2)) / ((n1 - x1) * x2) else NA_real_
  woolf <- if (all(tbl > 0)) exp(log(or) + c(-1, 1) * z * sqrt(sum(1 / tbl))) else c(NA_real_, NA_real_)
  ft <- stats::fisher.test(tbl, conf.level = conf_level)
  pooled <- (x1 + x2) / (n1 + n2)
  chisq <- if (pooled > 0 && pooled < 1) (p1 - p2)^2 / (pooled * (1 - pooled) * (1 / n1 + 1 / n2)) else NA_real_

  new_ss_result(list(
    n_total = n1 + n2, proportion_1 = p1, proportion_2 = p2,
    risk_difference = d,
    wald_lower = wald[1], wald_upper = wald[2],
    wald_cc_lower = wald_cc[1], wald_cc_upper = wald_cc[2],
    agresti_caffo_lower = ac[1], agresti_caffo_upper = ac[2],
    newcombe_lower = newcombe[1], newcombe_upper = newcombe[2],
    newcombe_cc_lower = newcombe_cc[1], newcombe_cc_upper = newcombe_cc[2],
    miettinen_nurminen_lower = mn[1], miettinen_nurminen_upper = mn[2],
    mee_lower = mee[1], mee_upper = mee[2],
    risk_ratio = rr,
    ratio_katz_lower = katz[1], ratio_katz_upper = katz[2],
    ratio_adjusted_log_lower = adjlog[1], ratio_adjusted_log_upper = adjlog[2],
    ratio_koopman_lower = koopman[1], ratio_koopman_upper = koopman[2],
    odds_ratio = or, odds_ratio_woolf_lower = woolf[1], odds_ratio_woolf_upper = woolf[2],
    odds_ratio_conditional = unname(ft$estimate),
    odds_ratio_exact_lower = ft$conf.int[1], odds_ratio_exact_upper = ft$conf.int[2],
    chisq = chisq, chisq_p = if (is.na(chisq)) NA_real_ else stats::pchisq(chisq, 1, lower.tail = FALSE),
    fisher_p = ft$p.value,
    inputs = list(x1 = x1, n1 = n1, x2 = x2, n2 = n2, conf_level = conf_level)
  ))
}

# Display table of the interval methods for the difference, the ratio and the odds ratio.
analyze_compare_proportions_table <- function(result) {
  row <- function(measure, method, key, est, note) data.frame(
    measure = measure, method = method, estimate = est,
    lower = result[[paste0(key, "_lower")]], upper = result[[paste0(key, "_upper")]], note = note,
    stringsAsFactors = FALSE)
  d <- result$risk_difference; rr <- result$risk_ratio; or <- result$odds_ratio
  do.call(rbind, list(
    row("Difference", "Miettinen-Nurminen score", "miettinen_nurminen", d, "recommended by several reviews"),
    row("Difference", "Newcombe hybrid score", "newcombe", d, "recommended; no root-finding"),
    row("Difference", "Newcombe, continuity corrected", "newcombe_cc", d, "conservative"),
    row("Difference", "Mee score", "mee", d, "close to Miettinen-Nurminen"),
    row("Difference", "Agresti-Caffo", "agresti_caffo", d, "adds 1 success and 1 failure per group"),
    row("Difference", "Wald", "wald", d, "poor for small samples or extreme proportions"),
    row("Difference", "Wald, continuity corrected", "wald_cc", d, "conservative"),
    row("Ratio", "Koopman score", "ratio_koopman", rr, "recommended"),
    row("Ratio", "Adjusted log (+1/2)", "ratio_adjusted_log", rr, "defined when a count is zero"),
    row("Ratio", "Katz log", "ratio_katz", rr, "poor for small samples"),
    row("Odds ratio", "Conditional exact (Fisher)", "odds_ratio_exact", result$odds_ratio_conditional, "conservative; estimate is the conditional MLE"),
    row("Odds ratio", "Woolf log", "odds_ratio_woolf", or, "poor for small counts")
  ))
}

#' Compare two means from summary statistics (n, mean, SD per group)
#'
#' @param n1,mean1,sd1 Sample size, mean and standard deviation of group 1.
#' @param n2,mean2,sd2 The same for group 2.
#' @param conf_level Confidence level.
calc_analyze_compare_means <- function(n1, mean1, sd1, n2, mean2, sd2, conf_level = 0.95) {
  for (nm in c("n1", "n2")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < 2 || v != round(v)) {
      stop(sprintf("%s must be a single whole number of at least 2.", nm))
    }
  }
  for (nm in c("mean1", "mean2")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v)) stop(sprintf("%s must be a single number.", nm))
  }
  for (nm in c("sd1", "sd2")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v <= 0) stop(sprintf("%s must be a single positive number.", nm))
  }
  .validate_unit_interval(conf_level, "Confidence level")
  alpha <- 1 - conf_level
  diff <- mean1 - mean2

  se_w <- sqrt(sd1^2 / n1 + sd2^2 / n2)
  df_w <- se_w^4 / ((sd1^2 / n1)^2 / (n1 - 1) + (sd2^2 / n2)^2 / (n2 - 1))
  sp2 <- ((n1 - 1) * sd1^2 + (n2 - 1) * sd2^2) / (n1 + n2 - 2)
  se_p <- sqrt(sp2 * (1 / n1 + 1 / n2)); df_p <- n1 + n2 - 2
  tw <- diff / se_w; tp <- diff / se_p

  # variance ratio (F)
  fr <- sd1^2 / sd2^2
  f_ci <- c(fr / stats::qf(1 - alpha / 2, n1 - 1, n2 - 1), fr / stats::qf(alpha / 2, n1 - 1, n2 - 1))
  f_p <- 2 * min(stats::pf(fr, n1 - 1, n2 - 1), stats::pf(fr, n1 - 1, n2 - 1, lower.tail = FALSE))

  # standardized difference: Cohen's d (pooled SD), Hedges' g, noncentral-t limits
  sp <- sqrt(sp2); d_cohen <- diff / sp
  jfac <- exp(lgamma(df_p / 2) - lgamma((df_p - 1) / 2)) / sqrt(df_p / 2)
  scale <- sqrt(n1 * n2 / (n1 + n2))
  tstat <- d_cohen * scale
  ncp_lim <- function(p) {
    f <- function(ncp) stats::pt(tstat, df_p, ncp = ncp) - p
    lo <- tstat - 40; hi <- tstat + 40
    stats::uniroot(f, c(lo, hi), tol = 1e-10, extendInt = "yes")$root
  }
  d_lim <- c(ncp_lim(1 - alpha / 2), ncp_lim(alpha / 2)) / scale

  new_ss_result(list(
    n_total = n1 + n2, mean_difference = diff,
    welch_se = se_w, welch_df = df_w,
    welch_lower = diff - stats::qt(1 - alpha / 2, df_w) * se_w, welch_upper = diff + stats::qt(1 - alpha / 2, df_w) * se_w,
    welch_t = tw, welch_p = 2 * stats::pt(-abs(tw), df_w),
    pooled_se = se_p, pooled_df = df_p,
    pooled_lower = diff - stats::qt(1 - alpha / 2, df_p) * se_p, pooled_upper = diff + stats::qt(1 - alpha / 2, df_p) * se_p,
    pooled_t = tp, pooled_p = 2 * stats::pt(-abs(tp), df_p),
    variance_ratio = fr, variance_ratio_lower = f_ci[1], variance_ratio_upper = f_ci[2], variance_ratio_p = min(1, f_p),
    cohens_d = d_cohen, cohens_d_lower = d_lim[1], cohens_d_upper = d_lim[2],
    hedges_g = jfac * d_cohen, hedges_g_lower = jfac * d_lim[1], hedges_g_upper = jfac * d_lim[2],
    inputs = list(n1 = n1, mean1 = mean1, sd1 = sd1, n2 = n2, mean2 = mean2, sd2 = sd2, conf_level = conf_level)
  ))
}
