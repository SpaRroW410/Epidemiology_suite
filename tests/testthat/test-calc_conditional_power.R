test_that("calc_conditional_power_normal matches a hand-derived example (z1=1.5, n_max=128, OF design)", {
  # theta = 1.5/sqrt(64) = 0.1875; z2_cutoff = (1.968586-1.5*sqrt(.5))/sqrt(.5) = 1.283965 (approx)
  # CP = pnorm(sqrt(64)*0.1875 - 1.283965) = pnorm(0.216035) = 0.5855
  res <- calc_conditional_power_normal(z1 = 1.5, timing = 0.5, n_max = 128, boundary_final = 1.968586)
  expect_equal(round(res$theta, 4), 0.1875)
  expect_equal(round(res$conditional_power, 3), 0.586)
})

test_that("calc_conditional_power_normal, integrated over the interim Z distribution under the original design's own assumed effect, reconstructs that design's own achieved power", {
  # Design: calc_lan_demets_normal(delta=0.5, sd=1, timing=0.5, r=1, alpha=0.05,
  # power=0.8, spending="OF") -> n_total=128, b1=2.962588, b2=1.968586.
  # theta_design = 0.5/(1*2) = 0.25. Integrating conditional power (using
  # theta_design, not the observed trend) over Z1's own density under
  # theta_design, plus the probability of stopping at the interim, should
  # reconstruct this design's own achieved power (0.8052, per the earlier
  # Monte Carlo verification in test-calc_lan_demets.R -- some excess over
  # the 0.80 target from rounding the continuous root up to whole arms).
  n_max <- 128; timing <- 0.5; b1 <- 2.962588; b2 <- 1.968586
  theta_design <- 0.25
  mu1 <- theta_design * sqrt(timing * n_max)
  cp_vec <- Vectorize(function(z1) {
    calc_conditional_power_normal(z1, timing, n_max, b2, theta = theta_design)$conditional_power
  })
  integrand <- function(z1) dnorm(z1, mean = mu1, sd = 1) * cp_vec(z1)
  continuation_power <- integrate(integrand, lower = -10, upper = b1)$value
  stopping_power <- 1 - pnorm(b1 - mu1)
  total_power <- continuation_power + stopping_power
  expect_true(abs(total_power - 0.8052) < 0.001)
})

test_that("calc_ssr_normal recovers the target conditional power exactly at the re-estimated sample size", {
  res <- calc_ssr_normal(z1 = 1.5, timing = 0.5, n_max = 128, boundary_final = 1.968586, target_power = 0.9)
  expect_true(res$adapted)
  expect_equal(res$n_total_new, 252)
  cp_at_new_n <- calc_conditional_power_normal(
    z1 = 1.5, timing = 0.5, n_max = res$n_total_new, boundary_final = 1.968586, theta = res$theta
  )
  # calc_conditional_power_normal expects n_max as the TOTAL design size; here
  # we instead directly verify the underlying identity via the remaining info.
  # n_remaining is ceiling()'d (rounded up, like every other calculator in
  # this app), so the achieved CP is slightly at or above the target, not
  # exactly equal to it.
  z2_cutoff <- (1.968586 - 1.5 * sqrt(0.5)) / sqrt(0.5)
  cp_direct <- pnorm(sqrt(res$n_remaining) * res$theta - z2_cutoff)
  expect_true(cp_direct >= 0.9 && cp_direct < 0.91)
})

test_that("calc_ssr_normal declines to adapt when the observed trend is non-positive or conditional power is outside cpadj", {
  res_neg <- calc_ssr_normal(z1 = -0.5, timing = 0.5, n_max = 128, boundary_final = 1.968586, target_power = 0.9)
  expect_false(res_neg$adapted)
  expect_equal(res_neg$n_total_new, 128)

  # Very high observed trend -> conditional power already above cpadj[2], no adaptation
  res_high <- calc_ssr_normal(z1 = 2.9, timing = 0.5, n_max = 128, boundary_final = 1.968586,
                               target_power = 0.9, cpadj = c(0.3, 0.9))
  expect_false(res_high$adapted)
})

test_that("calc_ssr_normal caps the re-estimated sample size at maxinc * n_max", {
  # z1=1.5 gives a moderate planned conditional power (0.5855, well within a
  # wide cpadj window); an aggressive target_power would otherwise call for
  # a much larger sample size than maxinc allows.
  res <- calc_ssr_normal(z1 = 1.5, timing = 0.5, n_max = 128, boundary_final = 1.968586,
                          target_power = 0.999, maxinc = 1.5, cpadj = c(0.01, 0.99))
  expect_true(res$adapted)
  expect_equal(res$n_total_new, ceiling(1.5 * 128))
})

test_that("calc_ssr_normal and calc_conditional_power_normal reject invalid inputs", {
  expect_error(calc_conditional_power_normal(z1 = 1, timing = 0, n_max = 128, boundary_final = 2), "between 0 and 1")
  expect_error(calc_conditional_power_normal(z1 = 1, timing = 0.5, n_max = -1, boundary_final = 2), "positive")
  expect_error(calc_ssr_normal(z1 = 1, timing = 0.5, n_max = 128, boundary_final = 2, maxinc = 1), "maxinc")
  expect_error(calc_ssr_normal(z1 = 1, timing = 0.5, n_max = 128, boundary_final = 2, cpadj = c(0.9, 0.3)), "cpadj")
})
