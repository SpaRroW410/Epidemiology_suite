test_that("calc_competing_risks_joint matches powerCompRisk::powerCompRisk()'s own documented example exactly", {
  # Reproducing the package's own example (its source read directly from
  # its public CRAN mirror, since the package itself isn't installable
  # from CRAN in this sandbox -- no network access): lambda_11=0.3,
  # RR=0.8, HR_1=1.44, HR_all=1.33, attrition=0.1, accrual=1,
  # follow_up=8, a1=0.5, alpha=0.05, beta=0.2 (power=0.8). The package's
  # own printed output: Chi2 Joint (290 events, 436 total), Maximum Joint
  # (252 events, 378 total), Bonferroni (288 events, 430 total).
  res <- calc_competing_risks_joint(
    lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1.33, rr = 0.8,
    accrual = 1, follow_up = 8, attrition = 0.1, a1 = 0.5,
    alpha = 0.05, power = 0.8
  )
  expect_equal(res$chi2_events, 290)
  expect_equal(res$chi2_n, 436)
  expect_equal(res$max_events, 252)
  expect_equal(res$max_n, 378)
  expect_equal(res$bonferroni_events, 288)
  expect_equal(res$bonferroni_n, 430)
})

test_that("calc_competing_risks_joint needs more events/patients for a larger target power", {
  res_low <- calc_competing_risks_joint(
    lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1.33, rr = 0.8,
    accrual = 1, follow_up = 8, attrition = 0.1, a1 = 0.5,
    alpha = 0.05, power = 0.7
  )
  res_high <- calc_competing_risks_joint(
    lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1.33, rr = 0.8,
    accrual = 1, follow_up = 8, attrition = 0.1, a1 = 0.5,
    alpha = 0.05, power = 0.9
  )
  expect_lt(res_low$chi2_n, res_high$chi2_n)
  expect_lt(res_low$max_n, res_high$max_n)
  expect_lt(res_low$bonferroni_n, res_high$bonferroni_n)
})

test_that("calc_competing_risks_joint rejects invalid inputs", {
  expect_error(calc_competing_risks_joint(lambda_11 = -0.1, hr_1 = 1.44, hr_all = 1.33,
                                           rr = 0.8, accrual = 1, follow_up = 8), "positive")
  expect_error(calc_competing_risks_joint(lambda_11 = 0.3, hr_1 = 1, hr_all = 1.33,
                                           rr = 0.8, accrual = 1, follow_up = 8), "differ from 1")
  expect_error(calc_competing_risks_joint(lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1,
                                           rr = 0.8, accrual = 1, follow_up = 8), "differ from 1")
  expect_error(calc_competing_risks_joint(lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1.33,
                                           rr = 1.5, accrual = 1, follow_up = 8), "between 0 and 1")
  expect_error(calc_competing_risks_joint(lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1.33,
                                           rr = 0.8, accrual = 8, follow_up = 8), "greater than accrual")
  expect_error(calc_competing_risks_joint(lambda_11 = 0.3, hr_1 = 1.44, hr_all = 1.33,
                                           rr = 0.8, accrual = 1, follow_up = 8, attrition = 1), "\\[0, 1\\)")
  # This combination violates the package's own internal lambda_a2 >=
  # lambda_12 validity constraint (verified directly: with lambda_11=0.3,
  # rr=0.8, hr_1=0.8, hr_all=1.33, computing lambda_a1/lambda_12/lambda_a2
  # from the same formulas as the calc function gives lambda_a2 <
  # lambda_12).
  expect_error(calc_competing_risks_joint(lambda_11 = 0.3, hr_1 = 0.8, hr_all = 1.33,
                                           rr = 0.8, accrual = 1, follow_up = 8), "constraint")
})
