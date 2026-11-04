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
  ui_select_tab(app, "main_nav", "Home")
  app$run_js("document.getElementById('home_go_browse').click()")   # "Browse all calculators": the Find a calculator tab
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Find a calculator' && Shiny.shinyapp.$inputValues['home_helper'] === 'Browse all calculators'", timeout = 30000)
  app$wait_for_js("!!document.getElementById('home_browse_axis')", timeout = 30000)
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


test_that("no JavaScript or Shiny errors accumulated while opening every module", {
  skip_if_no_ui()
  expect_equal(ui_console_errors(ui_driver()), character())
})

# --- slow lane: every design of every module ---------------------------------
