test_that("calc_tsa_information_size RR matches RTSA::ris() (mc=0.8, pC=0.12 -> n=7030)", {
  res <- calc_tsa_information_size(outcome = "RR", mc = 0.8, pC = 0.12, alpha = 0.05, beta = 0.1, side = 2)
  expect_equal(res$n_total, 7030)
})

test_that("calc_tsa_information_size OR matches RTSA::ris() (mc=0.7, pC=0.25, beta=0.2 -> n=1455)", {
  res <- calc_tsa_information_size(outcome = "OR", mc = 0.7, pC = 0.25, alpha = 0.05, beta = 0.2, side = 2)
  expect_equal(res$n_total, 1455)
})

test_that("calc_tsa_information_size RD matches RTSA::ris() (pC=0.30, p1=0.25, mc=0.05, side=1 -> n=5447)", {
  res <- calc_tsa_information_size(outcome = "RD", mc = 0.05, pC = 0.30, p1 = 0.25, alpha = 0.05, beta = 0.1, side = 1)
  expect_equal(res$n_total, 5447)
})

test_that("calc_tsa_information_size MD matches RTSA::ris() (mc=0.3, sd_mc=1, alpha=0.01 -> n=662)", {
  res <- calc_tsa_information_size(outcome = "MD", mc = 0.3, sd_mc = 1, alpha = 0.01, beta = 0.1, side = 2)
  expect_equal(res$n_total, 662)
})

test_that("calc_tsa_information_size RR/OR handle a harmful (>1) ratio (mc=1.3, pC=0.10 -> n=4753)", {
  res <- calc_tsa_information_size(outcome = "RR", mc = 1.3, pC = 0.10, alpha = 0.05, beta = 0.1, side = 2)
  expect_equal(res$n_total, 4753)
})

test_that("calc_tsa_information_size rejects invalid inputs", {
  expect_error(calc_tsa_information_size(outcome = "RR", mc = 1, pC = 0.12), "no difference")
  expect_error(calc_tsa_information_size(outcome = "RR", mc = -0.8, pC = 0.12), "positive")
  expect_error(calc_tsa_information_size(outcome = "RR", mc = 0.8, pC = 1.5), "between 0 and 1")
  expect_error(calc_tsa_information_size(outcome = "RD", mc = 0.05, pC = 0.30), "between 0 and 1")
  expect_error(calc_tsa_information_size(outcome = "MD", mc = 0.3), "positive number")
  expect_error(calc_tsa_information_size(outcome = "RR", mc = 100, pC = 0.5), "outside \\(0, 1\\)")
  expect_error(calc_tsa_information_size(outcome = "RR", mc = 0.8, pC = 0.12, side = 3), "side must be 1 or 2")
})

test_that("calc_tsa_information_size accepts side as an integer, not just a double literal", {
  # Regression test: as.integer(input$side) from the Shiny selectInput produces
  # an integer (2L), which identical(side, 2) treats as unequal to the double
  # literal 2 -- this must be compared by value, not by type.
  res <- calc_tsa_information_size(outcome = "RR", mc = 0.8, pC = 0.12, alpha = 0.05, beta = 0.1, side = as.integer(2))
  expect_equal(res$n_total, 7030)
})
