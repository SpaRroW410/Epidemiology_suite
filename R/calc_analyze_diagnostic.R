# Analyze from summary counts: diagnostic test evaluation (ROADMAP Track B1,
# item 13), single test and combinations of 2-6 tests.
#
# Single test, from the four cells of a test-by-disease table:
#
#                  Disease +   Disease -
#   Test +           TP          FP
#   Test -           FN          TN
#
#   Se = TP/(TP+FN), Sp = TN/(TN+FP), PPV = TP/(TP+FP), NPV = TN/(TN+FN).
#   Proportion intervals: Clopper-Pearson exact (Clopper & Pearson, Biometrika
#   1934;26:404-413) or Wilson score (Wilson, JASA 1927;22:209-212).
#   Likelihood ratios: log method of Simel DL, Samsa GP, Matchar DB, J Clin
#   Epidemiol 1991;44:763-770.
#   PPV/NPV read straight from the counts are only meaningful if the sample's
#   disease prevalence is the prevalence of interest. For a case-control-type
#   sample, or to ask "what if prevalence were p", PPV and NPV are recomputed
#   by Bayes' rule from Se and Sp, with the logit-scale delta-method interval of
#   Mercaldo ND, Lau KF, Zhou XH, Stat Med 2007;26:2170-2183.
#
# Combined testing (serial / parallel), tests assumed conditionally independent
# given disease status. With per-test sensitivities Se_i and specificities Sp_i:
#   parallel (positive if ANY test is positive):
#       Se = 1 - prod(1 - Se_i),   Sp = prod(Sp_i)
#   serial   (positive only if ALL tests are positive):
#       Se = prod(Se_i),           Sp = 1 - prod(1 - Sp_i)
# These follow from the product rule for independent events; they are checked in
# tests/testthat/test-calc_analyze_diagnostic.R by enumerating every result
# pattern. If the tests are conditionally DEPENDENT (typical when they measure
# related things) the true combined performance differs, usually worse than
# these figures (Vacek PM, Biometrics 1985;41:959-968). Intervals use the delta
# method on the logit scale, treating the per-test estimates as independent
# binomial proportions.

.dx_validate_counts <- function(tp, fp, fn, tn) {
  cells <- list(TP = tp, FP = fp, FN = fn, TN = tn)
  for (nm in names(cells)) {
    v <- cells[[nm]]
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < 0 || v != round(v)) {
      stop(sprintf("Cell %s must be a single non-negative whole number.", nm))
    }
  }
  if (tp + fp + fn + tn == 0) stop("The table is empty.")
  invisible(TRUE)
}

# Interval for x successes out of n: "exact" (Clopper-Pearson) or "wilson".
.dx_prop_ci <- function(x, n, conf_level, method = c("exact", "wilson")) {
  method <- match.arg(method)
  if (n == 0) return(c(NA_real_, NA_real_))
  if (method == "exact") {
    return(as.numeric(stats::binom.test(x, n, conf.level = conf_level)$conf.int))
  }
  z <- stats::qnorm(1 - (1 - conf_level) / 2); p <- x / n
  centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  c(centre - half, centre + half)
}

.dx_logit_ci <- function(est, se_logit, z) {
  if (!is.finite(est) || est <= 0 || est >= 1 || !is.finite(se_logit)) return(c(NA_real_, NA_real_))
  stats::plogis(stats::qlogis(est) + c(-1, 1) * z * se_logit)
}

.dx_log_ci <- function(est, se_log, z) {
  if (!is.finite(est) || est <= 0 || !is.finite(se_log)) return(c(NA_real_, NA_real_))
  exp(log(est) + c(-1, 1) * z * se_log)
}

# Bayes' rule
.dx_ppv <- function(se, sp, prev) se * prev / (se * prev + (1 - sp) * (1 - prev))
.dx_npv <- function(se, sp, prev) sp * (1 - prev) / (sp * (1 - prev) + (1 - se) * prev)

#' Evaluate one diagnostic test from its 2x2 counts
#'
#' @param tp,fp,fn,tn True positives, false positives, false negatives, true
#'   negatives (test result by disease status).
#' @param conf_level Confidence level for every interval.
#' @param ci_method "exact" (Clopper-Pearson) or "wilson" for the proportions.
#' @param prevalence NULL to read PPV/NPV from the counts (valid when the
#'   sample's prevalence is representative), or a prevalence in (0, 1) to
#'   recompute them from Se and Sp at that prevalence.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_total`, `sensitivity`, `sensitivity_lower`, `sensitivity_upper`, `specificity`, `specificity_lower`, `specificity_upper`, `ppv`, `ppv_lower`, `ppv_upper`, `npv`, `npv_lower`, `npv_upper`, `lr_positive`, `lr_positive_lower`, `lr_positive_upper`, `lr_negative`, `lr_negative_lower`, `lr_negative_upper`, `accuracy`, `accuracy_lower`, `accuracy_upper`, `youden_index`, `prevalence_in_sample`, `prevalence_used_for_pv`, `predictive_values_from` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_dx_single(18, 3, 2, 77, ci_method = "wilson")
#' @export
calc_analyze_dx_single <- function(tp, fp, fn, tn, conf_level = 0.95,
                                   ci_method = c("exact", "wilson"), prevalence = NULL) {
  ci_method <- match.arg(ci_method)
  .dx_validate_counts(tp, fp, fn, tn)
  .validate_unit_interval(conf_level, "Confidence level")
  if (!is.null(prevalence)) .validate_unit_interval(prevalence, "Prevalence")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)

  n1 <- tp + fn; n0 <- fp + tn; npos <- tp + fp; nneg <- fn + tn; n <- n1 + n0
  prop <- function(x, d) {
    est <- if (d > 0) x / d else NA_real_
    ci <- .dx_prop_ci(x, d, conf_level, ci_method)
    list(est = est, lo = ci[1], hi = ci[2])
  }
  se <- prop(tp, n1); sp <- prop(tn, n0); acc <- prop(tp + tn, n)
  prev_sample <- prop(n1, n)
  app_prev <- prop(npos, n)

  # Likelihood ratios (Simel et al. 1991)
  lr_pos <- if (is.finite(se$est) && is.finite(sp$est) && sp$est < 1) se$est / (1 - sp$est) else NA_real_
  lr_neg <- if (is.finite(se$est) && is.finite(sp$est) && sp$est > 0) (1 - se$est) / sp$est else NA_real_
  lr_pos_ci <- if (tp > 0 && fp > 0) .dx_log_ci(lr_pos, sqrt(1 / tp - 1 / n1 + 1 / fp - 1 / n0), z) else c(NA_real_, NA_real_)
  lr_neg_ci <- if (fn > 0 && tn > 0) .dx_log_ci(lr_neg, sqrt(1 / fn - 1 / n1 + 1 / tn - 1 / n0), z) else c(NA_real_, NA_real_)

  if (is.null(prevalence)) {
    ppv <- prop(tp, npos); npv <- prop(tn, nneg)
    prev_used <- prev_sample$est
    pv_basis <- "counts"
  } else {
    prev_used <- prevalence
    ppv_est <- if (is.finite(lr_pos)) .dx_ppv(se$est, sp$est, prevalence) else NA_real_
    npv_est <- if (is.finite(se$est) && is.finite(sp$est)) .dx_npv(se$est, sp$est, prevalence) else NA_real_
    # SE of logit(PPV) = SE of ln(LR+) and SE of logit(NPV) = SE of ln(LR-): the prevalence only shifts the logit
    ppv_ci <- if (tp > 0 && fp > 0) .dx_logit_ci(ppv_est, sqrt((1 - se$est) / tp + sp$est / fp), z) else c(NA_real_, NA_real_)
    npv_ci <- if (fn > 0 && tn > 0) .dx_logit_ci(npv_est, sqrt((1 - sp$est) / tn + se$est / fn), z) else c(NA_real_, NA_real_)
    ppv <- list(est = ppv_est, lo = ppv_ci[1], hi = ppv_ci[2])
    npv <- list(est = npv_est, lo = npv_ci[1], hi = npv_ci[2])
    pv_basis <- "specified prevalence"
  }

  new_ss_result(list(
    n_total = n,
    sensitivity = se$est, sensitivity_lower = se$lo, sensitivity_upper = se$hi,
    specificity = sp$est, specificity_lower = sp$lo, specificity_upper = sp$hi,
    ppv = ppv$est, ppv_lower = ppv$lo, ppv_upper = ppv$hi,
    npv = npv$est, npv_lower = npv$lo, npv_upper = npv$hi,
    lr_positive = lr_pos, lr_positive_lower = lr_pos_ci[1], lr_positive_upper = lr_pos_ci[2],
    lr_negative = lr_neg, lr_negative_lower = lr_neg_ci[1], lr_negative_upper = lr_neg_ci[2],
    accuracy = acc$est, accuracy_lower = acc$lo, accuracy_upper = acc$hi,
    youden_index = se$est + sp$est - 1,
    prevalence_in_sample = prev_sample$est,
    prevalence_used_for_pv = prev_used,
    predictive_values_from = pv_basis,
    inputs = list(tp = tp, fp = fp, fn = fn, tn = tn, conf_level = conf_level, ci_method = ci_method)
  ))
}

# Combined Se/Sp of tests under a rule, tests conditionally independent.
.dx_combine <- function(se, sp, rule = c("parallel", "serial")) {
  rule <- match.arg(rule)
  if (rule == "parallel") c(se = 1 - prod(1 - se), sp = prod(sp))
  else c(se = prod(se), sp = 1 - prod(1 - sp))
}

# Delta-method variances of the combined Se and Sp, given the variances of the
# per-test estimates (independent binomial proportions).
.dx_combine_var <- function(se, sp, var_se, var_sp, rule) {
  k <- length(se)
  others <- function(v, f) vapply(seq_len(k), function(i) prod(f(v[-i])), numeric(1))
  if (rule == "parallel") {
    d_se <- others(se, function(x) 1 - x); d_sp <- others(sp, identity)
  } else {
    d_se <- others(se, identity); d_sp <- others(sp, function(x) 1 - x)
  }
  c(se = sum(d_se^2 * var_se), sp = sum(d_sp^2 * var_sp))
}

.dx_strategy <- function(se, sp, n_dis, n_non, prevalence, rule, z) {
  comb <- .dx_combine(se, sp, rule)
  se_c <- unname(comb["se"]); sp_c <- unname(comb["sp"])
  have_n <- !is.null(n_dis) && !is.null(n_non)
  v <- if (have_n) .dx_combine_var(se, sp, se * (1 - se) / n_dis, sp * (1 - sp) / n_non, rule) else c(se = NA_real_, sp = NA_real_)
  se_logit <- function(est, var) if (is.finite(var) && est > 0 && est < 1) sqrt(var) / (est * (1 - est)) else NA_real_
  lr_pos <- if (sp_c < 1) se_c / (1 - sp_c) else NA_real_
  lr_neg <- if (sp_c > 0) (1 - se_c) / sp_c else NA_real_
  var_ln_lrpos <- if (have_n && se_c > 0 && sp_c < 1) v["se"] / se_c^2 + v["sp"] / (1 - sp_c)^2 else NA_real_
  var_ln_lrneg <- if (have_n && se_c < 1 && sp_c > 0) v["se"] / (1 - se_c)^2 + v["sp"] / sp_c^2 else NA_real_
  ppv <- .dx_ppv(se_c, sp_c, prevalence); npv <- .dx_npv(se_c, sp_c, prevalence)
  se_ci <- .dx_logit_ci(se_c, se_logit(se_c, v["se"]), z)
  sp_ci <- .dx_logit_ci(sp_c, se_logit(sp_c, v["sp"]), z)
  ppv_ci <- .dx_logit_ci(ppv, sqrt(var_ln_lrpos), z)
  npv_ci <- .dx_logit_ci(npv, sqrt(var_ln_lrneg), z)
  list(sensitivity = se_c, sensitivity_lower = se_ci[1], sensitivity_upper = se_ci[2],
       specificity = sp_c, specificity_lower = sp_ci[1], specificity_upper = sp_ci[2],
       ppv = ppv, ppv_lower = ppv_ci[1], ppv_upper = ppv_ci[2],
       npv = npv, npv_lower = npv_ci[1], npv_upper = npv_ci[2],
       lr_positive = lr_pos, lr_negative = lr_neg)
}

#' Serial and parallel combinations of 2-6 diagnostic tests
#'
#' @param se,sp Sensitivity and specificity of each test, as proportions
#'   (vectors of equal length, 2 to 6 tests).
#' @param prevalence Disease prevalence in the population the tests will be used
#'   in (needed for the predictive values).
#' @param n_diseased,n_nondiseased Optional numbers of diseased / non-diseased
#'   subjects behind each test's Se / Sp; when both are given the combined
#'   estimates get confidence intervals.
#' @param conf_level Confidence level.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_tests`, `test1_sensitivity`, `test1_sensitivity_lower`, `test1_sensitivity_upper`, `test1_specificity`, `test1_specificity_lower`, `test1_specificity_upper`, `test1_ppv`, `test1_ppv_lower`, `test1_ppv_upper`, `test1_npv`, `test1_npv_lower`, `test1_npv_upper`, `test1_lr_positive`, `test1_lr_negative`, `test2_sensitivity`, `test2_sensitivity_lower`, `test2_sensitivity_upper`, `test2_specificity`, `test2_specificity_lower`, `test2_specificity_upper`, `test2_ppv`, `test2_ppv_lower`, `test2_ppv_upper`, `test2_npv`, `test2_npv_lower`, `test2_npv_upper`, `test2_lr_positive`, `test2_lr_negative`, `test3_sensitivity`, `test3_sensitivity_lower`, `test3_sensitivity_upper`, `test3_specificity`, `test3_specificity_lower`, `test3_specificity_upper`, `test3_ppv`, `test3_ppv_lower`, `test3_ppv_upper`, `test3_npv`, `test3_npv_lower`, `test3_npv_upper`, `test3_lr_positive`, `test3_lr_negative`, `parallel_sensitivity`, `parallel_sensitivity_lower`, `parallel_sensitivity_upper`, `parallel_specificity`, `parallel_specificity_lower`, `parallel_specificity_upper`, `parallel_ppv`, `parallel_ppv_lower`, `parallel_ppv_upper`, `parallel_npv`, `parallel_npv_lower`, `parallel_npv_upper`, `parallel_lr_positive`, `parallel_lr_negative`, `serial_sensitivity`, `serial_sensitivity_lower`, `serial_sensitivity_upper`, `serial_specificity`, `serial_specificity_lower`, `serial_specificity_upper`, `serial_ppv`, `serial_ppv_lower`, `serial_ppv_upper`, `serial_npv`, `serial_npv_lower`, `serial_npv_upper`, `serial_lr_positive`, `serial_lr_negative` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_analyze_dx_combined(c(0.9, 0.8, 0.85), c(0.7, 0.9, 0.8), prevalence = 0.1)
#' @export
calc_analyze_dx_combined <- function(se, sp, prevalence, n_diseased = NULL, n_nondiseased = NULL,
                                     conf_level = 0.95) {
  k <- length(se)
  if (k < 2 || k > 6) stop("Give between 2 and 6 tests.")
  if (length(sp) != k) stop("Sensitivity and specificity must be given for the same number of tests.")
  for (i in seq_len(k)) {
    .validate_unit_interval(se[i], sprintf("Sensitivity of test %d", i))
    .validate_unit_interval(sp[i], sprintf("Specificity of test %d", i))
  }
  .validate_unit_interval(prevalence, "Prevalence")
  .validate_unit_interval(conf_level, "Confidence level")
  have_n <- !is.null(n_diseased) && !is.null(n_nondiseased)
  if (have_n) {
    ok <- function(x) length(x) == k && all(is.finite(x)) && all(x >= 1)
    if (!ok(n_diseased) || !ok(n_nondiseased)) {
      stop("Numbers of diseased and non-diseased subjects must be given for every test and be at least 1.")
    }
  } else {
    n_diseased <- n_nondiseased <- NULL
  }
  z <- stats::qnorm(1 - (1 - conf_level) / 2)

  res <- list(n_tests = k)
  for (i in seq_len(k)) {
    ti <- .dx_strategy(se[i], sp[i], n_diseased[i], n_nondiseased[i], prevalence, "parallel", z) # one test: rule is moot
    for (nm in names(ti)) res[[paste0("test", i, "_", nm)]] <- ti[[nm]]
  }
  for (rule in c("parallel", "serial")) {
    st <- .dx_strategy(se, sp, n_diseased, n_nondiseased, prevalence, rule, z)
    for (nm in names(st)) res[[paste0(rule, "_", nm)]] <- st[[nm]]
  }
  res$inputs <- list(sensitivities = se, specificities = sp, prevalence = prevalence,
                     n_diseased = if (have_n) n_diseased else NA, n_nondiseased = if (have_n) n_nondiseased else NA,
                     conf_level = conf_level)
  new_ss_result(res)
}

# Strategy table for display: each test alone, then parallel and serial.
analyze_dx_combined_table <- function(result) {
  k <- result$n_tests
  row <- function(label, prefix) {
    g <- function(f) { v <- result[[paste0(prefix, "_", f)]]; if (is.null(v)) NA_real_ else v }
    data.frame(strategy = label,
               sensitivity = g("sensitivity"), sensitivity_lower = g("sensitivity_lower"), sensitivity_upper = g("sensitivity_upper"),
               specificity = g("specificity"), specificity_lower = g("specificity_lower"), specificity_upper = g("specificity_upper"),
               ppv = g("ppv"), ppv_lower = g("ppv_lower"), ppv_upper = g("ppv_upper"),
               npv = g("npv"), npv_lower = g("npv_lower"), npv_upper = g("npv_upper"),
               lr_positive = g("lr_positive"), lr_negative = g("lr_negative"),
               stringsAsFactors = FALSE)
  }
  rows <- c(lapply(seq_len(k), function(i) row(sprintf("Test %d alone", i), paste0("test", i))),
            list(row(sprintf("Parallel: positive if ANY of the %d tests is positive", k), "parallel"),
                 row(sprintf("Serial: positive only if ALL %d tests are positive", k), "serial")))
  do.call(rbind, rows)
}

# Single-test estimates as a tidy table for display.
analyze_dx_single_table <- function(result) {
  m <- function(label, base) data.frame(
    measure = label, estimate = result[[base]],
    lower = result[[paste0(base, "_lower")]], upper = result[[paste0(base, "_upper")]],
    stringsAsFactors = FALSE)
  do.call(rbind, list(
    m("Sensitivity", "sensitivity"), m("Specificity", "specificity"),
    m("Positive predictive value (PPV)", "ppv"), m("Negative predictive value (NPV)", "npv"),
    m("Positive likelihood ratio (LR+)", "lr_positive"), m("Negative likelihood ratio (LR-)", "lr_negative"),
    m("Accuracy", "accuracy")
  ))
}
