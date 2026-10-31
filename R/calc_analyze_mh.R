# Analyze from summary counts: stratified 2x2 tables, Mantel-Haenszel analysis
# (ROADMAP Track B1, item 13).
#
# k strata (confounder levels), each a 2x2 table with rows = exposure, columns =
# outcome:   a b / c d   (exposed with/without outcome, unexposed with/without).
# Per stratum: N1 = a+b, N0 = c+d, M1 = a+c, M0 = b+d, T = N1+N0.
#
# Pooled (adjusted) estimates
#   OR_MH  = sum(a d / T) / sum(b c / T)                     Mantel & Haenszel,
#            J Natl Cancer Inst 1959;22:719-748; variance of ln OR_MH: Robins J,
#            Breslow N, Greenland S. Biometrics 1986;42:311-323.
#   RR_MH  = sum(a N0 / T) / sum(c N1 / T), variance of ln RR_MH from Greenland S,
#            Robins JM. Biometrics 1985;41:55-68.
#   RD_MH  = sum((a N0 - c N1)/T) / sum(N1 N0 / T), variance of Sato T. Biometrics
#            1989;45:1323-1324 (valid also for sparse strata).
# Tests
#   Cochran-Mantel-Haenszel chi-square for conditional independence (1 df), with
#   and without the continuity correction: Mantel & Haenszel 1959.
#   Homogeneity of the stratum odds ratios: Woolf (Ann Hum Genet 1955;19:251-253),
#   Breslow-Day (Breslow NE, Day NE. Statistical Methods in Cancer Research, vol 1,
#   IARC 1980) and Tarone's correction (Tarone RE. Biometrika 1985;72:431-435).
#   Homogeneity of the stratum risk ratios: the Woolf-type inverse-variance test.
# The pooled estimate is meaningful only if the strata agree (the homogeneity
# tests), and "adjusted" only compared with the crude (collapsed) estimate.
# The closed forms are written out here; epiR::epi.2by2(), stats::mantelhaen.test()
# and DescTools::BreslowDayTest() are the verification oracles in
# tests/testthat/test-calc_analyze_mh.R.

.mh_parse_strata <- function(tables) {
  m <- tryCatch(as.matrix(as.data.frame(tables)), error = function(e) NULL)
  if (is.null(m) || ncol(m) < 4) stop("Give the strata as rows of four counts: a, b, c, d.")
  m <- m[, 1:4, drop = FALSE]
  storage.mode(m) <- "double"
  colnames(m) <- c("a", "b", "c", "d")
  k <- nrow(m)
  if (k < 2) stop("Give at least 2 strata.")
  if (k > 20) stop("At most 20 strata are supported.")
  for (i in seq_len(k)) {
    v <- m[i, ]
    if (any(is.na(v)) || any(!is.finite(v)) || any(v < 0) || any(v != round(v))) {
      stop(sprintf("Stratum %d: every cell must be a non-negative whole number.", i))
    }
    if (sum(v) == 0) stop(sprintf("Stratum %d is empty.", i))
  }
  m
}

# Breslow-Day expected a (A*) given the pooled odds ratio and the margins: the
# root of A (D) / (B C) = OR with B = N1 - A, C = M1 - A, D = N0 - M1 + A that lies
# in the feasible range.
.mh_expected_a <- function(or, n1, n0, m1) {
  if (abs(or - 1) < 1e-10) return(n1 * m1 / (n1 + n0))
  bb <- n0 + n1 * or - m1 * (1 - or)
  det <- sqrt(bb^2 + 4 * (1 - or) * or * n1 * m1)
  cand <- cbind((-bb - det) / (2 - 2 * or), (-bb + det) / (2 - 2 * or))
  amax <- pmin(n1, m1)
  amin <- pmax(0, m1 - n0)
  ifelse(cand[, 1] >= amin - 1e-9 & cand[, 1] <= amax + 1e-9, cand[, 1], cand[, 2])
}

#' Mantel-Haenszel analysis of stratified 2x2 tables
#'
#' @param tables A matrix or data frame with one row per stratum and four columns
#'   a, b, c, d (exposed with outcome, exposed without, unexposed with, unexposed without).
#' @param design "cohort" (also gives the risk ratio and risk difference) or
#'   "case_control" (odds ratio only).
#' @param conf_level Confidence level for every interval.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_strata`, `n_total`, `design`, `crude_odds_ratio`, `crude_odds_ratio_lower`, `crude_odds_ratio_upper`, `mh_odds_ratio`, `mh_odds_ratio_lower`, `mh_odds_ratio_upper`, `odds_ratio_change_percent`, `crude_risk_ratio`, `crude_risk_ratio_lower`, `crude_risk_ratio_upper`, `mh_risk_ratio`, `mh_risk_ratio_lower`, `mh_risk_ratio_upper`, `risk_ratio_change_percent`, `crude_risk_difference`, `crude_risk_difference_lower`, `crude_risk_difference_upper`, `mh_risk_difference`, `mh_risk_difference_lower`, `mh_risk_difference_upper`, `cmh_chisq`, `cmh_p`, `cmh_chisq_corrected`, `cmh_p_corrected`, `strata_in_homogeneity_tests`, `woolf_or_chisq`, `woolf_or_df`, `woolf_or_p`, `woolf_rr_chisq`, `woolf_rr_df`, `woolf_rr_p`, `breslow_day_chisq`, `breslow_day_df`, `breslow_day_p`, `tarone_chisq`, `tarone_p`, `zero_cell_strata` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_mantel_haenszel(rbind(c(5, 5, 0, 10), c(0, 8, 3, 9)))
#' @export
calc_analyze_mantel_haenszel <- function(tables, design = c("cohort", "case_control"), conf_level = 0.95) {
  design <- match.arg(design)
  m <- .mh_parse_strata(tables)
  .validate_unit_interval(conf_level, "Confidence level")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  k <- nrow(m)
  a <- m[, "a"]; b <- m[, "b"]; c <- m[, "c"]; d <- m[, "d"]
  n1 <- a + b; n0 <- c + d; m1 <- a + c; m0 <- b + d; tt <- n1 + n0

  # crude (collapsed over strata) 2x2 table
  crude <- calc_analyze_2x2(sum(a), sum(b), sum(c), sum(d), design = design, conf_level = conf_level)

  res <- list(n_strata = k, n_total = sum(tt), design = design)

  # --- Mantel-Haenszel odds ratio (Robins-Breslow-Greenland variance) -------------
  g <- a * d / tt; h <- b * c / tt; p <- (a + d) / tt; q <- (b + c) / tt
  or_mh <- if (sum(h) > 0 && sum(g) > 0) sum(g) / sum(h) else NA_real_
  or_ci <- c(NA_real_, NA_real_)
  if (is.finite(or_mh)) {
    var_ln <- sum(g * p) / (2 * sum(g)^2) + sum(g * q + h * p) / (2 * sum(g) * sum(h)) + sum(h * q) / (2 * sum(h)^2)
    or_ci <- exp(log(or_mh) + c(-1, 1) * z * sqrt(var_ln))
  }
  res$crude_odds_ratio <- crude$odds_ratio
  res$crude_odds_ratio_lower <- crude$odds_ratio_lower; res$crude_odds_ratio_upper <- crude$odds_ratio_upper
  res$mh_odds_ratio <- or_mh; res$mh_odds_ratio_lower <- or_ci[1]; res$mh_odds_ratio_upper <- or_ci[2]
  res$odds_ratio_change_percent <- if (is.finite(or_mh) && !is.na(crude$odds_ratio)) 100 * (crude$odds_ratio - or_mh) / or_mh else NA_real_

  if (design == "cohort") {
    # --- Mantel-Haenszel risk ratio (Greenland-Robins variance) ---------------------
    r_num <- sum(a * n0 / tt); s_den <- sum(c * n1 / tt)
    rr_mh <- if (s_den > 0 && r_num > 0) r_num / s_den else NA_real_
    rr_ci <- c(NA_real_, NA_real_)
    if (is.finite(rr_mh)) {
      var_ln <- sum(m1 * n1 * n0 / tt^2 - a * c / tt) / (r_num * s_den)
      rr_ci <- exp(log(rr_mh) + c(-1, 1) * z * sqrt(var_ln))
    }
    # --- Mantel-Haenszel risk difference (Sato variance) ----------------------------
    w <- sum(n1 * n0 / tt)
    rd_mh <- sum((a * n0 - c * n1) / tt) / w
    pp <- sum((n1^2 * c - n0^2 * a + 0.5 * n1 * n0 * (n0 - n1)) / tt^2)
    qq <- sum((a * (n0 - c) + c * (n1 - a)) / (2 * tt))
    rd_se <- sqrt((rd_mh * pp + qq) / w^2)
    res$crude_risk_ratio <- crude$risk_ratio
    res$crude_risk_ratio_lower <- crude$risk_ratio_lower; res$crude_risk_ratio_upper <- crude$risk_ratio_upper
    res$mh_risk_ratio <- rr_mh; res$mh_risk_ratio_lower <- rr_ci[1]; res$mh_risk_ratio_upper <- rr_ci[2]
    res$risk_ratio_change_percent <- if (is.finite(rr_mh) && !is.na(crude$risk_ratio)) 100 * (crude$risk_ratio - rr_mh) / rr_mh else NA_real_
    res$crude_risk_difference <- crude$risk_difference
    res$crude_risk_difference_lower <- crude$risk_difference_lower; res$crude_risk_difference_upper <- crude$risk_difference_upper
    res$mh_risk_difference <- rd_mh
    res$mh_risk_difference_lower <- rd_mh - z * rd_se; res$mh_risk_difference_upper <- rd_mh + z * rd_se
  }

  # --- Cochran-Mantel-Haenszel test of conditional independence -------------------
  use <- tt >= 2
  e_a <- n1 * m1 / tt
  v_a <- n1 * n0 * m1 * m0 / (tt^2 * (tt - 1))
  dev <- sum((a - e_a)[use]); vsum <- sum(v_a[use])
  cmh <- if (vsum > 0) dev^2 / vsum else NA_real_
  cmh_cc <- if (vsum > 0) max(abs(dev) - 0.5, 0)^2 / vsum else NA_real_
  pchi <- function(x, df) if (is.na(x)) NA_real_ else stats::pchisq(x, df, lower.tail = FALSE)
  res$cmh_chisq <- cmh; res$cmh_p <- pchi(cmh, 1)
  res$cmh_chisq_corrected <- cmh_cc; res$cmh_p_corrected <- pchi(cmh_cc, 1)

  # --- Homogeneity of stratum effects ---------------------------------------------
  full <- a > 0 & b > 0 & c > 0 & d > 0
  nf <- sum(full)
  res$strata_in_homogeneity_tests <- nf
  woolf <- function(ln, var) {
    wgt <- 1 / var; centre <- sum(wgt * ln) / sum(wgt); sum(wgt * (ln - centre)^2)
  }
  if (nf >= 2) {
    x <- woolf(log(a * d / (b * c))[full], (1 / a + 1 / b + 1 / c + 1 / d)[full])
    res$woolf_or_chisq <- x; res$woolf_or_df <- nf - 1; res$woolf_or_p <- pchi(x, nf - 1)
    if (design == "cohort") {
      xr <- woolf(log((a / n1) / (c / n0))[full], (1 / a - 1 / n1 + 1 / c - 1 / n0)[full])
      res$woolf_rr_chisq <- xr; res$woolf_rr_df <- nf - 1; res$woolf_rr_p <- pchi(xr, nf - 1)
    }
  } else {
    res$woolf_or_chisq <- NA_real_; res$woolf_or_df <- NA_integer_; res$woolf_or_p <- NA_real_
    if (design == "cohort") { res$woolf_rr_chisq <- NA_real_; res$woolf_rr_df <- NA_integer_; res$woolf_rr_p <- NA_real_ }
  }
  inf <- n1 > 0 & n0 > 0 & m1 > 0 & m0 > 0 # strata whose margins let A* exist
  ni <- sum(inf)
  if (ni >= 2 && is.finite(or_mh) && or_mh > 0) {
    astar <- .mh_expected_a(or_mh, n1[inf], n0[inf], m1[inf])
    bstar <- n1[inf] - astar; cstar <- m1[inf] - astar; dstar <- n0[inf] - m1[inf] + astar
    vv <- 1 / (1 / astar + 1 / bstar + 1 / cstar + 1 / dstar)
    bd <- sum((a[inf] - astar)^2 / vv)
    tar <- bd - sum(a[inf] - astar)^2 / sum(vv)
    res$breslow_day_chisq <- bd; res$breslow_day_df <- ni - 1; res$breslow_day_p <- pchi(bd, ni - 1)
    res$tarone_chisq <- tar; res$tarone_p <- pchi(tar, ni - 1)
  } else {
    res$breslow_day_chisq <- NA_real_; res$breslow_day_df <- NA_integer_; res$breslow_day_p <- NA_real_
    res$tarone_chisq <- NA_real_; res$tarone_p <- NA_real_
  }

  res$zero_cell_strata <- sum(!full)
  strata_inputs <- as.list(as.vector(t(m)))
  names(strata_inputs) <- paste0(rep(c("a", "b", "c", "d"), k), "_", rep(seq_len(k), each = 4))
  res$inputs <- c(strata_inputs, list(conf_level = conf_level))
  new_ss_result(res)
}

# Stratum-specific estimates for display, rebuilt from the stored inputs.
analyze_mh_strata_table <- function(result, labels = NULL) {
  k <- result$n_strata
  design <- result$design
  rows <- lapply(seq_len(k), function(i) {
    cell <- function(x) result$inputs[[paste0(x, "_", i)]]
    r <- calc_analyze_2x2(cell("a"), cell("b"), cell("c"), cell("d"), design = design,
                          conf_level = result$inputs$conf_level)
    data.frame(
      stratum = if (!is.null(labels) && length(labels) >= i && nzchar(labels[i])) labels[i] else paste("Stratum", i),
      a = cell("a"), b = cell("b"), c = cell("c"), d = cell("d"),
      odds_ratio = r$odds_ratio, odds_ratio_lower = r$odds_ratio_lower, odds_ratio_upper = r$odds_ratio_upper,
      risk_ratio = if (design == "cohort") r$risk_ratio else NA_real_,
      risk_ratio_lower = if (design == "cohort") r$risk_ratio_lower else NA_real_,
      risk_ratio_upper = if (design == "cohort") r$risk_ratio_upper else NA_real_,
      stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
