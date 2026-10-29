# Home tab: a short welcome, then a "Helper" area (one navset_card_tab) that
# bundles the three ways to find/understand a calculator -- the dual-taxonomy
# browser (home_finder.R), the guided wizard (design_wizard.R), and a formula/
# LaTeX explainer + live sandbox (this file) -- so the top navbar only needs
# one "Home" entry instead of separate crowding tabs for each. Composes
# home_finder.R's and design_wizard.R's UI-fragment/server functions rather
# than rewriting them (both already expose exactly that shape); this file
# just supplies the Welcome block, the wrapping navset, and the new sandbox.
#
# Same non-idiomatic pattern as home_finder.R/design_wizard.R: plain
# UI-building + server logic, not a Shiny module, since the pieces it
# composes need root-session access to jump the top-level navbar.

# Title of a module (what the navbar lists), looked up from the registry so the Home page cannot drift from it.
.home_module_title <- function(id) {
  for (m in module_registry()) if (identical(m$id, id)) return(m$title)
  stop("No module with id '", id, "'.")
}

# The calculators a person is most likely to want first: shown as quick links under the search box.
.home_quick_ids <- c("proportion", "means", "logrank", "correlation", "case_control", "cohort")

# How many calculators each workbench lists (counted from the workbench definitions, never typed in by hand).
.home_workbench_count <- function(wb_id) {
  for (wb in module_workbenches) if (identical(wb$id, wb_id)) return(length(unlist(lapply(wb$groups, `[[`, "module_ids"))))
  0L
}

# The small search box at the right of the navbar, so a calculator can be found from any page.
nav_search_ui <- function() {
  selectizeInput(
    "nav_search",
    label = tags$span(class = "visually-hidden", "Search all calculators"),
    choices = NULL, width = "15rem",
    options = list(
      placeholder = "Search calculators", valueField = "key", labelField = "label",
      searchField = c("label", "answers", "module"), maxOptions = 12, openOnFocus = FALSE
    )
  )
}

# One row per built calculator for the search box: the catalog key it opens, its label, a short "answers" text and the module it lives in.
.home_search_table <- function() {
  built <- Filter(function(e) isTRUE(e$built), calculator_catalog)
  data.frame(
    key = vapply(built, `[[`, "", "key"),
    label = vapply(built, `[[`, "", "label"),
    answers = vapply(built, function(e) if (is.null(e$answers) || is.na(e$answers)) "" else e$answers, ""),
    module = vapply(built, function(e) e$nav_target, ""),
    stringsAsFactors = FALSE
  )
}

home_panel_ui <- function() {
  task_card <- function(id, title, text) {
    bslib::card(
      class = "home-task-card", fill = FALSE,
      bslib::card_body(fill = FALSE,
        h5(class = "mb-1", title),
        p(class = "text-muted small flex-grow-1", text),
        actionButton(id, "Open", class = "btn-outline-primary btn-sm align-self-start")
      )
    )
  }
  tagList(
    tags$style(HTML("
.home-hero { text-align: center; padding: 1.2rem 0 .4rem; }
.home-hero .selectize-control { max-width: 46rem; margin: 0 auto; text-align: left; }
.home-hero .selectize-input { border-radius: 2rem; padding: .7rem 1.2rem; font-size: 1.05rem; border: 2px solid var(--bs-primary); }
.home-quick .btn { margin: .15rem; border-radius: 2rem; }
.home-task-card { height: 100%; }
.home-task-card .card-body { flex: 1 1 auto !important; display: flex; flex-direction: column; justify-content: flex-start !important; }
.home-guide .card-body > div { flex: 1 1 14rem; min-width: 0; }
.home-guide .card-body { flex-direction: row !important; flex-wrap: wrap; align-items: center; justify-content: flex-start; gap: 1rem; }
")),
    div(class = "home-hero",
      h2("What do you want to do?"),
      p(class = "text-muted", "Sample size, power and analysis tools for community medicine, epidemiology and clinical research."),
      selectizeInput(
        "home_search",
        label = tags$span(class = "visually-hidden", "Search all calculators"),
        choices = NULL, width = "100%",
        options = list(
          placeholder = "Search the calculators",
          valueField = "key", labelField = "label", searchField = c("label", "answers", "module"),
          maxOptions = 12, openOnFocus = FALSE
        )
      ),
      p(class = "text-muted small mt-1 mb-2", "Try: two means, kappa, stepped wedge, eyes per patient"),
      div(class = "home-quick",
        lapply(.home_quick_ids, function(id) actionButton(paste0("home_quick_", id), .home_module_title(id), class = "btn-outline-secondary btn-sm")))
    ),
    br(),
    bslib::layout_column_wrap(
      width = "14rem", heights_equal = "row", fill = FALSE, fillable = FALSE,
      task_card("home_go_plan", "Plan a study",
                sprintf("Sample size and power: %d calculators, each with its formula, its reference and a paragraph for your protocol.", .home_workbench_count("plan"))),
      task_card("home_go_analyze", "Analyze counts I have",
                sprintf("%d tools: 2x2 tables, rates, Mantel-Haenszel, diagnostic accuracy, vaccine efficacy, standardization, outbreaks.", .home_workbench_count("analyze"))),
      task_card("home_go_outbreak", "Outbreak and surveillance",
                "Attack rates, aberration detection (EARS, CUSUM) and SIR / SEIR teaching models."),
      task_card("home_go_survey", "Survey and field work",
                "Sample selection (random, systematic, PPS, WHO EPI 30 x 7), survey weights, randomization lists, attrition.")
    ),
    bslib::card(
      class = "mt-3 border-primary-subtle home-guide", fill = FALSE,
      bslib::card_body(
        fill = FALSE,
        div(h5(class = "mb-0", "Not sure which calculator?"),
            p(class = "text-muted mb-0", "Answer a few questions or describe your study in a sentence.")),
        actionButton("home_go_wizard", "Start the guide", class = "btn-primary ms-auto")
      )
    ),
    # the long lists stay one click away instead of filling the page
    bslib::accordion(
      id = "home_more", open = FALSE, class = "mt-4",
      bslib::accordion_panel(
        "Browse all calculators, the guided wizard, formulas", value = "more",
        # not a fill item: bslib's default makes the card as tall as the window and scrolls its content inside it, which left a
        # small scroll window (and a cramped question box); here the card grows with its content and the page scrolls
        bslib::remove_all_fill(navset_card_tab(
          id = "home_helper",
          nav_panel("Browse calculators", br(), home_finder_body()),
          nav_panel("Which calculator? (guided wizard)", br(), design_wizard_body()),
          nav_panel("Formulas & LaTeX", br(), home_sandbox_ui())
        ))
      )
    )
  )
}

home_server <- function(input, output, session) {
  home_finder_server(input, output, session)
  design_wizard_server(input, output, session)

  # search boxes (the big one on Home and the small one in the navbar): choose a calculator and it opens, on the design that was named
  search_table <- .home_search_table()
  for (box in c("home_search", "nav_search")) local({
    box <- box
    updateSelectizeInput(session, box, choices = search_table, server = TRUE)
    observeEvent(input[[box]], {
      key <- input[[box]]
      if (is.null(key) || !nzchar(key)) return()
      entry <- catalog_entry(key)
      jump_to_module(session, entry$nav_target)
      if (!is.na(entry$module_input_id)) updateRadioButtons(session, entry$module_input_id, selected = entry$design_value)
      updateSelectizeInput(session, box, selected = "")
    }, ignoreInit = TRUE)
  })

  # quick links and task cards
  for (id in .home_quick_ids) local({
    id <- id
    observeEvent(input[[paste0("home_quick_", id)]], jump_to_module(session, .home_module_title(id)), ignoreInit = TRUE)
  })
  observeEvent(input$home_go_plan, nav_select("main_nav", "Plan: Sample Size", session = session), ignoreInit = TRUE)
  observeEvent(input$home_go_analyze, nav_select("main_nav", "Analyze", session = session), ignoreInit = TRUE)
  observeEvent(input$home_go_outbreak, jump_to_module(session, .home_module_title("analyze_outbreak")), ignoreInit = TRUE)
  observeEvent(input$home_go_survey, jump_to_module(session, .home_module_title("survey_selection")), ignoreInit = TRUE)
  observeEvent(input$home_go_wizard, {
    bslib::accordion_panel_open("home_more", "more", session = session)
    nav_select("home_helper", "Which calculator? (guided wizard)", session = session)
  }, ignoreInit = TRUE)

  latex_input <- debounce(reactive(input$home_latex_sandbox), 400)

  output$home_latex_preview <- renderUI({
    raw <- latex_input()
    body <- gsub("\\${2}", "", if (is.null(raw)) "" else raw)
    tagList(
      div(id = "home_latex_output", class = "border rounded p-3 bg-light",
          withMathJax(HTML(paste0("$$", body, "$$")))),
      tags$script(HTML(
        "if (window.MathJax && MathJax.Hub) {",
        "  MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'home_latex_output']);",
        "}"
      ))
    )
  })
}

home_sandbox_ui <- function() {
  tagList(
    h4("How formulas are written in this app"),
    shiny::markdown(paste(
      "Every formula in this app is typeset with MathJax using standard",
      "LaTeX, wrapped in `$$...$$` for display-mode equations (e.g.",
      "`$$n = ...$$`). A multi-line formula is just several `$$...$$` blocks",
      "one after another. Because R itself treats a single backslash as an",
      "escape character, every LaTeX backslash has to be doubled when it's",
      "written inside an R string -- `\\frac` becomes `\\\\frac`,",
      "`\\alpha` becomes `\\\\alpha`, and so on.",
      "",
      "Try it yourself below -- type LaTeX (without the `$$`) and see it",
      "rendered live."
    )),
    textAreaInput(
      "home_latex_sandbox", NULL,
      value = "n = \\frac{Z_{1-\\alpha/2}^2\\,p(1-p)}{d^2}",
      width = "100%", rows = 2
    ),
    uiOutput("home_latex_preview")
  )
}
