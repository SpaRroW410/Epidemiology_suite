# Background computation for the Monte Carlo calculators (ROADMAP Phase 6; owner's decision of 31 Oct 2026: the mirai package).
#
# On a shared server (the phone / server version on Connect Cloud, the Docker image) a simulation that takes several seconds would
# otherwise hold up every other user of the same R process. Here the 10 simulation-based calc_*() functions run in separate R
# processes ("daemons", started by mirai when the first one is needed) through shiny::ExtendedTask, so the app stays responsive; the
# Calculate button shows that a calculation is running.
#
# When background computation is not possible the calculation runs in the session, as before: in the browser build (webR cannot start
# processes), when mirai is not installed, when the number of workers is 0 (environment variable EPIDEMIOLOGYSUITE_WORKERS or
# options(epidemiologysuite.workers = 0)), or when the daemons fail to start. Results go through the same cache as memo_calc()
# (memo_cache.R), so a repeat is immediate either way.
#
# mirai is only suggested, and its functions are looked up by name (.mirai()) rather than written as mirai::name: the browser build
# bundles every package it finds written that way, and it cannot use this one.

.bg <- new.env(parent = emptyenv())
.bg$started <- FALSE
.bg$failed <- FALSE
.bg_profile <- "epidemiologysuite"   # mirai compute profile, kept apart from any daemons the user runs for other work
.bg_mirai_pkg <- "mirai"

.mirai <- function(name) getExportedValue(.bg_mirai_pkg, name)

# Number of background R processes: EPIDEMIOLOGYSUITE_WORKERS, else options(epidemiologysuite.workers), else 1.
background_workers <- function() {
  raw <- Sys.getenv("EPIDEMIOLOGYSUITE_WORKERS", "")
  if (!nzchar(raw)) raw <- getOption("epidemiologysuite.workers", 1L)
  n <- suppressWarnings(as.integer(raw))
  if (length(n) != 1 || is.na(n) || n < 0) 1L else n
}

# How a fresh R process gets the calculation functions: the installed package, the development copy (pkgload), or the R/ files the
# Connect bundle sources (their paths are left in options(epidemiologysuite.source_files) by tools/connect/app.R). NULL if none works.
.bg_loader <- function() {
  ns <- environment(memo_calc)
  if (isNamespace(ns)) {
    if (!is.null(ns[[".__DEVTOOLS__"]])) {
      if (!requireNamespace("pkgload", quietly = TRUE)) return(NULL)
      return(list(expr = quote(getExportedValue("pkgload", "load_all")(path, quiet = TRUE, helpers = FALSE, attach_testthat = FALSE)),
                  data = list(path = getNamespaceInfo(ns, "path"))))
    }
    return(list(expr = quote(loadNamespace(pkg)), data = list(pkg = getNamespaceName(ns))))
  }
  files <- getOption("epidemiologysuite.source_files")
  if (is.null(files) || !all(file.exists(files))) return(NULL)
  list(expr = quote(for (f in files) source(f, local = FALSE)), data = list(files = files))
}

background_available <- function() {
  if (isTRUE(.bg$failed) || background_workers() < 1L) return(FALSE)
  if (identical(Sys.info()[["sysname"]], "Emscripten")) return(FALSE)
  if (!requireNamespace(.bg_mirai_pkg, quietly = TRUE)) return(FALSE)
  if (utils::packageVersion("shiny") < "1.8.1" || utils::packageVersion("bslib") < "0.7.0") return(FALSE)
  !is.null(.bg_loader())
}

# Starts the daemons and loads the functions into each, once per R process. FALSE (and no further attempts) if that fails.
.bg_start <- function() {
  if (isTRUE(.bg$started)) return(TRUE)
  if (!background_available()) return(FALSE)
  ok <- tryCatch({
    loader <- .bg_loader()
    .mirai("daemons")(background_workers(), .compute = .bg_profile)
    # the workers search the app's own library paths (a package installed in a user or project library would not be found otherwise)
    .mirai("everywhere")(.libPaths(lib), lib = .libPaths(), .compute = .bg_profile)
    do.call(.mirai("everywhere"), c(list(.expr = loader$expr), loader$data, list(.compute = .bg_profile)))
    # check that a worker really has the functions; otherwise fall back to the session rather than fail every calculation
    probe <- .mirai("mirai")(
      exists("calc_ks_two_sample", envir = if (isNamespaceLoaded(pkg)) asNamespace(pkg) else globalenv(), mode = "function"),
      pkg = "epidemiologysuite", .compute = .bg_profile)
    found <- .mirai("call_mirai")(probe)$data
    if (!isTRUE(found)) stop("the workers could not load the calculation functions")
    TRUE
  }, error = function(e) {
    try(.mirai("daemons")(0, .compute = .bg_profile), silent = TRUE)
    message("epidemiologysuite: background computation not available (", conditionMessage(e), "); calculating in the session.")
    FALSE
  })
  .bg$started <- ok
  .bg$failed <- !ok
  ok
}

# Stops the daemons (tests; the daemons also end with the R process).
background_stop <- function() {
  if (isTRUE(.bg$started)) try(.mirai("daemons")(0, .compute = .bg_profile), silent = TRUE)
  .bg$started <- FALSE
  .bg$failed <- FALSE
  invisible(NULL)
}

# A promise of list(ok = TRUE, value = result) or list(ok = FALSE, message = ...) for one calculation run in a daemon.
.bg_submit <- function(fn_name, args) {
  m <- .mirai("mirai")(
    {
      # mirai's daemons use the L'Ecuyer-CMRG generator; with the app's generator, a seed gives the same result as in the session
      do.call(RNGkind, as.list(rng_kind))
      where <- if (isNamespaceLoaded(pkg)) asNamespace(pkg) else globalenv()
      tryCatch(list(ok = TRUE, value = do.call(get(fn_name, envir = where, mode = "function"), args)),
               error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    },
    fn_name = fn_name, args = args, pkg = "epidemiologysuite", rng_kind = RNGkind(), .compute = .bg_profile
  )
  promises::then(promises::as.promise(m), function(res) {
    if (is.list(res) && !is.null(res$ok)) res
    else list(ok = FALSE, message = paste("The background calculation failed:", paste(format(res), collapse = " ")))
  })
}

# For one module instance (call inside moduleServer()). Returns
#   calc(fn_name, ...)  use in place of memo_calc() inside the module's result reactive: returns a stored result at once, or starts the
#                       calculation in the background and returns a placeholder;
#   result(r)           wraps the module's result reactive `r` (a function returning list(ok, value) or list(ok, message)): while a
#                       background calculation runs its outputs show as recalculating, and the finished result replaces the placeholder;
#   active              whether calculations go to the background.
# `button` is the id of the module's Calculate button (monte_carlo_calculate_ui()), which shows "Calculating..." while one runs.
background_calc <- function(button = "calculate", session = shiny::getDefaultReactiveDomain()) {
  if (identical(Sys.info()[["sysname"]], "Emscripten")) return(.browser_calc(button, session))
  if (!background_available()) {
    return(list(calc = memo_calc, result = function(r) r, active = FALSE))
  }
  state <- new.env(parent = emptyenv())
  state$pending <- NULL
  task <- shiny::ExtendedTask$new(function(fn_name, args, key) {
    promises::then(.bg_submit(fn_name, args), function(res) {
      if (isTRUE(res$ok)) memo_store(key, res$value)
      list(key = key, res = res)
    })
  })
  bslib::bind_task_button(task, button, session = session)

  finished <- function(key) {
    if (!identical(shiny::isolate(task$status()), "success")) return(NULL)
    out <- shiny::isolate(task$result())
    if (identical(out$key, key)) out$res else NULL
  }

  calc <- function(fn_name, ...) {
    args <- list(...)
    key <- .memo_key(fn_name, args)
    hit <- memo_lookup(key)
    if (hit$found) return(hit$value)
    done <- finished(key)
    if (!is.null(done)) {
      if (isTRUE(done$ok)) return(done$value)
      stop(done$message, call. = FALSE)
    }
    if (!.bg_start()) return(memo_calc(fn_name, ...))
    if (!identical(state$pending, key)) {
      state$pending <- key
      task$invoke(fn_name, args, key)
    }
    structure(list(key = key), class = "epidemiologysuite_pending")
  }

  result <- function(r) {
    shiny::reactive({
      res <- r()
      if (!isTRUE(res$ok) || !inherits(res$value, "epidemiologysuite_pending")) return(res)
      status <- task$status()
      if (identical(status, "running")) task$result()   # signals "in progress": the outputs keep their place, greyed out
      if (identical(status, "error")) {
        msg <- tryCatch({ task$result(); "The background calculation failed." }, error = function(e) conditionMessage(e))
        res$value <- NULL
        return(utils::modifyList(res, list(ok = FALSE, message = msg)))
      }
      if (identical(status, "success")) {
        out <- task$result()
        if (identical(out$key, res$value$key)) {
          res$value <- NULL
          return(utils::modifyList(res, out$res))   # keeps a module's own fields (e.g. `design`)
        }
      }
      shiny::req(FALSE)
    })
  }

  list(calc = calc, result = result, active = TRUE)
}

# The browser build (webR) runs R on the page's single thread and cannot start background processes, so a simulation started
# automatically -- when a Monte Carlo calculator is opened or its design is chosen -- would hold up every other calculator for as long
# as it runs (in the browser crawl the GLMM designs held up the next calculator, Trial Sequential Analysis, for over two minutes).
# Here a simulation runs only when Calculate is pressed; until then the result stays empty under the "click Calculate" note, and a
# result already calculated for the same inputs is shown at once.
.browser_calc <- function(button, session) {
  state <- new.env(parent = emptyenv())
  state$used <- 0L
  calc <- function(fn_name, ...) {
    args <- list(...)
    key <- .memo_key(fn_name, args)
    hit <- memo_lookup(key)
    if (hit$found) return(hit$value)
    clicks <- shiny::isolate(session$input[[button]])
    clicks <- if (is.null(clicks)) 0L else as.integer(clicks)
    if (clicks > state$used) {
      state$used <- clicks
      return(memo_calc(fn_name, ...))
    }
    structure(list(key = key), class = "epidemiologysuite_pending")
  }
  result <- function(r) {
    shiny::reactive({
      res <- r()
      if (isTRUE(res$ok) && inherits(res$value, "epidemiologysuite_pending")) shiny::req(FALSE)
      res
    })
  }
  list(calc = calc, result = result, active = FALSE)
}
