# Browser-driven UI tests, the guide (wizard) (split from test-ui_smoke.R on 4 Nov 2026 so that a failure points to one area; helpers in
# helper-ui.R; each file starts its own app).

.wizard_open <- function(app) {
  ui_select_tab(app, "main_nav", "Home")
  app$run_js("document.getElementById('home_go_wizard').click()")   # "Start the guide": the Find a calculator tab, guided questions
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Find a calculator' && Shiny.shinyapp.$inputValues['home_helper'] === 'Guided questions'", timeout = 30000)
  app$wait_for_js("(function(){var e=document.getElementById('design_wizard_freetext'); return !!e && e.getBoundingClientRect().width > 0;})()", timeout = 30000)
  app$wait_for_idle(500, timeout = 30000)
}

test_that("the wizard's question box is full width and tall enough to read, and the Home card is not a small scroll window", {
  skip_if_no_ui()
  app <- ui_driver()
  .wizard_open(app)
  box <- app$get_js("(function(){var r=document.getElementById('design_wizard_freetext').getBoundingClientRect(); return [r.width, r.height];})()")
  expect_gt(box[[1]], 400); expect_gt(box[[2]], 70)
  # no card body on the Home page scrolls inside a window smaller than its content
  expect_equal(app$get_js("Array.from(document.querySelectorAll('.card-body')).filter(function(e){return e.clientHeight > 0 && e.scrollHeight > e.clientHeight + 4;}).length"), 0)
})

test_that("wizard: a cohort with a measured outcome reaches the means calculators, Back steps back, free text pre-fills", {
  skip_if_no_ui()
  app <- ui_driver()
  .wizard_open(app)
  app$set_inputs(design_wizard_freetext = "Cohort study, difference in mean blood pressure between exposed and unexposed")
  app$click("design_wizard_parse")
  app$wait_for_idle(800, timeout = 30000)
  txt <- ui_output_text(app, "design_wizard_trace")
  expect_match(txt, "auto-suggested")
  expect_match(txt, "Their exposure status")
  expect_match(txt, "A measurement compared between exposed and unexposed")
  expect_match(ui_output_text(app, "design_wizard_body"), "Anything unusual about the two groups")
  # click through to the calculator
  ui_wait_bound(app, "design_wizard_choice"); app$set_inputs(design_wizard_choice = "1"); app$click("design_wizard_next"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Two independent groups")
  expect_match(ui_output_text(app, "design_wizard_body"), "Go to: Means")
  # Back returns to the previous question
  app$click("design_wizard_back"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Anything unusual about the two groups")
  app$click("design_wizard_restart"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "primary purpose of your study")
  expect_equal(ui_output_errors(app), 0)
})

test_that("wizard: the case-control question offers a measured exposure, and its Go to button opens the means calculator", {
  skip_if_no_ui()
  app <- ui_driver()
  .wizard_open(app)
  if (app$get_js("!!document.getElementById('design_wizard_restart')")) { app$click("design_wizard_restart"); app$wait_for_idle(500, timeout = 30000) }
  app$set_inputs(design_wizard_freetext = "Case-control study comparing mean serum lead level between cases and controls, unmatched")
  app$click("design_wizard_parse"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Anything unusual about the two groups")
  ui_wait_bound(app, "design_wizard_choice"); app$set_inputs(design_wizard_choice = "1"); app$click("design_wizard_next"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Go to: Means")
  app$click("design_wizard_jump")
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Plan: Sample Size'", timeout = 60000)
  app$wait_for_js("Shiny.shinyapp.$inputValues['means-design'] !== undefined", timeout = 60000)
  expect_equal(ui_output_errors(app), 0)
})
