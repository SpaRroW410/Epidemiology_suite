# Two-proportion examples: 56/70 vs 48/80 and 9/10 vs 3/10 (the examples used in DescTools::BinomDiffCI()'s
# help page, after Newcombe 1998), 5/56 vs 0/29 (a zero cell) and 6/7 vs 2/7.
prop_cases <- list(c(56, 70, 48, 80), c(9, 10, 3, 10), c(5, 56, 0, 29), c(6, 7, 2, 7), c(30, 200, 18, 220))

test_that("difference intervals (Wald, Wald-cc, Agresti-Caffo, Newcombe, Newcombe-cc, MN, Mee) equal DescTools::BinomDiffCI()", {
  skip_if_not_installed("DescTools")
  map <- c(wald = "wald", waldcc = "wald_cc", ac = "agresti_caffo", score = "newcombe", scorecc = "newcombe_cc",
           mn = "miettinen_nurminen", mee = "mee")
  for (cs in prop_cases) {
    r <- calc_analyze_compare_proportions(cs[1], cs[2], cs[3], cs[4])
    for (m in names(map)) {
      d <- DescTools::BinomDiffCI(cs[1], cs[2], cs[3], cs[4], method = m)
      # DescTools solves the score limits with uniroot()'s default tolerance (~1e-4); ours to 1e-12
      mine <- c(r[[paste0(map[[m]], "_lower")]], r[[paste0(map[[m]], "_upper")]])
      if (m %in% c("mn", "mee")) {
        expect_lt(max(abs(mine - as.numeric(d[1, 2:3]))), 5e-4)    # absolute: the limits can be near 0
      } else {
        expect_equal(mine, as.numeric(d[1, 2:3]), tolerance = 1e-8, info = paste(paste(cs, collapse = "/"), m))
      }
    }
  }
})

test_that("ratio intervals (Katz log, adjusted log, Koopman score) equal DescTools::BinomRatioCI()", {
  skip_if_not_installed("DescTools")
  map <- c(katz.log = "ratio_katz", adj.log = "ratio_adjusted_log", koopman = "ratio_koopman")
  for (cs in prop_cases[c(1, 2, 4, 5)]) {
    r <- calc_analyze_compare_proportions(cs[1], cs[2], cs[3], cs[4])
    for (m in names(map)) {
      d <- DescTools::BinomRatioCI(cs[1], cs[2], cs[3], cs[4], method = m)
      mine <- c(r[[paste0(map[[m]], "_lower")]], r[[paste0(map[[m]], "_upper")]])
      if (m == "koopman") expect_lt(max(abs(mine / as.numeric(d[1, 2:3]) - 1)), 5e-4)
      else expect_equal(mine, as.numeric(d[1, 2:3]), tolerance = 1e-8, info = paste(paste(cs, collapse = "/"), m))
    }
  }
})

test_that("odds ratio: Woolf is the textbook formula; the conditional exact interval and p-value equal fisher.test()", {
  r <- calc_analyze_compare_proportions(56, 70, 48, 80)
  tbl <- matrix(c(56, 14, 48, 32), 2, byrow = TRUE); z <- qnorm(0.975)
  expect_equal(r$odds_ratio, (56 * 32) / (14 * 48))
  expect_equal(c(r$odds_ratio_woolf_lower, r$odds_ratio_woolf_upper), exp(log(r$odds_ratio) + c(-1, 1) * z * sqrt(sum(1 / tbl))))
  ft <- fisher.test(tbl)
  expect_equal(c(r$odds_ratio_conditional, r$odds_ratio_exact_lower, r$odds_ratio_exact_upper), c(unname(ft$estimate), ft$conf.int))
  expect_equal(r$fisher_p, ft$p.value)
  expect_equal(r$chisq_p, suppressWarnings(chisq.test(tbl, correct = FALSE))$p.value, tolerance = 1e-10)
})

test_that("a score limit satisfies its defining equation (the score statistic equals z at the limit)", {
  x1 <- 9; n1 <- 10; x2 <- 3; n2 <- 10; z <- qnorm(0.975); n <- 20
  r <- calc_analyze_compare_proportions(x1, n1, x2, n2)
  for (delta in c(r$miettinen_nurminen_lower, r$miettinen_nurminen_upper)) {
    p <- .cmp_mle_diff(0.9, n1, 0.3, n2, delta)
    v <- p[1] * (1 - p[1]) / n1 + p[2] * (1 - p[2]) / n2
    expect_equal((0.6 - delta)^2 / (v * n / (n - 1)), z^2, tolerance = 1e-6)
    expect_equal(p[1] - p[2], delta, tolerance = 1e-10)
  }
})

test_that("coverage: Miettinen-Nurminen, Newcombe and Agresti-Caffo are close to nominal; Wald undercovers for a small sample", {
  set.seed(14)
  n1 <- 25; n2 <- 25; p1 <- 0.7; p2 <- 0.35; truth <- p1 - p2
  reps <- 1000
  x1 <- rbinom(reps, n1, p1); x2 <- rbinom(reps, n2, p2)
  res <- lapply(seq_len(reps), function(i) calc_analyze_compare_proportions(x1[i], n1, x2[i], n2))   # computed once, used for all methods
  hit <- function(key) mean(vapply(res, function(r) r[[paste0(key, "_lower")]] <= truth && truth <= r[[paste0(key, "_upper")]], logical(1)))
  expect_equal(hit("miettinen_nurminen"), 0.95, tolerance = 0.025)
  expect_equal(hit("newcombe"), 0.95, tolerance = 0.03)
  expect_equal(hit("agresti_caffo"), 0.95, tolerance = 0.03)
  expect_lt(hit("wald"), 0.95)
})

test_that("zero events: the ratio and odds-ratio intervals that are undefined are NA, the difference intervals stay inside [-1, 1]", {
  r <- calc_analyze_compare_proportions(5, 56, 0, 29)
  expect_true(is.na(r$risk_ratio) && is.na(r$ratio_katz_lower) && is.na(r$ratio_koopman_lower))
  expect_true(is.na(r$odds_ratio_woolf_lower))
  for (m in c("wald", "wald_cc", "agresti_caffo", "newcombe", "newcombe_cc", "miettinen_nurminen", "mee")) {
    expect_gte(r[[paste0(m, "_lower")]], -1); expect_lte(r[[paste0(m, "_upper")]], 1)
  }
})

test_that("proportion input is validated; display table lists the methods", {
  expect_error(calc_analyze_compare_proportions(-1, 10, 2, 10), "non-negative whole number")
  expect_error(calc_analyze_compare_proportions(1, 0, 2, 10), "positive whole number")
  expect_error(calc_analyze_compare_proportions(11, 10, 2, 10), "cannot exceed")
  expect_error(calc_analyze_compare_proportions(1.5, 10, 2, 10), "whole number")
  expect_error(calc_analyze_compare_proportions(1, 10, 2, 10, conf_level = 1))
  tb <- analyze_compare_proportions_table(calc_analyze_compare_proportions(56, 70, 48, 80))
  expect_equal(nrow(tb), 12); expect_true(all(c("Difference", "Ratio", "Odds ratio") %in% tb$measure)); expect_true(all(nzchar(tb$note)))
})

# ---- means ------------------------------------------------------------------------------------

make_group <- function(n, mean, sd, seed) { set.seed(seed); z <- rnorm(n); mean + sd * (z - base::mean(z)) / stats::sd(z) }

test_that("Welch and pooled t intervals and p-values equal t.test() on data with exactly the given summary statistics", {
  a <- make_group(25, 52, 9, 1); b <- make_group(31, 47, 12, 2)
  r <- calc_analyze_compare_means(25, 52, 9, 31, 47, 12)
  w <- t.test(a, b); s <- t.test(a, b, var.equal = TRUE)
  expect_equal(c(r$welch_lower, r$welch_upper, r$welch_df, r$welch_p), c(w$conf.int, unname(w$parameter), w$p.value), tolerance = 1e-10)
  expect_equal(c(r$pooled_lower, r$pooled_upper, r$pooled_df, r$pooled_p), c(s$conf.int, unname(s$parameter), s$p.value), tolerance = 1e-10)
  expect_equal(r$mean_difference, 5)
})

test_that("variance-ratio interval and p-value equal var.test()", {
  a <- make_group(25, 52, 9, 1); b <- make_group(31, 47, 12, 2)
  r <- calc_analyze_compare_means(25, 52, 9, 31, 47, 12)
  v <- var.test(a, b)
  expect_equal(c(r$variance_ratio, r$variance_ratio_lower, r$variance_ratio_upper, r$variance_ratio_p),
               c(unname(v$estimate), v$conf.int, v$p.value), tolerance = 1e-10)
})

test_that("Cohen's d, Hedges' g and their noncentral-t limits: formulas, defining equations and coverage", {
  r <- calc_analyze_compare_means(25, 52, 9, 31, 47, 12)
  sp <- sqrt((24 * 81 + 30 * 144) / 54)
  expect_equal(r$cohens_d, 5 / sp)
  jfac <- exp(lgamma(27) - lgamma(26.5)) / sqrt(27)
  expect_equal(r$hedges_g, jfac * r$cohens_d)
  expect_lt(jfac, 1); expect_gt(jfac, 0.98)   # the small-sample correction is slightly below 1 (about 1 - 3/(4 df - 1))
  expect_equal(jfac, 1 - 3 / (4 * 54 - 1), tolerance = 1e-3)
  scale <- sqrt(25 * 31 / 56); tstat <- r$cohens_d * scale
  expect_equal(pt(tstat, 54, ncp = r$cohens_d_lower * scale), 0.975, tolerance = 1e-8)
  expect_equal(pt(tstat, 54, ncp = r$cohens_d_upper * scale), 0.025, tolerance = 1e-8)
  # coverage of the interval for the true standardized difference
  set.seed(31)
  delta <- 0.5; n1 <- 20; n2 <- 20
  hit <- replicate(2000, {
    a <- rnorm(n1, delta); b <- rnorm(n2, 0)
    q <- calc_analyze_compare_means(n1, mean(a), sd(a), n2, mean(b), sd(b))
    q$cohens_d_lower <= delta && delta <= q$cohens_d_upper
  })
  expect_equal(mean(hit), 0.95, tolerance = 0.02)
})

test_that("with equal SDs and sample sizes the Welch and pooled intervals coincide; unequal ones differ", {
  eq <- calc_analyze_compare_means(30, 10, 4, 30, 8, 4)
  expect_equal(c(eq$welch_lower, eq$welch_upper), c(eq$pooled_lower, eq$pooled_upper), tolerance = 1e-10)
  ne <- calc_analyze_compare_means(10, 10, 2, 40, 8, 9)
  expect_gt(abs(ne$welch_lower - ne$pooled_lower), 0.1)
  expect_lt(ne$welch_df, ne$pooled_df)
})

test_that("means input is validated", {
  expect_error(calc_analyze_compare_means(1, 5, 2, 10, 4, 2), "at least 2")
  expect_error(calc_analyze_compare_means(10, 5, 0, 10, 4, 2), "positive")
  expect_error(calc_analyze_compare_means(10, NA, 2, 10, 4, 2), "single number")
  expect_error(calc_analyze_compare_means(10, 5, 2, 10, 4, 2, conf_level = 0))
  expect_s3_class(calc_analyze_compare_means(10, 5, 2, 10, 4, 2), "ss_result")
})
