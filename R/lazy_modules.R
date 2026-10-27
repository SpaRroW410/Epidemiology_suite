# Lazy loading of the calculator modules (start-up time).
# The app has ~65 modules, ~1,500 inputs and a 6 MB page. Building all of that before the first screen made the start slow
# (a few seconds in R, over a minute in the browser build). The calculators' list in the sidebars is always complete, but
# only a few basic calculators (lazy_core_modules) get their UI and server at start-up; the others get a placeholder and are
# loaded
#   - at once when the user opens one (or a Home button / the wizard jumps to it), and
#   - one by one in the background a moment after the first screen.
# What is loaded and what is left is shown beside the calculator list (lazy_sidebar_assets()): a small animated bar with
# "12 of 61 ready" above the list, calculators still to come drawn faint with a pulsing dot, the one being loaded next with
# a spinner, and a brief tick when one becomes ready.
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

# Module ids in the order the sidebars list them (workbench by workbench, group by group), then any not listed.
.sidebar_order <- function(ids) {
  shown <- unlist(lapply(module_workbenches, function(wb) unlist(lapply(wb$groups, `[[`, "module_ids"))))
  c(intersect(shown, ids), setdiff(ids, shown))
}

# Per-session loader. `core_ids` are the modules whose UI and server already exist. Returns functions to load a module by
# id or by title, and to start the one-by-one background loading.
lazy_module_loader <- function(session, registry, core_ids, background = .background_load_enabled(), delay_ms = 1500, step_ms = 120) {
  reg_ids <- vapply(registry, `[[`, character(1), "id")
  ids <- .sidebar_order(reg_ids)     # background loading follows the sidebars, top to bottom, so the faint entries fill in from the top
  titles <- vapply(registry, `[[`, character(1), "title")[match(ids, reg_ids)]
  by_id <- setNames(registry[match(ids, reg_ids)], ids)
  state <- new.env()
  state$loaded <- core_ids
  n_lazy <- length(setdiff(ids, core_ids))

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
    left <- setdiff(ids, state$loaded)
    session$sendCustomMessage("lazy_progress", list(
      ready = unname(titles[match(id, ids)]), total = n_lazy, done = n_lazy - length(left),
      upcoming = if (length(left)) unname(titles[match(left[1], ids)]) else NULL))
    invisible(TRUE)
  }
  ensure_title <- function(title) ensure(ids[match(title, titles)])

  start_background <- function() {
    if (!background) return(invisible(NULL))
    if (n_lazy == 0) return(invisible(NULL))
    started <- FALSE
    shiny::observe({
      if (!started) {                        # wait for the first screen to be on the page before doing anything
        started <<- TRUE
        shiny::invalidateLater(delay_ms, session)
        return()
      }
      pending <- setdiff(ids, state$loaded)
      if (length(pending) == 0) return()
      ensure(pending[1])
      shiny::invalidateLater(step_ms, session)
    })
    invisible(NULL)
  }

  list(ensure = ensure, ensure_title = ensure_title, start_background = start_background,
       loaded = function() state$loaded)
}

# Styles and script for the loading indicator beside the calculator lists. `pending_titles` are the calculators that are not
# loaded at start-up; they are drawn as "still to come" from the first paint, then the server's "lazy_progress" messages
# mark each one ready. The same bar is put at the top of every workbench's list and disappears when everything is ready.
lazy_sidebar_assets <- function(pending_titles) {
  css <- "
.lazy-box { flex: 0 0 auto; list-style: none; margin: 0 0 .5rem 0; padding: .45rem .6rem .5rem; border-radius: .4rem;
  background: var(--bs-tertiary-bg, #f1f3f5); font-size: .78rem; position: sticky; top: 0; z-index: 2;
  transition: opacity .6s ease, max-height .6s ease, margin .6s ease, padding .6s ease; max-height: 5rem; overflow: hidden; }
.lazy-box.lazy-complete { opacity: 0; max-height: 0; margin: 0; padding-top: 0; padding-bottom: 0; pointer-events: none; }
.lazy-box .lazy-caption { display: flex; justify-content: space-between; color: var(--bs-secondary-color, #6c757d); margin-bottom: .3rem; }
.lazy-box .lazy-track { height: .38rem; border-radius: .2rem; background: var(--bs-border-color, #dee2e6); overflow: hidden; }
.lazy-box .lazy-fill { height: 100%; width: 0; border-radius: .2rem; transition: width .35s ease;
  background: repeating-linear-gradient(45deg, var(--bs-primary, #2c7be5) 0 .5rem, color-mix(in srgb, var(--bs-primary, #2c7be5) 70%, white) .5rem 1rem);
  background-size: 1.41rem 100%; animation: lazy-stripes 0.9s linear infinite; }
.lazy-box .lazy-next { margin-top: .3rem; color: var(--bs-secondary-color, #6c757d); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
ul.nav-stacked a.lazy-pending { opacity: .55; position: relative; }
ul.nav-stacked a.lazy-pending::after { content: ''; position: absolute; right: .55rem; top: 50%; width: .4rem; height: .4rem; margin-top: -.2rem;
  border-radius: 50%; background: var(--bs-secondary-color, #6c757d); animation: lazy-pulse 1.4s ease-in-out infinite; }
ul.nav-stacked a.lazy-pending.lazy-next-up::after { width: .7rem; height: .7rem; margin-top: -.35rem; background: transparent;
  border: 2px solid var(--bs-primary, #2c7be5); border-top-color: transparent; animation: lazy-spin .7s linear infinite; }
ul.nav-stacked a.lazy-flash { position: relative; }
ul.nav-stacked a.lazy-flash::after { content: '\\2713'; position: absolute; right: .5rem; top: 50%; margin-top: -.6rem; font-size: .8rem;
  color: var(--bs-success, #198754); animation: lazy-tick 1.4s ease-out forwards; }
.lazy-note::before { content: ''; display: inline-block; width: .8rem; height: .8rem; margin-right: .5rem; vertical-align: -.1rem;
  border: 2px solid var(--bs-primary, #2c7be5); border-top-color: transparent; border-radius: 50%; animation: lazy-spin .7s linear infinite; }
@keyframes lazy-stripes { to { background-position: 1.41rem 0; } }
@keyframes lazy-pulse { 0%, 100% { opacity: .25; transform: scale(.8); } 50% { opacity: .9; transform: scale(1.1); } }
@keyframes lazy-spin { to { transform: rotate(360deg); } }
@keyframes lazy-tick { 0% { opacity: 0; } 15% { opacity: 1; } 75% { opacity: 1; } 100% { opacity: 0; } }
@media (prefers-reduced-motion: reduce) {
  .lazy-box .lazy-fill, ul.nav-stacked a.lazy-pending::after, .lazy-note::before { animation: none; }
}
"
  js <- sprintf("
(function () {
  var pending = %s, total = pending.length, done = 0, upcoming = null;
  function links(title) {
    return Array.prototype.filter.call(document.querySelectorAll('ul.nav-stacked a[data-value]'),
      function (a) { return a.getAttribute('data-value') === title; });
  }
  function boxes() { return document.querySelectorAll('.lazy-box'); }
  function paint() {
    Array.prototype.forEach.call(boxes(), function (b) {
      b.querySelector('.lazy-fill').style.width = (total ? 100 * done / total : 100) + '%%';
      b.querySelector('.lazy-count').textContent = done + ' of ' + total + ' ready';
      b.querySelector('.lazy-next').textContent = upcoming ? 'Next: ' + upcoming : '';
      if (done >= total) b.classList.add('lazy-complete');
    });
    document.querySelectorAll('a.lazy-next-up').forEach(function (a) { a.classList.remove('lazy-next-up'); });
    if (upcoming) links(upcoming).forEach(function (a) { a.classList.add('lazy-next-up'); });
  }
  function setup() {
    pending.forEach(function (t) { links(t).forEach(function (a) { a.classList.add('lazy-pending'); }); });
    document.querySelectorAll('ul.nav-stacked').forEach(function (ul) {
      if (ul.querySelector('.lazy-box')) return;
      var li = document.createElement('li');
      li.className = 'lazy-box'; li.setAttribute('role', 'status'); li.setAttribute('aria-live', 'polite');
      li.innerHTML = '<div class=\"lazy-caption\"><span>Loading calculators</span><span class=\"lazy-count\"></span></div>' +
        '<div class=\"lazy-track\"><div class=\"lazy-fill\"></div></div><div class=\"lazy-next\"></div>';
      ul.insertBefore(li, ul.firstChild);
    });
    paint();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', setup); else setup();
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('lazy_progress', function (m) {
      done = m.done; total = m.total; upcoming = m.upcoming || null;
      links(m.ready).forEach(function (a) {
        a.classList.remove('lazy-pending', 'lazy-next-up'); a.classList.add('lazy-flash');
        setTimeout(function () { a.classList.remove('lazy-flash'); }, 1500);
      });
      paint();
    });
  }
})();", .json_strings(pending_titles))
  tagList(tags$style(HTML(css)), tags$script(HTML(js)))
}

# A JSON array of strings (no jsonlite dependency for this).
.json_strings <- function(x) {
  esc <- gsub("\\\\", "\\\\\\\\", unname(x))
  esc <- gsub("\"", "\\\\\"", esc, fixed = FALSE)
  paste0("[", paste0("\"", esc, "\"", collapse = ","), "]")
}
