# Colour-contrast crawl (dev tool, not part of the test suite): opens Home, the Find tab, Cite and every calculator's Calculate,
# Formula / Help and Reference tabs in headless Chrome, in dark mode (default) or light mode, and lists text whose contrast with its
# background is below 3:1. axe-core (tools/ui-audit/a11y.R) checks the WCAG rules; this catches what it skips, such as text on a light
# box that dark mode left light (the problem fixed in #30). Used on PRs #30-#33.
# Usage (from the repository root): Rscript tools/ui-audit/contrast.R [dark|light] [module-id ...]
# Needs shinytest2 and Chrome/Chromium (CHROMOTE_CHROME). Exits with status 1 if anything is below 3:1.
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) && args[1] %in% c("dark", "light")) args[1] else "dark"
only <- setdiff(args, c("dark", "light"))
suppressMessages(pkgload::load_all(".", quiet = TRUE))
setwd("tests/testthat"); source("helper-ui.R"); setwd("../..")
ui_app_dir <- function() normalizePath(".")
js <- paste(readLines("tools/ui-audit/contrast.js"), collapse = "\n")

Sys.setenv(CHROMOTE_CHROME = ui_chrome_path(), EPIDEMIOLOGYSUITE_WORKERS = "0", EPIDEMIOLOGYSUITE_BACKGROUND_LOAD = "false")
args_chrome <- c("--disable-gpu", "--disable-dev-shm-usage")
if (identical(unname(Sys.info()[["effective_user"]]), "root")) args_chrome <- c(args_chrome, "--no-sandbox")
chromote::set_chrome_args(args_chrome)
app <- shinytest2::AppDriver$new(ui_app_dir(), load_timeout = 90000, timeout = 60000, width = 1280, height = 1000)
on.exit(app$stop(), add = TRUE)
app$wait_for_idle(1500)
if (mode == "dark") {
  app$run_js("document.querySelector('bslib-input-dark-mode').shadowRoot.querySelector('button').click()"); Sys.sleep(1.5)
}
cat("theme:", app$get_js("document.documentElement.getAttribute('data-bs-theme')"), "\n")

found <- 0L
check <- function(where) {
  r <- unique(unlist(app$get_js(js)))
  if (length(r)) { found <<- found + length(r); cat("==", where, "\n"); cat(paste0("   ", r), sep = "\n") }
}
if (!length(only)) {
  check("Home")
  ui_select_tab(app, "main_nav", "Find a calculator"); app$wait_for_idle(800)
  for (t in c("Guided questions", "Browse all calculators", "Formulas & LaTeX", "Glossary")) {
    app$run_js(sprintf("var a = document.querySelector('#home_helper a[data-value=\"%s\"]'); if (a) a.click();", t)); Sys.sleep(1)
    app$wait_for_idle(800)
    if (t == "Browse all calculators") { app$run_js("var b = document.querySelector('#home_browse_accordion .accordion-button'); if (b) b.click();"); Sys.sleep(1) }
    check(paste("Find:", t))
  }
  ui_select_tab(app, "main_nav", "Cite"); app$wait_for_idle(800); check("Cite")
}
mods <- module_registry()
if (length(only)) mods <- Filter(function(m) m$id %in% only, mods)
for (m in mods) {
  ui_open_module(app, m$title)
  for (tab in c("Calculate", "Formula / Help", "Reference")) {
    app$run_js(sprintf("Array.from(document.querySelectorAll('a[data-bs-toggle=tab][data-value=\"%s\"]')).filter(function (a) { return a.offsetParent !== null; }).slice(0, 1).forEach(function (a) { a.click(); })", tab))
    Sys.sleep(0.6); app$wait_for_idle(500, timeout = 120000)
    check(paste(m$id, tab))
  }
  app$run_js("Array.from(document.querySelectorAll('a[data-bs-toggle=tab][data-value=\"Calculate\"]')).filter(function (a) { return a.offsetParent !== null; }).forEach(function (a) { a.click(); })")
}
cat(sprintf("%d element(s) below 3:1 (%s mode)\n", found, mode))
quit(status = if (found > 0) 1L else 0L)
