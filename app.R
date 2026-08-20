# Entry point: builds the navbar shell and wires up modules from the registry
# defined in global.R. Adding a new calculator = append to module_registry;
# this file does not need to change.

source("global.R")

nav_panels <- lapply(module_registry, function(m) {
  nav_panel(title = m$title, m$ui(m$id))
})

home_panel <- nav_panel("Home", home_panel_ui())

# do.call() lets us pass a variable-length, dynamically built list of nav
# panels as page_navbar()'s "..." argument -- equivalent to calling
# page_navbar(title = ..., theme = ..., home_panel, nav_panels[[1]], ...)
# but built from the module_registry loop above instead of hardcoded.
# id = "main_nav" lets the Home finder jump to a tab programmatically via
# bslib::nav_select("main_nav", ...) -- see home_finder.R.
ui <- do.call(page_navbar, c(
  list(id = "main_nav", title = "Sample Size Calculator", theme = bs_theme(version = 5)),
  list(home_panel),
  nav_panels
))

server <- function(input, output, session) {
  home_finder_server(input, output, session)
  for (m in module_registry) {
    m$server(m$id)
  }
}

shinyApp(ui, server)
