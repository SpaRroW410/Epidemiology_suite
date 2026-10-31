# The app also runs in the browser (a Shinylive / WebAssembly build published on GitHub Pages, ROADMAP item 15).
# The installed R package is the complete version; the browser build runs the same code but a few designs need
# compiled packages that have no WebAssembly build (none at present: TOST, Fisher and Boschloo were rewritten in R on
# 31 Oct 2026), and the simulation designs are slower. These helpers tell the user so, and say how to get the full version.

# Single place for the install instructions, so a repository rename touches one line.
.install_instructions <- paste0(
  "install.packages(\"remotes\"); remotes::install_github(\"SpaRroW410/Epidemiology_suite\"); ",
  "epidemiologysuite::run_app()"
)

# TRUE when running inside webR (the browser build).
is_browser_build <- function() identical(Sys.info()[["sysname"]], "Emscripten")

# A one-line notice shown above the app in the browser build only (NULL elsewhere).
browser_notice_ui <- function() {
  if (!is_browser_build()) return(NULL)
  div(
    class = "alert alert-info py-1 px-3 mb-0 rounded-0 small", role = "note",
    strong("Browser version. "),
    "Everything runs on your device and nothing you type is sent anywhere. Simulation designs run when you press Calculate and are ",
    "faster in the installed package. To install it, run in R: ",
    tags$code(.install_instructions)
  )
}

# A function of a large package that only a few calculators use (lme4 for the mixed-model simulations, survival for RMST and the
# weighted log-rank test), looked up by name. Written this way, shinylive does not bundle the package with the browser build's first
# download (it bundles every package written as pkg::fn), and the browser build does not load it at start-up: the first calculation
# that needs it downloads and loads it (webR's webr::install()), which takes a few seconds once. Elsewhere the package is a normal
# dependency and this is getExportedValue().
.pkg_fn <- function(pkg, name) {
  if (!isNamespaceLoaded(pkg) && is_browser_build() && !requireNamespace(pkg, quietly = TRUE)) {
    tryCatch(getExportedValue("webr", "install")(pkg, quiet = TRUE), error = function(e) NULL)
  }
  .require_pkg(pkg, sprintf("This calculation (it uses %s::%s())", pkg, name))
  getExportedValue(pkg, name)
}
