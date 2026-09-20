source(file.path("..", "..", "R", "calc", "calc_resource_equation.R"))

test_that("calc_resource_equation_check reproduces Charan & Kantharia (2013)'s own worked example", {
  # 5 groups, 10 rats each (N=50) -> E = 50-5 = 45, "more than needed"
  res <- calc_resource_equation_check(k_groups = 5, n_per_group = 10)
  expect_equal(res$n_total, 50)
  expect_equal(res$e, 45)
  expect_equal(res$verdict, "more than needed")
})

test_that("calc_resource_equation_size gives a smaller, still-adequate alternative", {
  # Same 5 groups, target E=10 (minimum adequate) -> N=15, 3/group
  res <- calc_resource_equation_size(k_groups = 5, e_target = 10)
  expect_equal(res$n_total, 15)
  expect_equal(res$n_per_group, 3)
  expect_equal(res$e, 10)
})

test_that("calc_resource_equation_check classifies E correctly across the 10-20 boundary", {
  expect_equal(calc_resource_equation_check(k_groups = 4, n_per_group = 3)$verdict, "too low")   # E=8
  expect_equal(calc_resource_equation_check(k_groups = 4, n_per_group = 4)$verdict, "adequate")   # E=12
  expect_equal(calc_resource_equation_check(k_groups = 4, n_per_group = 6)$verdict, "adequate")   # E=20
  expect_equal(calc_resource_equation_check(k_groups = 4, n_per_group = 7)$verdict, "more than needed") # E=24
})

test_that("calc_resource_equation_size and _check are mutually consistent", {
  sized <- calc_resource_equation_size(k_groups = 4, e_target = 10)
  checked <- calc_resource_equation_check(k_groups = 4, n_per_group = sized$n_per_group)
  expect_true(checked$e >= 10)
})

test_that("calc_resource_equation functions reject invalid inputs", {
  expect_error(calc_resource_equation_size(k_groups = 1, e_target = 10), ">= 2")
  expect_error(calc_resource_equation_size(k_groups = 4, e_target = 0), ">= 1")
  expect_error(calc_resource_equation_size(k_groups = 4.5, e_target = 10), "whole number")
  expect_error(calc_resource_equation_check(k_groups = 1, n_per_group = 10), ">= 2")
  expect_error(calc_resource_equation_check(k_groups = 4, n_per_group = 0), ">= 1")
})
