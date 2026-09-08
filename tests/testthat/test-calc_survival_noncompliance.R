source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_survival_noncompliance.R"))

test_that("calc_survival_noncompliance matches Hmisc::cpower()'s own documented example closely", {
  # Reproducing the package's own example code exactly:
  #   nc.i <- 25; nc.c <- 15; mort <- .18; r <- 15
  #   uniroot(function(x) cpower(5, x, mort, r, 1.5, 5, nc.c, nc.i, pr=FALSE) - .8,
  #           c(1000, 40000))$root
  # gives a total n = 14632.19 (achieving power exactly 0.80). This
  # calculator's own root-find (constrained to an even total n, since
  # cpower() splits the total evenly between the two arms) gives 14634,
  # matching to within the expected rounding.
  res <- calc_survival_noncompliance(
    tref = 5, mc = 0.18, pct_reduction = 15, accrual = 1.5, tmin = 5,
    noncomp_c = 15, noncomp_i = 25, alpha = 0.05, power = 0.8
  )
  expect_equal(res$n_total, 14634)
  expect_equal(res$n_per_group, 7317)
  expect_equal(round(res$achieved_power, 2), 0.80)
})

test_that("calc_survival_noncompliance needs a larger n as noncompliance increases", {
  res_compliant <- calc_survival_noncompliance(
    tref = 5, mc = 0.18, pct_reduction = 15, accrual = 1.5, tmin = 5,
    noncomp_c = 0, noncomp_i = 0, alpha = 0.05, power = 0.8
  )
  res_noncompliant <- calc_survival_noncompliance(
    tref = 5, mc = 0.18, pct_reduction = 15, accrual = 1.5, tmin = 5,
    noncomp_c = 15, noncomp_i = 25, alpha = 0.05, power = 0.8
  )
  expect_lt(res_compliant$n_total, res_noncompliant$n_total)
})

test_that("calc_survival_noncompliance rejects invalid inputs", {
  expect_error(calc_survival_noncompliance(tref = -1, mc = 0.18, pct_reduction = 15,
                                            accrual = 1.5, tmin = 5), "positive")
  expect_error(calc_survival_noncompliance(tref = 5, mc = 1.2, pct_reduction = 15,
                                            accrual = 1.5, tmin = 5), "between 0 and 1")
  expect_error(calc_survival_noncompliance(tref = 5, mc = 0.18, pct_reduction = 150,
                                            accrual = 1.5, tmin = 5), "between 0 and 100")
  expect_error(calc_survival_noncompliance(tref = 5, mc = 0.18, pct_reduction = 15,
                                            accrual = 1.5, tmin = 5, noncomp_c = 105),
               "\\[0, 100\\)")
})
