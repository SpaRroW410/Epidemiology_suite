# "Which calculator?" guided wizard (docs/design_identification_algorithm.md).
# Walks the flat node registry in home_design_tree.R one question at a time,
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
    div(class = "card card-body bg-light mb-3",
      p(class = "small text-muted",
        paste("Optional: describe your study in a sentence or two and this",
              "will pre-fill as many answers below as it can confidently",
              "infer, then stop at the first question it isn't sure about --",
              "check the pre-filled trail and continue manually from there.",
              "This is keyword-based, not a language model: it never guesses",
              "a final answer, it only skips questions it's confident about.")),
      textAreaInput("design_wizard_freetext", NULL, rows = 2,
                    placeholder = "e.g. \"We compared cases and controls, individually matched, for exposure to pesticide.\""),
      actionButton("design_wizard_parse", "Suggest from this text", class = "btn-outline-primary btn-sm")
    ),
    uiOutput("design_wizard_trace"),
    uiOutput("design_wizard_body")
  )
}

design_wizard_server <- function(input, output, session) {
  state <- reactiveValues(node_id = "root", trace = list(), flags = list())

  observeEvent(input$design_wizard_parse, {
    res <- walk_free_text(input$design_wizard_freetext)
    state$node_id <- res$node_id
    state$trace <- res$trace
    state$flags <- res$flags
  }, ignoreInit = TRUE)

  output$design_wizard_trace <- renderUI({
    if (length(state$trace) == 0) return(NULL)
    tags$ul(class = "text-muted small",
      lapply(state$trace, function(t) tags$li(paste0(
        t$question, " -> ", t$answer,
        if (!is.null(t$confidence)) paste0(" (auto-suggested, ", t$confidence, " confidence)") else ""
      ))))
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
    updateTextAreaInput(session, "design_wizard_freetext", value = "")
  }, ignoreInit = TRUE)

  observeEvent(input$design_wizard_jump, {
    node <- design_nodes[[state$node_id]]
    .design_wizard_go(session, .terminal_catalog_key(node, state$flags))
  }, ignoreInit = TRUE)

  # Cluster-randomised paths: the per-arm n from the matched module still
  # needs inflating, so offer the two modules that do that.
  observeEvent(input$design_wizard_jump_deff, {
    .design_wizard_go(session, "cluster_deff")
  }, ignoreInit = TRUE)
  observeEvent(input$design_wizard_jump_glmm, {
    .design_wizard_go(session, if (identical(state$flags$outcome, "binary")) "glmm_binary" else "glmm_lmm_continuous")
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

.terminal_catalog_key <- function(node, flags) {
  if (is.function(node$catalog_key)) node$catalog_key(flags) else node$catalog_key
}

.design_wizard_go <- function(session, key) {
  req(key)
  entry <- catalog_entry(key)
  req(entry)
  nav_select("main_nav", entry$nav_target, session = session)
  if (!is.na(entry$module_input_id)) {
    updateRadioButtons(session, entry$module_input_id, selected = entry$design_value)
  }
}

# Terminals that already account for clustering themselves -- no need to
# tell the user to inflate their n afterwards.
.cluster_aware_keys <- c("cluster_deff", "cluster_deff_variable", "cluster_survey",
                         "cluster_pps_optimal", "stepped_wedge_normal",
                         "glmm_lmm_continuous", "glmm_binary", "multilevel_three_level")

.render_design_terminal <- function(node, flags) {
  key <- .terminal_catalog_key(node, flags)
  entry <- if (!is.null(key)) catalog_entry(key) else NULL

  body <- if (!is.null(entry) && isTRUE(entry$built)) {
    tagList(
      if (!is.null(entry$answers) && !is.na(entry$answers)) p(class = "text-muted", entry$answers),
      actionButton("design_wizard_jump", paste("Go to:", entry$nav_target), class = "btn-success")
    )
  } else if (!isTRUE(node$guidance)) {
    div(class = "alert alert-warning",
        p(strong("Not yet built in this app.")),
        if (!is.null(node$would_use)) p("What it needs: ", code(node$would_use)),
        if (!is.null(node$citation) && !identical(node$citation, "-")) p(class = "text-muted small", node$citation),
        p("This item is tracked, with what would unblock it, in ", code("docs/ROADMAP.md"), " (section 4)."))
  }

  tagList(
    h4(node$design),
    if (!is.null(node$note)) div(class = "alert alert-info small", node$note),
    if (isTRUE(flags$cluster) && !any(key %in% .cluster_aware_keys)) div(class = "alert alert-info small",
      p(paste(
        "This was reached via a cluster-randomised design. The module below",
        "returns the n for individually randomised subjects -- inflate it by",
        "the design effect, DEFF = 1 + (m - 1) x ICC (or the unequal-cluster-size",
        "version), or simulate the mixed-model analysis directly.")),
      actionButton("design_wizard_jump_deff", "Go to: Cluster / Design Effect", class = "btn-light btn-sm"),
      " ",
      actionButton("design_wizard_jump_glmm", "Go to: Monte Carlo Mixed Models", class = "btn-light btn-sm")),
    body,
    br(), br(),
    actionButton("design_wizard_restart", "Start over / this isn't my design", class = "btn-link")
  )
}
