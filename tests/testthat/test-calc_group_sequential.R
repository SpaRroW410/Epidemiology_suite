source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_group_sequential.R"))

test_that("calc_group_sequential_normal: n_looks=1 (fixed design) is close to pwr::pwr.t.test", {
  # delta=0.5, sd=1 (d=0.5), alpha=0.05, power=0.8, two-sided, equal
  # allocation. gsdesign.normal uses a z-test approximation (not pwr's
  # exact t-test iterative solve), so this is a close cross-check, not an
  # exact match -- both land around a total of ~126-128 (2x the per-arm
  # answer of pwr::pwr.t.test, ~63.77 per arm for this classic Cohen
  # "medium effect" case).
  res <- calc_group_sequential_normal(delta = 0.5, sd = 1, n_looks = 1,
                                       alpha = 0.05, power = 0.8)
  expect_equal(res$n_total, 126)
  expect_equal(res$n_control, 63)
  expect_equal(res$n_experimental, 63)
})

test_that("calc_group_sequential_normal: multi-look design needs more subjects than fixed design", {
  res_fixed <- calc_group_sequential_normal(delta = 0.25, sd = 1, n_looks = 1,
                                             alpha = 0.05, power = 0.8)
  res_4look <- calc_group_sequential_normal(delta = 0.25, sd = 1, n_looks = 4,
                                             alpha = 0.05, power = 0.8, futility = TRUE)
  expect_gt(res_4look$n_total, res_fixed$n_total)
  expect_equal(res_4look$n_total, 584)
  expect_equal(length(res_4look$ifrac), 4)
  expect_equal(res_4look$ifrac, c(0.25, 0.5, 0.75, 1))
  expect_true(!is.null(res_4look$futility_boundary))
})

test_that("calc_group_sequential_normal is exactly reproducible across repeated calls", {
  res1 <- calc_group_sequential_normal(delta = 0.25, sd = 1, n_looks = 4,
                                        alpha = 0.05, power = 0.8, futility = TRUE)
  res2 <- calc_group_sequential_normal(delta = 0.25, sd = 1, n_looks = 4,
                                        alpha = 0.05, power = 0.8, futility = TRUE)
  expect_identical(res1$n_total, res2$n_total)
  expect_identical(res1$efficacy_boundary, res2$efficacy_boundary)
  expect_identical(res1$futility_boundary, res2$futility_boundary)
})

test_that("calc_group_sequential_normal rejects invalid inputs", {
  expect_error(calc_group_sequential_normal(delta = 0, sd = 1, n_looks = 4), "must differ from 0")
  expect_error(calc_group_sequential_normal(delta = 0.5, sd = -1, n_looks = 4), "positive")
  expect_error(calc_group_sequential_normal(delta = 0.5, sd = 1, n_looks = 0), ">= 1")
  expect_error(calc_group_sequential_normal(delta = 0.5, sd = 1, n_looks = 4, boundary_shape = 0.7),
               "Pocock")
})

test_that("calc_group_sequential_binary: n_looks=1 is close to pwr::pwr.2p.test", {
  # pC=0.3, pE=0.5, alpha=0.05, power=0.8. gsdesign.binomial applies the
  # Casagrande-Pike-Smith continuity correction by default and uses
  # unpooled p(1-p) variance (not pwr's arcsine h), so this is a close
  # cross-check (~201 vs 2*92.7=185.4 from pwr), not an exact match --
  # both known, standard two-proportion formulas with expected small
  # differences.
  res <- calc_group_sequential_binary(pC = 0.3, pE = 0.5, n_looks = 1,
                                       alpha = 0.05, power = 0.8)
  expect_equal(res$n_total, 201)
})

test_that("calc_group_sequential_binary: multi-look design needs more subjects", {
  res_fixed <- calc_group_sequential_binary(pC = 0.3, pE = 0.5, n_looks = 1,
                                             alpha = 0.05, power = 0.8)
  res_4look <- calc_group_sequential_binary(pC = 0.3, pE = 0.5, n_looks = 4,
                                             alpha = 0.05, power = 0.8, futility = TRUE)
  expect_gt(res_4look$n_total, res_fixed$n_total)
  expect_equal(res_4look$n_total, 230)
  expect_equal(res_4look$n_control, 115)
  expect_equal(res_4look$n_experimental, 115)
})

test_that("calc_group_sequential_binary rejects invalid inputs", {
  expect_error(calc_group_sequential_binary(pC = 0.5, pE = 0.5, n_looks = 4), "must differ")
  expect_error(calc_group_sequential_binary(pC = 1.5, pE = 0.5, n_looks = 4), "between 0 and 1")
})

test_that("calc_group_sequential_survival: n_looks=1 matches the classic Schoenfeld formula exactly", {
  # haz_ratio=0.5, alpha=0.05, power=0.8, equal allocation -> events =
  # 4*(qnorm(0.975)+qnorm(0.8))^2 / log(0.5)^2 = 65.3457, ceiling -> 66,
  # matching clinfun::gsdesign.survival()'s single-look case exactly
  # (independently re-derived and confirmed to reproduce the package's
  # own output bit-for-bit for this fixed-design special case).
  res <- calc_group_sequential_survival(haz_ratio = 0.5, n_looks = 1,
                                         alpha = 0.05, power = 0.8)
  expect_equal(res$n_events_total, 66)

  hand <- 4 * (qnorm(0.975) + qnorm(0.8))^2 / log(0.5)^2
  expect_equal(ceiling(hand), 66)
})

test_that("calc_group_sequential_survival: multi-look design needs more events", {
  res_fixed <- calc_group_sequential_survival(haz_ratio = 0.5, n_looks = 1,
                                               alpha = 0.05, power = 0.8)
  res_4look <- calc_group_sequential_survival(haz_ratio = 0.5, n_looks = 4,
                                               alpha = 0.05, power = 0.8, futility = TRUE)
  expect_gt(res_4look$n_events_total, res_fixed$n_events_total)
  expect_equal(res_4look$n_events_total, 76)
})

test_that("calc_group_sequential_survival rejects invalid inputs", {
  expect_error(calc_group_sequential_survival(haz_ratio = 1, n_looks = 4), "must differ from 1")
  expect_error(calc_group_sequential_survival(haz_ratio = -1, n_looks = 4), "positive")
})
