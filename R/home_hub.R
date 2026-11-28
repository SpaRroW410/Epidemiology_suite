# Home: the one start page (docs/ui_remap_plan.md, step 6, 28 Nov 2026). Three doors at the top -- I have a question (the guide),
# I know the test or name (the search box), I want to browse -- then quick links and task cards, then the "Find a calculator"
# section (find_panel_ui()): the guided wizard (design_wizard.R), the dual-taxonomy browser (home_finder.R), the glossary and a
# formula/LaTeX explainer + live sandbox (this file). Until 28 Nov 2026 that section was a top tab of its own. Composes
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
.home-door { height: 100%; }
.home-door .card-body { display: flex; flex-direction: column; }
.home-door.home-hero { text-align: left; padding: 0; }
.home-door.home-hero .selectize-input { font-size: 1rem; padding: .55rem 1rem; }
")),
    div(class = "home-hero",
      h2("What do you want to do?"),
      p(class = "text-muted", "Sample size, power and analysis tools for community medicine, epidemiology and clinical research.")
    ),
    # the three ways in, side by side (stacked on a phone)
    bslib::layout_column_wrap(
      width = "16rem", heights_equal = "row", fill = FALSE, fillable = FALSE, class = "home-doors",
      bslib::card(class = "home-door", fill = FALSE, bslib::card_body(fill = FALSE,
        h5(class = "mb-1", "I have a question"),
        p(class = "text-muted small", "Answer a few questions, or describe your study in a sentence: the guide suggests the design and the calculator."),
        actionButton("home_go_wizard", "Start the guide", class = "btn-primary align-self-start"))),
      bslib::card(class = "home-door home-hero", fill = FALSE, bslib::card_body(fill = FALSE,
        h5(class = "mb-1", "I know the test or name"),
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
        p(class = "text-muted small mt-1 mb-0", "Try: two means, kappa, stepped wedge, eyes per patient"))),
      bslib::card(class = "home-door", fill = FALSE, bslib::card_body(fill = FALSE,
        h5(class = "mb-1", "I want to browse"),
        p(class = "text-muted small", "Every calculator, grouped by study design or by statistical test, with what each one answers."),
        actionButton("home_go_browse", "Browse all calculators", class = "btn-outline-primary align-self-start")))
    ),
    div(class = "home-quick text-center mt-2",
      span(class = "text-muted small me-1", "Most used:"),
      lapply(.home_quick_ids, function(id) actionButton(paste0("home_quick_", id), .home_module_title(id), class = "btn-outline-secondary btn-sm"))),
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
    # the guide, Browse, the glossary and the formulas: the doors above open their tab here and scroll to it
    div(id = "home_find", class = "mt-4",
      h4("Find a calculator"),
      find_panel_ui()),
    versions_details_ui(),
    # scrolls the page to the top when a Home button opens another tab (the new tab would otherwise open part-way down), and to the
    # "Find a calculator" section when a door opens one of its tabs
    tags$script(HTML(paste(
      "if (window.Shiny && Shiny.addCustomMessageHandler) {",
      "  Shiny.addCustomMessageHandler('home_scroll_top', function (msg) { window.scrollTo(0, 0); });",
      # the tab's content (e.g. the Browse list) is drawn after the tab is shown, so the page may not be long enough at first: try again
      "  Shiny.addCustomMessageHandler('home_scroll_find', function (msg) { [120, 700, 1600].forEach(function (ms) { setTimeout(function () {",
      "    var e = document.getElementById('home_find'); if (e && Math.abs(e.getBoundingClientRect().top) > 30) e.scrollIntoView({ block: 'start' }); }, ms); }); });",
      "}")))
  )
}

# "Find a calculator" section of Home: the guided questions, the list of every calculator (by study design or by test) and the formula
# sandbox. They used to sit in a folded section at the bottom of Home, where "Start the guide" opened them below the visible part
# of the page, so the button seemed to do nothing; a tab of their own opens at the top.
find_panel_ui <- function() {
  # not a fill item: bslib's default makes the card as tall as the window and scrolls its content inside it, which left a small
  # scroll window (and a cramped question box); here the card grows with its content and the page scrolls
  bslib::remove_all_fill(navset_card_tab(
    id = "home_helper",
    nav_panel("Guided questions", br(), design_wizard_body()),
    nav_panel("Browse all calculators", br(), home_finder_body()),
    nav_panel("Glossary", br(), glossary_ui()),
    nav_panel("Formulas & LaTeX", br(), home_sandbox_ui())
  ))
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
      catalog_open(session, entry)
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
  open_find <- function(tab) {
    nav_select("main_nav", "Home", session = session)
    nav_select("home_helper", tab, session = session)
    session$sendCustomMessage("home_scroll_find", list())
  }
  observeEvent(input$home_go_wizard, open_find("Guided questions"), ignoreInit = TRUE)
  observeEvent(input$home_go_browse, open_find("Browse all calculators"), ignoreInit = TRUE)

  latex_input <- debounce(reactive(input$home_latex_sandbox), 400)

  output$home_latex_preview <- renderUI({
    raw <- latex_input()
    body <- gsub("\\${2}", "", if (is.null(raw)) "" else raw)
    tagList(
      div(id = "home_latex_output", class = "border rounded p-3 bg-body-tertiary",
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
