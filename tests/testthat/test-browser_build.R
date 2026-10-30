test_that("the browser notice appears only in the browser build and names the install command", {
  expect_false(is_browser_build())
  expect_null(browser_notice_ui())
  testthat::local_mocked_bindings(is_browser_build = function() TRUE)
  html <- as.character(browser_notice_ui())
  expect_match(html, "Browser version")
  expect_match(html, "remotes::install_github", fixed = TRUE)
  expect_match(html, "epidemiologysuite::run_app()", fixed = TRUE)
})

test_that("a design whose package cannot load says how to get the full package", {
  err <- tryCatch(.require_pkg("notarealpackage123", "This design"), error = conditionMessage)
  expect_match(err, "This design needs the R package 'notarealpackage123'")
  expect_match(err, "remotes::install_github", fixed = TRUE)
})
