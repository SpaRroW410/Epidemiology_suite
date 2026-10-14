test_that("calc_multilevel_two_level matches real powerlmm::get_power() (n1=11, T=10, var_ratio=0.02, delta=-0.9 -> n2=5639)", {
  # Verified exactly (6 decimal places) against real powerlmm::get_power()
  # at this same n: study_parameters(n1=11, n2=5639, T_end=10,
  # icc_pre_subject=0.5, var_ratio=0.02, effect_size=-0.9, sigma_error=10)
  # -> power = 0.800017, matching res$achieved_power bit-for-bit.
  res <- calc_multilevel_two_level(n1 = 11, T_end = 10, var_ratio = 0.02, delta = -0.9,
                                    sigma_error = 10, alpha = 0.05, power = 0.8)
  expect_equal(res$n_per_arm, 5639)
  expect_equal(res$n_total, 2 * 5639)
  expect_equal(round(res$achieved_power, 6), 0.800017)
})

test_that("calc_multilevel_two_level matches real powerlmm at a second scenario (n1=6, T=5, var_ratio=0.05, delta=1.5, power=0.9 -> n2=2503)", {
  res <- calc_multilevel_two_level(n1 = 6, T_end = 5, var_ratio = 0.05, delta = 1.5,
                                    sigma_error = 10, alpha = 0.05, power = 0.9)
  expect_equal(res$n_per_arm, 2503)
  expect_equal(round(res$achieved_power, 6), 0.900031)
})

test_that("calc_multilevel_two_level rejects invalid inputs", {
  expect_error(calc_multilevel_two_level(n1 = 1, T_end = 10, var_ratio = 0.02, delta = -0.9), "at least 2")
  expect_error(calc_multilevel_two_level(n1 = 11, T_end = -1, var_ratio = 0.02, delta = -0.9), "positive")
  expect_error(calc_multilevel_two_level(n1 = 11, T_end = 10, var_ratio = -0.02, delta = -0.9), "positive")
  expect_error(calc_multilevel_two_level(n1 = 11, T_end = 10, var_ratio = 0.02, delta = 0), "nonzero")
})

test_that("calc_multilevel_three_level matches real powerlmm (n1=11, n2=10, T=10, var_ratio=0.02, icc_slope=0.1, delta=-0.9 -> n3=914)", {
  # Verified exactly against real powerlmm::get_power() at this same n3
  # (achieved power 0.800181 in both, and confirmed icc_pre_subject/
  # icc_pre_cluster have zero effect on this test by directly varying them
  # against the real package with everything else held fixed).
  res <- calc_multilevel_three_level(n1 = 11, n2 = 10, T_end = 10, var_ratio = 0.02,
                                      icc_slope = 0.1, delta = -0.9, sigma_error = 10,
                                      alpha = 0.05, power = 0.8)
  expect_equal(res$n_clusters_per_arm, 914)
  expect_equal(res$n_total_clusters, 2 * 914)
  expect_equal(res$n_total_subjects, 2 * 914 * 10)
  expect_equal(round(res$achieved_power, 6), 0.800181)
})

test_that("calc_multilevel_three_level matches real powerlmm at a second scenario (n1=20, n2=15, T=24, var_ratio=0.1, icc_slope=0.05, delta=-3, alpha=0.01 -> n3=1706)", {
  res <- calc_multilevel_three_level(n1 = 20, n2 = 15, T_end = 24, var_ratio = 0.1,
                                      icc_slope = 0.05, delta = -3, sigma_error = 10,
                                      alpha = 0.01, power = 0.8)
  expect_equal(res$n_clusters_per_arm, 1706)
  expect_equal(round(res$achieved_power, 6), 0.800202)
})

test_that("calc_multilevel_three_level rejects invalid inputs", {
  expect_error(calc_multilevel_three_level(n1 = 11, n2 = 10, T_end = 10, var_ratio = 0.02,
                                            icc_slope = 1.5, delta = -0.9), "between 0 and 1")
  expect_error(calc_multilevel_three_level(n1 = 11, n2 = -1, T_end = 10, var_ratio = 0.02,
                                            icc_slope = 0.1, delta = -0.9), "positive")
  expect_error(calc_multilevel_three_level(n1 = 11, n2 = 10, T_end = 10, var_ratio = 0.02,
                                            icc_slope = 0.1, delta = 0), "nonzero")
})
