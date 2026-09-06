source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_anova_general.R"))

test_that("calc_anova_general cross-validates against pwr::pwr.anova.test()'s one-way ANOVA special case", {
  # A one-way ANOVA with k=4 groups, Cohen's f=0.25 (medium), alpha=0.05,
  # power=0.8 is the special case u = k-1 = 3 of the general F-test
  # engine. pwr.anova.test() (already used/verified in the Means module)
  # gives n=44.6/group -> 45/group -> 180 total. The general engine
  # (u=3, f2=0.25^2) should agree closely -- both derive from the same
  # noncentral-F theory (Cohen 1988) -- differing only by how each
  # rounds continuous df to whole subjects (per-group vs. total-residual
  # rounding), so an exact match isn't expected, just close agreement.
  res <- calc_anova_general(u = 3, effect_size = 0.25^2, effect_size_type = "f2",
                             alpha = 0.05, power = 0.8)
  expect_equal(res$n_total, 179)
  expect_true(abs(res$n_total - 180) <= 2)
})

test_that("calc_anova_general's eta2 input converts to f2 correctly", {
  # f2 = eta2/(1-eta2); eta2=0.0588 -> f2=0.0625=0.25^2 (Cohen's medium f).
  res_f2 <- calc_anova_general(u = 3, effect_size = 0.0625, effect_size_type = "f2")
  res_eta2 <- calc_anova_general(u = 3, effect_size = 0.0625 / 1.0625, effect_size_type = "eta2")
  expect_equal(round(res_eta2$f2, 4), round(res_f2$f2, 4))
  expect_equal(res_eta2$n_total, res_f2$n_total)
})

test_that("calc_anova_general rejects invalid inputs", {
  expect_error(calc_anova_general(u = 0, effect_size = 0.1), ">= 1")
  expect_error(calc_anova_general(u = 3, effect_size = 1.5, effect_size_type = "eta2"), "between 0 and 1")
  expect_error(calc_anova_general(u = 3, effect_size = -1), "positive")
})
