# Entry points of the package: builds the navbar shell and wires up modules
# from the registry in registry.R. Adding a new calculator = append to
# module_registry() and to the right group of module_workbenches; nothing in this
# file needs to change beyond that.

#' Run the epidemiologicasuite application
#'
#' Starts the sample size / power calculator in the default web browser (or the
#' RStudio viewer). Blocks until the app is stopped.
#'
#' @param ... Passed on to [shiny::runApp()], e.g. `port = 8080`,
#'   `host = "0.0.0.0"` or `launch.browser = FALSE`.
#' @return Does not return while the app is running.
#' @export
run_app <- function(...) {
  shiny::runApp(epidemiologicasuite_app(), ...)
}

#' Build the epidemiologicasuite Shiny app object
#'
#' The app object itself, without running it -- for `shiny::runApp()`, for the
#' root `app.R` used during development, and for deployment or testing
#' (e.g. `shiny::testServer()`, shinytest2).
#'
#' @param lazy If `TRUE` (the default) only a few basic calculators are built when the app
#'   starts and the others are loaded when opened, and in the background with a progress bar,
#'   which makes the first screen much faster; `FALSE` builds every calculator up front.
#'   The default can be changed with `options(epidemiologicasuite.lazy = FALSE)`.
#' @return A [shiny::shinyApp()] object.
#' @export
epidemiologicasuite_app <- function(lazy = getOption("epidemiologicasuite.lazy", TRUE)) {
  registry <- module_registry()
  registry_by_id <- setNames(registry, vapply(registry, `[[`, character(1), "id"))
  # Modules that exist at start-up; the others are placeholders filled by lazy_module_loader() (lazy_modules.R).
  core_ids <- if (isTRUE(lazy)) intersect(lazy_core_modules, names(registry_by_id)) else names(registry_by_id)

  # One top-navbar item per workbench (module_workbenches in registry.R); inside
  # it a vertical list of modules under one small header per group
  # (bslib::navset_pill_list turns a bare string into a header). bslib dropdowns
  # cannot nest and 15 of them no longer fit one navbar, hence the sidebar.
  # jump_to_module() (registry.R) selects the workbench and then the module, so
  # the Home hub and wizard buttons work whichever workbench a module is in.
  pending_titles <- vapply(registry[!names(registry_by_id) %in% core_ids], `[[`, character(1), "title")
  workbench_panels <- lapply(module_workbenches, function(wb) {
    items <- unlist(lapply(wb$groups, function(g) {
      c(list(g$title), lapply(g$module_ids, function(mid) {
        m <- registry_by_id[[mid]]
        nav_panel(title = m$title, if (m$id %in% core_ids) m$ui(m$id) else lazy_placeholder(m$id))
      }))
    }), recursive = FALSE)
    nav_panel(
      title = wb$title,
      do.call(navset_pill_list, c(
        list(id = wb$nav_id, widths = c(3, 9), well = FALSE),
        items
      ))
    )
  })

  home_panel <- nav_panel("Home", home_panel_ui())

  # do.call() lets us pass a variable-length, dynamically built list of nav
  # panels as page_navbar()'s "..." argument -- equivalent to calling
  # page_navbar(title = ..., theme = ..., home_panel, workbench_panels[[1]], ...)
  # but built from the module_workbenches loop above instead of hardcoded.
  # id = "main_nav" lets the Home hub jump to a workbench programmatically via
  # bslib::nav_select("main_nav", ...) -- see jump_to_module() in registry.R.
  ui <- do.call(page_navbar, c(
    list(
      id = "main_nav", title = "epidemiologicasuite",
      theme = bs_theme(
        version = 5,
        bootswatch = "litera",
        # A local font stack, not bslib::font_google(): that downloads the font when the first page is
        # rendered, so the app could not start without internet (a Shinylive/offline build, a locked-down
        # server). "Source Serif 4" is used if it is installed on the viewer's machine.
        base_font = font_collection("Source Serif 4", "Georgia", "Cambria", "Times New Roman", "serif"),
        heading_font = font_collection("Source Serif 4", "Georgia", "Cambria", "Times New Roman", "serif"),
        "font-size-base" = "0.95rem"
      ),
      header = tagList(browser_notice_ui(), tags$style(HTML(.workbench_css)),
                       if (length(pending_titles)) lazy_sidebar_assets(pending_titles))
    ),
    list(home_panel),
    workbench_panels
  ))

  server <- function(input, output, session) {
    home_server(input, output, session)
    for (m in registry[names(registry_by_id) %in% core_ids]) {
      m$server(m$id)
    }
    if (length(core_ids) < length(registry)) {
      loader <- lazy_module_loader(session, registry, core_ids)
      # jump_to_module() (registry.R) loads a module before selecting it
      session$userData$ensure_module_title <- loader$ensure_title
      # opening a not-yet-loaded calculator from its sidebar loads it at once
      for (wb in module_workbenches) local({
        nav_id <- wb$nav_id
        observeEvent(input[[nav_id]], loader$ensure_title(input[[nav_id]]), ignoreNULL = TRUE)
      })
      # the browser reports each inserted calculator once its inputs are bound; then its server starts
      observeEvent(input$lazy_bound, for (id in input$lazy_bound$ids) loader$start_server(id), ignoreNULL = TRUE)
      loader$start_background()
    }
  }

  app <- shinyApp(ui, server)
  attr(app, "ui_tags") <- ui   # for tests that inspect the page without a browser
  app
}

# Styling for the workbench sidebars: a scrollable, sticky module list whose group
# headers are small caps labels (navset_pill_list renders them as .navbar-brand
# items, which are far too large for a list heading). On phones the list stacks
# above the calculator, so its height is capped.
.workbench_css <- "
.tab-pane > .row > .col-sm-3 > ul.nav-stacked {
  position: sticky; top: 4.5rem; max-height: calc(100vh - 6rem); overflow-y: auto;
  padding-right: .5rem;
  flex-direction: column; flex-wrap: nowrap; /* Bootstrap 5 .nav wraps; a capped height would otherwise make columns */
}
.tab-pane > .row > .col-sm-3 > ul.nav-stacked > li.navbar-brand {
  display: block; margin: .9rem 0 .2rem 0; padding: 0;
  font-size: .72rem; font-weight: 700; letter-spacing: .06em; text-transform: uppercase;
  color: var(--bs-secondary-color, #6c757d);
}
.tab-pane > .row > .col-sm-3 > ul.nav-stacked > li > a { padding: .3rem .6rem; font-size: .9rem; }
@media (max-width: 575.98px) {
  .tab-pane > .row > .col-sm-3 > ul.nav-stacked { position: static; max-height: 40vh; }
}
"
