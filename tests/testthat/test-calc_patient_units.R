# Several measurements per patient (eyes, lesions, patches, split-face). Every number is checked against a real package (clusterPower for the
# between-patient designs, pwr for the within-patient paired design) or by simulation; the packages are verification oracles only.

res <- function(x) x[setdiff(names(x), "inputs")]

test_that("between-patient, continuous: patients per arm equal clusterPower::cpa.normal(method = 'weighted') (equal and unequal numbers of units)", {
  skip_if_not_installed("clusterPower")
  for (a in list(c(0.5, 1, 0.5, 2, 0), c(0.3, 1, 0.2, 3, 0.5), c(5, 12, 0.1, 10, 0.3), c(0.4, 1, 0.05, 4, 0))) {
    mine <- calc_patient_units_between_continuous(delta = a[1], sd = a[2], icc = a[3], units_per_patient = a[4], cv = a[5])
    oracle <- clusterPower::cpa.normal(alpha = 0.05, power = 0.8, nsubjects = a[4], d = a[1], ICC = a[3],
                                       sigma_sq = a[2]^2 * (1 - a[3]), CV = a[5], method = "weighted")
    # the oracle's own root finder stops at a tolerance of about 1e-4
    expect_equal(mine$n_patients_per_arm_exact, unname(oracle), tolerance = 5e-5, info = paste(a, collapse = ","))
    expect_equal(mine$n_patients_per_arm, ceiling(unname(oracle) - 1e-4), info = paste(a, collapse = ","))
  }
})

test_that("between-patient, binary: patients per arm equal clusterPower::cpa.binary()", {
  skip_if_not_installed("clusterPower")
  for (a in list(c(0.3, 0.2, 0.05, 20, 0.5), c(0.4, 0.25, 0.3, 2, 0), c(0.15, 0.08, 0.5, 2, 0.3))) {
    mine <- calc_patient_units_between_binary(p1 = a[1], p2 = a[2], icc = a[3], units_per_patient = a[4], cv = a[5])
    oracle <- clusterPower::cpa.binary(alpha = 0.05, power = 0.8, nsubjects = a[4], CV = a[5], p1 = a[1], p2 = a[2], ICC = a[3], tdist = TRUE)
    expect_equal(mine$n_patients_per_arm_exact, unname(oracle), tolerance = 5e-5, info = paste(a, collapse = ","))
  }
})

test_that("within-patient: patients equal pwr's paired t-test on the standardised difference of arm means", {
  skip_if_not_installed("pwr")
  for (a in list(c(0.5, 1, 0.5, 1), c(0.3, 1, 0.7, 2), c(5, 12, 0.3, 3), c(1, 4, 0.2, 5))) {
    mine <- calc_patient_units_within_continuous(delta = a[1], sd = a[2], icc = a[3], units_per_arm = a[4])
    sd_diff <- a[2] * sqrt(2 * (1 - a[3]) / a[4])
    oracle <- pwr::pwr.t.test(d = a[1] / sd_diff, sig.level = 0.05, power = 0.8, type = "paired")$n
    expect_equal(mine$n_patients_exact, oracle, tolerance = 1e-10, info = paste(a, collapse = ","))
    expect_equal(mine$sd_difference, sd_diff)
  }
})

test_that("with one unit per patient and no clustering the designs reduce to the ordinary comparisons", {
  b <- calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = 0, units_per_patient = 1)
  expect_equal(b$design_effect, 1)
  expect_equal(b$n_patients_per_arm, calc_means_2s_indep(mu1 = 0, mu2 = 0.5, sd = 1)$n_per_group)
  w <- calc_patient_units_within_continuous(delta = 0.5, sd = 1, icc = 0.5, units_per_arm = 1)
  expect_equal(w$n_patients, calc_means_paired(mean_diff = 0.5, sd_diff = sqrt(2 * (1 - 0.5)))$n)
})

test_that("the documented worked examples are what the functions return", {
  a <- calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = 0.5, units_per_patient = 2)
  expect_equal(a$n_patients_per_arm, 49); expect_equal(a$n_patients_total, 98); expect_equal(a$n_units_total, 196)
  expect_equal(a$n_patients_per_arm_exact, 48.07277, tolerance = 1e-6)
  expect_equal(a$design_effect, 1.5)
  expect_equal(a$n_patients_per_arm_if_units_independent, 32)
  expect_equal(a$n_patients_per_arm_floor, 33)
  b <- calc_patient_units_between_binary(p1 = 0.4, p2 = 0.25, icc = 0.3, units_per_patient = 2)
  expect_equal(b$n_patients_per_arm, 98); expect_equal(b$n_units_total, 392)
  expect_equal(b$n_patients_per_arm_if_units_independent, 76); expect_equal(b$n_patients_per_arm_floor, 46)
  w <- calc_patient_units_within_continuous(delta = 0.5, sd = 1, icc = 0.6, units_per_arm = 2)
  expect_equal(w$n_patients, 15); expect_equal(w$n_units_total, 60)
  expect_equal(w$sd_difference, sqrt(0.4), tolerance = 1e-12)
  expect_equal(w$n_patients_if_treatments_in_separate_patients, 104)
  expect_equal(calc_patient_units_within_continuous(delta = 0.5, sd = 1, icc = 0.6, units_per_arm = 1)$n_patients, 28)
})

test_that("more units per patient never needs more patients, and the patients never fall below the floor", {
  ns <- vapply(c(1, 2, 4, 8, 16, 64, 1000), function(m)
    calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = 0.3, units_per_patient = m)$n_patients_per_arm, numeric(1))
  expect_true(all(diff(ns) <= 0))
  floor_k <- calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = 0.3, units_per_patient = 2)$n_patients_per_arm_floor
  expect_true(all(ns >= floor_k))
  expect_equal(tail(ns, 1), floor_k)
  # no correlation, no floor: units are as good as patients
  z <- calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = 0, units_per_patient = 2)
  expect_true(is.na(z$n_patients_per_arm_floor))
  # the floor shrinks as the correlation falls
  f <- function(r) calc_patient_units_between_continuous(delta = 0.5, sd = 1, icc = r, units_per_patient = 2)$n_patients_per_arm_floor
  expect_gt(f(0.5), f(0.2))
})

test_that("units per patient needed: the answer reaches the power with the given patients and one unit fewer does not", {
  for (case in list(list("between_continuous", 40, 0.3), list("between_continuous", 31, 0.3), list("between_continuous", 60, 0.1))) {
    u <- calc_patient_units_needed(case[[1]], patients = case[[2]], delta = 0.5, sd = 1, icc = case[[3]])
    expect_true(u$achievable)
    reaches <- function(m) calc_patient_units_between_continuous(0.5, 1, case[[3]], m)$n_patients_per_arm <= case[[2]]
    expect_true(reaches(u$n_units_per_patient))
    if (u$n_units_per_patient > 1) expect_false(reaches(u$n_units_per_patient - 1))
  }
  b <- calc_patient_units_needed("between_binary", patients = 150, p1 = 0.4, p2 = 0.25, icc = 0.3, cv = 0.2)
  expect_true(b$achievable)
  expect_lte(calc_patient_units_between_binary(0.4, 0.25, 0.3, b$n_units_per_patient, 0.2)$n_patients_per_arm, 150)
  expect_gt(calc_patient_units_between_binary(0.4, 0.25, 0.3, b$n_units_per_patient - 1, 0.2)$n_patients_per_arm, 150)
  w <- calc_patient_units_needed("within_continuous", patients = 20, delta = 0.5, sd = 1, icc = 0.6)
  expect_equal(w$n_units_per_patient, 2)
  expect_lte(calc_patient_units_within_continuous(0.5, 1, 0.6, 2)$n_patients, 20)
  expect_gt(calc_patient_units_within_continuous(0.5, 1, 0.6, 1)$n_patients, 20)
})

test_that("fewer patients than the floor are reported as not achievable, with the floor", {
  floor_k <- calc_patient_units_between_continuous(0.4, 1, 0.3, 2)$n_patients_per_arm_floor
  u <- calc_patient_units_needed("between_continuous", patients = floor_k - 1, delta = 0.4, sd = 1, icc = 0.3)
  expect_false(u$achievable); expect_true(is.na(u$n_units_per_patient)); expect_equal(u$n_patients_per_arm_floor, floor_k)
})

test_that("a patient with enough power at one unit needs no more", {
  u <- calc_patient_units_needed("between_continuous", patients = 500, delta = 0.5, sd = 1, icc = 0.3)
  expect_equal(u$n_units_per_patient, 1)
})

test_that("invalid inputs are rejected with a clear message", {
  expect_error(calc_patient_units_between_continuous(0, 1, 0.3, 2), "must not be 0")
  expect_error(calc_patient_units_between_continuous(0.5, 0, 0.3, 2), "positive")
  expect_error(calc_patient_units_between_continuous(0.5, 1, 1, 2), "\\[0, 1\\)")
  expect_error(calc_patient_units_between_continuous(0.5, 1, 0.3, 0.5), ">= 1")
  expect_error(calc_patient_units_between_continuous(0.5, 1, 0.3, 2, cv = -1), "cv")
  expect_error(calc_patient_units_between_binary(0.3, 0.3, 0.3, 2), "differ")
  expect_error(calc_patient_units_between_binary(0, 0.3, 0.3, 2), "between 0 and 1")
  expect_error(calc_patient_units_within_continuous(0.5, 1, 0.3, 0), ">= 1")
  expect_error(calc_patient_units_needed("between_continuous", patients = 1, delta = 0.5, sd = 1, icc = 0.3), ">= 2")
})

test_that("results carry the headline field first, so the curves and exports find it", {
  expect_equal(.ss_curve_n_field(calc_patient_units_between_continuous(0.5, 1, 0.3, 2)), "n_patients_per_arm")
  expect_equal(.ss_curve_n_field(calc_patient_units_between_binary(0.4, 0.25, 0.3, 2)), "n_patients_per_arm")
  expect_equal(.ss_curve_n_field(calc_patient_units_within_continuous(0.5, 1, 0.3, 1)), "n_patients")
  expect_equal(.ss_curve_n_field(calc_patient_units_needed("between_continuous", 40, delta = 0.5, sd = 1, icc = 0.3)), "n_units_per_patient")
})

test_that("simulation: the patients required reach the power in simulated trials (patient effect shared by a patient's units)", {
  skip_if_not_slow()
  set.seed(2026)
  sim_within <- function(N, m, delta, sd, icc, reps = 4000) mean(replicate(reps, {
    p <- rnorm(N, 0, sd * sqrt(icc))
    arm <- function(shift) rowMeans(matrix(rnorm(N * m, 0, sd * sqrt(1 - icc)), N, m)) + p + shift
    t.test(arm(delta), arm(0), paired = TRUE)$p.value < 0.05
  }))
  sim_between <- function(k, m, delta, sd, icc, reps = 4000) mean(replicate(reps, {
    pm <- function(shift) rnorm(k, 0, sd * sqrt(icc)) + rowMeans(matrix(rnorm(k * m, 0, sd * sqrt(1 - icc)), k, m)) + shift
    t.test(pm(delta), pm(0), var.equal = TRUE)$p.value < 0.05
  }))
  w <- calc_patient_units_within_continuous(0.5, 1, 0.6, 2)
  expect_equal(sim_within(w$n_patients, 2, 0.5, 1, 0.6), 0.8, tolerance = 0.05)
  expect_lt(sim_within(w$n_patients - 3, 2, 0.5, 1, 0.6), 0.76)
  b <- calc_patient_units_between_continuous(0.5, 1, 0.4, 2)
  expect_equal(sim_between(b$n_patients_per_arm, 2, 0.5, 1, 0.4), 0.8, tolerance = 0.05)
  b6 <- calc_patient_units_between_continuous(0.4, 1, 0.3, 6)
  expect_equal(sim_between(b6$n_patients_per_arm, 6, 0.4, 1, 0.3), 0.8, tolerance = 0.05)
})

test_that("the module is registered, in a group, with its catalog entries and wizard terminals", {
  ids <- vapply(module_registry(), `[[`, "", "id")
  expect_true("patient_units" %in% ids)
  grouped <- unlist(lapply(module_workbenches, function(wb) lapply(wb$groups, `[[`, "module_ids")))
  expect_true("patient_units" %in% grouped)
  keys <- c("patient_units_between_continuous", "patient_units_between_binary", "patient_units_within_continuous")
  expect_true(all(keys %in% vapply(calculator_catalog, `[[`, "", "key")))
  expect_true(all(c("term_pu_between_cont", "term_pu_between_bin", "term_pu_within") %in% names(design_nodes)))
})

test_that("plain-language descriptions of eyes / lesions per patient reach the right calculator", {
  expect_equal(walk_free_text("Randomised trial of two eye drops, both eyes of each patient receive the same drop, outcome intraocular pressure")$node_id,
               "term_pu_between_cont")
  expect_equal(walk_free_text("randomized split-face trial comparing two creams, acne lesion count")$node_id, "term_pu_within")
  expect_equal(walk_free_text("randomised trial one eye per arm fellow eye control visual acuity")$node_id, "term_pu_within")
})
