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
