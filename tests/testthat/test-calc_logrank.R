source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_logrank.R"))

test_that("calc_logrank matches Rosner (2006) Example 14.42 exactly", {
  # pE = 0.3707, pC = 0.4890, HR = 0.7, ratio = 1, alpha = 0.05, power = 0.80
  # -> nE = nC = 294 (the textbook's own published answer).
  res <- calc_logrank(pE = 0.3707, pC = 0.4890, hr = 0.7, ratio = 1,
                       alpha = 0.05, power = 0.80)
  expect_equal(res$n_exp, 294)
  expect_equal(res$n_control, 294)
  expect_equal(res$n_total, 588)
})

test_that("calc_logrank rejects invalid inputs", {
  expect_error(calc_logrank(pE = 0.3, pC = 0.3, hr = 1), "must differ")
  expect_error(calc_logrank(pE = 0, pC = 0.3, hr = 0.7), "between 0 and 1")
  expect_error(calc_logrank(pE = 0.3, pC = 0.4, hr = -1), "positive")
})

test_that("calc_cox_binary matches Latouche et al (2004) Section 5.2 exactly", {
  # power=0.80, theta=2, p=0.39, psi=0.505, rho2=0.132^2 -> n=139.
  res <- calc_cox_binary(power = 0.80, theta = 2, p = 0.39, psi = 0.505, rho2 = 0.132^2)
  expect_equal(res$n, 139)
})

test_that("calc_cox_binary rejects invalid inputs", {
  expect_error(calc_cox_binary(power = 0.8, theta = 1, p = 0.39, psi = 0.505), "must differ")
  expect_error(calc_cox_binary(power = 0.8, theta = 2, p = 1.5, psi = 0.505), "between 0 and 1")
  expect_error(calc_cox_binary(power = 0.8, theta = 2, p = 0.39, psi = 0.505, rho2 = 1), "\\[0, 1\\)")
})

test_that("calc_cox_continuous matches Hsieh & Lavori (2000) worked example exactly", {
  # power=0.806, theta=exp(1), sigma2=0.3126^2, psi=0.738, rho2=0.1837, alpha=0.1
  # (two-sided alpha=0.1 corresponds to their one-sided alpha=0.05) -> n=107.
  res <- calc_cox_continuous(power = 0.806, theta = exp(1), sigma2 = 0.3126^2,
                              psi = 0.738, rho2 = 0.1837, alpha = 0.1)
  expect_equal(res$n, 107)
})

test_that("calc_cox_continuous rejects invalid inputs", {
  expect_error(calc_cox_continuous(power = 0.8, theta = 1, sigma2 = 0.1, psi = 0.5), "must differ")
  expect_error(calc_cox_continuous(power = 0.8, theta = 2, sigma2 = -1, psi = 0.5), "positive")
  expect_error(calc_cox_continuous(power = 0.8, theta = 2, sigma2 = 0.1, psi = 0.5, rho2 = 1), "\\[0, 1\\)")
})

test_that("calc_survival_stratified matches powerSurvEpi::ssize.stratify()'s own documented example (Palta & Amini 1985, p.803) exactly", {
  res <- calc_survival_stratified(power = 0.9, timeUnit = 1.25, gVec = c(0.5, 0.5),
                                   pVec = c(0.5, 0.5), hr = 1 / 1.91,
                                   lambda0Vec = c(2.303, 1.139), alpha = 0.05)
  expect_equal(res$n_total, 146)
})

test_that("calc_survival_stratified rejects invalid inputs", {
  expect_error(calc_survival_stratified(power = 0.9, timeUnit = 1.25, gVec = c(0.5, 0.5),
                                         pVec = c(0.5, 0.5), hr = 1, lambda0Vec = c(2.303, 1.139)),
               "must differ")
  expect_error(calc_survival_stratified(power = 0.9, timeUnit = 1.25, gVec = c(0.5, 0.6),
                                         pVec = c(0.5, 0.5), hr = 0.5, lambda0Vec = c(2.303, 1.139)),
               "sum to 1")
  expect_error(calc_survival_stratified(power = 0.9, timeUnit = 1.25, gVec = c(0.5),
                                         pVec = c(0.5, 0.5), hr = 0.5, lambda0Vec = c(2.303, 1.139)),
               "same length")
})

test_that("calc_weighted_logrank is reproducible under a fixed seed", {
  res1 <- calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4, effect_timing = "delayed",
                                 accrual = 12, tot_time = 30, rho = 0, power = 0.8)
  res2 <- calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4, effect_timing = "delayed",
                                 accrual = 12, tot_time = 30, rho = 0, power = 0.8)
  expect_identical(res1$n0, res2$n0)
  expect_identical(res1$achieved_power, res2$achieved_power)
})

test_that("calc_weighted_logrank reproduces the well-documented, opposite-direction behavior of the Fleming-Harrington G-rho family under delayed vs. early/fading non-PH effects", {
  # npsurvSS (the checklist's named package) isn't installable from CRAN
  # in this sandbox (no network access); its own source, read from its
  # public GitHub CRAN mirror, implements a much larger (11-file,
  # numerical-integration-based) weighted log-rank engine judged too
  # complex to safely reimplement here -- so this instead directly
  # simulates the actual Fleming-Harrington G^rho test via the
  # already-installed `survival::survdiff()`, per the checklist's own
  # "npsurvSS/simulation" allowance. Verified directly by Rscript before
  # wiring into the app: under a DELAYED effect, rho=1 (which up-weights
  # the early period where the curves haven't yet separated) needs far
  # MORE n than rho=0 (ordinary log-rank); under the mirror-image
  # EARLY/FADING effect, rho=1 needs FEWER n than rho=0 -- the
  # well-documented, opposite-direction behavior of this test family
  # (Harrington & Fleming 1982; Fleming & Harrington 1991).
  res_delayed_rho0 <- calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4,
                                             effect_timing = "delayed", accrual = 12, tot_time = 30,
                                             rho = 0, power = 0.8)
  res_delayed_rho1 <- calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4,
                                             effect_timing = "delayed", accrual = 12, tot_time = 30,
                                             rho = 1, power = 0.8)
  expect_equal(res_delayed_rho0$n_total, 280)
  expect_equal(res_delayed_rho1$n_total, 1080)
  expect_gt(res_delayed_rho1$n_total, res_delayed_rho0$n_total)

  res_fading_rho0 <- calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4,
                                            effect_timing = "early_fading", accrual = 12, tot_time = 30,
                                            rho = 0, power = 0.8)
  res_fading_rho1 <- calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4,
                                            effect_timing = "early_fading", accrual = 12, tot_time = 30,
                                            rho = 1, power = 0.8)
  expect_equal(res_fading_rho0$n_total, 510)
  expect_equal(res_fading_rho1$n_total, 266)
  expect_lt(res_fading_rho1$n_total, res_fading_rho0$n_total)
})

test_that("calc_weighted_logrank rejects invalid inputs", {
  expect_error(
    calc_weighted_logrank(hazard0 = 0.15, hr = 1, change_time = 4, accrual = 12, tot_time = 30),
    "differ from 1"
  )
  expect_error(
    calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 30, accrual = 12, tot_time = 30),
    "less than tot_time"
  )
  expect_error(
    calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4, accrual = 30, tot_time = 20),
    "greater than accrual"
  )
  expect_error(
    calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4, accrual = 12, tot_time = 30, rho = -1),
    "rho"
  )
  expect_error(
    calc_weighted_logrank(hazard0 = 0.15, hr = 0.5, change_time = 4, accrual = 12, tot_time = 30,
                           effect_timing = "bad"),
    "delayed"
  )
  expect_error(
    calc_weighted_logrank(hazard0 = -1, hr = 0.5, change_time = 4, accrual = 12, tot_time = 30),
    "positive"
  )
})
