# Accessibility audit (dev tool, not part of the test suite): opens every calculator in headless Chrome and runs axe-core
# (WCAG 2.0/2.1 A and AA rules) on the visible page, then lists the rule violations per calculator.
# Usage (from the repository root): AXE_JS=/path/to/axe.min.js Rscript tools/ui-audit/a11y.R <output-dir> [module-id ... | extras]
# "extras" also scans the screens that are not calculators (4 Nov 2026): the Find tab (guide, browse, glossary), the guide's choice of
# designs and its last step, the Studies tab with a result in it, Cite, the Effect Size page with the "Use this value" panel, and the
# server-version notice (the app is started with EPIDEMIOLOGYSUITE_SERVER_VERSION=true for the audit).
# Get axe-core with `npm i axe-core` (node_modules/axe-core/axe.min.js). Needs shinytest2 and Chrome/Chromium (CHROMOTE_CHROME).
# axe finds what a machine can find (names, roles, contrast, structure); it cannot judge reading order or whether the text makes
# sense to a screen-reader user, so a clean run is not a full WCAG pass.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "a11y-output"
only <- if (length(args) > 1) args[-1] else NULL
extras <- is.null(only) || "extras" %in% only
if (extras) Sys.setenv(EPIDEMIOLOGYSUITE_SERVER_VERSION = "true")
axe_js <- Sys.getenv("AXE_JS"); if (!nzchar(axe_js) || !file.exists(axe_js)) stop("set AXE_JS to the path of axe.min.js")
dark <- identical(Sys.getenv("A11Y_DARK"), "true")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
suppressMessages(pkgload::load_all(".", quiet = TRUE))
setwd("tests/testthat"); source("helper-ui.R"); setwd("../..")
ui_app_dir <- function() normalizePath(".")

run_axe <- "
(function () {
  var done = window.__axe_done = null;
  axe.run(document, {runOnly: {type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']}, resultTypes: ['violations']})
    .then(function (r) { window.__axe_done = JSON.stringify(r.violations.map(function (v) {
      return {id: v.id, impact: v.impact, help: v.help, n: v.nodes.length,
              sample: v.nodes.slice(0, 3).map(function (n) { return n.target.join(' ') + ' :: ' + (n.failureSummary || '').split('\\n').slice(1, 2).join(''); })}; })); })
    .catch(function (e) { window.__axe_done = JSON.stringify({error: String(e)}); });
  return 'started';
})()"

audit <- function(width, label) {
  app <- ui_fresh_driver(background_load = FALSE, name = paste0("a11y_", label), width = width, height = 900)
  on.exit(app$stop())
  app$run_js(paste(readLines(axe_js, warn = FALSE), collapse = "\n"))
  if (dark) app$run_js("document.documentElement.setAttribute('data-bs-theme', 'dark')")
  rows <- list()
  extra_pages <- if (extras) list(
    list(id = "find_guide", title = NULL, go = function() { app$run_js("document.getElementById('home_go_wizard').click()"); Sys.sleep(1.5) }),
    list(id = "guide_choices", title = NULL, go = function() {
      app$set_inputs(design_wizard_freetext = "determinants of smoking in youth of a city"); app$click("design_wizard_parse") }),
    list(id = "guide_last_step", title = NULL, go = function() app$click("design_wizard_rq_survey")),
    list(id = "find_browse", title = NULL, go = function() app$run_js("document.querySelector('#home_helper a[data-value=\"Browse all calculators\"]').click()")),
    list(id = "find_glossary", title = NULL, go = function() app$run_js("document.querySelector('#home_helper a[data-value=\"Glossary\"]').click()")),
    list(id = "studies", title = NULL, go = function() {
      ui_open_module(app, "Proportions"); app$run_js("document.getElementById('proportion-study_target').nextElementSibling.click();")
      app$wait_for_idle(800, timeout = 60000); ui_select_tab(app, "main_nav", "Studies") }),
    list(id = "cite", title = NULL, go = function() ui_select_tab(app, "main_nav", "Cite")),
    list(id = "use_value_panel", title = NULL, go = function() {
      ui_open_module(app, "Nonparametric Tests"); app$run_js("var e = document.getElementById('nonparametric-es_f_kw'); if (e) e.click();") })
  ) else list()
  for (m in c(list(list(id = "home", title = "Home")), module_registry(), extra_pages)) {
    if (!is.null(only) && m$id != "home" && !(m$id %in% only) && !(extras && is.function(m$go))) next
    err <- tryCatch({
      if (is.function(m$go)) { ui_select_tab(app, "main_nav", "Home"); app$wait_for_idle(300, timeout = 60000); if (startsWith(m$id, "guide_") || startsWith(m$id, "find_")) ui_select_tab(app, "main_nav", "Find a calculator"); m$go(); app$wait_for_idle(800, timeout = 60000) }
      else if (m$id == "home") { ui_select_tab(app, "main_nav", "Home"); app$wait_for_idle(500, timeout = 60000) } else ui_open_module(app, m$title)
      NULL
    }, error = function(e) conditionMessage(e))
    app$run_js(run_axe)
    v <- NULL
    for (i in 1:40) { Sys.sleep(0.25); r <- app$get_js("window.__axe_done"); if (!is.null(r)) { v <- jsonlite::fromJSON(r, simplifyVector = FALSE); break } }
    for (x in v) rows[[length(rows) + 1]] <- data.frame(size = label, module = m$id, rule = x$id, impact = x$impact %||% "", nodes = x$n,
      help = x$help, sample = paste(unlist(x$sample), collapse = " || "), stringsAsFactors = FALSE)
    cat(sprintf("[%s] %-24s %s\n", label, m$id, if (!is.null(err)) paste("OPEN ERROR:", err) else if (length(v)) paste(length(v), "rule(s):", paste(vapply(v, `[[`, "", "id"), collapse = ", ")) else "ok"))
  }
  if (length(rows)) do.call(rbind, rows) else data.frame()
}
`%||%` <- function(a, b) if (is.null(a)) b else a
res <- rbind(audit(1366, "desktop"), audit(390, "phone"))
utils::write.csv(res, file.path(out, "a11y.csv"), row.names = FALSE)
cat("\n== violations by rule (distinct modules) ==\n")
if (nrow(res)) print(aggregate(module ~ rule + impact + help, res, function(x) length(unique(x))), right = FALSE) else cat("none\n")
