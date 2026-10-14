test_that("calc_sccs_samplesize matches SCCS::samplesize()'s own documented examples exactly", {
  # eexpo=2.5, risk=21, astart=366, aend=730, alpha=0.05, power=0.8:
  # p=1 (no age effects, all cases exposed) -> n=110.
  res1 <- calc_sccs_samplesize(eexpo = 2.5, risk = 21, astart = 366, aend = 730,
                                p = 1, alpha = 0.05, power = 0.8)
  expect_equal(res1$n, 110)

  # p=0.75 (75% of cases exposed) -> n=143.
  res2 <- calc_sccs_samplesize(eexpo = 2.5, risk = 21, astart = 366, aend = 730,
                                p = 0.75, alpha = 0.05, power = 0.8)
  expect_equal(res2$n, 143)

  # With age effects: p=c(.50,.35,.1,.05), eage=c(1.2,1.6,2.0), agegrp=c(457,548,639) -> n=132.
  res3 <- calc_sccs_samplesize(eexpo = 2.5, risk = 21, astart = 366, aend = 730,
                                p = c(0.50, 0.35, 0.1, 0.05), alpha = 0.05, power = 0.8,
                                eage = c(1.2, 1.6, 2.0), agegrp = c(457, 548, 639))
  expect_equal(res3$n, 132)
})

test_that("calc_sccs_samplesize rejects invalid inputs", {
  expect_error(calc_sccs_samplesize(eexpo = 1, risk = 21, astart = 366, aend = 730), "must differ")
  expect_error(calc_sccs_samplesize(eexpo = 2.5, risk = 21, astart = 730, aend = 366), "greater than astart")
  expect_error(calc_sccs_samplesize(eexpo = 2.5, risk = 400, astart = 366, aend = 730), "shortest age group")
  expect_error(calc_sccs_samplesize(eexpo = 2.5, risk = 21, astart = 366, aend = 730, p = 1.5), "sum of p")
  expect_error(
    calc_sccs_samplesize(eexpo = 2.5, risk = 21, astart = 366, aend = 730, eage = c(1.2)),
    "must both be supplied together"
  )
})
