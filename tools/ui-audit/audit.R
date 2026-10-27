# UI audit (dev tool, not part of the test suite): opens every calculator at a desktop and a phone width in headless Chrome and
# reports layout problems a person would notice: horizontal page scroll, content wider than the window, small scroll windows
# inside the page, clipped inputs/buttons, Shiny output errors, R errors in the app log and JavaScript console errors.
# Usage (from the repository root): Rscript tools/ui-audit/audit.R <output-dir> [module-id ...]
# Needs shinytest2 and Chrome/Chromium (CHROMOTE_CHROME). Writes issues.csv and screenshots of the flagged calculators.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "ui-audit-output"
only <- if (length(args) > 1) args[-1] else NULL
dir.create(out, showWarnings = FALSE, recursive = TRUE)
suppressMessages(pkgload::load_all(".", quiet = TRUE))
setwd("tests/testthat"); source("helper-ui.R"); setwd("../..")
ui_app_dir <- function() normalizePath(".")     # the repository root (it holds app.R)

probe_js <- "
(function () {
  var W = window.innerWidth, H = window.innerHeight, res = {hscroll: false, wide: [], scrollers: [], clipped: [], tiny: []};
  res.hscroll = document.documentElement.scrollWidth > W + 1;
  var visible = function (e) { var r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && e.offsetParent !== null; };
  var desc = function (e) { return e.tagName.toLowerCase() + (e.id ? '#' + e.id : '') + (e.className && typeof e.className === 'string' ? '.' + e.className.trim().split(/\\s+/).slice(0, 2).join('.') : ''); };
  var pane = document.querySelector('.tab-pane.active .tab-pane.active') || document.body;
  pane.querySelectorAll('*').forEach(function (e) {
    if (!visible(e)) return;
    var r = e.getBoundingClientRect(), cs = getComputedStyle(e);
    if (r.right > W + 2 && cs.position !== 'fixed' && !e.closest('.nav-tabs, .navbar, pre, .table-responsive, .shiny-text-output, table, .MathJax_Display, .MathJax, .formula-block, mjx-container')) res.wide.push(desc(e) + ' right=' + Math.round(r.right));
    if ((cs.overflowY === 'auto' || cs.overflowY === 'scroll') && e.scrollHeight > e.clientHeight + 24 && e.clientHeight > 0 &&
        !e.matches('textarea, pre, ul.nav-stacked, .shiny-text-output, html, body, select, .selectize-dropdown-content'))
      res.scrollers.push(desc(e) + ' client=' + e.clientHeight + ' scroll=' + e.scrollHeight);
    if (e.matches('input[type=text], input[type=number], textarea, select, button, .btn') && e.scrollWidth > e.clientWidth + 3 && cs.overflowX !== 'visible')
      res.clipped.push(desc(e) + ' client=' + e.clientWidth + ' scroll=' + e.scrollWidth);
    if (e.matches('textarea') && (r.width < 200 || r.height < 50)) res.tiny.push(desc(e) + ' ' + Math.round(r.width) + 'x' + Math.round(r.height));
  });
  ['wide', 'scrollers', 'clipped', 'tiny'].forEach(function (k) { res[k] = res[k].slice(0, 6); });
  return JSON.stringify(res);
})()"

audit_size <- function(width, height, label) {
  app <- ui_fresh_driver(background_load = FALSE, name = paste0("audit_", label), width = width, height = height)
  on.exit(app$stop())
  rows <- list(); seen_r_errors <- 0
  # Home first
  for (m in c(list(list(id = "home", title = "Home")), module_registry())) {
    if (!is.null(only) && m$id != "home" && !(m$id %in% only)) next
    err <- tryCatch({
      if (m$id == "home") { ui_select_tab(app, "main_nav", "Home"); app$wait_for_idle(500, timeout = 60000) } else ui_open_module(app, m$title)
      NULL
    }, error = function(e) conditionMessage(e))
    p <- tryCatch(jsonlite::fromJSON(app$get_js(probe_js)), error = function(e) NULL)
    logs <- app$get_logs(); r <- logs[logs$location == "shiny", "message", drop = TRUE]
    new_r <- sum(grepl("^(Warning: )?Error", r)) - seen_r_errors; seen_r_errors <- sum(grepl("^(Warning: )?Error", r))
    out_err <- tryCatch(ui_output_errors(app), error = function(e) NA)
    rows[[length(rows) + 1]] <- data.frame(size = label, module = m$id, open_error = if (is.null(err)) "" else err,
      hscroll = isTRUE(p$hscroll), wide = paste(p$wide, collapse = " | "), scrollers = paste(p$scrollers, collapse = " | "),
      clipped = paste(p$clipped, collapse = " | "), tiny_textarea = paste(p$tiny, collapse = " | "),
      output_errors = out_err, new_r_errors = new_r, stringsAsFactors = FALSE)
    flagged <- !is.null(err) || isTRUE(p$hscroll) || length(p$wide) || length(p$scrollers) || length(p$clipped) || length(p$tiny) || isTRUE(out_err > 0) || new_r > 0
    if (flagged) try(app$get_screenshot(file.path(out, sprintf("%s_%s.png", label, m$id))), silent = TRUE)
    cat(sprintf("[%s] %-24s %s\n", label, m$id, if (flagged) "FLAGGED" else "ok"))
  }
  js <- ui_console_errors(app)
  list(rows = do.call(rbind, rows), console = js)
}

res <- list(audit_size(1366, 800, "desktop"), audit_size(390, 800, "phone"))
issues <- do.call(rbind, lapply(res, `[[`, "rows"))
utils::write.csv(issues, file.path(out, "issues.csv"), row.names = FALSE)
cat("\n== console / R errors ==\n"); for (r in res) print(unique(r$console))
bad <- issues[issues$open_error != "" | issues$hscroll | issues$wide != "" | issues$scrollers != "" | issues$clipped != "" |
              issues$tiny_textarea != "" | (!is.na(issues$output_errors) & issues$output_errors > 0) | issues$new_r_errors > 0, ]
cat(sprintf("\n%d of %d checks flagged\n", nrow(bad), nrow(issues)))
if (nrow(bad)) print(bad[, c("size", "module", "hscroll", "wide", "scrollers", "clipped", "tiny_textarea", "output_errors", "new_r_errors", "open_error")], right = FALSE)
