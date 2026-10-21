test_that("Wilson, Clopper-Pearson, Agresti-Coull and Jeffreys intervals equal epiR::epi.conf()", {
  skip_if_not_installed("epiR")
  # epiR does not cut Agresti-Coull to [0, 1] (it can give -0.004 or 1.004), so its limits are clamped for
  # the comparison; x = 0 and x = n, where epiR also lacks the Jeffreys end-point convention, are tested below
  cases <- list(c(7, 20), c(1, 10), c(9, 10), c(45, 120), c(300, 1000), c(2, 3))
  for (cs in cases) {
    r <- calc_analyze_ci_proportion(cs[1], cs[2])
    for (m in c("exact", "wilson", "agresti", "jeffreys")) {
      e <- suppressMessages(epiR::epi.conf(as.matrix(cbind(cs[1], cs[2])), ctype = "prevalence", method = m,
                                           N = 1e9, design = 1, conf.level = 0.95))
      key <- c(exact = "exact", wilson = "wilson", agresti = "agresti_coull", jeffreys = "jeffreys")[[m]]
      expect_equal(c(r[[paste0(key, "_lower")]], r[[paste0(key, "_upper")]]),
                   pmin(1, pmax(0, as.numeric(e[1, c("lower", "upper")]))), tolerance = 1e-6, info = paste(cs, collapse = "/", m))
    }
  }
})

test_that("at x = 0 and x = n every interval stays inside [0, 1] and Jeffreys uses the end-point convention", {
  for (cs in list(c(0, 25), c(25, 25), c(1, 10), c(9, 10))) {
    r <- calc_analyze_ci_proportion(cs[1], cs[2])
    for (m in c("wald", "wilson", "exact", "agresti_coull", "jeffreys", "mid_p")) {
      expect_gte(r[[paste0(m, "_lower")]], 0); expect_lte(r[[paste0(m, "_upper")]], 1)
    }
  }
  expect_equal(calc_analyze_ci_proportion(0, 25)$jeffreys_lower, 0)
  expect_equal(calc_analyze_ci_proportion(25, 25)$jeffreys_upper, 1)
  expect_equal(calc_analyze_ci_proportion(0, 25)$exact_lower, 0)
  expect_equal(calc_analyze_ci_proportion(0, 25)$exact_upper, 1 - 0.025^(1 / 25))   # closed form at x = 0
})

test_that("Wald interval is the textbook formula, cut to [0, 1]", {
  r <- calc_analyze_ci_proportion(7, 20); z <- qnorm(0.975)
  expect_equal(c(r$wald_lower, r$wald_upper), 0.35 + c(-1, 1) * z * sqrt(0.35 * 0.65 / 20))
  edge <- calc_analyze_ci_proportion(0, 25)
  expect_equal(c(edge$wald_lower, edge$wald_upper), c(0, 0))   # the known zero-width failure of the Wald interval
  expect_gte(calc_analyze_ci_proportion(24, 25)$wald_lower, 0); expect_lte(calc_analyze_ci_proportion(24, 25)$wald_upper, 1)
})

test_that("Clopper-Pearson matches binom.test; Wilson matches its closed form", {
  r <- calc_analyze_ci_proportion(18, 20)
  expect_equal(c(r$exact_lower, r$exact_upper), as.numeric(binom.test(18, 20)$conf.int))
  z <- qnorm(0.975); p <- 0.9; n <- 20
  expect_equal(r$wilson_upper, (p + z^2 / (2 * n) + z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n))
})

test_that("mid-P limits satisfy their defining equation (half the point probability in each tail)", {
  for (cs in list(c(7, 20), c(1, 10), c(45, 120), c(5, 6))) {
    x <- cs[1]; n <- cs[2]; r <- calc_analyze_ci_proportion(x, n); a <- 0.05
    expect_equal(pbinom(x, n, r$mid_p_lower, lower.tail = FALSE) + 0.5 * dbinom(x, n, r$mid_p_lower), a / 2, tolerance = 1e-8)
    expect_equal(pbinom(x - 1, n, r$mid_p_upper) + 0.5 * dbinom(x, n, r$mid_p_upper), a / 2, tolerance = 1e-8)
  }
  z <- calc_analyze_ci_proportion(0, 15); full <- calc_analyze_ci_proportion(15, 15)
  expect_equal(z$mid_p_lower, 0); expect_equal(full$mid_p_upper, 1)
  expect_gt(z$mid_p_upper, 0)
})

test_that("the exact interval is the widest and contains the mid-P interval, which is narrower (known ordering)", {
  r <- calc_analyze_ci_proportion(7, 20)
  expect_lt(r$exact_lower, r$mid_p_lower); expect_gt(r$exact_upper, r$mid_p_upper)
})

test_that("intervals contain the estimate (except Wald/Agresti at the boundary) and widen with confidence level", {
  r95 <- calc_analyze_ci_proportion(30, 100); r99 <- calc_analyze_ci_proportion(30, 100, conf_level = 0.99)
  for (m in c("wald", "wilson", "exact", "agresti_coull", "jeffreys", "mid_p")) {
    expect_true(r95[[paste0(m, "_lower")]] < 0.3 && 0.3 < r95[[paste0(m, "_upper")]], info = m)
    expect_gt(r99[[paste0(m, "_upper")]] - r99[[paste0(m, "_lower")]], r95[[paste0(m, "_upper")]] - r95[[paste0(m, "_lower")]])
  }
})

test_that("coverage of the exact interval is at least nominal and Wilson's is close to nominal (simulation)", {
  set.seed(3)
  n <- 40; p <- 0.2; xs <- rbinom(4000, n, p)
  cover <- function(m) mean(vapply(xs, function(x) {
    r <- calc_analyze_ci_proportion(x, n); r[[paste0(m, "_lower")]] <= p && p <= r[[paste0(m, "_upper")]]
  }, logical(1)))
  expect_gte(cover("exact"), 0.95 - 0.012)
  expect_equal(cover("wilson"), 0.95, tolerance = 0.03)
})

test_that("proportion input is validated", {
  expect_error(calc_analyze_ci_proportion(5, 0), "positive whole number")
  expect_error(calc_analyze_ci_proportion(-1, 10), "non-negative whole number")
  expect_error(calc_analyze_ci_proportion(11, 10), "cannot exceed")
  expect_error(calc_analyze_ci_proportion(2.5, 10), "whole number")
  expect_error(calc_analyze_ci_proportion(5, 10, conf_level = 1))
})

test_that("mean interval equals t.test on data with exactly that mean and SD", {
  set.seed(8); z <- rnorm(30); z <- (z - mean(z)) / sd(z)      # exactly mean 0, sd 1
  x <- 10 + 2 * z                                              # exactly mean 10, sd 2
  tt <- t.test(x)$conf.int
  r <- calc_analyze_ci_mean(30, 10, 2)
  expect_equal(c(r$mean_lower, r$mean_upper), as.numeric(tt), tolerance = 1e-10)
  expect_equal(r$standard_error, 2 / sqrt(30))
  expect_equal(r$t_quantile, qt(0.975, 29))
  expect_lt(r$mean_z_upper - r$mean_z_lower, r$mean_upper - r$mean_lower)  # normal quantile < t quantile
})

test_that("SD interval has nominal coverage for normal data (simulation) and contains the estimate", {
  set.seed(4)
  n <- 25; sigma <- 3; reps <- 6000
  hit <- replicate(reps, {
    s <- sd(rnorm(n, 0, sigma)); r <- calc_analyze_ci_mean(n, 0, s)
    r$sd_lower <= sigma && sigma <= r$sd_upper
  })
  expect_equal(mean(hit), 0.95, tolerance = 0.015)
  r <- calc_analyze_ci_mean(25, 5, 3); expect_true(r$sd_lower < 3 && 3 < r$sd_upper)
})

test_that("mean input is validated", {
  expect_error(calc_analyze_ci_mean(1, 5, 2), "at least 2")
  expect_error(calc_analyze_ci_mean(10, 5, 0), "positive")
  expect_error(calc_analyze_ci_mean(10, NA, 2), "single number")
  expect_error(calc_analyze_ci_mean(10, 5, 2, conf_level = 0))
})

test_that("the display table lists the six methods", {
  tb <- analyze_ci_proportion_table(calc_analyze_ci_proportion(7, 20))
  expect_equal(nrow(tb), 6); expect_match(tb$method[1], "Wilson"); expect_match(tb$method[6], "Wald")
})
