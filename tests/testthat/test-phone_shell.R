# The phone layout (narrow screens): bottom tab bar and a calculator drop-down instead of the long list; wider screens unchanged.

test_that("on a phone the navbar is a bottom tab bar and the calculators are one drop-down that opens the chosen calculator (browser test)", {
  skip_if_no_ui()
  app <- ui_fresh_driver(background_load = FALSE, name = "phone_shell", width = 390, height = 700)
  withr::defer(app$stop())
  bar <- "document.querySelector('nav.navbar .navbar-collapse')"
  expect_equal(app$get_js(sprintf("getComputedStyle(%s).position", bar)), "fixed")
  expect_equal(app$get_js(sprintf("Math.round(%s.getBoundingClientRect().bottom) === window.innerHeight", bar)), TRUE)
  tabs <- unlist(app$get_js("Array.from(document.querySelectorAll('nav.navbar .navbar-nav > li.nav-item > a')).map(function(a){return a.textContent.trim()})"))
  expect_equal(tabs, c("Home", "Plan", "Analyze", "Cite"))
  ui_select_tab(app, "main_nav", "Plan: Sample Size")
  expect_equal(app$get_js("getComputedStyle(document.querySelector('ul.nav-stacked')).display"), "none")
  expect_equal(app$get_js("document.querySelectorAll('.phone-picker').length >= 2"), TRUE)
  app$run_js("var s = document.querySelector('.phone-picker'); s.value = 'Means'; s.dispatchEvent(new Event('change'));")
  app$wait_for_js("(document.querySelector('#plan_nav a.active') || {}).textContent === 'Means'", timeout = 30000)
  expect_equal(app$get_js("document.querySelector('.phone-picker').value"), "Means")
  expect_equal(app$get_js("document.querySelector('nav.navbar .navbar-nav > li.nav-item > a[aria-label]').getAttribute('aria-label')"), "Plan: Sample Size")
})

test_that("on a wide screen the navbar stays at the top and the calculator list is shown (browser test)", {
  skip_if_no_ui()
  app <- ui_fresh_driver(background_load = FALSE, name = "wide_shell", width = 1280, height = 800)
  withr::defer(app$stop())
  expect_false(app$get_js("getComputedStyle(document.querySelector('nav.navbar .navbar-collapse')).position") == "fixed")
  ui_select_tab(app, "main_nav", "Plan: Sample Size")
  expect_equal(app$get_js("getComputedStyle(document.querySelector('ul.nav-stacked')).display"), "flex")
  expect_equal(app$get_js("getComputedStyle(document.querySelector('.phone-picker')).display"), "none")
  expect_equal(app$get_js("document.querySelector('nav.navbar .navbar-nav > li.nav-item:nth-child(2) > a').textContent.trim()"), "Plan: Sample Size")
})
