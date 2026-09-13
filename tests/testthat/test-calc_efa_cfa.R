source(file.path("..", "..", "R", "calc", "calc_efa_cfa.R"))

test_that("calc_efa_cfa_sample_size computes the three ratio-based N's correctly", {
  res <- calc_efa_cfa_sample_size(n_items = 20)
  expect_equal(res$n_5to1, 100)
  expect_equal(res$n_10to1, 200)
  expect_equal(res$n_20to1, 400)
})

test_that("calc_efa_cfa_sample_size applies the Comrey & Lee (1992) adjective scale correctly", {
  expect_equal(.comrey_lee_adjective(49), "below the Comrey & Lee (1992) scale's minimum (very poor starts at N=50)")
  expect_equal(.comrey_lee_adjective(50), "very poor")
  expect_equal(.comrey_lee_adjective(100), "poor")
  expect_equal(.comrey_lee_adjective(200), "fair")
  expect_equal(.comrey_lee_adjective(300), "good")
  expect_equal(.comrey_lee_adjective(500), "very good")
  expect_equal(.comrey_lee_adjective(1000), "excellent")
  expect_equal(.comrey_lee_adjective(5000), "excellent")
})

test_that("calc_efa_cfa_sample_size is deterministic and monotonic in n_items", {
  res1 <- calc_efa_cfa_sample_size(n_items = 6)
  res2 <- calc_efa_cfa_sample_size(n_items = 6)
  expect_identical(res1, res2)

  res_more_items <- calc_efa_cfa_sample_size(n_items = 30)
  expect_gt(res_more_items$n_10to1, res1$n_10to1)
})

test_that("calc_efa_cfa_sample_size rejects invalid inputs", {
  expect_error(calc_efa_cfa_sample_size(n_items = 0), "must be a single whole number >= 1")
  expect_error(calc_efa_cfa_sample_size(n_items = 3.5), "must be a single whole number >= 1")
  expect_error(calc_efa_cfa_sample_size(n_items = NA), "must be a single whole number >= 1")
})
