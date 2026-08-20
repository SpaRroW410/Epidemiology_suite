source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_diagnostic.R"))

test_that("calc_diagnostic_accuracy: worst-case symmetric check (sens=spec=prev=0.5)", {
  # At sens = spec = prevalence = 0.5, Sn(1-Sn)/prevalence and
  # Sp(1-Sp)/(1-prevalence) are both maximal and equal, reducing to the
  # same n=385-per-side worst case as the single-proportion Cochran
  # calculator (0.25/0.0025 * 2 = 200, *z^2 = 769.15 -> 769), with the
  # implied diseased/healthy split each at n=385.
  res <- calc_diagnostic_accuracy(sens = 0.5, spec = 0.5, prevalence = 0.5,
                                   prec_sens = 0.05, prec_spec = 0.05,
                                   conf_level = 0.95)
  expect_equal(res$n, 769)
  expect_equal(res$n_sens, 769)
  expect_equal(res$n_spec, 769)
  expect_equal(res$n_diseased, 385)
  expect_equal(res$n_healthy, 385)
})

test_that("calc_diagnostic_accuracy: worked example from content_diagnostic.R", {
  res <- calc_diagnostic_accuracy(sens = 0.90, spec = 0.85, prevalence = 0.30,
                                   prec_sens = 0.05, prec_spec = 0.05,
                                   conf_level = 0.95)
  expect_equal(res$n_sens, 461)
  expect_equal(res$n_spec, 280)
  expect_equal(res$n, 461)
  expect_equal(res$binding, "sensitivity")
  expect_equal(res$n_diseased, 139)
  expect_equal(res$n_healthy, 323)
})

test_that("calc_diagnostic_accuracy: low prevalence inflates n_sens, binding flips to specificity when prevalence is high", {
  low_prev <- calc_diagnostic_accuracy(sens = 0.90, spec = 0.90, prevalence = 0.01)
  expect_equal(low_prev$binding, "sensitivity")
  expect_gt(low_prev$n_sens, low_prev$n_spec)

  high_prev <- calc_diagnostic_accuracy(sens = 0.90, spec = 0.90, prevalence = 0.99)
  expect_equal(high_prev$binding, "specificity")
  expect_gt(high_prev$n_spec, high_prev$n_sens)
})

test_that("calc_diagnostic_accuracy rejects invalid inputs", {
  expect_error(calc_diagnostic_accuracy(sens = 0, spec = 0.85, prevalence = 0.3), "between 0 and 1")
  expect_error(calc_diagnostic_accuracy(sens = 0.9, spec = 1, prevalence = 0.3), "between 0 and 1")
  expect_error(calc_diagnostic_accuracy(sens = 0.9, spec = 0.85, prevalence = 0), "between 0 and 1")
  expect_error(calc_diagnostic_accuracy(sens = 0.9, spec = 0.85, prevalence = 0.3, prec_sens = 0), "between 0 and 1")
  expect_error(calc_diagnostic_accuracy(sens = 0.9, spec = 0.85, prevalence = 0.3, conf_level = 1), "between 0 and 1")
})
