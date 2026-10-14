test_that("calc_capture_recapture_n2 reproduces this session's own Monte Carlo verification", {
  # N=1000, n1=100, target CV=0.10 (precision = 0.10 * z_0.975) -> n2=474,
  # independently confirmed by simulating 200,000 replicates of the actual
  # discrete hypergeometric mark-recapture process.
  z95 <- qnorm(0.975)
  res <- calc_capture_recapture_n2(N = 1000, n1 = 100, precision = 0.10 * z95, conf_level = 0.95)
  expect_equal(res$n2, 474)
  expect_true(abs(res$achieved_cv - 0.10) < 0.005)
})

test_that("calc_capture_recapture_n2 is deterministic (pure closed-form, no simulation)", {
  res1 <- calc_capture_recapture_n2(N = 1000, n1 = 100, precision = 0.10)
  res2 <- calc_capture_recapture_n2(N = 1000, n1 = 100, precision = 0.10)
  expect_identical(res1, res2)
})

test_that("calc_capture_recapture_n2 needs a larger n2 for a tighter precision target", {
  res_loose <- calc_capture_recapture_n2(N = 2000, n1 = 150, precision = 0.20)
  res_tight <- calc_capture_recapture_n2(N = 2000, n1 = 150, precision = 0.05)
  expect_gt(res_tight$n2, res_loose$n2)
})

test_that("calc_capture_recapture_n2's solved n2 never exceeds N (mathematical invariant)", {
  for (p in c(0.5, 0.1, 0.01, 0.001)) {
    res <- calc_capture_recapture_n2(N = 500, n1 = 50, precision = p)
    expect_lte(res$n2, 500)
  }
})

test_that("calc_capture_recapture_n2 rejects invalid inputs", {
  expect_error(calc_capture_recapture_n2(N = 100, n1 = 150, precision = 0.1), "n1 must be smaller than N")
  expect_error(calc_capture_recapture_n2(N = 1000, n1 = 100, precision = 1.5), "between 0 and 1")
  expect_error(calc_capture_recapture_n2(N = 1000, n1 = -10, precision = 0.1), "positive")
  expect_error(calc_capture_recapture_n2(N = 1000, n1 = 100, precision = 0.1, conf_level = 1.5), "between 0 and 1")
})
