# Entry point: builds the navbar shell and wires up modules from the registry
# defined in global.R. Adding a new calculator = append to module_registry
# and to the right module_groups entry; this file does not need to change
# beyond that.

source("global.R")

module_registry_by_id <- setNames(module_registry, vapply(module_registry, `[[`, character(1), "id"))

# One dropdown (bslib::nav_menu) per module_groups entry, grouping several
# module tabs under one top-bar label instead of listing all 24 flat -- see
# global.R's module_groups comment for why this grouping/order was chosen.
# nav_select("main_nav", <module title>, ...) (used throughout R/home/) keeps
# working unchanged whether a nav_panel sits directly on the navbar or inside
# a nav_menu dropdown.
group_menus <- lapply(module_groups, function(g) {
  panels <- lapply(g$module_ids, function(mid) {
    m <- module_registry_by_id[[mid]]
    nav_panel(title = m$title, m$ui(m$id))
  })
  do.call(nav_menu, c(list(title = g$title), panels))
})

home_panel <- nav_panel("Home", home_panel_ui())

# do.call() lets us pass a variable-length, dynamically built list of nav
# panels as page_navbar()'s "..." argument -- equivalent to calling
# page_navbar(title = ..., theme = ..., home_panel, group_menus[[1]], ...)
# but built from the module_groups loop above instead of hardcoded.
# id = "main_nav" lets the Home hub jump to a tab programmatically via
# bslib::nav_select("main_nav", ...) -- see R/home/home_finder.R.
ui <- do.call(page_navbar, c(
  list(
    id = "main_nav", title = "Sample Size Calculator",
    theme = bs_theme(
      version = 5,
      bootswatch = "litera",
      base_font = font_google("Source Serif 4"),
      heading_font = font_google("Source Serif 4"),
      "font-size-base" = "0.95rem"
    )
  ),
  list(home_panel),
  group_menus
))

server <- function(input, output, session) {
  home_server(input, output, session)
  for (m in module_registry) {
    m$server(m$id)
  }
}

shinyApp(ui, server)
