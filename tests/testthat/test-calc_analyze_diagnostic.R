# Scott et al. (2008) Table 1, the worked example in epiR::epi.tests()'s help page:
# 744 disease-positive patients of whom 670 test positive; 842 disease-negative of
# whom 640 test negative. Published reading: "Test sensitivity is 0.90 (95% CI 0.88
# to 0.92). Test specificity is 0.76 (95% CI 0.73 to 0.79). The likelihood ratio of
# a positive test is 3.75 (95% CI 3.32 to 4.24)."
scott <- list(tp = 670, fp = 202, fn = 74, tn = 640)
call_scott <- function(...) do.call(calc_analyze_dx_single, c(scott, list(...)))

test_that("reproduces the published Scott et al. (2008) / epiR example", {
  r <- call_scott()
  expect_equal(round(c(r$sensitivity, r$sensitivity_lower, r$sensitivity_upper), 2), c(0.90, 0.88, 0.92))
  expect_equal(round(c(r$specificity, r$specificity_lower, r$specificity_upper), 2), c(0.76, 0.73, 0.79))
  expect_equal(round(c(r$lr_positive, r$lr_positive_lower, r$lr_positive_upper), 2), c(3.75, 3.32, 4.24))
})

test_that("single-test estimates and intervals equal epiR::epi.tests() for exact and Wilson intervals", {
  skip_if_not_installed("epiR")
  tables <- list(c(670, 202, 74, 640), c(45, 12, 5, 138), c(18, 3, 2, 77), c(300, 150, 100, 450))
  for (tb in tables) {
    for (method in c("exact", "wilson")) {
      r <- calc_analyze_dx_single(tb[1], tb[2], tb[3], tb[4], ci_method = method)
      e <- suppressMessages(epiR::epi.tests(as.table(matrix(tb, 2, byrow = TRUE)), method = method))$detail
      get <- function(s) as.numeric(e[e$statistic == s, c("est", "lower", "upper")])
      info <- paste(paste(tb, collapse = "/"), method)
      expect_equal(c(r$sensitivity, r$sensitivity_lower, r$sensitivity_upper), get("se"), tolerance = 1e-6, info = info)
      expect_equal(c(r$specificity, r$specificity_lower, r$specificity_upper), get("sp"), tolerance = 1e-6, info = info)
      expect_equal(c(r$ppv, r$ppv_lower, r$ppv_upper), get("pv.pos"), tolerance = 1e-6, info = info)
      expect_equal(c(r$npv, r$npv_lower, r$npv_upper), get("pv.neg"), tolerance = 1e-6, info = info)
      expect_equal(c(r$accuracy, r$accuracy_lower, r$accuracy_upper), get("diag.ac"), tolerance = 1e-6, info = info)
      expect_equal(c(r$lr_positive, r$lr_positive_lower, r$lr_positive_upper), get("lr.pos"), tolerance = 1e-6, info = info)
      expect_equal(c(r$lr_negative, r$lr_negative_lower, r$lr_negative_upper), get("lr.neg"), tolerance = 1e-6, info = info)
    }
  }
})

test_that("Wilson interval matches its closed form and Clopper-Pearson matches binom.test", {
  r <- calc_analyze_dx_single(18, 3, 2, 77, ci_method = "wilson")
  z <- qnorm(0.975); p <- 18 / 20; n <- 20
  expect_equal(r$sensitivity_lower, (p + z^2 / (2 * n) - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n))
  ex <- calc_analyze_dx_single(18, 3, 2, 77)
  expect_equal(c(ex$sensitivity_lower, ex$sensitivity_upper), as.numeric(binom.test(18, 20)$conf.int))
})

test_that("PPV and NPV at a specified prevalence follow Bayes' rule; at the sample prevalence they equal the count-based values", {
  r <- call_scott(prevalence = 0.10)
  se <- 670 / 744; sp <- 640 / 842
  expect_equal(r$ppv, se * 0.1 / (se * 0.1 + (1 - sp) * 0.9))
  expect_equal(r$npv, sp * 0.9 / (sp * 0.9 + (1 - se) * 0.1))
  same <- call_scott(prevalence = 744 / 1586)
  expect_equal(c(same$ppv, same$npv), c(670 / 872, 640 / 714))
  expect_equal(r$predictive_values_from, "specified prevalence")
  expect_equal(call_scott()$predictive_values_from, "counts")
  # lower prevalence -> lower PPV, higher NPV
  expect_lt(r$ppv, call_scott()$ppv); expect_gt(r$npv, call_scott()$npv)
})

test_that("specified-prevalence PPV/NPV interval: logit-scale delta method, checked against a simulation of the sampling distribution", {
  set.seed(11)
  # large samples: the delta method is an asymptotic approximation
  tp <- 900; fn <- 100; tn <- 1600; fp <- 400; prev <- 0.2
  r <- calc_analyze_dx_single(tp, fp, fn, tn, prevalence = prev)
  sim <- replicate(20000, {
    se <- rbinom(1, tp + fn, tp / (tp + fn)) / (tp + fn); sp <- rbinom(1, tn + fp, tn / (tn + fp)) / (tn + fp)
    c(qlogis(.dx_ppv(se, sp, prev)), qlogis(.dx_npv(se, sp, prev)))
  })
  z <- qnorm(0.975)
  fin <- function(x) x[is.finite(x)] # a draw with Se = 1 has logit +Inf
  expect_equal((qlogis(r$ppv_upper) - qlogis(r$ppv_lower)) / (2 * z), sd(fin(sim[1, ])), tolerance = 0.03)
  expect_equal((qlogis(r$npv_upper) - qlogis(r$npv_lower)) / (2 * z), sd(fin(sim[2, ])), tolerance = 0.03)
})

test_that("a zero cell leaves the undefined interval NA rather than inventing one", {
  r <- calc_analyze_dx_single(20, 0, 5, 75)
  expect_true(is.na(r$lr_positive) || is.infinite(r$lr_positive) || is.na(r$lr_positive_lower))
  expect_true(is.na(r$lr_positive_lower))
  expect_equal(r$specificity, 1)
  r0 <- calc_analyze_dx_single(0, 0, 0, 50)
  expect_true(is.na(r0$sensitivity)); expect_true(is.na(r0$sensitivity_lower))
})

test_that("invalid input is refused", {
  expect_error(calc_analyze_dx_single(-1, 2, 3, 4), "non-negative whole number")
  expect_error(calc_analyze_dx_single(1.5, 2, 3, 4), "whole number")
  expect_error(calc_analyze_dx_single(0, 0, 0, 0), "empty")
  expect_error(calc_analyze_dx_single(5, 5, 5, 5, prevalence = 1.5))
  expect_error(calc_analyze_dx_single(5, 5, 5, 5, conf_level = 0))
})

# --- combined testing --------------------------------------------------------

# Independent oracle: enumerate every pattern of test results, weight by the
# product of the per-test probabilities (conditional independence), and sum the
# patterns for which the decision rule says "positive".
enumerate_combined <- function(se, sp, rule) {
  k <- length(se)
  patterns <- as.matrix(expand.grid(rep(list(c(FALSE, TRUE)), k)))
  prob_pattern <- function(prob_pos) apply(patterns, 1, function(p) prod(ifelse(p, prob_pos, 1 - prob_pos)))
  positive <- if (rule == "parallel") rowSums(patterns) >= 1 else rowSums(patterns) == k
  c(se = sum(prob_pattern(se)[positive]), sp = sum(prob_pattern(1 - sp)[!positive]))
}

test_that("parallel and serial Se/Sp equal exhaustive enumeration of result patterns, for 2 to 6 tests", {
  set.seed(5)
  for (k in 2:6) {
    se <- runif(k, 0.5, 0.99); sp <- runif(k, 0.5, 0.99)
    r <- calc_analyze_dx_combined(se, sp, prevalence = 0.15)
    for (rule in c("parallel", "serial")) {
      o <- enumerate_combined(se, sp, rule)
      expect_equal(r[[paste0(rule, "_sensitivity")]], unname(o["se"]), info = paste(k, rule))
      expect_equal(r[[paste0(rule, "_specificity")]], unname(o["sp"]), info = paste(k, rule))
    }
  }
})

test_that("the three-test hand example: parallel raises sensitivity and lowers specificity, serial the reverse", {
  r <- calc_analyze_dx_combined(c(0.9, 0.8, 0.85), c(0.7, 0.9, 0.8), prevalence = 0.1)
  expect_equal(r$parallel_sensitivity, 1 - 0.1 * 0.2 * 0.15)
  expect_equal(r$parallel_specificity, 0.7 * 0.9 * 0.8)
  expect_equal(r$serial_sensitivity, 0.9 * 0.8 * 0.85)
  expect_equal(r$serial_specificity, 1 - 0.3 * 0.1 * 0.2)
  expect_gt(r$parallel_sensitivity, max(0.9, 0.8, 0.85)); expect_lt(r$parallel_specificity, min(0.7, 0.9, 0.8))
  expect_lt(r$serial_sensitivity, min(0.9, 0.8, 0.85));  expect_gt(r$serial_specificity, max(0.7, 0.9, 0.8))
})

test_that("combined PPV/NPV are Bayes' rule on the combined Se/Sp at the stated prevalence", {
  r <- calc_analyze_dx_combined(c(0.9, 0.8, 0.85), c(0.7, 0.9, 0.8), prevalence = 0.1)
  for (rule in c("parallel", "serial")) {
    se <- r[[paste0(rule, "_sensitivity")]]; sp <- r[[paste0(rule, "_specificity")]]
    expect_equal(r[[paste0(rule, "_ppv")]], se * 0.1 / (se * 0.1 + (1 - sp) * 0.9))
    expect_equal(r[[paste0(rule, "_npv")]], sp * 0.9 / (sp * 0.9 + (1 - se) * 0.1))
  }
  expect_gt(r$serial_ppv, r$parallel_ppv); expect_gt(r$parallel_npv, r$serial_npv)
})

test_that("with sample sizes the combined estimates get intervals; without them they do not", {
  none <- calc_analyze_dx_combined(c(0.9, 0.8, 0.85), c(0.7, 0.9, 0.8), 0.1)
  expect_true(is.na(none$parallel_ppv_lower) && is.na(none$serial_sensitivity_lower))
  withn <- calc_analyze_dx_combined(c(0.9, 0.8, 0.85), c(0.7, 0.9, 0.8), 0.1, c(100, 200, 150), c(300, 250, 200))
  for (f in c("sensitivity", "specificity", "ppv", "npv")) {
    for (rule in c("parallel", "serial")) {
      lo <- withn[[paste0(rule, "_", f, "_lower")]]; hi <- withn[[paste0(rule, "_", f, "_upper")]]
      est <- withn[[paste0(rule, "_", f)]]
      expect_true(lo < est && est < hi, info = paste(rule, f))
    }
  }
})

test_that("a one-test strategy gives the same PPV/NPV interval as the single-test function at that prevalence", {
  s <- calc_analyze_dx_single(90, 40, 10, 160, prevalence = 0.2)
  se <- 0.9; sp <- 0.8
  st <- .dx_strategy(se, sp, 100, 200, 0.2, "parallel", qnorm(0.975))
  expect_equal(c(st$ppv, st$ppv_lower, st$ppv_upper), c(s$ppv, s$ppv_lower, s$ppv_upper))
  expect_equal(c(st$npv, st$npv_lower, st$npv_upper), c(s$npv, s$npv_lower, s$npv_upper))
})

test_that("variance of the combined Se and Sp (probability scale) equals the simulated variance, even in small samples", {
  set.seed(33)
  se <- c(0.9, 0.8, 0.85); sp <- c(0.7, 0.9, 0.8); n_d <- c(100, 200, 150); n_n <- c(300, 250, 200)
  for (rule in c("parallel", "serial")) {
    delta <- .dx_combine_var(se, sp, se * (1 - se) / n_d, sp * (1 - sp) / n_n, rule)
    sim <- replicate(40000, .dx_combine(rbinom(3, n_d, se) / n_d, rbinom(3, n_n, sp) / n_n, rule))
    # the delta method is first-order in the (small) per-test variances; products of independent
    # estimates have a second-order remainder, so allow 2% on the variance
    expect_equal(unname(delta["se"]), var(sim["se", ]), tolerance = 0.03, info = rule)
    expect_equal(unname(delta["sp"]), var(sim["sp", ]), tolerance = 0.03, info = rule)
  }
})

test_that("combined-test intervals: delta-method SE equals the simulated SD of the combined estimates (large samples)", {
  set.seed(21)
  se <- c(0.9, 0.8, 0.85); sp <- c(0.7, 0.9, 0.8); n_d <- c(1000, 2000, 1500); n_n <- c(3000, 2500, 2000)
  r <- calc_analyze_dx_combined(se, sp, 0.1, n_d, n_n)
  z <- qnorm(0.975)
  for (rule in c("parallel", "serial")) {
    sim <- replicate(20000, {
      se_h <- rbinom(3, n_d, se) / n_d; sp_h <- rbinom(3, n_n, sp) / n_n
      cm <- .dx_combine(se_h, sp_h, rule)
      c(qlogis(cm["se"]), qlogis(cm["sp"]), qlogis(.dx_ppv(cm["se"], cm["sp"], 0.1)), qlogis(.dx_npv(cm["se"], cm["sp"], 0.1)))
    })
    for (j in 1:4) {
      f <- c("sensitivity", "specificity", "ppv", "npv")[j]
      width <- (qlogis(r[[paste0(rule, "_", f, "_upper")]]) - qlogis(r[[paste0(rule, "_", f, "_lower")]])) / (2 * z)
      expect_equal(width, sd(sim[j, is.finite(sim[j, ])]), tolerance = 0.05, info = paste(rule, f))
    }
  }
})

test_that("invalid combined-test input is refused", {
  expect_error(calc_analyze_dx_combined(0.9, 0.8, 0.1), "between 2 and 6")
  expect_error(calc_analyze_dx_combined(rep(0.9, 7), rep(0.8, 7), 0.1), "between 2 and 6")
  expect_error(calc_analyze_dx_combined(c(0.9, 0.8), c(0.8), 0.1), "same number")
  expect_error(calc_analyze_dx_combined(c(0.9, 1.2), c(0.8, 0.8), 0.1))
  expect_error(calc_analyze_dx_combined(c(0.9, 0.8), c(0.8, 0.8), 0))
  expect_error(calc_analyze_dx_combined(c(0.9, 0.8), c(0.8, 0.8), 0.1, c(10, 0), c(10, 10)), "at least 1")
})

test_that("display tables list every strategy", {
  r <- calc_analyze_dx_combined(c(0.9, 0.8, 0.85), c(0.7, 0.9, 0.8), 0.1)
  tb <- analyze_dx_combined_table(r)
  expect_equal(nrow(tb), 5)  # 3 single + parallel + serial
  expect_match(tb$strategy[4], "Parallel"); expect_match(tb$strategy[5], "Serial")
  expect_equal(nrow(analyze_dx_single_table(call_scott())), 7)
})
