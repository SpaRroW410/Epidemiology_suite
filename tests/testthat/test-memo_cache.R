# The result cache of the Monte Carlo calculators (R/memo_cache.R).

test_that("a repeated call returns the stored result, identical to a fresh calculation", {
  memo_clear()
  args <- list(cluster_size = 10, icc = 0.05, sigma_total = 1, delta = 0.8, power = 0.8, nsim = 10, seed = 1)
  fresh <- suppressWarnings(do.call(calc_glmm_lmm_power, args))
  first <- suppressWarnings(do.call(memo_calc, c("calc_glmm_lmm_power", args)))
  expect_identical(first, fresh)
  expect_equal(memo_size(), 1L)
  t2 <- system.time(second <- do.call(memo_calc, c("calc_glmm_lmm_power", args)))[["elapsed"]]
  expect_identical(second, fresh)
  expect_equal(memo_size(), 1L)
  expect_lt(t2, 0.1)
})

test_that("different arguments (including the seed) are different entries", {
  memo_clear()
  a <- memo_calc("calc_ks_two_sample", effect_size = 0.8, nsim = 200, seed = 1)
  b <- memo_calc("calc_ks_two_sample", effect_size = 0.8, nsim = 200, seed = 2)
  c <- memo_calc("calc_ks_two_sample", effect_size = 0.80000001, nsim = 200, seed = 1)
  expect_equal(memo_size(), 3L)
  expect_identical(a, calc_ks_two_sample(effect_size = 0.8, nsim = 200, seed = 1))
  expect_identical(b, calc_ks_two_sample(effect_size = 0.8, nsim = 200, seed = 2))
  # the same values under different argument names are different calls
  d <- memo_calc("calc_ks_two_sample", effect_size = 1, n_ratio = 2, nsim = 200, seed = 1)
  e <- memo_calc("calc_ks_two_sample", n_ratio = 1, effect_size = 2, nsim = 200, seed = 1)
  expect_equal(memo_size(), 5L)
  expect_false(identical(d, e))
})

test_that("errors are not cached and the cache can be switched off", {
  memo_clear()
  expect_error(memo_calc("calc_ks_two_sample", effect_size = -1, nsim = 200))
  expect_equal(memo_size(), 0L)
  withr::local_options(epidemiologysuite.cache = FALSE)
  memo_calc("calc_ks_two_sample", effect_size = 0.8, nsim = 200, seed = 1)
  expect_equal(memo_size(), 0L)
})

test_that("the cache keeps at most its maximum number of entries, dropping the oldest", {
  memo_clear()
  withr::local_options(epidemiologysuite.cache = TRUE)
  local_mocked_bindings(.memo_max_entries = 3L)
  for (s in 1:5) memo_calc("calc_ks_two_sample", effect_size = 0.8, nsim = 100, seed = s)
  expect_equal(memo_size(), 3L)
  expect_false(any(grepl("seed = 1L?[,)]", .memo_cache$order)))
  expect_true(any(grepl("seed = 5L?[,)]", .memo_cache$order)))
  memo_clear()
})
