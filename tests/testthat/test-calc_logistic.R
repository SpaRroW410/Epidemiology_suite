source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_logistic.R"))

test_that("calc_logistic_binary matches Hsieh, Bloch & Larsen (1998) Table I exactly", {
  # p1=0.4, p2=0.5, B=0.5, alpha=0.05, power=0.95 -> n=1281
  # (Balanced design with high event rates).
  res <- calc_logistic_binary(p1 = 0.4, p2 = 0.5, prop_x1 = 0.5, alpha = 0.05, power = 0.95)
  expect_equal(res$n, 1281)
})

test_that("calc_logistic_binary rejects invalid inputs", {
  expect_error(calc_logistic_binary(p1 = 0.4, p2 = 0.4, prop_x1 = 0.5), "must differ")
  expect_error(calc_logistic_binary(p1 = 1.5, p2 = 0.4, prop_x1 = 0.5), "between 0 and 1")
})

test_that("calc_logistic_continuous matches Hsieh, Bloch & Larsen (1998) Table II exactly", {
  # p1=0.5, OR=exp(0.405), alpha=0.05, power=0.95 -> n=317 (Balanced design (1)).
  res <- calc_logistic_continuous(p1 = 0.5, or = exp(0.405), alpha = 0.05, power = 0.95)
  expect_equal(res$n, 317)
})

test_that("calc_logistic_continuous rejects invalid inputs", {
  expect_error(calc_logistic_continuous(p1 = 0.5, or = 1), "must differ")
  expect_error(calc_logistic_continuous(p1 = 0.5, or = -1), "positive")
})
