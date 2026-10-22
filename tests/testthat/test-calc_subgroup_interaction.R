test_that("calc_subgroup_interaction reproduces Brookes et al (2004)'s own headline 4x finding", {
  # A trial sized for 80% power on its main effect had only ~29% power
  # to detect an interaction of the SAME magnitude at that same n --
  # i.e. achieving 80% power for that interaction instead needs ~4x
  # the sample size. effect_ratio=1 (same magnitude).
  res <- calc_subgroup_interaction(n_main_total = 100, effect_ratio = 1)
  expect_equal(res$multiplier, 4)
  expect_equal(res$n_interaction_total, 400)
})

test_that("calc_subgroup_interaction reproduces the paper's reported 16x for half-magnitude interactions", {
  res <- calc_subgroup_interaction(n_main_total = 100, effect_ratio = 0.5)
  expect_equal(res$multiplier, 16)
  expect_equal(res$n_interaction_total, 1600)
})

test_that("calc_subgroup_interaction's 4/r^2 formula matches an independent first-principles derivation", {
  # Independently re-derive N_interaction/N_main from z-based power
  # formulas for a main-effect 2-group test vs. a 4-cell
  # difference-of-differences interaction test, rather than trusting
  # only the closed-form shortcut.
  alpha <- 0.05; power_target <- 0.80
  z_a <- qnorm(1 - alpha / 2); z_p <- qnorm(power_target)
  sigma <- 1; delta_main <- 1

  for (effect_ratio in c(1, 0.5, 0.25)) {
    n_main_per_group <- (z_a + z_p)^2 * 2 * sigma^2 / delta_main^2
    N_main_total <- 2 * n_main_per_group

    delta_int <- effect_ratio * delta_main
    n_int_per_cell <- (z_a + z_p)^2 * 4 * sigma^2 / delta_int^2
    N_int_total <- 4 * n_int_per_cell

    expected_multiplier <- N_int_total / N_main_total
    res <- calc_subgroup_interaction(n_main_total = 1000, effect_ratio = effect_ratio)
    expect_equal(res$multiplier, expected_multiplier)
  }
})

test_that("calc_subgroup_interaction needs a larger multiplier for a smaller relative interaction effect", {
  res_full <- calc_subgroup_interaction(n_main_total = 100, effect_ratio = 1)
  res_half <- calc_subgroup_interaction(n_main_total = 100, effect_ratio = 0.5)
  res_quarter <- calc_subgroup_interaction(n_main_total = 100, effect_ratio = 0.25)
  expect_true(res_full$multiplier < res_half$multiplier)
  expect_true(res_half$multiplier < res_quarter$multiplier)
})

test_that("calc_subgroup_interaction rejects invalid inputs", {
  expect_error(calc_subgroup_interaction(n_main_total = 1, effect_ratio = 1), ">= 2")
  expect_error(calc_subgroup_interaction(n_main_total = 100.5, effect_ratio = 1), "whole number")
  expect_error(calc_subgroup_interaction(n_main_total = 100, effect_ratio = 0), "positive")
  expect_error(calc_subgroup_interaction(n_main_total = 100, effect_ratio = -1), "positive")
})
