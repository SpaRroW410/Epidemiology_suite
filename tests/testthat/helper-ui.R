# Helpers for the browser-driven UI smoke tests (test-ui_smoke.R, ROADMAP item 12).
# They need shinytest2, a Chrome/Chromium and the repository checkout (the root
# app.R is the app under test), so every test using them skips when any is
# missing -- including under R CMD check, where the installed package has no app.R.

ui_app_dir <- function() normalizePath(file.path("..", ".."), mustWork = FALSE)

skip_if_no_ui <- function() {
  testthat::skip_if_not_installed("shinytest2")
  testthat::skip_if_not_installed("chromote")
  testthat::skip_on_cran()
  testthat::skip_if(identical(tolower(Sys.getenv("S2R_SKIP_UI")), "true"), "S2R_SKIP_UI=true")
  testthat::skip_if_not(file.exists(file.path(ui_app_dir(), "app.R")),
                        "no root app.R (not running from a repository checkout)")
  testthat::skip_if(is.null(ui_chrome_path()), "no Chrome/Chromium found")
}

ui_chrome_path <- function() {
  p <- Sys.getenv("CHROMOTE_CHROME")
  if (nzchar(p)) return(p)
  if (file.exists("/opt/pw-browsers/chromium")) return("/opt/pw-browsers/chromium")
  tryCatch(suppressWarnings(suppressMessages(chromote::find_chrome())), error = function(e) NULL)
}

# One AppDriver for the whole test file: starting the app is the slow part
# (~20 s), switching tabs is about a second.
ui_driver <- local({
  app <- NULL
  function() {
    if (is.null(app)) {
      Sys.setenv(CHROMOTE_CHROME = ui_chrome_path())
      args <- c("--disable-gpu", "--disable-dev-shm-usage")
      # Chrome refuses to start as root (containers, some CI) without this.
      if (identical(unname(Sys.info()[["effective_user"]]), "root")) args <- c(args, "--no-sandbox")
      chromote::set_chrome_args(args)
      app <<- shinytest2::AppDriver$new(ui_app_dir(), name = "smoke", load_timeout = 90000,
                                        timeout = 30000, view = FALSE)
      withr::defer(app$stop(), envir = testthat::teardown_env())
    }
    app
  }
})

ui_js_string <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE))

# JS expression for the first element matching `selector` whose data-value is
# exactly `value`. Comparing in JS instead of building an attribute selector keeps
# titles containing quotes ("Hotelling's") from breaking the generated script --
# which run_js() would swallow silently.
ui_js_by_data_value <- function(selector, value) {
  sprintf("Array.from(document.querySelectorAll(%s)).find(function(e){return e.getAttribute('data-value') === %s;})",
          ui_js_string(selector), ui_js_string(value))
}

ui_open_module <- function(app, title) {
  app$run_js(sprintf("%s.click()", ui_js_by_data_value("a[data-bs-toggle=tab][data-value]", title)))
  # Wait for the navbar input to reach the server, then for the server to go idle:
  # idle alone can be observed in the gap before the new tab's outputs start.
  app$wait_for_js(sprintf("Shiny.shinyapp.$inputValues['main_nav'] === %s", ui_js_string(title)),
                  timeout = 60000)
  app$wait_for_idle(800, timeout = 120000)
}

# Is the module's own top-level navbar pane on screen?
ui_pane_visible <- function(app, title) {
  app$get_js(sprintf("(function(){var p=%s; return !!p && p.offsetParent !== null;})()",
                     ui_js_by_data_value(".tab-pane[data-value]", title)))
}

# Choose a value of a radio group (by input name) as a user would.
ui_choose_radio <- function(app, name, value) {
  app$run_js(sprintf(
    "(function(){var e=Array.from(document.querySelectorAll('input[type=radio]')).find(function(e){return e.name === %s && e.value === %s;}); e.click();})()",
    ui_js_string(name), ui_js_string(value)))
}

# Number of outputs currently showing a Shiny error in the whole page.
ui_output_errors <- function(app) {
  app$get_js("document.querySelectorAll('.shiny-output-error').length")
}

# Trimmed text of an output, or NA if the page has no such element.
ui_output_text <- function(app, id) {
  txt <- app$get_js(sprintf(
    "(function(){var e=document.getElementById(%s); return e ? e.innerText : null;})()",
    ui_js_string(id)))
  if (is.null(txt)) NA_character_ else trimws(txt)
}

# Page-level JavaScript errors (browser console) and unhandled R errors in the app
# process. Failed *resource* loads (web fonts, MathJax CDN) are ignored because the
# sandbox/CI may be offline; R startup chatter (package loading messages, shiny's
# own notices) is not an error.
ui_console_errors <- function(app) {
  logs <- app$get_logs()
  js <- logs[logs$location == "chromote" & logs$level == "error", "message", drop = TRUE]
  js <- js[!grepl("Failed to load resource|ERR_|net::|fonts\\.(googleapis|gstatic)|mathjax", js, ignore.case = TRUE)]
  r <- logs[logs$location == "shiny", "message", drop = TRUE]
  r <- r[grepl("^(Error|Warning: Error)", r)]
  c(js, r)
}
