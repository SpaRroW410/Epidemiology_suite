# Browser test of background computation (R/background.R): a separate app with one background worker. Kept in its own file, which
# runs after test-ui_smoke.R: started in the middle of that file, the extra app disturbed the shared app the later tests use.

test_that("with a background worker, a Monte Carlo calculator still shows the session's result, and Calculate reruns it", {
  skip_if_no_ui()
  skip_if_not_installed("mirai")
  app <- ui_fresh_driver(name = "background", workers = 1L)
  withr::defer(app$stop())
  ui_open_module(app, "RMST Comparison")
  shown <- "document.querySelector('#rmst-result') !== null && /Sample size/.test(document.querySelector('#rmst-result').innerText)"
  app$wait_for_js(shown, timeout = 180000)
  # the defaults are the worked example (SSRMST's documented scenario: 206 per arm, see content_rmst.R)
  expected <- calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 500, shape0 = 1, scale0 = 8500, shape1 = 1, scale1 = 8500,
                                   margin = 18, allocation1 = 0.5, alpha = 0.05, power = 0.8)
  expect_match(ui_output_text(app, "rmst-result"), sprintf("n = %d per arm", expected$n0), fixed = TRUE)
  # a new input, then Calculate: the new result arrives from the worker
  app$set_inputs(`rmst-margin` = 25, wait_ = FALSE)
  app$click("rmst-calculate")
  expected2 <- calc_rmst_comparison(ac_period = 35, tot_time = 510, tau = 500, shape0 = 1, scale0 = 8500, shape1 = 1, scale1 = 8500,
                                    margin = 25, allocation1 = 0.5, alpha = 0.05, power = 0.8)
  app$wait_for_js(sprintf("document.querySelector('#rmst-result').innerText.indexOf(%s) >= 0",
                          ui_js_string(sprintf("n = %d per arm", expected2$n0))), timeout = 180000)
  expect_match(ui_output_text(app, "rmst-result"), sprintf("n = %d per arm", expected2$n0), fixed = TRUE)
  expect_equal(ui_console_errors(app), character())
})
