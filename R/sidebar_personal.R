# Favourites and recently used calculators (docs/ui_remap_plan.md, step 5; owner's choices 27 Nov 2026):
# - a short list at the top of each sidebar: "Favourites" and "Recent" (the last 5 opened), each a link that opens the calculator
#   (switching workbench if needed);
# - a star beside each calculator name, shown on hover (always shown when the calculator is a favourite); the star is a separate
#   button next to the link, not inside it;
# - in the filter box (R/sidebar_filter.R) the words "star", "fav", "favourite", "favorite" or the star symbols show only favourites;
# - kept in this browser (localStorage, with try/catch: the page works without it); when the app runs from the R package on the
#   user's own computer (run_app() in an interactive session), also saved to a small file in R's user data folder, so the lists
#   survive clearing the browser or changing browser on that computer. Never on a server (a hosted app would share one file
#   between all its visitors) and never in the browser build (no file system).
.personal_max_recent <- 5L
.personal_max_fav <- 40L

# Saving to a file: only in an interactive R session on the user's own computer, and never in the browser build.
.personal_save_enabled <- function() {
  if (identical(Sys.info()[["sysname"]], "Emscripten")) return(FALSE)
  isTRUE(getOption("epidemiologysuite.save_personal", interactive()))
}
.personal_file <- function() file.path(tools::R_user_dir("epidemiologysuite", "data"), "favourites.txt")

# File format: one calculator title per line, after "fav<TAB>" or "recent<TAB>". Base R only; unknown titles are dropped on reading.
.personal_read <- function(path = .personal_file(), titles = vapply(module_registry(), `[[`, character(1), "title")) {
  out <- list(fav = character(), recent = character())
  if (!file.exists(path)) return(out)
  ln <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8"), error = function(e) character())
  for (kind in c("fav", "recent")) {
    v <- sub(paste0("^", kind, "\t"), "", ln[startsWith(ln, paste0(kind, "\t"))])
    out[[kind]] <- unique(v[v %in% titles])
  }
  out$recent <- utils::head(out$recent, .personal_max_recent)
  out$fav <- utils::head(out$fav, .personal_max_fav)
  out
}
.personal_write <- function(state, path = .personal_file(), titles = vapply(module_registry(), `[[`, character(1), "title")) {
  clean <- function(x, n) utils::head(unique(as.character(unlist(x))[as.character(unlist(x)) %in% titles]), n)
  fav <- clean(state$fav, .personal_max_fav); recent <- clean(state$recent, .personal_max_recent)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(if (length(fav)) paste0("fav\t", fav), if (length(recent)) paste0("recent\t", recent)), path, useBytes = TRUE)
  invisible(list(fav = fav, recent = recent))
}

# Server side: send the saved lists to the page once, then save every change the page reports.
sidebar_personal_server <- function(input, session, save = .personal_save_enabled(), path = .personal_file()) {
  if (!isTRUE(save)) return(invisible(NULL))
  saved <- .personal_read(path)
  session$sendCustomMessage("es_personal_init", saved)
  observeEvent(input$es_personal, {
    tryCatch(.personal_write(input$es_personal, path), error = function(e) NULL)
  }, ignoreInit = TRUE)
  invisible(NULL)
}

sidebar_personal_assets <- function() {
  tagList(
    tags$style(HTML("
.sidebar-personal { font-size: .82rem; margin: 0 0 .6rem 0; }
.sidebar-personal .sp-head { font-size: .72rem; font-weight: 700; letter-spacing: .06em; text-transform: uppercase;
  color: var(--bs-secondary-color, #6c757d); margin-top: .3rem; }
.sidebar-personal a { display: block; padding: .1rem .6rem; }
ul.nav-stacked > li { position: relative; }
ul.nav-stacked > li > .sp-star { position: absolute; right: .2rem; top: .25rem; border: 0; background: none; padding: 0 .25rem;
  color: var(--bs-secondary-color, #6c757d); opacity: 0; line-height: 1.4; }
ul.nav-stacked > li:hover > .sp-star, ul.nav-stacked > li > .sp-star:focus, ul.nav-stacked > li > .sp-star[aria-pressed='true'] { opacity: 1; }
ul.nav-stacked > li > .sp-star[aria-pressed='true'] { color: #b8860b; }
ul.nav-stacked > li > a { padding-right: 1.6rem !important; }
@media (max-width: 575.98px) { .sidebar-personal, ul.nav-stacked > li > .sp-star { display: none; } }
")),
    tags$script(HTML(sprintf("
(function () {
  var KEY = 'es_personal_v1', MAXR = %d, MAXF = %d;
  var STAR_ON = '\\u2605', STAR_OFF = '\\u2606';
  function load() { try { var s = JSON.parse(window.localStorage.getItem(KEY) || '{}'); return { fav: s.fav || [], recent: s.recent || [] }; }
                    catch (e) { return { fav: [], recent: [] }; } }
  var state = load();
  function save(report) {
    try { window.localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
    if (report && window.Shiny && Shiny.setInputValue) Shiny.setInputValue('es_personal', { fav: state.fav, recent: state.recent }, { priority: 'event' });
    render();
  }
  window.esPersonal = { isFav: function (t) { return state.fav.indexOf(t) >= 0; } };
  function links() { return Array.prototype.slice.call(document.querySelectorAll('ul.nav-stacked a[data-value]')); }
  function linkFor(t) { return links().filter(function (a) { return a.getAttribute('data-value') === t; })[0]; }
  function open(t) {
    var a = linkFor(t); if (!a) return;
    var pane = a.closest('.tab-pane'); var tab = pane && document.querySelector('nav.navbar a[data-bs-target=\"#' + pane.id + '\"], nav.navbar a[href=\"#' + pane.id + '\"]');
    if (tab && !tab.classList.contains('active')) { tab.click(); setTimeout(function () { a.click(); }, 150); } else a.click();
  }
  function list(title, items) {
    if (!items.length) return null;
    var d = document.createElement('div');
    var h = document.createElement('div'); h.className = 'sp-head'; h.textContent = title; d.appendChild(h);
    items.forEach(function (t) {
      if (!linkFor(t)) return;
      var l = document.createElement('a'); l.href = '#'; l.textContent = (title === 'Favourites' ? STAR_ON + ' ' : '') + t;
      l.addEventListener('click', function (e) { e.preventDefault(); open(t); });
      d.appendChild(l);
    });
    return d;
  }
  function render() {
    document.querySelectorAll('ul.nav-stacked').forEach(function (ul) {
      var box = ul.parentNode.querySelector('.sidebar-personal');
      if (!box) { box = document.createElement('div'); box.className = 'sidebar-personal'; box.setAttribute('aria-label', 'Favourite and recent calculators');
                  box.setAttribute('role', 'navigation');
                  // before the phone drop-down if it is there: the phone script expects its drop-down right before the list
                  ul.parentNode.insertBefore(box, ul.parentNode.querySelector('.phone-picker') || ul); }
      box.innerHTML = '';
      var f = list('Favourites', state.fav), r = list('Recent', state.recent);
      if (f) box.appendChild(f); if (r) box.appendChild(r);
    });
    links().forEach(function (a) {
      var li = a.parentNode, b = li.querySelector('.sp-star'), t = a.getAttribute('data-value');
      if (!b) {
        b = document.createElement('button'); b.type = 'button'; b.className = 'sp-star';
        b.addEventListener('click', function (e) {
          e.preventDefault(); e.stopPropagation();
          var i = state.fav.indexOf(t);
          if (i >= 0) state.fav.splice(i, 1); else { state.fav.push(t); state.fav = state.fav.slice(0, MAXF); }
          save(true);
          var inp = document.querySelector('.sidebar-filter input'); if (inp && inp.value) inp.dispatchEvent(new Event('input'));
        });
        li.appendChild(b);
      }
      var on = state.fav.indexOf(t) >= 0;
      b.textContent = on ? STAR_ON : STAR_OFF;
      b.setAttribute('aria-pressed', on ? 'true' : 'false');
      b.setAttribute('aria-label', (on ? 'Remove from favourites: ' : 'Add to favourites: ') + t);
      b.title = on ? 'Remove from favourites' : 'Add to favourites';
    });
  }
  // a calculator opened from its sidebar (or by any jump) goes to the top of Recent
  document.addEventListener('shown.bs.tab', function (e) {
    var a = e.target; if (!a || !a.matches || !a.matches('ul.nav-stacked a[data-value]')) return;
    var t = a.getAttribute('data-value');
    state.recent = [t].concat(state.recent.filter(function (x) { return x !== t; })).slice(0, MAXR);
    save(true);
  });
  // lists saved in a file by the R package (on the user's own computer): they win over this browser's copy
  function init(msg) {
    var fav = [].concat(msg.fav || []), recent = [].concat(msg.recent || []);
    if (fav.length || recent.length) { state = { fav: fav, recent: recent }; save(false); }
    else if (state.fav.length || state.recent.length) save(true);
  }
  if (window.Shiny && Shiny.addCustomMessageHandler) Shiny.addCustomMessageHandler('es_personal_init', init);
  document.addEventListener('shiny:connected', render);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', render); else render();
})();
", .personal_max_recent, .personal_max_fav)))
  )
}
