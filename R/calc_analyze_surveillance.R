# Analyze from counts: aberration detection in a series of counts (ROADMAP Track B4, item 20).
# The input is a plain series of counts (daily or weekly cases) pasted in; nothing is estimated from line lists.
#
# EARS (CDC Early Aberration Reporting System; Hutwagner L, Thompson W, Seeman GM, Treadwell T. The bioterrorism
# preparedness and response Early Aberration Reporting System (EARS). J Urban Health 2003;80(Suppl 1):i89-i96; the
# formulas as laid out by Fricker RD, Hegler BL, Dunfee DA. Comparing syndromic surveillance detection methods: EARS'
# versus a CUSUM-based methodology. Stat Med 2008;27:3407-3429):
#   C1  S_t = (x_t - mean) / sd of the `baseline` observations just before t (default 7); signal if S_t > 3.
#   C2  the same with a guard band of 2 observations between the baseline and t (baseline t-9 ... t-3), so a rising
#       outbreak does not contaminate its own baseline; signal if S_t > 3.
#   C3  sum over t, t-1, t-2 of max(0, C2 statistic - 1); signal if the sum exceeds 2.
#   The baseline sd is the sample sd (n - 1). If it is zero the statistic is undefined (reported as missing, no
#   signal) unless a minimum sd is given.
# CUSUM (Page ES. Continuous inspection schemes. Biometrika 1954;41:100-115):
#   normal  z_t = (x_t - mu0) / sigma0, C_t = max(0, C_{t-1} + z_t - k); signal if C_t > h. mu0 and sigma0 are the
#           mean and sd of a baseline period (the first observations) or given. k = 0.5 detects a shift of one sd
#           quickly. This is the one-sided (upward) scheme: with k = 0.5, h = 4 the average run length to a false signal is
#           about 336 observations and with h = 5 about 931 (the familiar 168 and 465 are the two-sided values, half of
#           these). These are computed by spc::xcusum.arl() and checked by simulation in the tests
#           (Hawkins & Olwell, Cumulative Sum Charts and Charting for Quality Improvement, Springer 1998).
#   Poisson C_t = max(0, C_{t-1} + x_t - k_p) with k_p = (lambda1 - lambda0) / ln(lambda1 / lambda0), lambda0 the
#           baseline mean and lambda1 = shift_ratio * lambda0 (Lucas JM. Counted data CUSUMs. Technometrics
#           1985;27:129-144); signal if C_t > h (in counts).
#   After a signal the statistic is restarted at 0 when `reset` is TRUE (the usual practice in surveillance).
# Verification: C1 and C2 statistics and thresholds equal surveillance::earsC() (same baseline windows; earsC thresholds at
# qnorm(1 - alpha), so alpha = 1 - pnorm(3) reproduces the EARS value 3); C3 is checked by direct recomputation because
# earsC's C3 alarm rule leaves out the current-day term of the three-day sum, so it is not the same rule (noted, not
# copied). CUSUM run lengths in control and after 0.5 and 1 sd shifts agree with spc::xcusum.arl() by simulation (slow
# lane), and the recursions equal a by-hand computation. Both packages are used as oracles only (not runtime dependencies).

.sv_check_counts <- function(counts, min_n) {
  if (!is.numeric(counts) || anyNA(counts) || any(!is.finite(counts)) || any(counts < 0)) stop("Counts must be numbers, 0 or more.")
  if (length(counts) < min_n) stop(sprintf("Give at least %d observations for this method.", min_n))
  if (length(counts) > 5000) stop("At most 5000 observations are supported.")
}
.sv_check_pos <- function(x, label) if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) stop(sprintf("%s must be a single positive number.", label))

.sv_result <- function(fields, series, inputs) {
  fields$inputs <- inputs
  res <- new_ss_result(fields)
  attr(res, "series") <- series
  res
}

#' EARS C1, C2 and C3 aberration detection
#' @param counts Counts in time order. @param method "C1", "C2" or "C3".
#' @param baseline Length of the baseline (default 7). @param threshold Signal threshold (default 3; 2 for C3).
#' @param min_sd Smallest baseline sd allowed (default 0: undefined when the baseline has no variation).
calc_surveillance_ears <- function(counts, method = c("C1", "C2", "C3"), baseline = 7, threshold = NULL, min_sd = 0) {
  method <- match.arg(method)
  if (!is.numeric(baseline) || length(baseline) != 1 || is.na(baseline) || baseline < 3 || baseline != round(baseline)) stop("The baseline must be a whole number of at least 3 observations.")
  if (is.null(threshold)) threshold <- if (method == "C3") 2 else 3
  .sv_check_pos(threshold, "The threshold")
  if (!is.numeric(min_sd) || length(min_sd) != 1 || is.na(min_sd) || min_sd < 0) stop("The minimum sd must be a single number, 0 or more.")
  guard <- if (method == "C1") 0 else 2
  first_c <- baseline + guard + 1
  first <- first_c + if (method == "C3") 2 else 0
  .sv_check_counts(counts, first)
  n <- length(counts)
  stat_c <- rep(NA_real_, n)
  for (t in first_c:n) {
    base <- counts[(t - guard - baseline):(t - guard - 1)]
    s <- stats::sd(base)
    if (s < min_sd) s <- min_sd
    stat_c[t] <- if (s > 0) (counts[t] - mean(base)) / s else NA_real_
  }
  if (method == "C3") {
    stat <- rep(NA_real_, n)
    for (t in first:n) stat[t] <- sum(pmax(0, stat_c[t - 0:2] - 1))
  } else stat <- stat_c
  alarm <- !is.na(stat) & stat > threshold
  series <- data.frame(t = seq_len(n), count = counts, statistic = stat, threshold = threshold, alarm = alarm)
  .sv_result(list(method = method, n_obs = n, n_monitored = sum(!is.na(stat)), n_alarms = sum(alarm),
                  first_alarm = if (any(alarm)) which(alarm)[1] else NA_integer_, threshold = threshold, baseline = baseline,
                  n_undefined = sum(seq_len(n) >= first & is.na(stat))),
             series, list(method = method, baseline = baseline, threshold = threshold, min_sd = min_sd))
}

#' One-sided upward CUSUM for counts (normal or Poisson form)
#' @param counts Counts in time order.
#' @param type "normal" (standardized, reference value k, threshold h in sd units) or "poisson".
#' @param baseline Number of leading observations used to estimate the in-control mean (and sd); they are not monitored.
#' @param k,h Reference value and decision threshold (normal: sd units; Poisson: k is derived from `shift_ratio`).
#' @param shift_ratio Poisson: the out-of-control mean as a multiple of the in-control mean (> 1).
#' @param reset Restart the statistic at 0 after a signal.
calc_surveillance_cusum <- function(counts, type = c("normal", "poisson"), baseline = 14, k = 0.5, h = 4,
                                    shift_ratio = 2, reset = TRUE, min_sd = 0.5) {
  type <- match.arg(type)
  if (!is.numeric(baseline) || length(baseline) != 1 || is.na(baseline) || baseline < 3 || baseline != round(baseline)) stop("The baseline must be a whole number of at least 3 observations.")
  .sv_check_counts(counts, baseline + 1)
  .sv_check_pos(h, "The decision threshold h")
  if (type == "normal") {
    if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 0) stop("The reference value k must be a single number, 0 or more.")
  } else {
    .sv_check_pos(shift_ratio - 1, "The shift ratio minus 1 (the shift ratio must exceed 1)")
  }
  n <- length(counts)
  base <- counts[seq_len(baseline)]
  mu0 <- mean(base)
  if (type == "poisson" && mu0 <= 0) stop("The baseline has no cases, so a Poisson reference mean cannot be set.")
  sigma0 <- max(stats::sd(base), min_sd)
  kp <- if (type == "poisson") mu0 * (shift_ratio - 1) / log(shift_ratio) else NA_real_
  cs <- rep(NA_real_, n); alarm <- rep(FALSE, n)
  prev <- 0
  for (t in (baseline + 1):n) {
    inc <- if (type == "normal") (counts[t] - mu0) / sigma0 - k else counts[t] - kp
    cs[t] <- max(0, prev + inc)
    if (cs[t] > h) { alarm[t] <- TRUE; prev <- if (reset) 0 else cs[t] } else prev <- cs[t]
  }
  series <- data.frame(t = seq_len(n), count = counts, statistic = cs, threshold = h, alarm = alarm)
  .sv_result(list(method = paste0("CUSUM (", type, ")"), n_obs = n, n_monitored = n - baseline, n_alarms = sum(alarm),
                  first_alarm = if (any(alarm)) which(alarm)[1] else NA_integer_, threshold = h, baseline = baseline,
                  baseline_mean = mu0, baseline_sd = if (type == "normal") sigma0 else NA_real_,
                  reference_value = if (type == "normal") k else kp),
             series, list(type = type, baseline = baseline, k = k, h = h, shift_ratio = shift_ratio, reset = reset))
}
