# "Which calculator?" guided wizard (docs/design_identification_algorithm.md).
# Walks the flat node registry in design_tree.R one question at a time,
# showing the reasoning trace as it goes, and ends either on a jump button
# into a built module (reusing the same nav_select()/updateRadioButtons()
# mechanism as the Home finders) or an honest "not yet built" note.
#
# Same non-idiomatic pattern as home_finder.R: plain UI-building + server
# logic, not a Shiny module, because it needs to jump the top-level navbar
# and update another module's input from the root session.

design_wizard_body <- function() {
  tagList(
    p(paste(
      "Answer a few questions about your study and this points you to the",
      "right calculator -- showing its reasoning as it goes, so you can",
      "check it. It only ever suggests; nothing is decided silently, and",
      "you can start over at any point if a question doesn't fit your study."
    )),
    uiOutput("design_wizard_trace"),
    uiOutput("design_wizard_body")
  )
}

design_wizard_server <- function(input, output, session) {
  state <- reactiveValues(node_id = "root", trace = list(), flags = list())

  output$design_wizard_trace <- renderUI({
    if (length(state$trace) == 0) return(NULL)
    tags$ul(class = "text-muted small",
      lapply(state$trace, function(t) tags$li(paste0(t$question, " -> ", t$answer))))
  })

  output$design_wizard_body <- renderUI({
    node <- design_nodes[[state$node_id]]
    if (isTRUE(node$terminal)) .render_design_terminal(node, state$flags) else .render_design_question(node)
  })

  observeEvent(input$design_wizard_next, {
    node <- design_nodes[[state$node_id]]
    req(!isTRUE(node$terminal))
    req(input$design_wizard_choice)
    opt <- node$options[[as.integer(input$design_wizard_choice)]]

    if (!is.null(opt$set)) {
      for (nm in names(opt$set)) state$flags[[nm]] <- opt$set[[nm]]
    }
    state$trace <- c(state$trace, list(list(question = node$question, answer = opt$label)))
    state$node_id <- if (is.function(opt$next_id)) opt$next_id(state$flags) else opt$next_id
  }, ignoreInit = TRUE)

  observeEvent(input$design_wizard_restart, {
    state$node_id <- "root"
    state$trace <- list()
    state$flags <- list()
  }, ignoreInit = TRUE)

  observeEvent(input$design_wizard_jump, {
    node <- design_nodes[[state$node_id]]
    key <- if (is.function(node$catalog_key)) node$catalog_key(state$flags) else node$catalog_key
    req(key)
    entry <- catalog_entry(key)
    req(entry)
    nav_select("main_nav", entry$nav_target, session = session)
    if (!is.na(entry$module_input_id)) {
      updateRadioButtons(session, entry$module_input_id, selected = entry$design_value)
    }
  }, ignoreInit = TRUE)
}

.render_design_question <- function(node) {
  choice_labels <- vapply(node$options, `[[`, character(1), "label")
  tagList(
    if (!is.null(node$help)) p(class = "text-muted", node$help),
    radioButtons("design_wizard_choice", node$question,
                 choiceNames = as.list(choice_labels),
                 choiceValues = as.list(as.character(seq_along(node$options))),
                 selected = character(0)),
    actionButton("design_wizard_next", "Next", class = "btn-primary"),
    if (!identical(node$id, "root")) tagList(
      " ", actionButton("design_wizard_restart", "Start over", class = "btn-link")
    )
  )
}

.render_design_terminal <- function(node, flags) {
  key <- if (is.function(node$catalog_key)) node$catalog_key(flags) else node$catalog_key
  entry <- if (!is.null(key)) catalog_entry(key) else NULL

  body <- if (!is.null(entry) && isTRUE(entry$built)) {
    tagList(
      if (!is.null(entry$answers) && !is.na(entry$answers)) p(class = "text-muted", entry$answers),
      actionButton("design_wizard_jump", paste("Go to:", entry$nav_target), class = "btn-success")
    )
  } else if (isTRUE(node$guidance)) {
    div(class = "alert alert-info", p(node$note))
  } else {
    div(class = "alert alert-warning",
        p(strong("Not yet built in this app.")),
        if (!is.null(node$would_use)) p("Would use: ", code(node$would_use)),
        if (!is.null(node$citation) && !identical(node$citation, "-")) p(class = "text-muted small", node$citation),
        p("See ", code("docs/checklist_by_design.md"), " for the roadmap."))
  }

  tagList(
    h4(node$design),
    if (!is.null(node$note) && !isTRUE(node$guidance)) div(class = "alert alert-info small", node$note),
    if (isTRUE(flags$cluster)) div(class = "alert alert-info small", paste(
      "This was reached via a cluster-randomised design -- apply a design",
      "effect (DEFF = 1 + (m-1) x ICC) to the base n this module returns.",
      "This app doesn't compute DEFF automatically yet (Stage 5 modifier,",
      "see docs/design_identification_algorithm.md).")),
    body,
    br(), br(),
    actionButton("design_wizard_restart", "Start over / this isn't my design", class = "btn-link")
  )
}
