# Browser-driven UI tests, every design of every module (slow lane, S2R_SLOW_TESTS=true) (split from test-ui_smoke.R on 4 Nov 2026 so that a failure points to one area; helpers in
# helper-ui.R; each file starts its own app).

registry <- module_registry()

.ui_primary_radio <- function(app, id) {
  for (g in c("design", "outcome", "mode", "es_type")) {
    vals <- app$get_js(sprintf(
      "Array.from(document.querySelectorAll('input[type=radio]')).filter(function(e){return e.name === %s;}).map(function(e){return e.value;})",
      ui_js_string(paste0(id, "-", g))))
    if (length(vals)) return(list(group = g, values = unlist(vals)))
  }
  NULL
}

# Its own app, not the shared ui_driver(): this file switches every calculator to each of its designs and leaves it on the
# last one, and the shared app is reused by the files that run after it (test-ui_planning.R, test-ui_studies.R, ...), which
# expect each calculator's default design. Sharing it made those fail in every weekly slow run (16 and 23 Nov 2026).
.every_design_app <- local({
  app <- NULL
  function() {
    if (is.null(app)) {
      app <<- ui_fresh_driver(name = "every-design")
      withr::defer({ app$stop(); app <<- NULL }, envir = testthat::teardown_env())
      app$wait_for_idle(800, timeout = 120000)
    }
    try(app$get_chromote_session()$Page$bringToFront(), silent = TRUE)
    app
  }
})

for (m in registry) {
  local({
    m <- m
    test_that(sprintf("UI (every design): module '%s' renders each design without output errors", m$id), {
      skip_if_not_slow()
      skip_if_no_ui()
      app <- .every_design_app()
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

# --- lazy loading of the calculators (start-up time) -------------------------
