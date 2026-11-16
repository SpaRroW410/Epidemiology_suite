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

test_that("the heterogeneity-adjusted information size reproduces Wetterslev et al. 2009, Table 2", {
  # unadjusted size, inconsistency I2 (%), diversity D2 (%), I2-adjusted size, D2-adjusted size, as printed. The paper's sizes come
  # from unrounded I2 and D2, so the printed one-decimal percentages reproduce them to within 1.5%.
  tab <- rbind(c(3317, 0.0, 0.0, 3317, 3317), c(3516, 7.2, 13.9, 3789, 4083), c(193, 22.9, 37.3, 250, 307),
               c(8421, 13.4, 40.5, 9726, 14164), c(440, 40.2, 57.7, 736, 1039), c(31094, 61.9, 89.9, 81466, 306276),
               c(1699, 74.2, 79.4, 6581, 8239))
  for (i in seq_len(nrow(tab))) {
    expect_lt(abs(tab[i, 1] / (1 - tab[i, 2] / 100) / tab[i, 4] - 1), 0.015, label = paste("I2 row", i))
    expect_lt(abs(tab[i, 1] / (1 - tab[i, 3] / 100) / tab[i, 5] - 1), 0.015, label = paste("D2 row", i))
  }
  base <- calc_tsa_information_size("RR", mc = 0.8, pC = 0.12)
  expect_equal(base$n_total, 7030)
  expect_equal(c(base$n_total_adjusted, base$adjustment_factor), c(7030, 1))
  adj <- calc_tsa_information_size("RR", mc = 0.8, pC = 0.12, heterogeneity = 0.25)
  expect_equal(adj$n_total, 7030)                      # the fixed-effect size is unchanged
  expect_equal(adj$n_total_adjusted, 9373)
  expect_equal(adj$adjustment_factor, 1 / 0.75)
  expect_equal(calc_tsa_information_size("MD", mc = 0.3, sd_mc = 1, heterogeneity = 0.5)$adjustment_factor, 2)
  expect_error(calc_tsa_information_size("RR", mc = 0.8, pC = 0.12, heterogeneity = 1), "heterogeneity")
  expect_error(calc_tsa_information_size("RR", mc = 0.8, pC = 0.12, heterogeneity = 25), "heterogeneity")
})
