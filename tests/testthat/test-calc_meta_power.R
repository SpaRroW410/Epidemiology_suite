source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_meta_power.R"))

test_that("calc_meta_analysis_power matches metapower::mpower()'s own documented example (Cohen's d) exactly", {
  # metapower::mpower(effect_size=.2, study_size=10, k=10, i2=.5, es_type="d")
  # -> fixed_power=0.1694615, random_power=0.1357176 (verified directly
  # against a real package call this session).
  res <- calc_meta_analysis_power(effect_size = 0.2, study_size = 10, k = 10, i2 = 0.5, es_type = "d")
  expect_equal(round(res$fixed_power, 7), 0.1694615)
  expect_equal(round(res$random_power, 7), 0.1357176)
})

test_that("calc_meta_analysis_power matches metapower::mpower() exactly for es_type = 'r'", {
  # mpower(effect_size=.3, study_size=30, k=15, i2=.3, es_type="r") ->
  # fixed_power=0.9999906, random_power=0.998952.
  res <- calc_meta_analysis_power(effect_size = 0.3, study_size = 30, k = 15, i2 = 0.3, es_type = "r")
  expect_equal(round(res$fixed_power, 7), 0.9999906)
  expect_equal(round(res$random_power, 6), 0.998952)
})

test_that("calc_meta_analysis_power matches metapower::mpower() exactly for es_type = 'or'", {
  # mpower(study_size=100, k=8, i2=.4, es_type="or", con_table=c(30,20,15,35))
  # -> fixed_power=1, random_power=0.999971.
  res <- calc_meta_analysis_power(study_size = 100, k = 8, i2 = 0.4, es_type = "or",
                                   con_table = c(30, 20, 15, 35))
  expect_equal(round(res$fixed_power, 6), 1)
  expect_equal(round(res$random_power, 6), 0.999971)
})

test_that("calc_meta_analysis_power matches metapower::mpower() exactly for a one-tailed test", {
  # mpower(effect_size=.4, study_size=20, k=6, i2=.6, es_type="d",
  # test_type="one-tailed", p=0.01) -> fixed_power=0.4376054, random_power=0.231696.
  res <- calc_meta_analysis_power(effect_size = 0.4, study_size = 20, k = 6, i2 = 0.6, es_type = "d",
                                   test_type = "one-tailed", alpha = 0.01)
  expect_equal(round(res$fixed_power, 7), 0.4376054)
  expect_equal(round(res$random_power, 6), 0.231696)
})

test_that("calc_meta_analysis_power's random-effects power is never larger than its fixed-effect power, other things equal", {
  res <- calc_meta_analysis_power(effect_size = 0.5, study_size = 40, k = 12, i2 = 0.5, es_type = "d")
  expect_true(res$random_power <= res$fixed_power + 1e-8)
})

test_that("calc_meta_analysis_k finds the smallest k reaching target power and reproduces it via calc_meta_analysis_power", {
  res <- calc_meta_analysis_k(effect_size = 0.3, study_size = 25, i2 = 0.4, es_type = "d",
                               power = 0.8, model = "random")
  direct <- calc_meta_analysis_power(effect_size = 0.3, study_size = 25, k = res$k, i2 = 0.4, es_type = "d")
  expect_equal(res$achieved_power, direct$random_power)
  expect_true(res$achieved_power >= 0.8)
  # one fewer study should NOT reach the target (confirms k is the smallest)
  if (res$k > 2) {
    one_less <- calc_meta_analysis_power(effect_size = 0.3, study_size = 25, k = res$k - 1, i2 = 0.4, es_type = "d")
    expect_true(one_less$random_power < 0.8)
  }
})

test_that("calc_meta_analysis_k needs more studies under the random-effects model than the fixed-effect model, other things equal", {
  res_random <- calc_meta_analysis_k(effect_size = 0.3, study_size = 25, i2 = 0.5, es_type = "d",
                                      power = 0.8, model = "random")
  res_fixed <- calc_meta_analysis_k(effect_size = 0.3, study_size = 25, i2 = 0.5, es_type = "d",
                                     power = 0.8, model = "fixed")
  expect_true(res_random$k >= res_fixed$k)
})

test_that("calc_meta_analysis_power rejects invalid inputs", {
  expect_error(calc_meta_analysis_power(effect_size = 0.2, study_size = -1, k = 10, i2 = 0.5, es_type = "d"), "positive")
  expect_error(calc_meta_analysis_power(effect_size = 0.2, study_size = 10, k = 1, i2 = 0.5, es_type = "d"), ">= 2")
  expect_error(calc_meta_analysis_power(effect_size = 0.2, study_size = 10, k = 10, i2 = 1, es_type = "d"), "\\[0, 1\\)")
  expect_error(calc_meta_analysis_power(effect_size = 1.5, study_size = 10, k = 10, i2 = 0.5, es_type = "r"), "\\(-1, 1\\)")
  expect_error(calc_meta_analysis_power(study_size = 10, k = 10, i2 = 0.5, es_type = "or"), "con_table")
  expect_error(calc_meta_analysis_power(study_size = 10, k = 10, i2 = 0.5, es_type = "or", con_table = c(1, 1, 1, 1)), "sum of con_table")
})
