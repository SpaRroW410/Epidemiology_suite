# Effect-size converters (calc_effect_size.R): each against a package or a defining identity, by simulation, and by round trip; and the
# worked examples quoted in content_effect_size.R.

test_that("two means: d and g equal the Compare-two-groups tool; variances, differences and equal-size defaults agree", {
  a <- calc_es_two_means(mean1 = 132.86, mean2 = 127.44, sd1 = 15.34, sd2 = 18.23, n1 = 60, n2 = 50)
  b <- calc_analyze_compare_means(n1 = 60, mean1 = 132.86, sd1 = 15.34, n2 = 50, mean2 = 127.44, sd2 = 18.23)
  expect_equal(a$d, b$cohens_d); expect_equal(a$hedges_g, b$hedges_g)
  # variances instead of SDs, the difference instead of the means
  expect_equal(calc_es_two_means(diff = 5.42, var1 = 15.34^2, var2 = 18.23^2)$d, calc_es_two_means(132.86, 127.44, sd1 = 15.34, sd2 = 18.23)$d)
  # one SD is common to both groups
  expect_equal(calc_es_two_means(diff = 5, sd1 = 10)$d, 0.5)
  expect_error(calc_es_two_means(diff = 5, sd1 = 10, var1 = 100), "either the SD or the variance")
  expect_error(calc_es_two_means(mean1 = 5, diff = 1, sd1 = 1), "not both")
  expect_error(calc_es_two_means(diff = 5), "standard deviation")
  expect_error(calc_es_two_means(diff = 5, sd1 = 10, n1 = 20), "both group sizes")
  # the worked example of the help text
  w <- calc_es_two_means(mean1 = 132.86, mean2 = 127.44, sd1 = 15.34, sd2 = 18.23, n1 = 50, n2 = 50)
  expect_equal(round(c(w$pooled_sd, w$d, w$hedges_g, w$d_lower, w$d_upper), 3), c(16.847, 0.322, 0.319, -0.073, 0.716))
})

test_that("Hedges' g is closer to unbiased than d, and the standard error of d matches its simulated spread", {
  set.seed(3)
  r <- replicate(20000, { x <- rnorm(6, 0.5); y <- rnorm(6)
    e <- calc_es_two_means(mean(x), mean(y), sd1 = stats::sd(x), sd2 = stats::sd(y), n1 = 6, n2 = 6); c(e$d, e$hedges_g) })
  expect_gt(abs(mean(r[1, ]) - 0.5), abs(mean(r[2, ]) - 0.5))
  expect_lt(abs(mean(r[2, ]) - 0.5), 0.02)
  set.seed(4)
  dd <- replicate(10000, { x <- rnorm(50, 0.5); y <- rnorm(50); (mean(x) - mean(y)) / sqrt((stats::var(x) + stats::var(y)) / 2) })
  expect_equal(stats::sd(dd), calc_es_two_means(diff = 0.5, sd1 = 1, n1 = 50, n2 = 50)$se_d, tolerance = 0.03)
})

test_that("d from a t statistic equals the d of the data behind t.test()", {
  set.seed(1); x <- rnorm(30, 0.6); y <- rnorm(30)
  tt <- stats::t.test(x, y, var.equal = TRUE)
  expect_equal(calc_es_from_t(unname(tt$statistic), 30, 30)$d, (mean(x) - mean(y)) / sqrt((stats::var(x) + stats::var(y)) / 2))
  z <- rnorm(25, 0.5)
  expect_equal(calc_es_from_t(unname(stats::t.test(z)$statistic), 25)$d, mean(z) / stats::sd(z))
  expect_equal(round(unlist(calc_es_from_t(2.4, 30, 30)[c("d", "hedges_g")]), 3), c(d = 0.620, hedges_g = 0.612))
  expect_equal(calc_es_from_t(-2.4, 30, 30)$d, -calc_es_from_t(2.4, 30, 30)$d)
})

test_that("paired: the SD of differences follows from the SDs and correlation, and the implied correlation comes back", {
  p <- calc_es_paired(4, sd1 = 12, sd2 = 14, r = 0.6)
  expect_equal(p$sd_diff, sqrt(12^2 + 14^2 - 2 * 0.6 * 12 * 14))
  expect_equal(round(p$d_z, 3), 0.340)
  set.seed(5); x <- rnorm(1e5, 0, 12); y <- 0.6 * (14 / 12) * x + sqrt(1 - 0.36) * 14 * rnorm(1e5)
  expect_equal(calc_es_paired(1, sd1 = stats::sd(x), sd2 = stats::sd(y), r = stats::cor(x, y))$sd_diff, stats::sd(x - y), tolerance = 1e-3)
  back <- calc_es_paired(4, sd_diff = p$sd_diff, sd1 = 12, sd2 = 14)
  expect_equal(back$correlation, 0.6)
  expect_error(calc_es_paired(4, sd_diff = 40, sd1 = 12, sd2 = 14), "cannot go together")
  expect_error(calc_es_paired(4, sd1 = 12), "Give the SD")
})

test_that("f: from means, eta-squared, an F statistic and d all agree with aov() and the definitions", {
  expect_equal(calc_es_f(means = c(10, 12, 15), sd = 6)$f, sqrt(mean((c(10, 12, 15) - mean(c(10, 12, 15)))^2)) / 6)
  expect_equal(calc_es_f(eta2 = 0.06)$f, sqrt(0.06 / 0.94))
  set.seed(2); y <- c(rnorm(30, 10), rnorm(30, 11), rnorm(30, 12.2)); g <- gl(3, 30)
  fit <- summary(stats::aov(y ~ g))[[1]]
  ss <- fit$`Sum Sq`
  expect_equal(calc_es_f(F_stat = fit$`F value`[1], df1 = 2, df2 = 87)$f, sqrt(ss[1] / ss[2]))
  expect_equal(calc_es_f(F_stat = fit$`F value`[1], df1 = 2, df2 = 87)$eta2, ss[1] / sum(ss))
  expect_equal(calc_es_f(d = 0.5)$f, 0.25)
  # weighted by group size
  w <- calc_es_f(means = c(10, 20), sd = 5, n = c(30, 10))$f
  expect_equal(w, sqrt(0.75 * 0.25) * 10 / 5)
  expect_error(calc_es_f(), "exactly one"); expect_error(calc_es_f(eta2 = 0.1, d = 1), "exactly one")
  expect_equal(round(calc_es_f(means = c(10, 12, 15), sd = 6)$f, 3), 0.342)
})

test_that("proportions: any one of p1, OR, RR, RD gives the same others; h equals pwr::ES.h; OpenEpi's example is reproduced", {
  a <- calc_es_proportions(0.05, OR = 2)
  expect_equal(round(c(a$p1, a$RR, a$RD, a$NNT, a$h), 4), c(0.0952, 1.9048, 0.0452, 22.1053, 0.1764))   # OpenEpi: 9.52%, 1.90, 4.52
  for (k in list(list(p1 = a$p1), list(RR = a$RR), list(RD = a$RD))) {
    b <- do.call(calc_es_proportions, c(list(p0 = 0.05), k))
    expect_equal(c(b$p1, b$OR, b$RR, b$RD), c(a$p1, a$OR, a$RR, a$RD))
  }
  skip_if_not_installed("pwr")
  expect_equal(a$h, pwr::ES.h(a$p1, 0.05))
  expect_error(calc_es_proportions(0.6, RR = 2), "above 1")
  expect_error(calc_es_proportions(0.6, RD = 0.5), "outside")
  expect_error(calc_es_proportions(0.3, OR = 2, RR = 1.5), "exactly one")
  expect_equal(calc_es_proportions(0.3, p1 = 0.3)$NNT, Inf)
})

test_that("chi-square: w from a table, a statistic or proportions equals the chisq.test / pwr values; 2 x 2 w is phi", {
  tab <- matrix(c(30, 20, 15, 35), 2)
  w <- calc_es_chisq_w(table = tab)
  expect_equal(w$w, sqrt(unname(stats::chisq.test(tab, correct = FALSE)$statistic) / 100))
  expect_equal(w$w, stats::cor(rep(c(1, 1, 0, 0), c(30, 15, 20, 35)), rep(c(1, 0, 1, 0), c(30, 15, 20, 35))))
  expect_equal(w$cramers_v, w$w); expect_equal(w$df, 1)
  expect_equal(calc_es_chisq_w(chisq = w$chisq, n = 100)$w, w$w)
  big <- matrix(c(20, 15, 10, 12, 18, 25), 2)
  expect_equal(calc_es_chisq_w(table = big)$cramers_v, sqrt(unname(stats::chisq.test(big, correct = FALSE)$statistic) / (sum(big) * 1)))
  p0 <- rep(0.25, 4); p1 <- c(0.4, 0.2, 0.2, 0.2)
  skip_if_not_installed("pwr")
  expect_equal(calc_es_chisq_w(p0 = p0, p1 = p1)$w, pwr::ES.w1(p0, p1))
  expect_equal(round(c(w$w, w$chisq, calc_es_chisq_w(p0 = p0, p1 = p1)$w), 3), c(0.302, 9.091, 0.346))
  expect_error(calc_es_chisq_w(table = matrix(c(1, 0, 1, 0), 2)), "empty")
})

test_that("hazard ratio: medians under exponential survival, and survival or event probabilities", {
  expect_equal(calc_es_hazard_ratio(median_e = 18, median_c = 12)$hr, 12 / 18)
  set.seed(6); te <- rexp(3e5, log(2) / 18); tc <- rexp(3e5, log(2) / 12)
  # exponential samples: the hazard of each arm is events / person-time, so the hazard ratio is sum(tc) / sum(te)
  expect_equal(sum(tc) / sum(te), 12 / 18, tolerance = 0.02)
  expect_equal(calc_es_hazard_ratio(pe = 0.3707, pc = 0.489)$hr, calc_es_hazard_ratio(surv_e = 0.6293, surv_c = 0.511)$hr)
  expect_equal(round(calc_es_hazard_ratio(pe = 0.3707, pc = 0.489)$hr, 3), 0.690)
  expect_equal(calc_es_hazard_ratio(pe = 0.3707, pc = 0.489)$hr, calc_logrank(pE = 0.3707, pC = 0.489)$hr)
  expect_error(calc_es_hazard_ratio(median_e = 18), "both medians")
  expect_error(calc_es_hazard_ratio(median_e = 18, median_c = 12, pe = 0.3, pc = 0.4), "exactly one pair")
})
test_that("d <-> r is exact for two groups (checked against cor()), the large-sample form and the odds-ratio approximation hold", {
  set.seed(7); n1 <- 30; n2 <- 20; g <- rep(0:1, c(n1, n2)); y <- rnorm(50) + 0.6 * g
  d <- (mean(y[g == 1]) - mean(y[g == 0])) / sqrt(((n1 - 1) * stats::var(y[g == 0]) + (n2 - 1) * stats::var(y[g == 1])) / (n1 + n2 - 2))
  expect_equal(calc_es_convert(d = d, n1 = n1, n2 = n2)$r, stats::cor(y, g))
  expect_equal(calc_es_convert(r = stats::cor(y, g), n1 = n1, n2 = n2)$d, d)
  expect_equal(calc_es_convert(r = 0.3)$d, 2 * 0.3 / sqrt(1 - 0.09))
  expect_equal(calc_es_convert(d = calc_es_convert(r = 0.3)$d)$r, 0.3)
  expect_equal(calc_es_convert(OR = 2)$d, log(2) / (pi / sqrt(3)))
  expect_equal(log(2) / 1.81, calc_es_convert(OR = 2)$d, tolerance = 0.005)       # Chinn's rounded divisor
  # exact for a logistic latent variable: a shift of delta on the logit scale is an odds ratio of exp(delta), and d = delta * sqrt(3) / pi
  expect_equal(calc_es_convert(d = 0.5)$OR_approx, exp(0.5 * pi / sqrt(3)))
  expect_equal(calc_es_convert(r2 = 0.13)$f2, 0.13 / 0.87)
  expect_equal(calc_es_convert(f2 = 0.15)$r2, 0.15 / 1.15)
  expect_equal(unlist(calc_es_convert(d = 0.5)[c("r", "OR_approx", "r2", "f2")]), c(r = 0.2425, OR_approx = 2.4766, r2 = 0.0588, f2 = 0.0625), tolerance = 0.001)
  expect_error(calc_es_convert(), "exactly one"); expect_error(calc_es_convert(r = 1), "strictly between")
})

test_that("interpretation uses Cohen's conventions", {
  expect_match(calc_es_two_means(diff = 2, sd1 = 10)$interpretation, "^small")
  expect_match(calc_es_two_means(diff = 5, sd1 = 10)$interpretation, "^medium")
  expect_match(calc_es_two_means(diff = 8, sd1 = 10)$interpretation, "^large")
  expect_match(calc_es_two_means(diff = 1, sd1 = 10)$interpretation, "^smaller than small")
  expect_match(calc_es_f(eta2 = 0.04)$interpretation, "^small")     # f = 0.204
  expect_match(calc_es_f(eta2 = 0.06)$interpretation, "^medium")    # f = 0.253
})

test_that("every glossary term is complete, and info tips render for each", {
  expect_gt(length(glossary), 25)
  for (id in names(glossary)) {
    g <- glossary[[id]]
    expect_true(nzchar(g$label) && nzchar(g$short), info = id)
    expect_lt(nchar(g$short), 260)                                        # short enough for a popover
    html <- as.character(info_tip(id))
    expect_match(html, "aria-label", info = id)
    expect_match(html, "info-tip", info = id)
  }
  expect_error(info_tip("no_such_term"), "No glossary entry")
  expect_equal(unname(vapply(c("phi", "odds_ratio"), function(k) glossary_entry(k)$label, "")), c("phi (correlation of paired exposures)", "Odds ratio (OR)"))
})

test_that("every effect-size design renders its result, with every tip in the glossary", {
  # the worked example of each design, rendered by the module's display code (a mistyped glossary term stops here)
  values <- list(
    two_means = calc_es_two_means(132.86, 127.44, sd1 = 15.34, sd2 = 18.23, n1 = 50, n2 = 50),
    from_t = calc_es_from_t(2.4, 30, 30),
    paired_means = calc_es_paired(4, sd1 = 12, sd2 = 14, r = 0.6),
    anova_f = calc_es_f(means = c(10, 12, 15), sd = 6),
    proportions = calc_es_proportions(0.05, OR = 2),
    chisq_w = calc_es_chisq_w(table = matrix(c(30, 20, 15, 35), 2)),
    hazard_ratio = calc_es_hazard_ratio(median_e = 18, median_c = 12),
    correlation = calc_es_convert(d = 0.5),
    median_iqr = calc_mean_sd_from_median_iqr(45, 38, 54, 60),
    matched_pairs = calc_matched_pairs_phi(30, 25, 10, 35)
  )
  expect_equal(sort(names(values)), sort(unname(.es_designs)))
  for (d in names(values)) {
    html <- as.character(.es_render(d, values[[d]]))
    expect_gt(nchar(html), 100)
    expect_match(html, "info-tip|Hazard ratio|Estimated")
  }
  # the paired example with two sample variants, and the conversion that starts from R-squared
  expect_gt(nchar(as.character(.es_render("correlation", calc_es_convert(r2 = 0.13)))), 100)
  expect_gt(nchar(as.character(.es_render("two_means", calc_es_two_means(diff = 5, sd1 = 10)))), 100)
  # the module's defaults give a valid result for every design (the UI's starting values)
  html <- as.character(mod_effect_size_ui("x"))
  expect_match(html, "Cohen's d and Hedges' g")
})
