source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_lqas.R"))

test_that("calc_lqas reproduces the classic n=19 LQAS rule exactly", {
  # p_upper=0.80, p_lower=0.50, alpha=beta=0.10 is the widely-used LQAS
  # "n=19" rule (30-percentage-point threshold gap). Verified against a
  # real published worked example: the achieved risks (~6.8%, ~8.4%,
  # total ~15%, "below 20%") match the figures reported in the LQAS
  # field literature for this exact rule, including an independent
  # mirror-image check (counting the complementary "untreated" outcome
  # with the opposite decision direction gives the identical d=6,
  # alpha=6.8%, beta=8.4% by binomial symmetry).
  res <- calc_lqas(p_upper = 0.80, p_lower = 0.50, alpha = 0.10, beta = 0.10)
  expect_equal(res$n, 19)
  expect_equal(res$d, 13)
  expect_equal(round(res$alpha_achieved, 4), 0.0676)
  expect_equal(round(res$beta_achieved, 4), 0.0835)
})

test_that("calc_lqas is self-consistent: achieved risks always satisfy the targets", {
  res <- calc_lqas(p_upper = 0.80, p_lower = 0.50, alpha = 0.10, beta = 0.10)
  expect_true(res$alpha_achieved <= 0.10)
  expect_true(res$beta_achieved <= 0.10)
  # And re-checking directly via pbinom (not just trusting the function's
  # own internal computation) confirms the returned (n, d) pair actually
  # satisfies both constraints by definition.
  alpha_check <- pbinom(res$d - 1, res$n, 0.80)
  beta_check <- 1 - pbinom(res$d - 1, res$n, 0.50)
  expect_equal(alpha_check, res$alpha_achieved)
  expect_equal(beta_check, res$beta_achieved)
})

test_that("calc_lqas requires a larger sample size for tighter risk targets", {
  loose <- calc_lqas(p_upper = 0.80, p_lower = 0.50, alpha = 0.10, beta = 0.10)
  tight <- calc_lqas(p_upper = 0.80, p_lower = 0.50, alpha = 0.05, beta = 0.05)
  expect_true(tight$n > loose$n)
})

test_that("calc_lqas requires a much larger sample size for a narrower threshold gap", {
  wide_gap <- calc_lqas(p_upper = 0.80, p_lower = 0.50, alpha = 0.10, beta = 0.10)
  narrow_gap <- calc_lqas(p_upper = 0.70, p_lower = 0.60, alpha = 0.10, beta = 0.10)
  expect_true(narrow_gap$n > wide_gap$n)
})

test_that("calc_lqas rejects invalid inputs", {
  expect_error(calc_lqas(p_upper = 0.5, p_lower = 0.8), "strictly greater")
  expect_error(calc_lqas(p_upper = 0.5, p_lower = 0.5), "strictly greater")
  expect_error(calc_lqas(p_upper = 1.5, p_lower = 0.5), "between 0 and 1")
  expect_error(calc_lqas(p_upper = 0.8, p_lower = 0.5, alpha = 1.5), "between 0 and 1")
  expect_error(calc_lqas(p_upper = 0.8, p_lower = 0.5, beta = -0.1), "between 0 and 1")
})

test_that("calc_lqas errors gracefully when no feasible n exists within n_max", {
  expect_error(
    calc_lqas(p_upper = 0.51, p_lower = 0.50, alpha = 0.05, beta = 0.05, n_max = 20),
    "No feasible sample size"
  )
})
