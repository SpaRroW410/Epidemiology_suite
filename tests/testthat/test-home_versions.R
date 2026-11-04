# "Three versions: which one should I use?" (R/home_versions.R)

test_that("the table compares the three versions on every row and marks the one in use", {
  for (r in .versions_rows) expect_length(r, 4)
  html <- as.character(versions_table_ui("browser"))
  expect_match(html, "You are using the browser version.", fixed = TRUE)
  expect_match(html, "this one", fixed = TRUE)
  expect_match(html, .server_version_url, fixed = TRUE)
  expect_match(html, .browser_version_url, fixed = TRUE)
  expect_match(as.character(versions_table_ui("server")), "You are using the phone / server version.", fixed = TRUE)
  expect_equal(.current_version(), "package")
  withr::local_options(epidemiologysuite.server_version = TRUE)
  expect_equal(.current_version(), "server")
})

test_that("the table is folded on Home and shown on the Cite tab", {
  expect_match(as.character(home_panel_ui()), "Three versions: which one should I use?", fixed = TRUE)
  expect_match(as.character(cite_ui()), "Which version did you use?", fixed = TRUE)
})

test_that("the phone version's address agrees with the one the browser build redirects to", {
  f <- test_path("..", "..", "tools", "pages", "mobile_url.txt")
  skip_if_not(file.exists(f), "no tools/ (not a repository checkout)")
  urls <- trimws(Filter(function(l) nzchar(trimws(l)) && !startsWith(trimws(l), "#"), readLines(f, warn = FALSE)))
  expect_equal(urls, .server_version_url)
})
