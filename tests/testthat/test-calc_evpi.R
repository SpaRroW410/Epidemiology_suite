source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_evpi.R"))

test_that("calc_evpi_normal matches real voi::evpi() (mean=100, sd=200 -> 39.55931)", {
  # Verified against real voi::evpi() Monte Carlo estimates converging to
  # this value as nsim grows (39.559 at nsim=5,000,000), and against an
  # independent numerical integration of the same unit normal loss
  # integral (39.55931, bit-for-bit).
  res <- calc_evpi_normal(mean_inb = 100, sd_inb = 200)
  expect_equal(round(res$evpi_per_patient, 5), 39.55931)
  expect_equal(res$evpi_population, res$evpi_per_patient)
})

test_that("calc_evpi_normal scales linearly with population", {
  res <- calc_evpi_normal(mean_inb = 100, sd_inb = 200, population = 50000)
  expect_equal(res$evpi_population, res$evpi_per_patient * 50000)
})

test_that("calc_evpi_normal rejects invalid inputs", {
  expect_error(calc_evpi_normal(mean_inb = 100, sd_inb = -1), "positive")
  expect_error(calc_evpi_normal(mean_inb = 100, sd_inb = 200, population = 0), "positive")
})

test_that("calc_evsi_normal matches an independent numerical integration exactly (mean=100, sd=200, sampling_sd=300, n=200 -> 39.16682)", {
  # This numerical-integration check shares no code with voi at all, the
  # strongest form of verification used in this batch. voi's own
  # GAM-regression estimate converges toward this same value as its
  # internal nsim grows (39.35 at nsim=20,000 -> 39.14 at nsim=200,000).
  res <- calc_evsi_normal(mean_inb = 100, sd_inb = 200, sampling_sd = 300, n = 200)
  expect_equal(round(res$evsi_per_patient, 5), 39.16682)
})

test_that("calc_evsi_normal is monotonic increasing in n and converges to EVPI as n grows", {
  n_small <- calc_evsi_normal(mean_inb = 100, sd_inb = 200, sampling_sd = 300, n = 1)$evsi_per_patient
  n_med <- calc_evsi_normal(mean_inb = 100, sd_inb = 200, sampling_sd = 300, n = 200)$evsi_per_patient
  n_huge <- calc_evsi_normal(mean_inb = 100, sd_inb = 200, sampling_sd = 300, n = 1e7)$evsi_per_patient
  evpi <- calc_evpi_normal(mean_inb = 100, sd_inb = 200)$evpi_per_patient

  expect_true(n_small < n_med)
  expect_true(n_med < n_huge)
  expect_equal(round(n_huge, 4), round(evpi, 4))
})

test_that("calc_evsi_normal rejects invalid inputs", {
  expect_error(calc_evsi_normal(mean_inb = 100, sd_inb = 200, sampling_sd = -1, n = 10), "positive")
  expect_error(calc_evsi_normal(mean_inb = 100, sd_inb = 200, sampling_sd = 300, n = 0), "positive")
})

test_that("calc_enbs_optimal_n finds a sensible interior optimum (worked example)", {
  # Verified by hand: EVSI(n) increasing/concave, sampling cost linear, so
  # ENBS(n) is concave with a single interior maximum -- confirmed by
  # evaluating ENBS across a wide grid of n and finding a peak near n=629,
  # declining on both sides.
  res <- calc_enbs_optimal_n(mean_inb = 1000, sd_inb = 3000, sampling_sd = 8000,
                              cost_per_patient = 500, population = 50000)
  expect_equal(res$n_optimal, 629)
  expect_equal(round(res$enbs_at_optimal), 37503719)
  expect_false(res$at_search_boundary)

  # ENBS just above/below the optimum should both be lower.
  enbs_below <- 50000 * calc_evsi_normal(1000, 3000, 8000, n = res$n_optimal - 100)$evsi_per_patient -
    500 * (res$n_optimal - 100)
  enbs_above <- 50000 * calc_evsi_normal(1000, 3000, 8000, n = res$n_optimal + 100)$evsi_per_patient -
    500 * (res$n_optimal + 100)
  expect_true(res$enbs_at_optimal > enbs_below)
  expect_true(res$enbs_at_optimal > enbs_above)
})

test_that("calc_enbs_optimal_n flags when the optimum sits at the search boundary", {
  # A near-zero cost per patient means more sampling is (almost) always
  # worthwhile, pushing the unconstrained optimum to n_max.
  res <- calc_enbs_optimal_n(mean_inb = 1000, sd_inb = 3000, sampling_sd = 8000,
                              cost_per_patient = 0.001, population = 50000, n_max = 5000)
  expect_true(res$at_search_boundary)
})

test_that("calc_enbs_optimal_n rejects invalid inputs", {
  expect_error(calc_enbs_optimal_n(mean_inb = 100, sd_inb = 200, sampling_sd = 300,
                                    cost_per_patient = -1), "positive")
  expect_error(calc_enbs_optimal_n(mean_inb = 100, sd_inb = 200, sampling_sd = 300,
                                    cost_per_patient = 10, fixed_cost = -5), "fixed_cost")
  expect_error(calc_enbs_optimal_n(mean_inb = 100, sd_inb = 200, sampling_sd = 300,
                                    cost_per_patient = 10, n_max = 1), "n_max")
})
