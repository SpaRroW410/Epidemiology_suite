source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_noninferiority.R"))

test_that("calc_noninferiority_means matches Chow/Shao/Wang (2008, p.61-62) exactly", {
  res <- calc_noninferiority_means(mean_new = 0.20, mean_standard = 0.20, sd = 0.10,
                                    margin = 0.05, alpha = 0.05, power = 0.80, ratio = 1)
  expect_equal(res$n_total, 100)
  expect_equal(res$n_new, 50)
  expect_equal(res$n_standard, 50)
})

test_that("calc_noninferiority_means rejects invalid inputs", {
  expect_error(calc_noninferiority_means(mean_new = 1, mean_standard = 1, sd = -1, margin = 0.1), "positive")
  expect_error(calc_noninferiority_means(mean_new = 1, mean_standard = 1, sd = 1, margin = -0.1), "positive")
})

test_that("calc_noninferiority_proportions matches Chow/Shao/Wang (2008, p.90) exactly", {
  res <- calc_noninferiority_proportions(p_new = 0.85, p_standard = 0.65, margin = 0.10,
                                          alpha = 0.05, power = 0.80, ratio = 1)
  expect_equal(res$n_total, 50)
  expect_equal(res$n_new, 25)
  expect_equal(res$n_standard, 25)
})

test_that("calc_noninferiority_proportions: power computed from a fixed n reproduces 0.73", {
  # Chow/Shao/Wang's own follow-on example (n=40, 20/20) -> power = 0.73.
  fit <- epiR::epi.ssninfb(treat = 0.85, control = 0.65, delta = 0.10, n = 40,
                            power = NA, r = 1, nfractional = FALSE, alpha = 0.05)
  expect_equal(round(fit$power, 2), 0.73)
})

test_that("calc_noninferiority_proportions rejects invalid inputs", {
  expect_error(calc_noninferiority_proportions(p_new = 1.5, p_standard = 0.5, margin = 0.1), "between 0 and 1")
  expect_error(calc_noninferiority_proportions(p_new = 0.5, p_standard = 0.5, margin = 0.1, ratio = -1), "positive")
})

test_that("calc_noninferiority_or matches Chow, Shao & Wang (2003) Example 4.6.4", {
  # pt=0.4, pc=0.25 (implied OR=2), margin=0.2 (log-OR scale), k=1,
  # alpha=0.05, power=0.80 -> n=241.512, ceiling -> 242 per group.
  res <- calc_noninferiority_or(pt = 0.4, pc = 0.25, margin = 0.2, k = 1,
                                 alpha = 0.05, power = 0.80)
  expect_equal(res$n_control, 242)
  expect_equal(res$n_test, 242)
  expect_equal(res$n_total, 484)
  expect_equal(res$or, 2)
})

test_that("calc_noninferiority_or rejects invalid inputs", {
  expect_error(calc_noninferiority_or(pt = 0.5, pc = 0.5, margin = 0), "no effect to detect")
  expect_error(calc_noninferiority_or(pt = 1.5, pc = 0.5, margin = 0.1), "between 0 and 1")
  expect_error(calc_noninferiority_or(pt = 0.4, pc = 0.25, margin = 0.2, k = -1), "positive")
})

test_that("calc_noninferiority_hr matches Chow, Shao & Wang (2003) Example 7.3.4", {
  # hr=2 (loghr=log(2)), margin=0.5 (log-HR scale), p1=0.5, d=0.8,
  # alpha=0.05, power=0.80 -> n=828.6314, ceiling -> 829.
  res <- calc_noninferiority_hr(hr = 2, margin = 0.5, p1 = 0.5, d = 0.8,
                                 alpha = 0.05, power = 0.80)
  expect_equal(res$n, 829)
})

test_that("calc_noninferiority_hr rejects invalid inputs", {
  expect_error(calc_noninferiority_hr(hr = 1, margin = 0), "no effect to detect")
  expect_error(calc_noninferiority_hr(hr = -1, margin = 0.5), "positive")
  expect_error(calc_noninferiority_hr(hr = 2, margin = 0.5, p1 = 1.5), "between 0 and 1")
})
