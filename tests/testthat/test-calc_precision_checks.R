# Absolute and relative precision, the hard stops and warnings, and the non-response inflation in the five precision-based
# calculators (calc_precision_checks.R).

test_that("single proportion reproduces Pourhoseingholi et al. 2013, Table 1", {
  # Table 1 (95% confidence), rows = precision d, columns = assumed prevalence P. The table rounds n to the nearest whole number with
  # z = 1.96; the calculator rounds up with the exact quantile, so it gives the table's value or one more.
  P <- c(0.05, 0.2, 0.6)
  D <- c(0.01, 0.04, 0.10)
  table1 <- rbind(c(1825, 6147, 9220), c(114, 384, 576), c(18, 61, 92))
  for (i in seq_along(D)) for (j in seq_along(P)) {
    expect_equal(round(1.96^2 * P[j] * (1 - P[j]) / D[i]^2), table1[i, j])
    if (D[i] >= P[j]) {
      # P = 0.05 with d = 0.1 (the table's 18): the interval 0.05 +/- 0.1 goes below 0, which the calculator refuses
      expect_error(calc_proportion_precision(P[j], D[i]), "reach below 0")
    } else {
      n <- calc_proportion_precision(P[j], D[i])$n
      expect_true((n - table1[i, j]) %in% c(0, 1), info = sprintf("P = %s, d = %s: %s vs %s", P[j], D[i], n, table1[i, j]))
    }
  }
  expect_equal(calc_proportion_precision(0.05, 0.01)$n, 1825)
  expect_equal(calc_proportion_precision(0.6, 0.1)$n, 93)
})

test_that("single proportion matches epiR::epi.sssimpleestb() for relative and absolute precision", {
  skip_if_not_installed("epiR")
  for (p in c(0.05, 0.1, 0.2, 0.3, 0.5, 0.7, 0.85)) {
    for (eps in c(0.05, 0.1, 0.15, 0.2, 0.3)) {
      ref <- epiR::epi.sssimpleestb(N = NA, Py = p, epsilon = eps, error = "relative", se = 1, sp = 1, conf.level = 0.95)
      if (eps * p >= 1 - p) next
      expect_equal(calc_proportion_precision(p, eps, error = "relative")$n, ref, info = sprintf("p %s eps %s", p, eps))
    }
    for (d in c(0.01, 0.02, 0.05, 0.1)) {
      if (d >= min(p, 1 - p)) next
      ref <- epiR::epi.sssimpleestb(N = NA, Py = p, epsilon = d, error = "absolute", se = 1, sp = 1, conf.level = 0.95)
      expect_equal(calc_proportion_precision(p, d)$n, ref, info = sprintf("p %s d %s", p, d))
    }
  }
  # with a finite population: n0 / (1 + (n0 - 1)/N), the correction epiR applied up to 2.0.67 (from 2.0.93 it uses n0 / (1 + n0/N), which
  # gives 869 instead of 870 here), applied to epiR's unrounded n0
  n0 <- epiR::epi.sssimpleestb(N = NA, Py = 0.2, epsilon = 0.1, error = "relative", se = 1, sp = 1, nfractional = TRUE, conf.level = 0.95)
  expect_equal(calc_proportion_precision(0.2, 0.1, N = 2000, error = "relative")$n, ceiling(n0 / (1 + (n0 - 1) / 2000)))
  expect_equal(calc_proportion_precision(0.2, 0.1, N = 2000, error = "relative")$n, 870)
})

test_that("relative precision is the absolute precision epsilon x p", {
  for (p in c(0.1, 0.3, 0.6)) for (eps in c(0.05, 0.1, 0.2)) {
    rel <- calc_proportion_precision(p, eps, error = "relative")
    abs <- calc_proportion_precision(p, eps * p)
    expect_equal(rel$n, abs$n)
    expect_equal(rel$d_absolute, eps * p)
    expect_equal(rel$epsilon_relative, eps)
    expect_equal(rel$n, ceiling(stats::qnorm(0.975)^2 * (1 - p) / (eps^2 * p)))
  }
})

test_that("hard stops: the interval would pass 0 or 1, or a relative precision of 100% or more", {
  expect_error(calc_proportion_precision(0.03, 0.05), "reach below 0")
  expect_error(calc_proportion_precision(0.05, 0.05), "reach below 0")      # d equal to p
  expect_error(calc_proportion_precision(0.95, 0.05), "reach above 1")      # d equal to 1 - p (floating point)
  expect_error(calc_proportion_precision(0.9, 0.2, error = "relative"), "reach above 1")
  expect_error(calc_proportion_precision(0.3, 1, error = "relative"), "100% or more")
  expect_error(calc_proportion_precision(0.3, 1.5, error = "relative"), "100% or more")
  expect_error(calc_cluster_survey_binary(b = 20, p = 0.04, epsilon = 0.05, error = "absolute", rho = 0.02), "reach below 0")
  expect_error(calc_cluster_survey_binary(b = 20, p = 0.2, epsilon = 1, error = "relative", rho = 0.02), "100% or more")
  expect_error(calc_diagnostic_accuracy(0.95, 0.85, 0.1, prec_sens = 0.05), "1 - sensitivity")
  expect_error(calc_diagnostic_accuracy(0.9, 0.04, 0.1, prec_spec = 0.05), "specificity")
  expect_error(calc_means_single_precision(75, 15, 1, error = "relative"), "100% or more")
  expect_error(calc_rate_precision(2.5, epsilon = 1), "100% or more")
  # just inside the limits
  expect_silent(calc_proportion_precision(0.06, 0.05))
  expect_silent(calc_proportion_precision(0.3, 0.99, error = "relative"))
})

test_that("warnings: relative precision above 20%, small or large proportion with d above a quarter of it", {
  expect_length(calc_proportion_precision(0.5, 0.05)$precision_notes, 0)
  expect_length(calc_proportion_precision(0.3, 0.2, error = "relative")$precision_notes, 0)    # 20% exactly
  expect_match(calc_proportion_precision(0.3, 0.25, error = "relative")$precision_notes, "above 20%")
  expect_match(calc_proportion_precision(0.3, 0.25, error = "relative")$precision_notes, "no published source checked")
  expect_match(calc_proportion_precision(0.05, 0.02)$precision_notes, "one-fourth")
  expect_length(calc_proportion_precision(0.05, 0.0125)$precision_notes, 0)   # exactly p / 4
  expect_length(calc_proportion_precision(0.05, 0.01)$precision_notes, 0)     # the paper's own choice
  expect_match(calc_proportion_precision(0.96, 0.02)$precision_notes, "applied by this app to 1 - p")
  expect_match(calc_means_single_precision(75, 15, 0.3)$precision_notes, "above 20%")
  expect_match(calc_means_single_precision(75, 15, 80, error = "absolute")$precision_notes, "includes 0")
  expect_length(calc_means_single_precision(75, 15, 10, error = "absolute")$precision_notes, 0)
  expect_match(calc_rate_precision(2.5, epsilon = 0.3)$precision_notes, "above 20%")
  expect_match(suppressWarnings(calc_cluster_survey_binary(b = 20, p = 0.2, epsilon = 0.3, rho = 0.02))$precision_notes, "above 20%")
  expect_match(calc_diagnostic_accuracy(0.92, 0.85, 0.3, prec_sens = 0.05)$precision_notes, "1 - sensitivity")
})

test_that("non-response inflation is n / (1 - r), rounded up, in every calculator", {
  check <- function(n, enrolled, r) {
    expect_gte(enrolled * (1 - r), n - 1e-9)
    expect_lt((enrolled - 1) * (1 - r), n)
  }
  for (r in c(0.05, 0.1, 0.2, 1 / 3)) {
    a <- calc_proportion_precision(0.2, 0.1, error = "relative", nonresponse = r)
    check(a$n, a$n_enrolled, r)
    b <- calc_means_single_precision(75, 15, 0.05, nonresponse = r)
    check(b$n, b$n_enrolled, r)
    d <- calc_diagnostic_accuracy(0.9, 0.85, 0.1, nonresponse = r)
    check(d$n, d$n_enrolled, r)
    cl <- calc_cluster_survey_binary(b = 75, p = 0.46, epsilon = 0.1, rho = 0.2, conf_level = 0.9, nonresponse = r)
    check(75, cl$b_enrolled, r)
    expect_equal(cl$n_psu, calc_cluster_survey_binary(b = 75, p = 0.46, epsilon = 0.1, rho = 0.2, conf_level = 0.9)$n_psu)
    expect_equal(cl$n_ssu_enrolled, cl$n_psu * cl$b_enrolled)
    rt <- calc_rate_precision(2.5, 2.243, nonresponse = r)
    expect_equal(rt$person_time_planned * (1 - r), rt$person_time)
  }
  expect_equal(calc_proportion_precision(0.2, 0.1, error = "relative", nonresponse = 0.1)$n_enrolled, 1708)   # 1537 / 0.9
  expect_equal(calc_proportion_precision(0.5, 0.05, nonresponse = 0.2)$n_enrolled, 482)                      # 385 / 0.8 = 481.25
  expect_null(calc_proportion_precision(0.5, 0.05)$n_enrolled)
  expect_error(calc_proportion_precision(0.5, 0.05, nonresponse = 1), "nonresponse")
  expect_error(calc_proportion_precision(0.5, 0.05, nonresponse = -0.1), "nonresponse")
})

test_that("rate and diagnostic relative precision equal the absolute ones they imply", {
  expect_equal(calc_rate_precision(2.5, epsilon = 0.2)$n_events, calc_rate_precision(2.5, conf_width = 1)$n_events)
  expect_equal(calc_rate_precision(2.5, epsilon = 0.2)$n_events, 97)
  expect_error(calc_rate_precision(2.5, conf_width = 1, epsilon = 0.2), "either")
  expect_error(calc_rate_precision(2.5), "either")
  rel <- calc_diagnostic_accuracy(0.9, 0.85, 0.1, prec_sens = 0.05, prec_spec = 0.1, error = "relative")
  abs <- calc_diagnostic_accuracy(0.9, 0.85, 0.1, prec_sens = 0.045, prec_spec = 0.085)
  expect_equal(rel[c("n", "n_sens", "n_spec")], abs[c("n", "n_sens", "n_spec")])
  # the mean: relative epsilon and absolute epsilon x mean agree (epiR's own parameterisation)
  expect_equal(calc_means_single_precision(75, 15, 0.05)$n, calc_means_single_precision(75, 15, 3.75, error = "absolute")$n)
})

test_that("the exports state the precision type and the inflation", {
  res <- calc_proportion_precision(0.2, 0.1, error = "relative", nonresponse = 0.1)
  flat <- ss_result_flatten(res)
  expect_equal(flat$inputs.error, "relative")
  expect_equal(flat$inputs.nonresponse, 0.1)
  expect_equal(flat$n_enrolled, 1708)
  txt <- format_justification("Single proportion", res, "Cochran 1977")
  expect_match(txt, "n_enrolled = 1708")
  expect_match(txt, "error = relative")
  expect_match(txt, "nonresponse = 0.1")
})

test_that("the precision line states both forms", {
  expect_match(precision_equivalents_text(0.5, 0.05, "absolute", 0.95, "proportion"), "relative \\+/- 10% of p")
  expect_match(precision_equivalents_text(0.2, 0.1, "relative", 0.95, "proportion"), "0.18 to 0.22")
  expect_match(precision_equivalents_text(75, 0.2, "relative", 0.95, "mean"), "60 to 90")
  expect_match(precision_equivalents_text(2.5, 1, "absolute", 0.95, "rate"), "20% of the rate")
  expect_null(precision_equivalents_text(NA, 0.05, "absolute", 0.95))
  expect_null(precision_equivalents_text(0.5, NULL, "absolute", 0.95))
  for (k in c("proportion", "mean", "cluster", "rate", "diagnostic")) {
    md <- precision_guidance_md(k)
    expect_match(md, "Pourhoseingholi")
    expect_match(md, "n / \\(1 - r\\)")
  }
})
