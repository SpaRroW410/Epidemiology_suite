# Each design's forward direction (n -> width/prec.level) is checked directly
# against presize's own documented examples for exact formula fidelity. The
# reverse direction (width/prec.level -> n) is checked with a +/-1 tolerance
# on n, since presize's internal uniroot solve can leave a few 1e-5-scale
# residual that ceiling() amplifies into +1 -- the same behavior already
# documented for calc_agreement_ccc.

test_that("calc_precision_riskratio matches Fagerland et al. (2015)/Koopman's own example", {
  fwd <- presize::prec_riskratio(p1 = 7 / 34, p2 = 1 / 34, n1 = 34, r = 1, method = "koopman")
  expect_equal(round(fwd$conf.width, 5), 41.35486)

  res <- calc_precision_riskratio(p1 = 7 / 34, p2 = 1 / 34, r = 1,
                                   conf_width = 41.35486, method = "koopman")
  expect_true(abs(res$n1 - 34) <= 1)
  expect_equal(res$n2, res$n1)
  expect_equal(res$achieved_width, presize::prec_riskratio(
    p1 = 7 / 34, p2 = 1 / 34, n1 = res$n1, r = 1, method = "koopman")$conf.width)
})

test_that("calc_precision_riskratio rejects invalid inputs", {
  expect_error(calc_precision_riskratio(p1 = 1.5, p2 = 0.2), "between 0 and 1")
  expect_error(calc_precision_riskratio(p1 = 0.2, p2 = 0.3, r = -1), "positive")
})

test_that("calc_precision_or matches presize's own documented example", {
  fwd <- presize::prec_or(p1 = 0.1, p2 = 0.15, n1 = 100, method = "indip_smooth")
  expect_equal(round(fwd$conf.width, 6), 1.207484)

  res <- calc_precision_or(p1 = 0.1, p2 = 0.15, r = 1, conf_width = 1.207484,
                            method = "indip_smooth")
  expect_true(abs(res$n1 - 100) <= 1)
  expect_equal(res$achieved_width, presize::prec_or(
    p1 = 0.1, p2 = 0.15, n1 = res$n1, method = "indip_smooth")$conf.width)
})

test_that("calc_precision_or rejects invalid inputs", {
  expect_error(calc_precision_or(p1 = -0.1, p2 = 0.2), "between 0 and 1")
  expect_error(calc_precision_or(p1 = 0.2, p2 = 0.3, conf_width = -1), "positive")
})

test_that("calc_precision_rateratio matches Rothman & Greenland (2018)'s own example", {
  fwd <- presize::prec_rateratio(20, 0.5, 3)
  expect_equal(round(fwd$prec.level, 6), 3.814884)

  res <- calc_precision_rateratio(rate1 = 0.5, rate2 = 3, r = 1, prec_level = 3.814884)
  expect_true(abs(res$n1 - 20) <= 1)
  expect_equal(res$achieved_prec_level, presize::prec_rateratio(
    n1 = res$n1, rate1 = 0.5, rate2 = 3)$prec.level)
})

test_that("calc_precision_rateratio rejects invalid inputs", {
  expect_error(calc_precision_rateratio(rate1 = -1, rate2 = 3), "positive")
  expect_error(calc_precision_rateratio(rate1 = 0.5, rate2 = 3, prec_level = 0.5),
               "greater than 1")
})
