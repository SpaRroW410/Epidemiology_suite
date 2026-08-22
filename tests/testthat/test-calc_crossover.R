source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_crossover.R"))

test_that("calc_crossover_2x2 matches TrialSize::TwoSampleCrossOver.Equality() exactly", {
  # alpha=0.05, power=0.8, sigma=0.4, delta=0.2 -> n per sequence = 15.698,
  # ceiling 16, total 32 (TrialSize's own formula, Chow/Shao/Wang 2003).
  res <- calc_crossover_2x2(delta = 0.2, sigma = 0.4, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_sequence, 16)
  expect_equal(res$n_total, 32)
})

test_that("calc_crossover_2x2 rejects invalid inputs", {
  expect_error(calc_crossover_2x2(delta = 0, sigma = 0.4), "must differ")
  expect_error(calc_crossover_2x2(delta = 0.2, sigma = -1), "positive")
  expect_error(calc_crossover_2x2(delta = 0.2, sigma = 0.4, alpha = 1.5), "between 0 and 1")
})
