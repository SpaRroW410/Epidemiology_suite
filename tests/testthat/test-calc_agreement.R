source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_agreement.R"))

test_that("calc_icc matches Bonett (2002)'s own published worked example", {
  # Bonett (2002): 4 raters, ICC = 0.85, desired CI width 0.2 -> n = 19.2,
  # rounded up to 20 (also the presize::prec_icc() package's own doc example).
  res <- calc_icc(rho = 0.85, k = 4, conf_width = 0.2, conf_level = 0.95)
  expect_equal(res$n, 20)
})

test_that("calc_icc: 2-rater worked example from content_agreement.R", {
  res <- calc_icc(rho = 0.75, k = 2, conf_width = 0.2, conf_level = 0.95)
  expect_equal(res$n, 79)
})

test_that("calc_icc rejects invalid inputs", {
  expect_error(calc_icc(rho = 0, k = 2), "between 0 and 1")
  expect_error(calc_icc(rho = 1, k = 2), "between 0 and 1")
  expect_error(calc_icc(rho = 0.8, k = 1), ">= 2")
  expect_error(calc_icc(rho = 0.8, k = 2.5), ">= 2")
  expect_error(calc_icc(rho = 0.8, k = 2, conf_width = 0), "between 0 and 2")
})

test_that("calc_kappa matches presize::prec_kappa()'s own documented example", {
  # presize's own example: kappa = 0.5, CI width 0.15, 4 raters, 2 categories,
  # props = (0.3, 0.7) -> n = 198.
  res <- calc_kappa(kappa = 0.5, n_category = 2, raters = 4,
                     props = c(0.3, 0.7), conf_width = 0.15, conf_level = 0.95)
  expect_equal(res$n, 198)
})

test_that("calc_kappa: 2-rater worked example from content_agreement.R", {
  res <- calc_kappa(kappa = 0.6, n_category = 2, raters = 2,
                     props = c(0.4, 0.6), conf_width = 0.2, conf_level = 0.95)
  expect_equal(res$n, 211)
  expect_equal(round(res$lwr, 1), 0.5)
  expect_equal(round(res$upr, 1), 0.7)
})

test_that("calc_kappa's >2-rater (Fleiss-generalization) support is genuine across all documented raters x n_category combinations", {
  # kappaSize::CIBinary/CI3Cats/CI4Cats/CI5Cats (this app's backend, via
  # presize::prec_kappa()) document raters = 2..6 as a real argument, not a
  # workaround (Rotondi & Donner 2012's multi-rater generalization) --
  # confirm every combination actually runs and returns a DECREASING n as
  # more raters are added (more raters per subject means more information
  # per subject about kappa, so fewer subjects are needed for the same CI
  # width -- confirmed empirically here, not assumed).
  for (n_category in 2:5) {
    props <- rep(1 / n_category, n_category)
    ns <- sapply(2:6, function(r) {
      calc_kappa(kappa = 0.6, n_category = n_category, raters = r,
                 props = props, conf_width = 0.2, conf_level = 0.95)$n
    })
    expect_length(ns, 5)
    expect_true(all(ns > 0))
    expect_true(all(diff(ns) <= 0),
                info = paste("n_category =", n_category, "-> n not monotonic across raters:", paste(ns, collapse = ",")))
  }
})

test_that("calc_kappa rejects invalid inputs", {
  expect_error(calc_kappa(kappa = 1, props = c(0.5, 0.5)), "between -1 and 1")
  expect_error(calc_kappa(kappa = 0.5, n_category = 1, props = c(1)), "between 2 and 5")
  expect_error(calc_kappa(kappa = 0.5, raters = 1, props = c(0.5, 0.5)), "between 2 and 6")
  expect_error(calc_kappa(kappa = 0.5, props = c(0.5, 0.6)), "sum to 1")
  expect_error(calc_kappa(kappa = 0.5, n_category = 3, props = c(0.5, 0.5)), "must have exactly 3")
})

test_that("calc_agreement_cronbach matches presize::prec_cronb()'s own documented example", {
  # k=5, calpha=0.7, conf.width=0.1, conf.level=0.95 -> presize's own n=349.
  res <- calc_agreement_cronbach(k = 5, calpha = 0.7, conf_width = 0.1, conf_level = 0.95)
  expect_equal(res$n, 349)
})

test_that("calc_agreement_cronbach rejects invalid inputs", {
  expect_error(calc_agreement_cronbach(k = 1, calpha = 0.7), ">= 2")
  expect_error(calc_agreement_cronbach(k = 5, calpha = 1.5), "between 0 and 1")
  expect_error(calc_agreement_cronbach(k = 5, calpha = 0.7, conf_width = -1), "positive")
})

test_that("calc_agreement_bland_altman: self-consistent against presize::prec_lim_agree()", {
  res <- calc_agreement_bland_altman(conf_width = 1, conf_level = 0.95)
  expect_equal(res$n, 47)
  # presize's own documented example (a much tighter width).
  res2 <- calc_agreement_bland_altman(conf_width = 0.1, conf_level = 0.95)
  expect_equal(res2$n, 4610)
})

test_that("calc_agreement_bland_altman rejects invalid inputs", {
  expect_error(calc_agreement_bland_altman(conf_width = -1), "positive")
  expect_error(calc_agreement_bland_altman(conf_width = 1, conf_level = 1), "between 0 and 1")
})
