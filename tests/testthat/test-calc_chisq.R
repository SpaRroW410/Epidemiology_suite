source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_chisq.R"))

test_that("calc_chisq_gof matches Cohen (1988) Exercise 7.1, p. 249", {
  # 4 equally-likely null categories (P0 = 0.25 each), anticipating
  # P1 = (0.375, 0.2083, 0.2083, 0.2083) -> w ~ 0.289, and solving for N at
  # alpha = 0.05, power = 0.80 gives N = 131.
  P0 <- rep(0.25, 4)
  P1 <- c(0.375, rep((1 - 0.375) / 3, 3))
  res <- calc_chisq_gof(P0, P1, alpha = 0.05, power = 0.80)
  expect_equal(round(res$w, 3), 0.289)
  expect_equal(res$df, 3)
  expect_equal(res$N, 131)
})

test_that("calc_chisq_gof rejects invalid inputs", {
  expect_error(calc_chisq_gof(c(0.5, 0.4), c(0.3, 0.7)), "sum to 1")
  expect_error(calc_chisq_gof(c(0.5, 0.5), c(0.5, 0.5)), "must differ")
  expect_error(calc_chisq_gof(c(0.5, 0.5, 0.5), c(0.3, 0.3, 0.4)), "sum to 1")
})

test_that("calc_chisq_independence matches pwr::ES.w2()'s own documented 2x2 example", {
  # Joint proportions P = rbind(c(.15,.35), c(.10,.40)) -> w ~ 0.1155, and
  # solving for N at alpha = 0.05, power = 0.80 gives N = 589.
  P <- rbind(c(0.15, 0.35), c(0.10, 0.40))
  res <- calc_chisq_independence(P, alpha = 0.05, power = 0.80)
  expect_equal(round(res$w, 4), 0.1155)
  expect_equal(res$df, 1)
  expect_equal(res$N, 589)
})

test_that("calc_chisq_independence rejects invalid inputs", {
  expect_error(calc_chisq_independence(matrix(c(0.5, 0.5), nrow = 1)), "at least 2 rows")
  expect_error(calc_chisq_independence(rbind(c(0.5, 0.4), c(0.05, 0.1))), "sum to 1")
  # A table exactly consistent with independence (rows/cols proportional) has w = 0.
  expect_error(calc_chisq_independence(rbind(c(0.25, 0.25), c(0.25, 0.25))), "must not imply independence")
})

test_that("calc_mcnemar matches Chow, Shao & Wang (2003) Example 6.4.3", {
  # p10 = 0.5, p01 = 0.2 (psai = 0.4, paid = 0.7), alpha = 0.05, power = 0.80
  # -> n = 58.63, ceiling -> 59 pairs.
  res <- calc_mcnemar(p10 = 0.5, p01 = 0.2, alpha = 0.05, power = 0.80)
  expect_equal(res$n, 59)
})

test_that("calc_mcnemar rejects invalid inputs", {
  expect_error(calc_mcnemar(p10 = 0.3, p01 = 0.3), "must differ")
  expect_error(calc_mcnemar(p10 = 0.6, p01 = 0.5), "must be less than 1")
  expect_error(calc_mcnemar(p10 = 0, p01 = 0.2), "between 0 and 1")
  expect_error(calc_mcnemar(p10 = 0.5, p01 = 0.2, alpha = 0), "between 0 and 1")
})

test_that("calc_mantelhaenszel matches Chow, Shao & Wang (2003) Example 15.2.3", {
  # J=5 strata: a=(0.15,0.15,0.20,0.25,0.25), b=(0.4,0.4,0.5,0.6,0.6),
  # p1=(0.5,0.6,0.7,0.8,0.9), phi=2, alpha=0.05, power=0.80 -> stratified
  # (Mantel-Haenszel) n=447, naive pooled n=1151 (the textbook's own two
  # worked answers).
  a <- c(0.15, 0.15, 0.20, 0.25, 0.25)
  b <- c(0.4, 0.4, 0.5, 0.6, 0.6)
  p1 <- c(0.5, 0.6, 0.7, 0.8, 0.9)
  res <- calc_mantelhaenszel(alpha = 0.05, power = 0.80, a = a, b = b, p1 = p1, phi = 2)
  expect_equal(res$n_stratified, 447)
  expect_equal(res$n_pooled, 1151)
})

test_that("calc_mantelhaenszel: stratified n is smaller than the naive pooled n here", {
  a <- c(0.15, 0.15, 0.20, 0.25, 0.25)
  b <- c(0.4, 0.4, 0.5, 0.6, 0.6)
  p1 <- c(0.5, 0.6, 0.7, 0.8, 0.9)
  res <- calc_mantelhaenszel(alpha = 0.05, power = 0.80, a = a, b = b, p1 = p1, phi = 2)
  expect_lt(res$n_stratified, res$n_pooled)
})

test_that("calc_mantelhaenszel rejects invalid inputs", {
  a <- c(0.5, 0.5); b <- c(0.5, 0.5); p1 <- c(0.5, 0.5)
  expect_error(calc_mantelhaenszel(a = a, b = b, p1 = p1, phi = 1), "must differ from 1")
  expect_error(calc_mantelhaenszel(a = c(0.5, 0.6), b = b, p1 = p1, phi = 2), "sum to 1")
  expect_error(calc_mantelhaenszel(a = a, b = c(0.5, 0.5, 0.5), p1 = p1, phi = 2), "same length")
  expect_error(calc_mantelhaenszel(a = 0.5, b = 0.5, p1 = 0.5, phi = 2), "at least 2 strata")
})

test_that("calc_cochran_armitage_trend matches Chow, Shao & Wang (2003) Example 11.5", {
  # pi=(0.1,0.3,0.5,0.7), di=(1,2,3,4), ni=(10,10,10,10) equal allocation,
  # delta=1, alpha=0.05, power=0.80 -> raw n = 7.468497 for group 1;
  # ceiling'd and scaled by equal ratios -> n=8/group, 32 total, matching
  # the textbook's own worked answer ("~7.5 for one group, total 28-32").
  res <- calc_cochran_armitage_trend(pi = c(0.1, 0.3, 0.5, 0.7), di = c(1, 2, 3, 4),
                                      ni = c(10, 10, 10, 10), delta = 1,
                                      alpha = 0.05, power = 0.80)
  expect_equal(res$n_group1, 8)
  expect_equal(res$n_per_group, c(8, 8, 8, 8))
  expect_equal(res$n_total, 32)
})

test_that("calc_cochran_armitage_trend scales unequal allocation ratios correctly", {
  res <- calc_cochran_armitage_trend(pi = c(0.1, 0.3, 0.5, 0.7), di = c(1, 2, 3, 4),
                                      ni = c(1, 2, 1, 1), delta = 1,
                                      alpha = 0.05, power = 0.80)
  # Group 2's allocation ratio is double group 1's, so its sample size must
  # be at least as large (roughly double, modulo independent ceiling()'ing).
  expect_gt(res$n_per_group[2], res$n_per_group[1])
  expect_equal(res$n_total, sum(res$n_per_group))
})

test_that("calc_cochran_armitage_trend rejects invalid inputs", {
  expect_error(calc_cochran_armitage_trend(pi = c(0.5, 0.5), di = c(1, 2), ni = c(1, 1)),
               "no trend to detect")
  expect_error(calc_cochran_armitage_trend(pi = c(1.5, 0.3), di = c(1, 2), ni = c(1, 1)),
               "between 0 and 1")
  expect_error(calc_cochran_armitage_trend(pi = c(0.1, 0.3), di = c(1), ni = c(1, 1)),
               "same length as pi")
  expect_error(calc_cochran_armitage_trend(pi = c(0.1, 0.3), di = c(1, 2), ni = c(-1, 1)),
               "strictly positive")
  expect_error(calc_cochran_armitage_trend(pi = c(0.1, 0.3), di = c(1, 2), ni = c(1, 1), alpha = 0),
               "between 0 and 1")
})

test_that("calc_cochran_q is reproducible and matches its own directly-verified worked example", {
  skip_if_not_slow()
  # No installed package provides a sample-size/power FORMULA for
  # Cochran's Q (only analysis functions exist -- rstatix, already an
  # installed dependency, has cochran_qtest()); no closed form or
  # citable formula was found either, so this directly simulates the
  # actual test (rstatix::cochran_qtest()) on correlated binary data
  # from a random-intercept logistic model. Directly verified by
  # Rscript before wiring into the app: p=(0.2,0.3,0.4,0.5), k=4,
  # sigma2_subject=1, alpha=0.05, target power=0.8 -> n=57, simulated
  # achieved power 0.829.
  res1 <- calc_cochran_q(p = c(0.2, 0.3, 0.4, 0.5), sigma2_subject = 1, alpha = 0.05, power = 0.8)
  res2 <- calc_cochran_q(p = c(0.2, 0.3, 0.4, 0.5), sigma2_subject = 1, alpha = 0.05, power = 0.8)
  expect_identical(res1$n, res2$n)
  expect_identical(res1$achieved_power, res2$achieved_power)
  expect_equal(res1$n, 57)
})

test_that("calc_cochran_q needs a larger sample size for a higher target power", {
  skip_if_not_slow()
  res_low <- calc_cochran_q(p = c(0.2, 0.3, 0.4, 0.5), sigma2_subject = 1, power = 0.7)
  res_high <- calc_cochran_q(p = c(0.2, 0.3, 0.4, 0.5), sigma2_subject = 1, power = 0.9)
  expect_lt(res_low$n, res_high$n)
})

test_that("calc_cochran_q rejects invalid inputs", {
  expect_error(calc_cochran_q(p = c(0.3, 0.5), sigma2_subject = 1), "at least 3")
  expect_error(calc_cochran_q(p = c(0.3, 0.5, 1.2), sigma2_subject = 1), "between 0 and 1")
  expect_error(calc_cochran_q(p = c(0.3, 0.5, 0.6), sigma2_subject = -1), "positive")
})
