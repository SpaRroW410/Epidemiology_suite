# The alternative ways to give an effect (owner's request of 2 Nov 2026, layouts as in OpenEpi's sample-size forms): each route must give
# exactly the result of the plain one, and the helpers that lay out the inputs must turn them into the same arguments.

test_that("two independent means: both means, the difference, Cohen's d and a variance all give the same sample size", {
  base <- calc_means_2s_indep(mu1 = 12.5, mu2 = 11.5, sd = 2)
  expect_equal(calc_means_2s_indep(diff = 1, sd = 2)$n_per_group, base$n_per_group)
  expect_equal(calc_means_2s_indep(mu1 = 12.5, mu2 = 11.5, variance = 4)$n_per_group, base$n_per_group)
  expect_equal(calc_means_2s_indep(diff = 1, variance = 4)$n_per_group, base$n_per_group)
  expect_equal(calc_means_2s_indep(d = 0.5)$n_per_group, base$n_per_group)
  expect_equal(calc_means_2s_indep(12.5, 11.5, 2, 0.05, 0.8)$n_per_group, base$n_per_group)          # positional calls still work
  expect_error(calc_means_2s_indep(diff = 1), "standard deviation")
  expect_error(calc_means_2s_indep(mu1 = 1, diff = 1, sd = 1), "not both")
  expect_error(calc_means_2s_indep(d = 0.5, sd = 1), "not both")
  expect_error(calc_means_2s_indep(diff = 0, sd = 1), "must not be 0")
  expect_error(calc_means_2s_indep(1, 1, 1), "must differ")
  expect_error(calc_means_2s_indep(diff = 1, sd = 1, variance = 1), "either the SD or the variance")
})

test_that("unequal group sizes: the same alternatives", {
  base <- calc_means_2s_unequal_n(mu1 = 10, mu2 = 9.4, sd = 1, n1 = 90)
  expect_equal(calc_means_2s_unequal_n(diff = 0.6, variance = 1, n1 = 90)$n2, base$n2)
  expect_equal(calc_means_2s_unequal_n(d = 0.6, n1 = 90)$n2, base$n2)
  expect_equal(calc_means_2s_unequal_n(10, 9.4, 1, 90)$n2, base$n2)
})

test_that("Welch / OpenEpi form: difference and variances, the ratio, and the form's own example inputs", {
  base <- calc_means_welch(mu1 = 0, mu2 = 0.5, sd1 = 1, sd2 = 2)
  expect_equal(base$n1, 157)                                                  # the verified example of the Welch design
  expect_equal(calc_means_welch(diff = -0.5, var1 = 1, var2 = 4)$n1, base$n1)
  expect_equal(calc_means_welch(mu1 = 0, mu2 = 0.5, var1 = 1, sd2 = 2)$n1, base$n1)
  # the formula itself: n1 = (z(1-alpha/2) + z(power))^2 (sd1^2 + sd2^2 / ratio) / diff^2, n2 = ratio n1
  z <- qnorm(0.975) + qnorm(0.8)
  w <- calc_means_welch(mu1 = 132.86, mu2 = 127.44, sd1 = 15.34, sd2 = 18.23, ratio = 1)
  expect_equal(w$n1, ceiling(z^2 * (15.34^2 + 18.23^2) / 5.42^2)); expect_equal(w$n1, 152)
  r2 <- calc_means_welch(diff = 5.42, var1 = 15.34^2, var2 = 18.23^2, ratio = 2)
  expect_equal(r2$n1, ceiling(z^2 * (15.34^2 + 18.23^2 / 2) / 5.42^2)); expect_equal(r2$n2, ceiling(2 * r2$n1))
  expect_equal(w$delta, 5.42)
  expect_error(calc_means_welch(diff = 1, sd1 = 1), "group 2")
})

test_that("paired means: the SD of the differences, or the two SDs and their correlation", {
  a <- calc_means_paired(mean_diff = 4, sd1 = 12, sd2 = 14, r = 0.6)
  b <- calc_means_paired(mean_diff = 4, sd_diff = sqrt(12^2 + 14^2 - 2 * 0.6 * 12 * 14))
  expect_equal(a$n, b$n); expect_equal(a$sd_diff, b$sd_diff)
  expect_equal(calc_means_paired(2, 5)$n, calc_means_paired(2, sd_diff = 5)$n)
  expect_error(calc_means_paired(4, sd1 = 12), "Give the SD")
  expect_error(calc_means_paired(4, sd_diff = 5, sd1 = 1, sd2 = 1, r = 0), "not both")
})

test_that("cohort and two proportions: any one of p1, OR, RR, RD gives the same size; the others are returned", {
  a <- calc_cohort(0.05, OR = 2, power = 0.8)
  for (k in list(list(p1 = a$p1), list(RR = a$rr), list(RD = a$risk_difference))) {
    b <- do.call(calc_cohort, c(list(p0 = 0.05, power = 0.8), k))
    expect_equal(b$n_total, a$n_total)
  }
  expect_equal(round(c(a$p1, a$rr, a$risk_difference), 4), c(0.0952, 1.9048, 0.0452))     # the cohort form's own example: 9.52%, 1.90, 4.52
  expect_equal(calc_cohort(0.15, 0.30)$n_total, calc_cohort(p0 = 0.15, p1 = 0.30)$n_total)
  expect_error(calc_cohort(0.05), "exactly one"); expect_error(calc_cohort(0.05, 0.1, OR = 2), "exactly one")
  # group 2 is the reference in the two-proportion design
  x <- calc_proportion_2s(p2 = 0.25, OR = 0.3)
  expect_equal(x$p1, 0.3 * (0.25 / 0.75) / (1 + 0.3 * (0.25 / 0.75)))
  expect_equal(calc_proportion_2s(p1 = x$p1, p2 = 0.25)$n_per_group, x$n_per_group)
  expect_equal(calc_proportion_2s(0.1, 0.3)$n_per_group, calc_proportion_2s(p1 = 0.1, p2 = 0.3)$n_per_group)
})

test_that("design effect in the prevalence calculator: multiplies the size after the finite population correction", {
  base <- calc_proportion_precision(0.5, 0.05)
  expect_equal(base$n, 385); expect_null(base$deff)
  expect_equal(calc_proportion_precision(0.5, 0.05, deff = 2)$n, 769)                  # 384.16 x 2 = 768.3
  # with a population size: the closed form of an OpenEpi-style layout, n = DEFF N p q / ((d^2 / z^2)(N - 1) + p q)
  z <- qnorm(0.975)
  f <- function(N, p, d, deff) deff * N * p * (1 - p) / ((d^2 / z^2) * (N - 1) + p * (1 - p))
  for (case in list(c(1000, 0.5, 0.05, 1.5), c(20000, 0.2, 0.03, 2), c(5000, 0.1, 0.02, 1))) {
    r <- calc_proportion_precision(case[2], case[3], N = case[1], deff = case[4])
    expect_equal(r$n, ceiling(round(f(case[1], case[2], case[3], case[4]), 8)), info = paste(case, collapse = " "))
  }
  r <- calc_proportion_precision(0.5, 0.05, N = 1000, deff = 1.5)
  expect_equal(c(r$n, r$n_simple_random), c(417, 278))
  # the non-response inflation is applied after the design effect
  expect_equal(calc_proportion_precision(0.5, 0.05, deff = 2, nonresponse = 0.1)$n_enrolled, ceiling(769 / 0.9))
  expect_error(calc_proportion_precision(0.5, 0.05, deff = 0), "deff"); expect_error(calc_proportion_precision(0.5, 0.05, deff = -1), "deff")
})

test_that("log-rank, case-control: the hazard ratio from medians and p1 stay consistent with the converters", {
  expect_equal(calc_es_hazard_ratio(median_e = 18, median_c = 12)$hr, calc_logrank(pE = 0.3707, pC = 0.489, hr = 12 / 18)$hr)
})

test_that("the input helpers build the same arguments as a direct call", {
  # Cohen's f
  expect_equal(effect_f_value(list(f_kw_as = "f", f_kw = 0.3), "f_kw"), 0.3)
  expect_equal(effect_f_value(list(f_kw = 0.3), "f_kw"), 0.3)                              # before the radio is bound
  expect_equal(effect_f_value(list(f_kw_as = "means", f_kw_means = "10, 12, 15", f_kw_sd = 6), "f_kw"), calc_es_f(means = c(10, 12, 15), sd = 6)$f)
  expect_equal(effect_f_value(list(f_kw_as = "eta2", f_kw_eta2 = 0.06), "f_kw"), calc_es_f(eta2 = 0.06)$f)
  expect_error(effect_f_value(list(f_kw_as = "means", f_kw_means = "10, x", f_kw_sd = 6), "f_kw"), "numbers")
  # Cohen's d
  expect_equal(effect_d_value(list(d_x_as = "d", d_x = 0.5), "d_x"), 0.5)
  expect_equal(effect_d_value(list(d_x_as = "sd", d_x_diff = 5, d_x_sd = 10), "d_x"), 0.5)
  expect_equal(effect_d_value(list(d_x_as = "var", d_x_diff = 5, d_x_var = 100), "d_x"), 0.5)
  # the other proportion
  expect_equal(prop_given_args(list(cohort_given = "OR", cohort_OR = 2), "cohort", "p1"), list(OR = 2))
  expect_equal(prop_given_args(list(p1 = 0.3), "cohort", "p1"), list(p1 = 0.3))
  expect_equal(prop_given_p1(list(cohort_given = "OR", cohort_OR = 2), "cohort", "p1", 0.05), calc_es_proportions(0.05, OR = 2)$p1)
  expect_null(prop_given_p1(list(cohort_given = "RR", cohort_RR = 30), "cohort", "p1", 0.05))      # impossible: p1 would exceed 1
  # the means: arguments and the plain numbers the power curves need
  inp <- list(effect_as_two = "diff", diff_two = 1, spread_as_two = "var", var_two = 4)
  expect_equal(.means_args(inp, "two"), list(diff = 1, variance = 4))
  expect_equal(.means_resolved(inp, "two"), list(mu1 = 1, mu2 = 0, sd = 2))
  expect_equal(.means_args(list(effect_as_two = "d", d_two = 0.5), "two"), list(d = 0.5))
  expect_equal(.means_resolved(list(effect_as_two = "d", d_two = 0.5), "two")$mu1, 0.5)
  w <- list(effect_as_welch = "means", mu1_welch = 0, mu2_welch = 0.5, spread_as_welch = "var", var1_welch = 1, var2_welch = 4)
  expect_equal(do.call(calc_means_welch, .means_args(w, "welch", TRUE))$n1, 157)
  expect_equal(.means_resolved(w, "welch", TRUE)$sd2, 2)
})

test_that("every glossary term used for an information tip anywhere in the app exists", {
  files <- list.files(test_path("..", "..", "R"), pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0)
  src <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  tip_calls <- regmatches(src, gregexpr("info_tip\\(\"[a-z_0-9]+\"\\)", src))[[1]]
  with_calls <- regmatches(src, gregexpr("with_tip\\(\"[^\"]{1,200}\", \"[a-z_0-9]+\"\\)", src))[[1]]
  used <- unique(c(sub('info_tip\\("([a-z_0-9]+)"\\)', "\\1", tip_calls), sub('.*, "([a-z_0-9]+)"\\)$', "\\1", with_calls)))
  expect_gt(length(used), 15)
  expect_equal(setdiff(used, names(glossary)), character())
})
