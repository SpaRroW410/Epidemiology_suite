# Browser-driven UI smoke tests (ROADMAP P1 item 12, finding F6): the whole app
# is started once in headless Chrome via shinytest2 and every module is opened
# in turn. Unit tests call calc_*() directly and never see a module's own wiring
# (a broken content_fn, a renderUI error, a missing output), which is exactly
# what these catch. The per-design pass over every module's design radio is slow
# and runs only with S2R_SLOW_TESTS=true (the weekly CI run).

registry <- module_registry()

test_that("the app starts on the Home hub with no console errors", {
  skip_if_no_ui()
  app <- ui_driver()
  app$wait_for_idle(800, timeout = 120000)
  expect_equal(ui_output_errors(app), 0)
  expect_equal(app$get_js("document.querySelector('.navbar-brand, .navbar .navbar-title') !== null"), TRUE)
  expect_equal(app$get_value(input = "main_nav"), "Home")
  expect_equal(ui_console_errors(app), character())
})

test_that("a Home 'Browse calculators' button that shares its calculator with another family opens it", {
  skip_if_no_ui()
  app <- ui_driver()
  ids <- home_browse_button_ids()
  # A calculator listed under 2+ families of one lens: click the LAST such button
  # (the one a duplicated id would have shadowed).
  for (axis in c("design", "test")) {
    lens <- ids[startsWith(names(ids), paste0("jump_browse_", axis))]
    dup_keys <- unique(lens[duplicated(lens)])
    if (length(dup_keys)) break
  }
  expect_gt(length(dup_keys), 0)
  key <- dup_keys[[1]]
  entry <- catalog_entry(key)
  btn <- tail(names(lens)[lens == key], 1)
  app$set_inputs(home_browse_axis = axis, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 30000)
  expect_equal(app$get_js(sprintf("Array.from(document.querySelectorAll('[id]')).filter(function(e){return e.id === %s;}).length", ui_js_string(btn))), 1)
  app$run_js(sprintf("document.getElementById(%s).click()", ui_js_string(btn)))
  app$wait_for_idle(800, timeout = 30000)
  wb <- module_workbench_of(entry$nav_target)
  expect_equal(app$get_value(input = "main_nav"), wb$title)
  expect_equal(app$get_value(input = wb$nav_id), entry$nav_target)
  expect_equal(ui_output_errors(app), 0)
})

for (m in registry) {
  local({
    m <- m
    test_that(sprintf("UI: module '%s' opens and renders without output errors", m$id), {
      skip_if_no_ui()
      app <- ui_driver()
      ui_open_module(app, m$title)
      wb <- module_workbench_of(m$title)
      expect_equal(app$get_value(input = "main_nav"), wb$title)
      expect_equal(app$get_value(input = wb$nav_id), m$title)
      expect_true(ui_pane_visible(app, m$title))
      expect_equal(ui_output_errors(app), 0)
      txt <- ui_output_text(app, paste0(m$id, "-result"))
      if (!is.na(txt)) expect_gt(nchar(txt), 0)
    })
  })
}

test_that("Diagnostic Test Evaluation: single test shows CIs; combining 3 tests lists serial and parallel, with CIs once n is given", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Diagnostic Test Evaluation")
  single <- ui_output_text(app, "analyze_dx-result")
  expect_match(single, "Sensitivity")
  expect_match(single, "90.1% \\(87.7 to 92.1\\)")   # Scott et al. 2008 / epiR::epi.tests()
  expect_match(single, "Positive predictive value")

  app$set_inputs(`analyze_dx-design` = "combined")
  app$wait_for_idle(800, timeout = 60000)
  combined <- ui_output_text(app, "analyze_dx-result")
  expect_match(combined, "Parallel: positive if ANY of the 3 tests")
  expect_match(combined, "Serial: positive only if ALL 3 tests")
  expect_match(combined, "99.7%")   # parallel sensitivity of 90/80/85
  expect_match(combined, "61.2%")   # serial sensitivity
  expect_match(combined, "Enter the numbers of diseased and non-diseased")
  app$set_inputs(`analyze_dx-nd1` = 100, `analyze_dx-nd2` = 200, `analyze_dx-nd3` = 150,
                 `analyze_dx-nn1` = 300, `analyze_dx-nn2` = 250, `analyze_dx-nn3` = 200)
  app$wait_for_idle(800, timeout = 60000)
  with_ci <- ui_output_text(app, "analyze_dx-result")
  expect_match(with_ci, " to ")
  expect_false(grepl("Enter the numbers of diseased", with_ci))
  expect_equal(ui_output_errors(app), 0)
})

test_that("no JavaScript or Shiny errors accumulated while opening every module", {
  skip_if_no_ui()
  expect_equal(ui_console_errors(ui_driver()), character())
})

# --- slow lane: every design of every module ---------------------------------

.ui_primary_radio <- function(app, id) {
  for (g in c("design", "outcome", "mode", "es_type")) {
    vals <- app$get_js(sprintf(
      "Array.from(document.querySelectorAll('input[type=radio]')).filter(function(e){return e.name === %s;}).map(function(e){return e.value;})",
      ui_js_string(paste0(id, "-", g))))
    if (length(vals)) return(list(group = g, values = unlist(vals)))
  }
  NULL
}

for (m in registry) {
  local({
    m <- m
    test_that(sprintf("UI (every design): module '%s' renders each design without output errors", m$id), {
      skip_if_not_slow()
      skip_if_no_ui()
      app <- ui_driver()
      ui_open_module(app, m$title)
      radio <- .ui_primary_radio(app, m$id)
      skip_if(is.null(radio), "module has no design selector")
      for (v in radio$values) {
        ui_choose_radio(app, paste0(m$id, "-", radio$group), v)
        app$wait_for_idle(800, timeout = 180000)
        expect_equal(ui_output_errors(app), 0, info = paste(m$id, v))
      }
    })
  })
}
