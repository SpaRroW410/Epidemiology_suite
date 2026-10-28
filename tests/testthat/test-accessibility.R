# The browser-level check is tools/ui-audit/a11y.R (axe-core over every calculator, light and dark); these tests keep the
# pieces it depends on from being removed by accident, without needing a browser.

page_text <- function() as.character(htmltools::as.tags(attr(epidemiologicasuite_app(lazy = FALSE), "ui_tags")))

test_that("the page declares its language, has a dark-mode switch and carries the accessibility repair script", {
  page <- page_text()
  expect_identical(attr(attr(epidemiologicasuite_app(lazy = FALSE), "ui_tags"), "lang"), "en")   # becomes <html lang="en">
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
  expect_match(js, 'role="status"', fixed = TRUE)
})

test_that("the theme colours used for text and buttons reach WCAG AA contrast (4.5:1) against white", {
  lum <- function(hex) {
    c <- grDevices::col2rgb(hex)[, 1] / 255
    c <- ifelse(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055)^2.4)
    sum(c * c(0.2126, 0.7152, 0.0722))
  }
  ratio <- function(a, b) { l <- sort(c(lum(a), lum(b)), decreasing = TRUE); (l[1] + 0.05) / (l[2] + 0.05) }
  for (nm in names(.theme_colours)) expect_gte(ratio(.theme_colours[[nm]], "#FFFFFF"), 4.5, label = nm)
  # the pale page background of the navbar and tabs (#f9f9f9) must also work for the primary colour used for links
  expect_gte(ratio(.theme_colours[["primary"]], "#F9F9F9"), 4.5)
})
