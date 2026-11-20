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
    div(class = "card card-body bg-body-tertiary mb-3",
      p(class = "small text-muted",
        paste("Optional: describe your study in a sentence or two and this",
              "will pre-fill as many answers below as it can confidently",
              "infer, then stop at the first question it isn't sure about --",
              "check the pre-filled trail and continue manually from there.",
              "This is keyword-based, not a language model: it never guesses",
              "a final answer, it only skips questions it's confident about.")),
      textAreaInput("design_wizard_freetext", NULL, rows = 4, width = "100%", resize = "vertical",
                    placeholder = "e.g. \"We compared cases and controls, individually matched, for exposure to pesticide.\""),
      actionButton("design_wizard_parse", "Suggest from this text", class = "btn-outline-primary btn-sm")
    ),
    uiOutput("design_wizard_trace"),
    uiOutput("design_wizard_body")
  )
}

design_wizard_server <- function(input, output, session) {
  state <- reactiveValues(node_id = "root", trace = list(), flags = list(), history = list())
  # one step back: every move first saves where the user was
  remember <- function() {
    state$history <- c(state$history, list(list(node_id = state$node_id, trace = state$trace, flags = state$flags)))
  }

  observeEvent(input$design_wizard_parse, {
    remember()
    res <- walk_free_text(input$design_wizard_freetext)
    state$node_id <- res$node_id
    state$trace <- res$trace
    state$flags <- res$flags
    # nothing recognised: say so, instead of leaving the guide as it was (a research question such as "determinants of ... among
    # youth" names no design; ROADMAP: expanding the free-text reader)
    state$parse_note <- if (identical(res$flags$ambiguous, "determinants")) "choose"
                        else if (length(res$trace) == 0 && !is.null(input$design_wizard_freetext) && nzchar(trimws(input$design_wizard_freetext))) "none"
                        else NULL
  }, ignoreInit = TRUE)

  output$design_wizard_trace <- renderUI({
    if (identical(state$parse_note, "choose")) return(.render_rq_choices())
    if (identical(state$parse_note, "none")) {
      return(div(class = "alert alert-warning small", role = "status",
        p(class = "mb-1", strong("Nothing in this description could be matched to a study design yet.")),
        p(class = "mb-1", "The reader looks for words about the design (survey, prevalence, cohort, case-control, trial, compare, ",
          "before and after, ...) and the outcome (a proportion, a mean, time to an event). A research question that names only the topic, ",
          "such as \"determinants of ... among ...\", does not say which design you plan."),
        p(class = "mb-0", "Answer the questions below instead, or add a few words, for example: \"cross-sectional survey of the prevalence of ... ",
          "and the factors associated with it\".")))
    }
    conflict <- state$flags$conflict
    warnings <- state$flags$warnings
    if (length(state$trace) == 0 && is.null(conflict) && !length(warnings)) return(NULL)
    tagList(
      if (length(state$trace)) tags$ul(class = "text-muted small",
        lapply(state$trace, function(t) tags$li(paste0(
          t$question, " -> ", t$answer,
          if (!is.null(t$confidence)) paste0(" (auto-suggested", if (!is.null(t$words)) paste0(" from \"", t$words, "\""), ", ",
                                             t$confidence, " confidence)") else ""
        )))),
      # the description fits two answers of the next question: say which words point where, and let the user choose (FIND-18)
      if (!is.null(conflict)) {
        opts <- design_nodes[[conflict$node_id]]$options
        div(class = "alert alert-info small", role = "status",
          p(class = "mb-1", strong("Your description fits more than one answer to the question below:")),
          tags$ul(class = "mb-1", lapply(seq_along(conflict$words), function(i)
            tags$li(paste0("\"", conflict$words[[i]], "\" suggests: ", opts[[conflict$options[[i]]]]$label)))),
          p(class = "mb-0", "Choose the one that describes how your study is run."))
      },
      # warnings that ask, never a silent change of the route (FIND-19)
      if (length(warnings)) div(class = "alert alert-warning small", role = "status",
        p(class = "mb-1", strong("Please check:")),
        tags$ul(class = "mb-0", lapply(warnings, tags$li)))
    )
  })

  pubmed_builder_server(input, output, session, reactive({
    node <- design_nodes[[state$node_id]]
    if (isTRUE(node$terminal)) .design_card_key(node, state$flags) else NULL
  }))

  output$design_wizard_body <- renderUI({
    node <- design_nodes[[state$node_id]]
    can_back <- length(state$history) > 0
    if (isTRUE(node$terminal)) .render_design_terminal(node, state$flags, can_back) else .render_design_question(node, can_back)
  })

  observeEvent(input$design_wizard_next, {
    node <- design_nodes[[state$node_id]]
    req(!isTRUE(node$terminal))
    req(input$design_wizard_choice)
    opt <- node$options[[as.integer(input$design_wizard_choice)]]

    if (!is.null(opt$set)) {
      for (nm in names(opt$set)) state$flags[[nm]] <- opt$set[[nm]]
    }
    remember()
    state$parse_note <- NULL
    state$trace <- c(state$trace, list(list(question = node$question, answer = opt$label)))
    state$node_id <- if (is.function(opt$next_id)) opt$next_id(state$flags) else opt$next_id
  }, ignoreInit = TRUE)

  observeEvent(input$design_wizard_back, {
    n <- length(state$history)
    req(n > 0)
    prev <- state$history[[n]]
    state$history <- state$history[-n]
    state$node_id <- prev$node_id
    state$trace <- prev$trace
    state$flags <- prev$flags
  }, ignoreInit = TRUE)

  observeEvent(input$design_wizard_restart, {
    state$parse_note <- NULL
    state$node_id <- "root"
    state$trace <- list()
    state$flags <- list()
    state$history <- list()
    updateTextAreaInput(session, "design_wizard_freetext", value = "")
  }, ignoreInit = TRUE)

  observeEvent(input$design_wizard_study_add, {
    node <- design_nodes[[state$node_id]]
    req(isTRUE(node$terminal))
    key <- .terminal_catalog_key(node, state$flags)
    entry <- if (!is.null(key)) catalog_entry(key) else NULL
    calc <- if (!is.null(entry) && isTRUE(entry$built)) paste0(entry$nav_target, ": ", entry$label) else NULL
    e <- study_design_entry(node$design, state$trace, calc)
    session$sendCustomMessage("study_add", list(study = input$design_wizard_study_add$study, entry = e, summary = study_entry_summary(e)))
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
  observeEvent(input$design_wizard_jump_rank, {
    node <- design_nodes[[state$node_id]]
    .design_wizard_go(session, .rank_alternative(.terminal_catalog_key(node, state$flags)))
  }, ignoreInit = TRUE)
  # a determinants question: the user picks the design (.rq_routes); the guide continues from there
  for (r in names(.rq_routes)) local({
    route <- r
    observeEvent(input[[paste0("design_wizard_rq_", route)]], {
      remember()
      answers <- .rq_routes[[route]]$answers
      if (route == "survey" && grepl("\\blevels?\\b|\\bscores?\\b|\\bconcentrations?\\b|\\bmean\\b|average", if (is.null(input$design_wizard_freetext)) "" else input$design_wizard_freetext, ignore.case = TRUE)) answers <- c(1, 2)
      w <- .walk_answers(answers, state$flags[intersect(names(state$flags), c("determinants", "population"))])
      state$node_id <- w$node_id; state$trace <- w$trace; state$flags <- w$flags
      state$parse_note <- NULL
    }, ignoreInit = TRUE)
  })

  # research questions: the association part, and the design effect for a population named by place (.render_research_question_notes())
  rq_key <- function() .terminal_catalog_key(design_nodes[[state$node_id]], state$flags)
  observeEvent(input$design_wizard_jump_assoc_two, .design_wizard_go(session, .rq_assoc_keys(rq_key())[["two"]]), ignoreInit = TRUE)
  observeEvent(input$design_wizard_jump_assoc_reg, .design_wizard_go(session, .rq_assoc_keys(rq_key())[["reg"]]), ignoreInit = TRUE)
  observeEvent(input$design_wizard_jump_pop_deff, .design_wizard_go(session, "cluster_deff"), ignoreInit = TRUE)
  observeEvent(input$design_wizard_jump_glmm, {
    .design_wizard_go(session, if (identical(state$flags$outcome, "binary")) "glmm_binary" else "glmm_lmm_continuous")
  }, ignoreInit = TRUE)
}

.render_design_question <- function(node, can_back = FALSE) {
  choice_labels <- vapply(node$options, `[[`, character(1), "label")
  tagList(
    if (!is.null(node$help)) p(class = "text-muted", node$help),
    radioButtons("design_wizard_choice", node$question, width = "100%",
                 choiceNames = as.list(choice_labels),
                 choiceValues = as.list(as.character(seq_along(node$options))),
                 selected = character(0)),
    if (can_back) tagList(actionButton("design_wizard_back", "Back", class = "btn-outline-secondary"), " "),
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
  catalog_open(session, entry)
}

# Terminals that already account for clustering themselves -- no need to
# tell the user to inflate their n afterwards.
.cluster_aware_keys <- c("cluster_deff", "cluster_deff_calc", "cluster_deff_variable", "cluster_survey",
                         "cluster_pps_optimal", "stepped_wedge_normal",
                         "glmm_lmm_continuous", "glmm_binary", "multilevel_three_level")

# The rank-based counterpart of a means design, offered when the outcome is summarised by a median and IQR.
.rank_alternative <- function(key) {
  if (is.null(key)) return(NULL)
  switch(key,
    means_two_indep = , means_two_indep_unequal_n = , means_welch = "wilcoxon_rank_sum",
    means_two_dep = , means_single = "wilcoxon_signed_rank",
    means_k = "kruskal_wallis",
    NULL)
}

# The designs a determinants question can mean (docs/design_identification_algorithm.md: show them, let the user choose), with the guide's
# answers from the root that lead to each.
.rq_routes <- list(
  survey = list(label = "A survey of a population now (cross-sectional)",
                when = "You will study a sample of the population once, measuring the outcome and the possible factors together. The usual design for \"determinants of ... in the youth of a city\".",
                answers = c(1, 1)),
  case_control = list(label = "Cases compared with people without the condition (case-control)",
                      when = "You start from people who have the outcome and people who do not, and look back at their exposures. Good for rare outcomes.",
                      answers = c(2, 2, 2)),
  cohort = list(label = "People followed over time (cohort)",
                when = "You start from people with and without the exposures and follow them until the outcome appears.",
                answers = c(2, 2, 1)),
  prediction = list(label = "A model to predict who will have the outcome (prediction model)",
                    when = "The aim is a score or model that predicts the outcome for an individual, not the role of each factor.",
                    answers = c(3))
)
.render_rq_choices <- function() {
  div(class = "card card-body mb-3", role = "group", `aria-label` = "Which design is your study?",
    p(class = "mb-2", strong("Your question asks about determinants or risk factors. "), info_tip("determinants"), " ",
      "That can mean different designs, and the sample size depends on which. Choose the one you plan:"),
    lapply(names(.rq_routes), function(r) {
      x <- .rq_routes[[r]]
      div(class = "mb-2",
          actionButton(paste0("design_wizard_rq_", r), x$label, class = "btn-outline-primary btn-sm text-start"),
          div(class = "small text-muted mt-1", x$when))
    }))
}

# A survey reached from a research question (R/design_free_text.R, .free_text_flags()): the estimate is only part of the answer.
.rq_estimate_keys <- c("proportion_single_precision", "means_single_precision", "cluster_survey")
.rq_assoc_keys <- function(key) {
  if (identical(key, "means_single_precision")) c(two = "means_two_indep", reg = "regression_r2")
  else c(two = "proportion_two_indep", reg = "logistic_binary_adjusted")
}
.render_research_question_notes <- function(key, flags) {
  if (is.null(key) || !key %in% .rq_estimate_keys) return(NULL)
  assoc <- .rq_assoc_keys(key)
  tagList(
    if (isTRUE(flags$determinants)) div(class = "alert alert-info small",
      p(strong("Your question also asks what is associated with the outcome (its determinants or risk factors). "),
        "The calculator below gives the sample size for how common the outcome is (or its average). The associations need a sample size ",
        "of their own: for one factor at a time, a comparison of two groups (for example users and non-users); for several factors together, ",
        "a multiple regression", info_tip("logistic_regression"), ". Plan each, use the largest, and add each to your study."),
      actionButton("design_wizard_jump_assoc_two", paste("Go to:", catalog_entry(assoc[["two"]])$label), class = "btn-light btn-sm"), " ",
      actionButton("design_wizard_jump_assoc_reg", paste("Go to:", catalog_entry(assoc[["reg"]])$label), class = "btn-light btn-sm")),
    if (isTRUE(flags$population) && !identical(key, "cluster_survey")) div(class = "alert alert-info small",
      p(strong("The population is named by a place or setting. "), info_tip("cluster_sampling"), " ",
        "If you will select clusters (wards, villages, schools, colleges ...) and then people within them, rather than people from one list, ",
        "multiply the sample size by the design effect (most commonly taken as 1.5 or 2 when nothing is known), or calculate the design ",
        "effect from the variance between clusters."),
      actionButton("design_wizard_jump_pop_deff", "Go to: Cluster / Design Effect", class = "btn-light btn-sm"))
  )
}

.render_design_terminal <- function(node, flags, can_back = FALSE) {
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
        p("This item is tracked, with what would unblock it, in the project's list of open items (", code("docs/PENDING.md"), ")."))
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
    if (identical(flags$summary, "median") && !is.null(.rank_alternative(key))) div(class = "alert alert-info small",
      p(strong("Your outcome is summarised by a median and IQR. "),
        "Either estimate a mean and SD from them and use the calculator below (Wan et al. 2014: mean = (q1 + median + q3) / 3,",
        "SD = IQR / 1.35 for a large sample; the Means calculator has a converter under its design list), or, for a clearly skewed",
        "outcome, plan the rank-based test instead."),
      actionButton("design_wizard_jump_rank", paste("Go to:", catalog_entry(.rank_alternative(key))$label), class = "btn-outline-primary btn-sm")),
    .render_research_question_notes(key, flags),
    body,
    # planning notes for the design (R/design_cards.R): fallback, threats, reporting guideline; sourced or marked as a suggestion
    .render_design_card(.design_card_key(node, flags)),
    # a PubMed search for studies of this design (R/pubmed_search.R): published filters where they exist, labelled
    .render_pubmed_builder(.design_card_key(node, flags)),
    # Studies (R/mod_studies.R): keep this design choice, with the answers that led to it, in a study
    div(class = "study-add d-flex flex-wrap gap-2 align-items-center mt-3",
      tags$label(class = "small mb-0", `for` = "design_wizard_study_target", "Add this design choice to"),
      tags$select(id = "design_wizard_study_target", class = "form-select form-select-sm study-target w-auto"),
      tags$button(type = "button", class = "btn btn-sm btn-outline-primary",
                  onclick = "esStudies.request('design_wizard_study_add', this.previousElementSibling.value);", "Add")),
    br(),
    if (can_back) tagList(actionButton("design_wizard_back", "Back one question", class = "btn-outline-secondary btn-sm"), " "),
    actionButton("design_wizard_restart", "Start over / this isn't my design", class = "btn-link")
  )
}
