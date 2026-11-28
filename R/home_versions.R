# "Three versions: which one should I use?" -- a table comparing the phone / server version, the browser version and the R package
# (docs/archive/to_do_later.md C, 3 Nov 2026). Shown folded on Home and on the Cite tab; the column of the version being used is marked. Facts and their
# sources: docs/hosting.md (where each runs, privacy), R/background.R (simulations), tools/ui-audit/live_timing.js (browser start-up,
# measured 3 Nov 2026 on a desktop: 38.9 s until Home is usable), R/mod_studies.R (Studies storage).

# Addresses of the two hosted versions. The phone address is also in tools/pages/mobile_url.txt (test-home_versions.R checks they agree).
.browser_version_url <- "https://sparrow410.github.io/Epidemiology_suite/app/"
.server_version_url <- "https://sparrow410-epidemiological-suite.share.connect.posit.cloud"

.versions_rows <- list(
  c("Where it runs",
    "On a server (Posit Connect Cloud); your phone or browser only shows the pages",
    "In your browser, on your own device (WebAssembly)",
    "In R on your own computer"),
  c("What you type",
    "Sent to the server to calculate the results; the app does not save it to disk or ask who you are",
    "Stays on your device; nothing is sent anywhere",
    "Stays on your computer"),
  c("Internet",
    "Needed all the time",
    "Needed to open it (about 64 MB the first time)",
    "Only to install it"),
  c("Start-up",
    "A few seconds once the server is awake; longer after it has been idle (not measured here)",
    "About 40 seconds on a desktop computer (measured 3 Nov 2026); too heavy for most phones (about 1 GB of memory)",
    "A few seconds"),
  c("Simulation designs",
    "Run in a background process when you press Calculate, so other users are not held up",
    "Run in the page when you press Calculate; slower",
    "Fastest; run in your R session"),
  c("Suits",
    "Phones and tablets (they are sent here automatically), and any browser",
    "Desktop and laptop browsers",
    "Analysts who use R; scripts and reports"),
  c("Studies (Add to study, Word file)",
    "Kept only in the browser tab; closing the tab loses it",
    "Kept only in the browser tab; closing the tab loses it",
    "Not in R; the calc_*() functions return the results, and run_app() opens the same app"),
  c("How to open it",
    .server_version_url,
    .browser_version_url,
    paste0("install.packages(\"remotes\"); remotes::install_github(\"SpaRroW410/Epidemiology_suite\"); epidemiologysuite::run_app()")),
  c("How to cite it",
    "The same citation for all three (Cite tab): name the version you used",
    "The same citation for all three (Cite tab): name the version you used",
    "citation(\"epidemiologysuite\")")
)

# Which version is running: "server", "browser" or "package"
.current_version <- function() if (is_browser_build()) "browser" else if (is_server_version()) "server" else "package"

versions_table_ui <- function(current = .current_version()) {
  heads <- c(server = "Phone / server version", browser = "Browser version", package = "R package")
  cell <- function(x, col) {
    content <- if (grepl("^https://", x)) tags$a(href = x, target = "_blank", rel = "noopener", x)
               else if (grepl("^(install\\.packages|citation\\()", x)) tags$code(x) else x
    tags$td(class = if (identical(col, current)) "table-primary" else NULL, content)
  }
  div(class = "table-responsive",
    tags$table(class = "table table-sm align-top small mb-2",
      tags$caption(class = "small", sprintf("You are using the %s.", tolower(heads[[current]]))),
      tags$thead(tags$tr(tags$th(scope = "col", ""),
                         lapply(names(heads), function(k) tags$th(scope = "col", class = if (identical(k, current)) "table-primary" else NULL,
                                                                  heads[[k]], if (identical(k, current)) span(class = "badge bg-primary ms-1", "this one"))))),
      tags$tbody(lapply(.versions_rows, function(r) tags$tr(tags$th(scope = "row", r[1]), cell(r[2], "server"), cell(r[3], "browser"), cell(r[4], "package"))))))
}

versions_details_ui <- function() {
  tags$details(class = "mt-3 home-versions",
    tags$summary("Three versions: which one should I use?"),
    div(class = "mt-2", versions_table_ui()))
}
