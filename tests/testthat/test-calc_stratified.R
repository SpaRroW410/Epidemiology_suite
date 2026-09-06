source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_stratified.R"))

test_that("calc_stratified_sampling matches samplingbook::stratasize()'s own documented example (proportional)", {
  # Nh=c(100000,300000,600000), Sh=c(1,2,3), e=0.1, level=0.95 -> n=2568
  # (samplingbook's own stratasize() worked example, reproduced without
  # taking that package's heavy pps/sampling/survey dependency chain).
  res <- calc_stratified_sampling(Nh = c(100000, 300000, 600000), Sh = c(1, 2, 3),
                                   e = 0.1, type = "proportional")
  expect_equal(res$n_total, 2568)
})

test_that("calc_stratified_sampling matches samplingbook::stratasize()'s own documented example (optimal)", {
  # Same scenario, optimal (Neyman) allocation -> n=2395.
  res <- calc_stratified_sampling(Nh = c(100000, 300000, 600000), Sh = c(1, 2, 3),
                                   e = 0.1, type = "optimal")
  expect_equal(res$n_total, 2395)
})

test_that("calc_stratified_sampling's allocation weights match samplingbook::stratasamp()'s own documented examples", {
  # Proportional: Nh=c(5234,2586,649,157), n=500 -> nh=c(303,150,38,9).
  res_prop <- calc_stratified_sampling(Nh = c(5234, 2586, 649, 157), Sh = c(1, 1, 1, 1),
                                        e = 1, type = "proportional")
  expect_equal(round(500 * res_prop$wh), c(303, 150, 38, 9))

  # Optimal: same Nh, Sh=c(251,1165,8035,24725), n=500 -> nh=c(49,112,194,145).
  res_opt <- calc_stratified_sampling(Nh = c(5234, 2586, 649, 157),
                                       Sh = c(251, 1165, 8035, 24725),
                                       e = 1, type = "optimal")
  expect_equal(round(500 * res_opt$wh), c(49, 112, 194, 145))
})

test_that("calc_stratified_sampling's nh allocation is internally consistent with n_total", {
  res <- calc_stratified_sampling(Nh = c(100000, 300000, 600000), Sh = c(1, 2, 3),
                                   e = 0.1, type = "optimal")
  expect_equal(res$nh, round(res$n_total * res$wh))
})

test_that("calc_stratified_sampling rejects invalid inputs", {
  expect_error(calc_stratified_sampling(Nh = c(100), Sh = c(1), e = 0.1), "at least 2")
  expect_error(calc_stratified_sampling(Nh = c(100, 1), Sh = c(1, 1), e = 0.1), ">= 2")
  expect_error(calc_stratified_sampling(Nh = c(100, 200), Sh = c(-1, 1), e = 0.1), ">= 0")
  expect_error(calc_stratified_sampling(Nh = c(100, 200), Sh = c(1, 1), e = -1), "positive")
})
