# Browser-driven UI tests, lazy loading of the calculators (split from test-ui_smoke.R on 4 Nov 2026 so that a failure points to one area; helpers in
# helper-ui.R; each file starts its own app).

test_that("start-up builds only the core calculators; lazy = FALSE builds all (static check)", {
  count_placeholders <- function(app) {
    html <- htmltools::renderTags(attr(app, "ui_tags"))$html
    lengths(regmatches(html, gregexpr('id="lazy_', html)))
  }
  n_lazy <- count_placeholders(epidemiologysuite_app(lazy = TRUE))
  expect_equal(n_lazy, length(module_registry()) - length(lazy_core_modules))
  expect_equal(count_placeholders(epidemiologysuite_app(lazy = FALSE)), 0)
  expect_true(all(lazy_core_modules %in% vapply(module_registry(), `[[`, character(1), "id")))
  # the module every workbench opens on (its first, or the one it names) is a core module, so none opens on a placeholder
  firsts <- vapply(module_workbenches, function(wb) if (!is.null(wb$open_on)) wb$open_on else wb$groups[[1]]$module_ids[1], "")
  expect_true(all(firsts %in% lazy_core_modules))
})

test_that("a Home jump to a calculator that is not loaded yet loads it and then sets its design", {
  skip_if_no_ui()
  app <- ui_fresh_driver(name = "lazy_jump")
  withr::defer(app$stop())
  expect_true(app$get_js("!!document.querySelector('#lazy_survey_selection > .lazy-note')"))   # not loaded at start
  ids <- home_browse_button_ids()
  btn <- names(ids)[ids == "survey_select_epi"][1]
  app$run_js(sprintf("Shiny.setInputValue(%s, 1, {priority: 'event'})", ui_js_string(btn)))   # what the Home button sends
  app$wait_for_js("Shiny.shinyapp.$inputValues['survey_selection-design'] === 'epi'", timeout = 60000)
  expect_false(app$get_js("!!document.querySelector('#lazy_survey_selection > .lazy-note')"))
  app$wait_for_idle(800, timeout = 60000)
  expect_equal(ui_output_errors(app), 0)
})

test_that("background loading fills in every calculator with the indicator beside the lists, without errors", {
  skip_if_no_ui()
  old <- Sys.getenv("EPIDEMIOLOGYSUITE_BACKGROUND_LOAD"); on.exit(Sys.setenv(EPIDEMIOLOGYSUITE_BACKGROUND_LOAD = old), add = TRUE)
  app <- ui_fresh_driver(background_load = TRUE, name = "lazy_bg")
  withr::defer(app$stop())
  # the indicator beside the calculator lists: faint entries for what is still to come, and a bar with the count
  expect_true(app$get_js("document.querySelectorAll('ul.nav-stacked a.lazy-pending').length") > 0)
  expect_true(app$get_js("document.querySelectorAll('.lazy-box').length") == 2)       # one per workbench
  expect_true(app$get_js("document.querySelectorAll('.lazy-note').length") > 0)
  app$wait_for_js("document.querySelectorAll('.lazy-note').length === 0", timeout = 240000)
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_js("document.querySelectorAll('ul.nav-stacked a.lazy-pending').length"), 0)   # nothing left to come
  expect_equal(app$get_js("document.querySelectorAll('.lazy-box:not(.lazy-complete)').length"), 0)   # and the bar has finished
  expect_equal(ui_output_errors(app), 0)
  ui_open_module(app, "Epidemic Models and Herd Immunity")
  # a calculator loaded in the background renders once its tab is shown; on a slow machine that is after "idle" first reads true
  app$wait_for_js("(function(){var e=document.getElementById('epidemic_model-result'); return !!e && e.innerText.trim().length > 0;})()", timeout = 60000)
  expect_match(ui_output_text(app, "epidemic_model-result"), "Herd-immunity threshold 91\\.7%")
})

# --- Home wizard (guided questions + free-text box) --------------------------
