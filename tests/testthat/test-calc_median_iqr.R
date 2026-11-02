# Mean and SD from a median and IQR (Wan et al. 2014, scenario C3).

test_that("the formulas are Wan et al.'s scenario C3, and the SD divisor tends to the Cochrane 1.35", {
  r <- calc_mean_sd_from_median_iqr(median = 45, q1 = 38, q3 = 54, n = 60)
  expect_equal(r$mean, (38 + 45 + 54) / 3)
  expect_equal(r$sd, (54 - 38) / (2 * qnorm((0.75 * 60 - 0.125) / (60 + 0.25))))
  expect_equal(calc_mean_sd_from_median_iqr(0, -1, 1, n = 1e7)$divisor, 2 * qnorm(0.75), tolerance = 1e-5)
  expect_equal(round(2 * qnorm(0.75), 3), 1.349)
  expect_error(calc_mean_sd_from_median_iqr(50, 55, 60), "q1 <= median")
  expect_error(calc_mean_sd_from_median_iqr(50, 40, 60, n = 1), "n must")
})

test_that("for normal samples the estimates recover the sample mean and SD (simulation)", {
  set.seed(2)
  est <- replicate(1000, {
    x <- stats::rnorm(201, 50, 17)
    q <- unname(stats::quantile(x, c(0.25, 0.5, 0.75)))
    e <- calc_mean_sd_from_median_iqr(q[2], q[1], q[3], 201)
    c(e$mean - mean(x), e$sd / stats::sd(x) - 1)
  })
  expect_lt(abs(mean(est[1, ])), 0.1)     # mean 50, SD 17
  expect_lt(abs(mean(est[2, ])), 0.01)    # relative bias of the SD below 1%
})
