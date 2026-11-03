# Studies in a real browser (R/mod_studies.R): add results under a calculator, see them in the Studies tab (repeated use of one design as a
# table), survive a page reload (the record is kept in the tab's sessionStorage), Undo, remove, a new study, recent calculations.

ui_study_add <- function(app, module_id, study = NULL) {
  if (!is.null(study)) app$run_js(sprintf("document.getElementById('%s-study_target').value = '%s';", module_id, study))
  app$run_js(sprintf("document.getElementById('%s-study_target').nextElementSibling.click();", module_id))
  app$wait_for_idle(800, timeout = 60000)
}
ui_studies_text <- function(app) app$get_js("var e = document.getElementById('studies_view'); e ? e.innerText : ''")
ui_open_studies <- function(app, pick = NULL) {
  ui_select_tab(app, "main_nav", "Studies")
  if (!is.null(pick)) app$set_inputs(studies_pick = pick, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
}

test_that("results added to a study show as a table for one design, can be undone or removed, and survive a reload", {
  skip_if_no_ui()
  # its own app: the reload at the end leaves the page without shinytest2's helpers, so the shared driver is not used
  app <- ui_fresh_driver(name = "studies")
  on.exit(app$stop(), add = TRUE)
  ui_open_module(app, "Proportions")
  ui_choose_radio(app, "proportion-design", "precision")
  app$wait_for_idle(800, timeout = 60000)
  # the drop-down under the result lists the three studies
  expect_equal(app$get_js("document.getElementById('proportion-study_target').options.length"), 3)
  ui_study_add(app, "proportion", "s1")
  expect_match(app$get_js("document.getElementById('study_toast').innerText"), "Added to Study 1: Proportions")
  app$set_inputs(`proportion-d_precision` = 0.04, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
  ui_study_add(app, "proportion", "s1")
  ui_open_module(app, "Means")
  ui_study_add(app, "means", "s1")

  ui_open_studies(app, "s1")
  txt <- ui_studies_text(app)
  expect_match(txt, "3 result\\(s\\) from 2 calculator design\\(s\\)")
  expect_match(txt, "Same in every row")
  expect_match(txt, "References")
  # the proportion design is one table of two rows; d is the column that changed
  expect_equal(app$get_js("document.querySelectorAll('#studies_view table tbody tr').length"), 2)
  expect_true(app$get_js("Array.from(document.querySelectorAll('#studies_view table thead th')).some(function (t) { return t.innerText.trim() === 'd'; })"))

  # Undo right after adding, and Remove from the list
  ui_open_module(app, "Proportions")
  ui_study_add(app, "proportion", "s1")
  app$run_js("document.getElementById('study_undo').click();")
  app$wait_for_idle(800, timeout = 60000)
  ui_open_studies(app, "s1")
  expect_match(ui_studies_text(app), "3 result\\(s\\)")
  app$run_js("document.querySelector('#studies_view .card:last-of-type button.text-danger').click();")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_studies_text(app), "2 result\\(s\\) from 1 calculator design\\(s\\)")
  expect_equal(ui_output_errors(app), 0)

  # a reload keeps it (sessionStorage) and the new session draws it again; only plain JavaScript from here on
  app$run_js("location.reload();")
  Sys.sleep(2)
  app$wait_for_js("window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected() && !!document.getElementById('studies_view')", timeout = 90000)
  app$run_js("document.querySelector('a[data-value=\"Studies\"]').click(); Shiny.setInputValue('studies_pick', 's1');")
  app$wait_for_js("document.getElementById('studies_view').innerText.indexOf('2 result(s) from 1 calculator design(s)') >= 0", timeout = 60000)
  expect_match(ui_studies_text(app), "2 result\\(s\\) from 1 calculator design\\(s\\)")
})

test_that("a new study can be named, and recent calculations are recorded after a change", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_studies(app)
  app$run_js("document.getElementById('studies_new').click();")
  app$wait_for_idle(800, timeout = 60000)
  expect_equal(app$get_value(input = "studies_pick"), "s4")
  app$run_js("var n = document.getElementById('studies_name'); n.value = 'Anaemia survey'; n.dispatchEvent(new Event('change'));")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(app$get_js("Array.from(document.getElementById('studies_pick').options).map(function (o) { return o.text; }).join('|')"), "Anaemia survey \\(0\\)")

  # recent: a change in a calculator, left alone for a few seconds, is recorded once
  ui_open_module(app, "Correlation")
  app$set_inputs(`correlation-r` = 0.25, wait_ = FALSE)
  Sys.sleep(4.5)
  app$wait_for_idle(800, timeout = 60000)
  ui_open_studies(app, "recent")
  txt <- ui_studies_text(app)
  expect_match(txt, "Correlation")
  # and it can be added to the new study from there
  app$run_js("var s = document.querySelector('#studies_view select.study-target'); s.value = 's4'; s.nextElementSibling.click();")
  app$wait_for_idle(800, timeout = 60000)
  ui_open_studies(app, "s4")
  expect_match(ui_studies_text(app), "1 result\\(s\\) from 1 calculator design\\(s\\)")

  # Download (.docx): the file is made in R and saved by the browser
  app$run_js("document.getElementById('studies_download').click();")
  app$wait_for_js("!!window.esStudiesLastFile", timeout = 60000)
  f <- app$get_js("window.esStudiesLastFile")
  expect_match(f$name, "^Anaemia_survey_[0-9]{4}-[0-9]{2}-[0-9]{2}[.]docx$")
  expect_gt(f$size, 5000)
  expect_equal(f$head, "PK")   # a zip archive, as a .docx is
  expect_match(app$get_js("document.getElementById('study_toast').innerText"), "Saved Anaemia_survey_")
  expect_equal(ui_output_errors(app), 0)
})
