# Lazy loading of the calculator modules (start-up time).
# The app has ~65 modules, ~1,500 inputs and a 6 MB page. Building all of that before the first screen made the start slow
# (a few seconds in R, over a minute in the browser build). The calculators' list in the sidebars is always complete, but
# only a few basic calculators (lazy_core_modules) get their UI and server at start-up; the others get a placeholder and are
# loaded
#   - at once when the user opens one (or a Home button / the wizard jumps to it), and
#   - one by one in the background a moment after the first screen, with a progress bar ("Loading calculators 12 of 61").
# Nothing about a module changes: the same ui() is inserted with insertUI() and the same server() started, so a module behaves
# the same whenever it is loaded. `epidemiologicasuite_app(lazy = FALSE)` builds everything up front as before.

# The calculators that are ready at start-up: the first of each workbench plus the commonest basic ones.
lazy_core_modules <- c("proportion", "means", "correlation", "analyze_2x2")

lazy_container_id <- function(id) paste0("lazy_", id)

lazy_placeholder <- function(id) {
  div(id = lazy_container_id(id), p(class = "lazy-note text-muted py-3", "Loading this calculator..."))
}

# Background loading can be switched off for tests and debugging: options(epidemiologicasuite.background_load = FALSE)
# or the environment variable EPIDEMIOLOGICASUITE_BACKGROUND_LOAD=false.
.background_load_enabled <- function() {
  env <- tolower(Sys.getenv("EPIDEMIOLOGICASUITE_BACKGROUND_LOAD", "true"))
  isTRUE(getOption("epidemiologicasuite.background_load", TRUE)) && !identical(env, "false")
}

# Per-session loader. `core_ids` are the modules whose UI and server already exist. Returns functions to load a module by
# id or by title, and to start the one-by-one background loading.
lazy_module_loader <- function(session, registry, core_ids, background = .background_load_enabled(), delay_ms = 1500, step_ms = 120) {
  ids <- vapply(registry, `[[`, character(1), "id")
  titles <- vapply(registry, `[[`, character(1), "title")
  by_id <- setNames(registry, ids)
  state <- new.env()
  state$loaded <- core_ids

  ensure <- function(id) {
    if (length(id) != 1 || is.na(id) || !id %in% ids || id %in% state$loaded) return(invisible(FALSE))
    state$loaded <- c(state$loaded, id)   # marked first, so a second request while this one runs does nothing
    m <- by_id[[id]]
    shiny::withReactiveDomain(session, {
      shiny::insertUI(selector = paste0("#", lazy_container_id(id)), where = "beforeEnd", ui = m$ui(m$id),
                      immediate = TRUE, session = session)
      shiny::removeUI(selector = paste0("#", lazy_container_id(id), " > .lazy-note"), immediate = TRUE, session = session)
      m$server(m$id)
    })
    invisible(TRUE)
  }
  ensure_title <- function(title) ensure(ids[match(title, titles)])

  start_background <- function() {
    if (!background) return(invisible(NULL))
    n_lazy <- length(setdiff(ids, core_ids))
    if (n_lazy == 0) return(invisible(NULL))
    started <- FALSE
    prog <- NULL
    shiny::observe({
      if (!started) {                        # wait for the first screen to be on the page before doing anything
        started <<- TRUE
        shiny::invalidateLater(delay_ms, session)
        return()
      }
      pending <- setdiff(ids, state$loaded)
      if (length(pending) == 0) {
        if (!is.null(prog)) prog$close()
        prog <<- NULL
        return()
      }
      if (is.null(prog)) prog <<- shiny::Progress$new(session, min = 0, max = n_lazy)
      ensure(pending[1])
      done <- n_lazy - length(pending) + 1
      prog$set(value = done, message = "Loading calculators", detail = sprintf("%d of %d", done, n_lazy))
      shiny::invalidateLater(step_ms, session)
    })
    invisible(NULL)
  }

  list(ensure = ensure, ensure_title = ensure_title, start_background = start_background,
       loaded = function() state$loaded)
}
