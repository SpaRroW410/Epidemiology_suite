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

test_that("calc_ordinal_proportional_odds matches Hmisc's own documented example exactly", {
  # p = c(.1,.2,.4,.3) (back-pain severity, 4 ordered categories),
  # odds.ratio = 1.2, fraction = 0.5, alpha = 0.05, power = 0.8 ->
  # Hmisc::posamsize() itself returns n = 3148.3 -> ceiling 3149;
  # Hmisc::popower() at n = 3148 reproduces power = 0.80 exactly.
  res <- calc_ordinal_proportional_odds(p = c(.1, .2, .4, .3), odds_ratio = 1.2,
                                         fraction = 0.5, alpha = 0.05, power = 0.8)
  expect_equal(res$n, 3149)
  expect_equal(round(res$eff, 2), 0.90)

  fit <- Hmisc::popower(p = c(.1, .2, .4, .3), odds.ratio = 1.2, n = 3148)
  expect_equal(round(fit$power, 2), 0.80)
})

test_that("calc_ordinal_proportional_odds rejects invalid inputs", {
  expect_error(calc_ordinal_proportional_odds(p = c(.5, .6), odds_ratio = 1.2), "must sum to 1")
  expect_error(calc_ordinal_proportional_odds(p = c(1.5, -0.5), odds_ratio = 1.2), "between 0 and 1")
  expect_error(calc_ordinal_proportional_odds(p = c(.5, .5), odds_ratio = 1), "must differ from 1")
  expect_error(calc_ordinal_proportional_odds(p = c(.5, .5), odds_ratio = -1), "positive")
  expect_error(calc_ordinal_proportional_odds(p = c(.5, .5), odds_ratio = 1.2, fraction = 1.5), "between 0 and 1")
  expect_error(calc_ordinal_proportional_odds(p = c(.5, .5), odds_ratio = 1.2, alpha = 0), "between 0 and 1")
  expect_error(calc_ordinal_proportional_odds(p = c(.5, .5), odds_ratio = 1.2, power = 0), "between 0 and 1")
})

test_that("calc_logistic_binary_adjusted reduces exactly to the simple case at r2=0 and inflates correctly", {
  # Hsieh, Bloch & Larsen (1998), Table I: p1=0.4, p2=0.5, prop_x1=0.5,
  # alpha=0.05, 95% power -> n=1281 (already verified for the simple case).
  base <- calc_logistic_binary(p1 = 0.4, p2 = 0.5, prop_x1 = 0.5, alpha = 0.05, power = 0.95)
  at_zero <- calc_logistic_binary_adjusted(p1 = 0.4, p2 = 0.5, prop_x1 = 0.5, r2 = 0,
                                            alpha = 0.05, power = 0.95)
  expect_equal(at_zero$n, base$n)
  expect_equal(at_zero$n, 1281)

  doubled <- calc_logistic_binary_adjusted(p1 = 0.4, p2 = 0.5, prop_x1 = 0.5, r2 = 0.5,
                                            alpha = 0.05, power = 0.95)
  expect_equal(doubled$n, base$n * 2)
  expect_equal(doubled$n_unadjusted, base$n)
})

test_that("calc_logistic_binary_adjusted rejects invalid r2", {
  expect_error(calc_logistic_binary_adjusted(p1 = 0.4, p2 = 0.5, prop_x1 = 0.5, r2 = -0.1), "\\[0, 1\\)")
  expect_error(calc_logistic_binary_adjusted(p1 = 0.4, p2 = 0.5, prop_x1 = 0.5, r2 = 1), "\\[0, 1\\)")
})

test_that("calc_logistic_continuous_adjusted reduces exactly to the simple case at r2=0 and inflates correctly", {
  # Hsieh, Bloch & Larsen (1998), Table II: p1=0.5, OR=exp(0.405), alpha=0.05,
  # 95% power -> n=317 (already verified for the simple case).
  base <- calc_logistic_continuous(p1 = 0.5, or = exp(0.405), alpha = 0.05, power = 0.95)
  at_zero <- calc_logistic_continuous_adjusted(p1 = 0.5, or = exp(0.405), r2 = 0,
                                                alpha = 0.05, power = 0.95)
  expect_equal(at_zero$n, base$n)
  expect_equal(at_zero$n, 317)

  inflated <- calc_logistic_continuous_adjusted(p1 = 0.5, or = exp(0.405), r2 = 0.3,
                                                 alpha = 0.05, power = 0.95)
  expect_equal(inflated$n, ceiling(base$n / 0.7))
})

test_that("calc_logistic_continuous_adjusted rejects invalid r2", {
  expect_error(calc_logistic_continuous_adjusted(p1 = 0.5, or = 1.5, r2 = -0.1), "\\[0, 1\\)")
  expect_error(calc_logistic_continuous_adjusted(p1 = 0.5, or = 1.5, r2 = 1), "\\[0, 1\\)")
})
