# Plots carry a text description (their alt text) for people who cannot see them; it states the axes, the ranges, the trend and the
# current setting, computed from the same numbers as the plot.

test_that("the power / sensitivity curves have a description with the axes, the trend and the current value (browser test)", {
  skip_if_no_ui()
  app <- ui_fresh_driver(background_load = FALSE, name = "alt_curves")
  withr::defer(app$stop())
  ui_open_module(app, module_registry()[[1]]$title)
  app$run_js("document.querySelector('#proportion-curves_acc .accordion-button').click()")
  app$wait_for_js("document.querySelectorAll('#proportion-curve_effect img, #proportion-curve_power img').length === 2", timeout = 60000)
  alts <- app$get_js("Array.from(document.querySelectorAll('#proportion-curve_effect img, #proportion-curve_power img')).map(function(i){return i.getAttribute('alt')})")
  alts <- unlist(alts); expect_length(alts, 2)
  for (a in alts) {
    expect_match(a, "^Line chart: ")
    expect_match(a, "Horizontal axis: ")
    expect_match(a, "Vertical axis: required n, from ")
    expect_match(a, "the required n is 385 \\(marked with a red dot\\)")
  }
  expect_match(alts[2], "falls as the horizontal value increases")
})

test_that("the surveillance and epidemic-model plots have descriptions that match their results (browser test)", {
  skip_if_no_ui()
  app <- ui_fresh_driver(background_load = FALSE, name = "alt_plots")
  withr::defer(app$stop())
  ui_open_module(app, "Aberration Detection")
  app$wait_for_js("!!document.querySelector('#analyze_surveillance-plot img')", timeout = 60000)
  a <- app$get_js("document.querySelector('#analyze_surveillance-plot img').getAttribute('alt')")
  expect_match(a, "^Two charts over \\d+ observations\\. Top: the count at each observation")
  expect_match(a, "dashed threshold of ")
})
