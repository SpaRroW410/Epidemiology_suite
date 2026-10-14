# The two (rho_c, rho, u, conf_width) scenarios below were derived by
# generating a real synthetic paired dataset, running the actual, installed
# epiR::epi.ccc(x, y, ci = "asymptotic") on it, and reading off its own
# reported CCC estimate, underlying Pearson correlation, location-shift u,
# and asymptotic CI half-width -- i.e. this cross-checks calc_agreement_ccc()
# against epiR's own independently-implemented, citable (Lin 1989/2000)
# calculation on real data, not merely against a copy of the same formula.
# Because the sample-size solve inverts a sqrt() and then ceiling()s the
# result, floating-point noise on the order of 1e-14 can occasionally push
# the answer to the next integer -- so `n` is checked to be within 1 of the
# originating sample size (not asserted exactly), and `achieved_width` (the
# width actually achieved at the returned, integer n) is checked against the
# originating width with a loose relative tolerance, since it necessarily
# differs very slightly whenever ceiling() rounds up.

test_that("calc_agreement_ccc matches a real epiR::epi.ccc() run (n ~ 500, with bias)", {
  # epi.ccc() on a real generated dataset (n = 500) reported rho_c =
  # 0.7966592, r = 0.8326027, u = 0.2696744, and an asymptotic 95% CI whose
  # half-width corresponds to conf_width = 0.06060282.
  res <- calc_agreement_ccc(rho_c = 0.7966592, rho = 0.8326027, u = 0.2696744,
                             conf_width = 0.06060282, conf_level = 0.95)
  expect_true(abs(res$n - 500) <= 1)
  expect_equal(res$achieved_width, 0.06060282, tolerance = 0.01)
})

test_that("calc_agreement_ccc matches a real epiR::epi.ccc() run (n ~ 300, negligible bias)", {
  # epi.ccc() on a second real generated dataset (n = 300, near-zero
  # location shift) reported rho_c = 0.897508474109392,
  # r = 0.899937697350373, u = -0.001230843431406, conf_width = 0.043545001423342.
  res <- calc_agreement_ccc(rho_c = 0.897508474109392, rho = 0.899937697350373,
                             u = -0.001230843431406, conf_width = 0.043545001423342,
                             conf_level = 0.95)
  expect_true(abs(res$n - 300) <= 1)
  expect_equal(res$achieved_width, 0.043545001423342, tolerance = 0.01)
})

test_that("calc_agreement_ccc sample size decreases as the desired CI narrows less", {
  n_narrow <- calc_agreement_ccc(rho_c = 0.8, rho = 0.85, u = 0, conf_width = 0.05)$n
  n_wide <- calc_agreement_ccc(rho_c = 0.8, rho = 0.85, u = 0, conf_width = 0.2)$n
  expect_true(n_narrow > n_wide)
})

test_that("calc_agreement_ccc sample size increases with a larger location-shift bias u", {
  n_no_bias <- calc_agreement_ccc(rho_c = 0.8, rho = 0.85, u = 0, conf_width = 0.1)$n
  n_biased <- calc_agreement_ccc(rho_c = 0.8, rho = 0.85, u = 0.5, conf_width = 0.1)$n
  expect_true(n_biased > n_no_bias)
})

test_that("calc_agreement_ccc rejects invalid inputs", {
  expect_error(calc_agreement_ccc(rho_c = 1, rho = 0.9), "between -1 and 1")
  expect_error(calc_agreement_ccc(rho_c = 0.5, rho = 0), "not 0")
  expect_error(calc_agreement_ccc(rho_c = 0.9, rho = 0.5), "cannot exceed")
  expect_error(calc_agreement_ccc(rho_c = 0.5, rho = 0.6, conf_width = -0.1), "positive")
  expect_error(calc_agreement_ccc(rho_c = 0.5, rho = 0.6, conf_level = 1), "between 0 and 1")
})
