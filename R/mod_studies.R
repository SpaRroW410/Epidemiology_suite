# Studies (decisions S1-S5 of 3 Nov 2026, ROADMAP §10): a working record of calculations, kept in the browser tab only.
#
# While working, the user adds results to a study ("Add to [Study 1 v] Add" under every result); the Studies tab shows each study
# with repeated uses of one calculator and design as one table, and a list of recent calculations recorded automatically. Nothing is
# calculated again: an entry is the result as it was shown, with its inputs, warnings, formula, justification paragraph and citation.
#
# Where the data lives (S1): in the browser tab's sessionStorage, which is the single copy. The server sends a new entry to the page
# (custom messages "study_add" and "study_recent"); the page stores it and sends the whole record back as input$studies_state, from
# which this file draws the Studies tab. After a reload, or when a phone wakes and the server version has dropped the connection, the
# page sends the stored record to the new session. Closing the tab loses it. Nothing is written on the server.
#
# This file: the entry builder, the grouping into tables, the Studies tab (UI and server), the "Add to study" row used by
# export_controls_ui(), and the page script (studies_assets()). Phase S-2 adds the Word file.

.study_max <- 10L      # studies (S4: three to start, more on request; a soft limit keeps the page light)
.recent_max <- 20L     # recent calculations kept (S3)
.recent_delay_ms <- 3000L   # a result is recorded as "recent" once it has stayed the same this long

# --- entries ---------------------------------------------------------------------------------------------------------------

.study_fmt <- function(v) {
  if (is.null(v) || length(v) == 0 || is.list(v)) return(NULL)
  if (is.numeric(v) && all(is.na(v))) return(NULL)
  .ss_result_fmt_value(v)
}
.study_fmt_list <- function(x) {
  if (!is.list(x) || is.null(names(x))) return(list())
  out <- lapply(x, .study_fmt)
  out[!vapply(out, is.null, logical(1))]
}

#' One study entry from a calculator's result (a plain list, sent to the page as JSON)
#'
#' @param module_id,module_title The calculator (registry id and title).
#' @param value The `ss_result` shown.
#' @param content The design's content entry: `list(title, formula_latex, citation, backend, ...)`.
#' @return list(module, module_title, design, inputs, results, headline, notes, formula_latex, citation, backend, justification, time,
#'   version, key); `inputs` and `results` are named lists of formatted strings, `key` identifies the same calculation.
#' @noRd
study_entry <- function(module_id, module_title, value, content) {
  stopifnot(is.list(value))
  nms <- setdiff(names(value), c("inputs", "precision_notes", "notes", "interpretation"))
  results <- .study_fmt_list(value[nms])
  headline <- Filter(.ss_result_is_headline, names(results))
  if (length(headline) == 0) headline <- utils::head(names(results), 3)
  inputs <- .study_fmt_list(value$inputs)
  notes <- c(value$precision_notes, value$notes)
  notes <- as.character(notes[nzchar(notes)])
  justification <- tryCatch(format_justification(content$title, value, content$citation, content$backend), error = function(e) "")
  key <- paste(module_id, content$title, paste(names(inputs), unlist(inputs), sep = "=", collapse = ";"),
               paste(headline, unlist(results[headline]), sep = "=", collapse = ";"), sep = "|")
  list(module = module_id, module_title = module_title, design = as.character(content$title),
       inputs = inputs, results = results, headline = as.list(headline), notes = as.list(notes),
       formula_latex = if (is.null(content$formula_latex)) "" else as.character(content$formula_latex),
       citation = if (is.null(content$citation)) "" else as.character(content$citation),
       backend = if (is.null(content$backend)) "" else as.character(content$backend),
       justification = justification, time = format(Sys.time(), "%Y-%m-%d %H:%M"), version = .release_label, key = key)
}

# A short line for messages and lists: "Proportions -- Single proportion: n = 323"
study_entry_summary <- function(e) {
  h <- unlist(e$headline)
  res <- if (length(h)) paste(sprintf("%s = %s", h, unlist(e$results[h])), collapse = ", ") else ""
  paste0(e$module_title, " -- ", e$design, if (nzchar(res)) paste0(": ", res) else "")
}

# --- the record sent back by the page --------------------------------------------------------------------------------------

.study_id_ok <- function(x) is.character(x) && length(x) == 1 && grepl("^[A-Za-z0-9_-]{1,40}$", x)

# input$studies_state as list(studies = list(list(id, name, entries)), recent = list(entries)); anything malformed is dropped
studies_normalize <- function(state) {
  blank <- list(studies = lapply(1:3, function(i) list(id = paste0("s", i), name = paste("Study", i), entries = list())), recent = list())
  if (!is.list(state) || !is.list(state$studies)) return(blank)
  fix_entries <- function(es) {
    if (!is.list(es)) return(list())
    Filter(function(e) is.list(e) && .study_id_ok(e$id) && is.character(e$module_title) && is.character(e$design), es)
  }
  studies <- Filter(function(s) is.list(s) && .study_id_ok(s$id), state$studies)
  studies <- lapply(studies, function(s) list(id = s$id, name = if (is.character(s$name) && length(s$name) == 1) s$name else s$id,
                                              entries = fix_entries(s$entries)))
  if (length(studies) == 0) studies <- blank$studies
  list(studies = studies, recent = fix_entries(state$recent))
}

# --- grouping: one table per calculator and design -------------------------------------------------------------------------

# Entries grouped by calculator and design, in the order each group was first added.
study_groups <- function(entries) {
  if (length(entries) == 0) return(list())
  keys <- vapply(entries, function(e) paste(e$module, e$design, sep = "\r"), character(1))
  lapply(unique(keys), function(k) entries[keys == k])
}

# For a group of two or more entries: the inputs that are the same in all (listed once) and a table of the rest.
# Returns list(constant = named character, table = data.frame with a column per varying input and per headline result).
study_table <- function(group) {
  ins <- lapply(group, function(e) unlist(e$inputs))
  all_inputs <- unique(unlist(lapply(ins, names)))
  val <- function(x, nm) if (nm %in% names(x)) unname(x[[nm]]) else ""
  varies <- vapply(all_inputs, function(nm) length(unique(vapply(ins, val, character(1), nm = nm))) > 1, logical(1))
  constant <- if (length(all_inputs)) vapply(all_inputs[!varies], function(nm) val(ins[[1]], nm), character(1)) else character()
  heads <- unique(unlist(lapply(group, function(e) unlist(e$headline))))
  cols <- list(`#` = as.character(seq_along(group)))
  for (nm in all_inputs[varies]) cols[[nm]] <- vapply(ins, val, character(1), nm = nm)
  for (nm in heads) cols[[nm]] <- vapply(group, function(e) val(unlist(e$results), nm), character(1))
  list(constant = constant, table = as.data.frame(cols, check.names = FALSE, stringsAsFactors = FALSE))
}

# --- the Studies tab ---------------------------------------------------------------------------------------------------------

studies_ui <- function() {
  div(class = "container-fluid py-3", style = "max-width: 70rem;",
    h3("Studies"),
    p(class = "text-muted",
      "Collect results while you work: under every result, choose a study and press Add. Using the same calculator again in a study ",
      "makes a table. Recent calculations are recorded here by themselves."),
    div(class = "alert alert-warning py-2 small", role = "note",
        strong("Kept only in this browser tab. "), "A reload keeps it; closing the tab loses it. Nothing is saved on a server."),
    div(class = "d-flex flex-wrap gap-2 align-items-end mb-2",
      div(style = "min-width: 16rem;",
          selectInput("studies_pick", "Show", choices = c("Study 1" = "s1", "Study 2" = "s2", "Study 3" = "s3", "Recent calculations" = "recent"))),
      tags$button(type = "button", class = "btn btn-outline-primary mb-3", id = "studies_new", onclick = "window.esStudies && esStudies.addStudy();",
                  "+ New study")),
    uiOutput("studies_view")
  )
}

# a JavaScript string literal (JSON-style quoting) without a package dependency
.study_js_str <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x); x <- gsub("\"", "\\\\\"", x); x <- gsub("\n", "\\\\n", x); x <- gsub("<", "\\\\u003c", x)
  paste0("\"", x, "\"")
}

.study_kv <- function(x) {
  if (length(x) == 0) return(NULL)
  tags$ul(class = "list-unstyled small mb-2", lapply(names(x), function(nm) tags$li(tags$code(nm), " = ", as.character(x[[nm]]))))
}

.study_remove_btn <- function(study_id, entry_id) {
  tags$button(type = "button", class = "btn btn-link btn-sm p-0 text-danger",
              onclick = sprintf("esStudies.remove(%s, %s);", .study_js_str(study_id), .study_js_str(entry_id)),
              `aria-label` = "Remove this entry", "Remove")
}

study_view_ui <- function(study) {
  entries <- study$entries
  head <- div(class = "d-flex flex-wrap gap-2 align-items-end mb-3",
    div(tags$label(class = "form-label", `for` = "studies_name", "Name of this study"),
        tags$input(id = "studies_name", class = "form-control", type = "text", value = study$name, maxlength = "120",
                   onchange = sprintf("esStudies.rename(%s, this.value);", .study_js_str(study$id)))),
    tags$button(type = "button", class = "btn btn-outline-danger mb-0",
                onclick = sprintf("esStudies.clear(%s);", .study_js_str(study$id)), "Clear this study"))
  if (length(entries) == 0) {
    return(tagList(head, p(class = "text-muted", "Nothing added yet. Under a result, choose this study and press Add.")))
  }
  groups <- study_groups(entries)
  refs <- unique(Filter(nzchar, vapply(entries, function(e) if (is.character(e$citation)) e$citation else "", character(1))))
  tagList(
    head,
    p(class = "small text-muted", sprintf("%d result(s) from %d calculator design(s).", length(entries), length(groups))),
    lapply(groups, function(g) {
      first <- g[[1]]
      body <- if (length(g) == 1) {
        tagList(
          div(class = "d-flex justify-content-between", span(class = "small text-muted", first$time), .study_remove_btn(study$id, first$id)),
          h6("Result"), .study_kv(first$results),
          h6("Inputs"), .study_kv(first$inputs),
          if (length(first$notes)) div(class = "small text-warning", lapply(unlist(first$notes), p))
        )
      } else {
        tb <- study_table(g)
        tagList(
          if (length(tb$constant)) tagList(h6("Same in every row"), .study_kv(as.list(tb$constant))),
          div(class = "table-responsive",
            tags$table(class = "table table-sm table-striped align-middle",
              tags$thead(tags$tr(lapply(names(tb$table), tags$th), tags$th(""))),
              tags$tbody(lapply(seq_len(nrow(tb$table)), function(i) {
                tags$tr(lapply(tb$table[i, ], function(v) tags$td(as.character(v))), tags$td(.study_remove_btn(study$id, g[[i]]$id)))
              }))))
        )
      }
      div(class = "card mb-3",
        div(class = "card-header", strong(first$module_title), " -- ", first$design),
        div(class = "card-body",
          body,
          if (nzchar(first$formula_latex)) tags$details(class = "small", tags$summary("Formula (LaTeX, for Word's Insert > Equation)"),
                                                       tags$pre(class = "mb-1", first$formula_latex)),
          if (nzchar(first$citation)) p(class = "small mb-0", strong("Source: "), first$citation)))
    }),
    if (length(refs)) tagList(h5("References"), tags$ol(class = "small", lapply(refs, tags$li)))
  )
}

recent_view_ui <- function(recent) {
  if (length(recent) == 0) {
    return(p(class = "text-muted", "No calculations yet. A result is recorded here once it has stayed the same for a few seconds."))
  }
  tagList(
    p(class = "small text-muted", sprintf("The last %d results (newest first), kept in this tab.", .recent_max)),
    tags$ul(class = "list-group",
      lapply(recent, function(e) tags$li(class = "list-group-item d-flex flex-wrap gap-2 justify-content-between align-items-center",
        div(div(study_entry_summary(e)), div(class = "small text-muted", e$time)),
        div(class = "d-flex gap-1 align-items-center",
          tags$select(class = "form-select form-select-sm study-target", `aria-label` = "Study to add this result to"),
          tags$button(type = "button", class = "btn btn-sm btn-outline-primary",
                      onclick = sprintf("esStudies.addFromRecent(%s, this.previousElementSibling.value);", .study_js_str(e$id)), "Add"))))))
}

studies_server <- function(input, output, session) {
  state <- reactive(studies_normalize(input$studies_state))
  # the drop-down lists the studies by name, then Recent calculations
  observe({
    st <- state()
    choices <- c(setNames(vapply(st$studies, `[[`, character(1), "id"), vapply(st$studies, function(s) sprintf("%s (%d)", s$name, length(s$entries)), character(1))),
                 c(`Recent calculations` = "recent"))
    sel <- isolate(input$studies_pick)
    if (is.null(sel) || !sel %in% choices) sel <- choices[[1]]
    updateSelectInput(session, "studies_pick", choices = choices, selected = sel)
  })
  # a new study opens at once
  observeEvent(input$studies_opened, updateSelectInput(session, "studies_pick", selected = input$studies_opened$id), ignoreInit = TRUE)
  output$studies_view <- renderUI({
    st <- state()
    pick <- input$studies_pick
    if (identical(pick, "recent")) return(recent_view_ui(st$recent))
    s <- Filter(function(s) identical(s$id, pick), st$studies)
    study_view_ui(if (length(s)) s[[1]] else st$studies[[1]])
  })
}

# --- the "Add to study" row under every result (export_controls_ui()) ---------------------------------------------------------

study_add_ui <- function(ns) {
  div(class = "study-add d-flex flex-wrap gap-2 align-items-center mt-3",
    tags$label(class = "small mb-0", `for` = ns("study_target"), "Add this result to"),
    tags$select(id = ns("study_target"), class = "form-select form-select-sm study-target w-auto"),
    tags$button(type = "button", class = "btn btn-sm btn-outline-primary",
                onclick = sprintf("esStudies.request(%s, this.previousElementSibling.value);", .study_js_str(ns("study_add"))), "Add"))
}

# Called from render_export_handlers(): "Add" sends the shown result to the page; results that stay the same for a few seconds after the
# user has changed something in this calculator are recorded as recent calculations.
study_capture_server <- function(result, content_fn, value_fn, session = shiny::getDefaultReactiveDomain()) {
  if (is.null(session)) return(invisible(NULL))
  module_id <- sub("-$", "", session$ns(""))
  if (!nzchar(module_id)) return(invisible(NULL))
  title <- NULL
  entry_now <- function() {
    res <- tryCatch(result(), error = function(e) NULL)
    if (is.null(res) || !isTRUE(res$ok)) return(NULL)
    if (is.null(title)) title <<- .module_title(module_id)
    tryCatch(study_entry(module_id, title, value_fn(res), content_fn()), error = function(e) NULL)
  }
  input <- session$input
  observeEvent(input$study_add, {
    e <- entry_now()
    if (is.null(e)) {
      session$sendCustomMessage("study_note", list(text = "There is no result to add yet."))
      return()
    }
    session$sendCustomMessage("study_add", list(study = input$study_add$study, entry = e, summary = study_entry_summary(e)))
  }, ignoreInit = TRUE)

  # recent calculations: only once the user has changed something here (so loading a calculator records nothing and nothing is
  # computed for calculators that were only loaded), then a result that has stayed the same for a few seconds
  armed <- reactiveVal(FALSE)
  seen <- FALSE
  arm <- observe({
    reactiveValuesToList(input)
    if (!seen) { seen <<- TRUE; return() }
    armed(TRUE)
    arm$destroy()
  })
  settled <- debounce(reactive({ req(armed()); entry_now() }), .recent_delay_ms)
  observeEvent(settled(), {
    e <- settled()
    if (!is.null(e)) session$sendCustomMessage("study_recent", list(entry = e))
  }, ignoreNULL = TRUE)
  invisible(NULL)
}

# --- the page script -----------------------------------------------------------------------------------------------------------

studies_assets <- function() {
  tagList(
    tags$style(HTML("
.study-toast { position: fixed; left: 50%; transform: translateX(-50%); bottom: 1rem; z-index: 1080; max-width: 92vw;
  background: var(--bs-body-bg); color: var(--bs-body-color); border: 1px solid var(--bs-primary); border-radius: .5rem;
  box-shadow: 0 4px 16px rgba(0,0,0,.2); padding: .5rem .75rem; font-size: .9rem; }
@media (max-width: 575.98px) { .study-toast { bottom: 4.5rem; } }
")),
    tags$script(HTML(sprintf("
(function () {
  var KEY = 'es_studies_v1', MAX = %d, RECENT = %d, state = null, toastTimer = null;
  function blank() { return { v: 1, seq: 0, last: 's1', studies: [1, 2, 3].map(function (i) { return { id: 's' + i, name: 'Study ' + i, entries: [] }; }), recent: [] }; }
  function load() { try { var s = JSON.parse(sessionStorage.getItem(KEY)); if (s && s.v === 1 && s.studies) return s; } catch (e) {} return blank(); }
  state = load();
  function find(id) { for (var i = 0; i < state.studies.length; i++) if (state.studies[i].id === id) return state.studies[i]; return null; }
  function push() { if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('studies_state', state); }
  function paint() {
    document.querySelectorAll('select.study-target').forEach(function (sel) {
      var keep = sel.value || state.last;
      sel.innerHTML = '';
      state.studies.forEach(function (s) { var o = document.createElement('option'); o.value = s.id; o.textContent = s.name + ' (' + s.entries.length + ')'; sel.appendChild(o); });
      sel.value = find(keep) ? keep : (find(state.last) ? state.last : state.studies[0].id);
    });
  }
  function save() {
    try { sessionStorage.setItem(KEY, JSON.stringify(state)); }
    catch (e) { toast('This browser tab could not keep the study (its storage is full or blocked). Download it before closing the tab.'); }
    push(); paint();
  }
  function toast(text, undo) {
    var t = document.getElementById('study_toast');
    if (!t) { t = document.createElement('div'); t.id = 'study_toast'; t.className = 'study-toast'; t.setAttribute('role', 'status'); t.setAttribute('aria-live', 'polite'); document.body.appendChild(t); }
    t.innerHTML = ''; var s = document.createElement('span'); s.textContent = text; t.appendChild(s);
    if (undo) { var b = document.createElement('button'); b.type = 'button'; b.className = 'btn btn-link btn-sm py-0'; b.id = 'study_undo'; b.textContent = 'Undo';
      b.onclick = function () { undo(); t.style.display = 'none'; }; t.appendChild(b); }
    t.style.display = 'block'; clearTimeout(toastTimer); toastTimer = setTimeout(function () { t.style.display = 'none'; }, 7000);
  }
  function add(studyId, entry, summary) {
    var s = find(studyId) || find(state.last) || state.studies[0];
    var e = JSON.parse(JSON.stringify(entry)); state.seq += 1; e.id = 'e' + state.seq;
    s.entries.push(e); state.last = s.id; save();
    toast('Added to ' + s.name + ': ' + (summary || e.module_title), function () { remove(s.id, e.id); });
  }
  function remove(studyId, entryId) { var s = find(studyId); if (!s) return; s.entries = s.entries.filter(function (e) { return e.id !== entryId; }); save(); }
  window.esStudies = {
    request: function (inputId, studyId) { if (window.Shiny) Shiny.setInputValue(inputId, { study: studyId, nonce: Math.random() }, { priority: 'event' }); },
    remove: remove,
    rename: function (studyId, name) { var s = find(studyId); if (!s) return; name = String(name || '').trim().slice(0, 120); s.name = name || s.id; save(); },
    clear: function (studyId) { var s = find(studyId); if (!s || !s.entries.length) return; if (!window.confirm('Remove every result from ' + s.name + '?')) return; s.entries = []; save(); },
    addStudy: function () {
      if (state.studies.length >= MAX) { toast('Up to ' + MAX + ' studies; clear one to start another.'); return; }
      var n = 1; while (find('s' + n)) n++;
      state.studies.push({ id: 's' + n, name: 'Study ' + n, entries: [] }); state.last = 's' + n; save();
      if (window.Shiny) Shiny.setInputValue('studies_opened', { id: 's' + n, nonce: Math.random() }, { priority: 'event' });
    },
    addFromRecent: function (entryId, studyId) {
      var e = state.recent.filter(function (r) { return r.id === entryId; })[0]; if (!e) return;
      add(studyId, e, e.module_title + ' -- ' + e.design);
    }
  };
  document.addEventListener('change', function (ev) {
    if (ev.target && ev.target.matches && ev.target.matches('select.study-target')) { state.last = ev.target.value; try { sessionStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} }
  });
  // calculators loaded later bring new drop-downs
  var pending = false;
  new MutationObserver(function () { if (pending) return; pending = true; setTimeout(function () { pending = false; paint(); }, 200); })
    .observe(document.documentElement, { childList: true, subtree: true });
  $(document).on('shiny:connected', function () { push(); paint(); });
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('study_add', function (m) { add(m.study, m.entry, m.summary); });
    Shiny.addCustomMessageHandler('study_note', function (m) { toast(m.text); });
    Shiny.addCustomMessageHandler('study_recent', function (m) {
      var e = m.entry; if (!e) return;
      if (state.recent.length && state.recent[0].key === e.key) return;
      state.recent = state.recent.filter(function (r) { return r.key !== e.key; });
      state.seq += 1; e.id = 'r' + state.seq; state.recent.unshift(e);
      if (state.recent.length > RECENT) state.recent.length = RECENT;
      save();
    });
  }
})();
", .study_max, .recent_max)))
  )
}
