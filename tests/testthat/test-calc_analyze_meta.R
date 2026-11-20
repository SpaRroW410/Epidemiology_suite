# Analyze: meta-analysis of study results (R/calc_analyze_meta.R; CHECKLIST WB-01). Reference values from metafor 5.2.1
# (rma(method = "FE") and rma(method = "DL")), computed 16 Nov 2026; compared live as well when metafor is installed.

# log risk ratios and their variances of the 13 BCG vaccine trials (metafor's dat.bcg through escalc(measure = "RR"))
bcg_yi <- c(-0.889311, -1.585389, -1.348073, -1.441551, -0.217547, -0.786116, -1.620898, 0.011952, -0.469418, -1.371345, -0.339359,
            0.445913, -0.017314)
bcg_vi <- c(0.325585, 0.194581, 0.415368, 0.02001, 0.05121, 0.006906, 0.223017, 0.003962, 0.056434, 0.073025, 0.012412, 0.532506,
            0.071405)

test_that("fixed-effect and DerSimonian-Laird results equal metafor's on the BCG trials", {
  a <- calc_analyze_meta(exp(bcg_yi), se = sqrt(bcg_vi), measure = "ratio")
  # metafor: FE estimate, se; DL estimate, se, tau2, I2, Q
  ref <- c(-0.430285, 0.040499, -0.714117, 0.178742, 0.30876, 92.117347, 152.233008)
  expect_equal(c(log(a$fixed_estimate), a$fixed_se, log(a$random_estimate), a$random_se, a$tau2, a$I2, a$Q), ref, tolerance = 1e-4)   # yi, vi above are rounded to 6 decimals; the live test below is exact
  expect_equal(a$H2, 12.68608, tolerance = 1e-4)   # the inputs above are rounded to 6 decimals
  expect_equal(log(c(a$random_lower, a$random_upper)), c(-1.064445, -0.3637892), tolerance = 1e-5)
  expect_equal(a$random_p, 6.462924e-05, tolerance = 1e-4)
  expect_equal(a$k, 13)
  expect_equal(a$Q_df, 12)
  s <- attr(a, "studies")
  expect_equal(sum(s$weight_fixed), 100); expect_equal(sum(s$weight_random), 100)
})

test_that("with no heterogeneity the two models agree, and differences are pooled as they are", {
  y <- c(0.10761, 0.24149, 0.35176, 0.06957, 0.33916, 0.30602); s <- c(0.20681, 0.21145, 0.27358, 0.26594, 0.12229, 0.24074)
  a <- calc_analyze_meta(y, se = s, measure = "difference")
  expect_equal(c(a$fixed_estimate, a$fixed_se, a$random_estimate, a$random_se, a$tau2, a$I2, a$Q),
               c(0.264091, 0.079715, 0.264091, 0.079715, 0, 0, 1.628793), tolerance = 2e-5)       # metafor
  expect_equal(c(a$random_lower, a$random_upper), c(0.107852, 0.420329), tolerance = 1e-5)
})

test_that("live comparison with metafor on other data", {
  skip_if_not_installed("metafor")
  set.seed(42)
  for (k in c(2, 5, 20)) {
    y <- rnorm(k, 0.2, 0.4); s <- runif(k, 0.05, 0.5)
    a <- calc_analyze_meta(y, se = s, measure = "difference", conf_level = 0.9)
    f <- metafor::rma(y, sei = s, method = "FE", level = 90); r <- metafor::rma(y, sei = s, method = "DL", level = 90)
    expect_equal(c(a$fixed_estimate, a$fixed_lower, a$fixed_upper, a$fixed_p), c(coef(f), f$ci.lb, f$ci.ub, f$pval), ignore_attr = TRUE)
    expect_equal(c(a$random_estimate, a$random_lower, a$random_upper, a$random_p, a$tau2, a$I2, a$H2, a$Q, a$Q_p),
                 c(coef(r), r$ci.lb, r$ci.ub, r$pval, r$tau2, r$I2, r$H2, r$QE, r$QEp), ignore_attr = TRUE)
    expect_equal(attr(a, "studies")$weight_random, as.numeric(stats::weights(r)))
  }
})

test_that("a confidence interval gives back the standard error, on the log scale for ratios", {
  se <- c(0.2, 0.35, 0.15); y <- c(-0.3, 0.1, -0.2); z <- qnorm(0.975)
  from_ci <- calc_analyze_meta(exp(y), lower = exp(y - z * se), upper = exp(y + z * se), measure = "ratio")
  from_se <- calc_analyze_meta(exp(y), se = se, measure = "ratio")
  expect_equal(from_ci[setdiff(names(from_ci), "inputs")], from_se[setdiff(names(from_se), "inputs")])
  z90 <- qnorm(0.95)
  expect_equal(calc_analyze_meta(y, lower = y - z90 * se, upper = y + z90 * se, measure = "difference", ci_level = 0.9)$fixed_se,
               calc_analyze_meta(y, se = se, measure = "difference")$fixed_se)
  # the studies table restates each interval at the pooled confidence level
  expect_equal(attr(from_se, "studies")$lower, exp(y - z * se))
})

test_that("the documented worked examples are what the function returns", {
  a <- calc_analyze_meta(c(0.75, 0.90, 0.62, 1.05), c(0.55, 0.70, 0.40, 0.80), c(1.02, 1.16, 0.96, 1.38), measure = "ratio")
  expect_equal(round(c(a$fixed_estimate, a$fixed_lower, a$fixed_upper), 3), c(0.865, 0.745, 1.004))
  expect_equal(round(c(a$random_estimate, a$random_lower, a$random_upper), 3), c(0.848, 0.695, 1.036))
  expect_equal(round(c(a$Q, a$I2, a$tau2, a$fixed_p, a$random_p), c(2, 1, 4, 3, 2)), c(5.08, 40.9, 0.0168, 0.057, 0.11))
  expect_equal(round(attr(a, "studies")$weight_random, 1), c(24.9, 31.0, 15.5, 28.6))
  b <- calc_analyze_meta(c(-2.1, -0.8, -3.0), se = c(0.9, 0.7, 1.2), measure = "difference")
  expect_equal(round(c(b$fixed_estimate, b$fixed_lower, b$fixed_upper, b$random_estimate, b$random_lower, b$random_upper, b$I2), 2),
               c(-1.59, -2.57, -0.61, -1.71, -2.95, -0.47, 32.78))
})

test_that("the text box is read, and unreadable lines are named", {
  st <- .meta_parse_studies("Study A, 0.75, 0.55, 1.02\n\n 0.90; 0.70; 1.16 \nC\t0.62\t0.40\t0.96")
  expect_equal(st$estimate, c(0.75, 0.90, 0.62)); expect_equal(st$lower, c(0.55, 0.70, 0.40)); expect_equal(st$upper, c(1.02, 1.16, 0.96))
  expect_equal(st$labels, c("Study A", NA, "C"))
  expect_equal(calc_analyze_meta(st$estimate, st$lower, st$upper, labels = st$labels)$k, 3)
  expect_equal(attr(calc_analyze_meta(st$estimate, st$lower, st$upper, labels = st$labels), "studies")$label, c("Study A", "Study 2", "C"))
  st <- .meta_parse_studies("T1, -2.1, 0.9\nT2, -0.8, 0.7")
  expect_equal(st$se, c(0.9, 0.7)); expect_null(st$lower)
  expect_error(.meta_parse_studies("only one, 1, 0.5, 2"), "at least two")
  expect_error(.meta_parse_studies("A, 1, 0.5, 2\nB, x, 0.5, 2"), "Line 2")
  expect_error(.meta_parse_studies("A, 1, 0.5, 2\nB, 1, 0.5"), "same figures")
})

test_that("invalid inputs are rejected", {
  expect_error(calc_analyze_meta(1.2, 0.8, 1.8), "At least two")
  expect_error(calc_analyze_meta(c(1.2, -0.5), c(0.8, 0.2), c(1.8, 0.9)), "greater than 0")
  expect_error(calc_analyze_meta(c(1.2, 0.5), c(0.8, 0.6), c(1.8, 0.9)), "inside its confidence interval")
  expect_error(calc_analyze_meta(c(1.2, 0.5), c(0.8, 0.2), c(0.7, 0.9)), "greater than its lower")
  expect_error(calc_analyze_meta(c(1.2, 0.5)), "confidence interval .* or its standard error")
  expect_error(calc_analyze_meta(c(1.2, 0.5), se = c(0.1, 0)), "standard error greater than 0")
})
