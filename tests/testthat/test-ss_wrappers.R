# ss_text(), ss_export(), ss_curve() (R/ss_wrappers.R): the app's export paragraph, downloads and curves, from R.

test_that("ss_text gives the app's justification paragraph and insists on a citation", {
  r <- calc_proportion_precision(p = 0.3, d = 0.05)
  cit <- "Cochran WG. Sampling Techniques. 3rd ed. New York: Wiley; 1977."
  expect_identical(ss_text(r, "Single proportion", cit), format_justification("Single proportion", r, cit))
  expect_match(ss_text(r, "Single proportion", cit), "n = 323")
  expect_error(ss_text(r, "Single proportion", ""), "citation")
  expect_error(ss_text(list(n = 1), "x", cit), "ss_result")
})

test_that("ss_export returns or writes the same CSV and JSON as the app's downloads", {
  r <- calc_means_1s(mu0 = 120, mu1 = 125, sd = 15)
  expect_identical(ss_export(r, "csv"), ss_result_to_csv(r))
  expect_identical(ss_export(r, "json"), ss_result_to_json(r))
  f <- tempfile(fileext = ".csv"); on.exit(unlink(f))
  expect_identical(ss_export(r, "csv", f), f)
  expect_equal(paste(readLines(f), collapse = "\n"), sub("\n$", "", ss_result_to_csv(r)))
  expect_error(ss_export(r, "xml"))
})

test_that("ss_curve varies one input with the others held, as the app's curves", {
  cv <- ss_curve(calc_proportion_precision, list(p = 0.3, d = 0.05), "d", c(0.03, 0.05, 0.1))
  expect_equal(cv$x, c(0.03, 0.05, 0.1))
  expect_equal(cv$y[2], calc_proportion_precision(p = 0.3, d = 0.05)$n)
  expect_true(all(diff(cv$y) < 0))                       # a wider margin needs fewer people
  expect_null(attr(cv, "timeouts"))
  expect_error(ss_curve(calc_proportion_precision, list(p = 0.3, d = 0.05), "nope", 1:2), "arguments")
})
