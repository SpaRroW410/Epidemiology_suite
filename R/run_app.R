# Entry points of the package: builds the navbar shell and wires up modules
# from the registry in registry.R. Adding a new calculator = append to
# module_registry() and to the right module_groups entry; nothing in this
# file needs to change beyond that.

#' Run the sample2result application
#'
#' Starts the sample size / power calculator in the default web browser (or the
#' RStudio viewer). Blocks until the app is stopped.
#'
#' @param ... Passed on to [shiny::runApp()], e.g. `port = 8080`,
#'   `host = "0.0.0.0"` or `launch.browser = FALSE`.
#' @return Does not return while the app is running.
#' @export
run_app <- function(...) {
  shiny::runApp(sample2result_app(), ...)
}

#' Build the sample2result Shiny app object
#'
#' The app object itself, without running it -- for `shiny::runApp()`, for the
#' root `app.R` used during development, and for deployment or testing
#' (e.g. `shiny::testServer()`, shinytest2).
#'
#' @return A [shiny::shinyApp()] object.
#' @export
sample2result_app <- function() {
  registry <- module_registry()
  registry_by_id <- setNames(registry, vapply(registry, `[[`, character(1), "id"))

  # One dropdown (bslib::nav_menu) per module_groups entry, grouping several
  # module tabs under one top-bar label instead of listing all 24 flat -- see
  # registry.R's module_groups comment for why this grouping/order was chosen.
  # nav_select("main_nav", <module title>, ...) (used throughout home_*.R) keeps
  # working unchanged whether a nav_panel sits directly on the navbar or inside
  # a nav_menu dropdown.
  group_menus <- lapply(module_groups, function(g) {
    panels <- lapply(g$module_ids, function(mid) {
      m <- registry_by_id[[mid]]
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
  # bslib::nav_select("main_nav", ...) -- see home_finder.R.
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
    for (m in registry) {
      m$server(m$id)
    }
  }

  shinyApp(ui, server)
}
