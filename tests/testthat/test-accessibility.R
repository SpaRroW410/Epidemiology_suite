# The browser-level check is tools/ui-audit/a11y.R (axe-core over every calculator, light and dark); these tests keep the
# pieces it depends on from being removed by accident, without needing a browser.

page_text <- function() as.character(htmltools::as.tags(attr(epidemiologicasuite_app(lazy = FALSE), "ui_tags")))

test_that("the page declares its language, has a dark-mode switch and carries the accessibility repair script", {
  page <- page_text()
  expect_match(page, 'lang="en"', fixed = TRUE)
  expect_match(page, "bslib-input-dark-mode", fixed = TRUE)
  expect_match(page, "combobox", fixed = TRUE)      # selectize search boxes get a name from their label
  expect_match(page, "tabindex", fixed = TRUE)      # scrollable result areas get keyboard access
})

test_that("the dark-mode switch is a list item, not a stray element inside the navbar list", {
  expect_false(grepl("bslib-nav-spacer", page_text(), fixed = TRUE))
})

test_that("the loading-progress live region is inside its list item (a <ul> may only contain <li>)", {
  js <- as.character(lazy_sidebar_assets("Means"))
  expect_false(grepl("li.setAttribute('role'", js, fixed = TRUE))
  expect_match(js, 'role=\\"status\\"', fixed = TRUE)
})
