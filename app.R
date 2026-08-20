# Entry point: builds the navbar shell and wires up modules from the registry
# defined in global.R. Adding a new calculator = append to module_registry;
# this file does not need to change.

source("global.R")

nav_panels <- lapply(module_registry, function(m) {
  nav_panel(title = m$title, m$ui(m$id))
})

home_panel <- nav_panel(
  "Home",
  h2("Comprehensive Sample Size Calculator"),
  p(paste(
    "A sample size and power calculator for community medicine,",
    "epidemiology, and clinical research. Each calculator includes a",
    "worked-formula help tab and a reference to its original source."
  )),
  p("Use the tabs above to choose a calculator family.")
)

# do.call() lets us pass a variable-length, dynamically built list of nav
# panels as page_navbar()'s "..." argument -- equivalent to calling
# page_navbar(title = ..., theme = ..., home_panel, nav_panels[[1]], ...)
# but built from the module_registry loop above instead of hardcoded.
ui <- do.call(page_navbar, c(
  list(title = "Sample Size Calculator", theme = bs_theme(version = 5)),
  list(home_panel),
  nav_panels
))

server <- function(input, output, session) {
  for (m in module_registry) {
    m$server(m$id)
  }
}

shinyApp(ui, server)
