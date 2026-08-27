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
