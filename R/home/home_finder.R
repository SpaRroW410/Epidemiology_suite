# Home page: two ways to find the right calculator (by study design, or by
# groups/data type), both backed by the catalog in home_catalog.R.
#
# This is plain UI-building + server logic, not a Shiny module (no NS()/
# moduleServer()) -- it's a one-per-app singleton, and it needs to jump the
# top-level navbar and update another module's input, which is simplest done
# from the root session (see README's "non-idiomatic patterns" section).

home_panel_ui <- function() {
  family_choices <- c(
    "Choose one..." = "",
    setNames(
      vapply(study_design_families, `[[`, character(1), "id"),
      vapply(study_design_families, `[[`, character(1), "label")
    )
  )

  tagList(
    h2("Comprehensive Sample Size Calculator"),
    p(paste(
      "A sample size and power calculator for community medicine,",
      "epidemiology, and clinical research. Each calculator includes a",
      "worked-formula help tab and a reference to its original source."
    )),
    p("Find your calculator below, or use the tabs above directly."),
    navset_card_tab(
      nav_panel(
        "By study design",
        br(),
        selectInput("home_design_family", "What best describes your study?",
                    choices = family_choices),
        uiOutput("home_design_hint"),
        uiOutput("home_design_result")
      ),
      nav_panel(
        "By groups & data type",
        br(),
        selectInput(
          "home_outcome_type", "What type of outcome are you measuring?",
          choices = c("Proportion / percentage" = "proportion",
                      "Mean / continuous" = "mean")
        ),
        radioButtons(
          "home_groups", "How many groups do you have data for?",
          choices = c("1 group" = "1", "2 groups" = "2", "3 or more groups" = "3plus")
        ),
        conditionalPanel(
          condition = "input.home_groups == '2'",
          radioButtons(
            "home_dependency",
            "Are the two groups independent, or dependent (paired/matched)?",
            choices = c("Independent" = "independent", "Dependent / paired" = "dependent")
          )
        ),
        conditionalPanel(
          condition = "input.home_groups == '1'",
          radioButtons(
            "home_has_reference",
            "Do you have a known/reference value to test against?",
            choices = c(
              "No — I'm just estimating with a desired precision" = "no",
              "Yes — testing against a known/reference value" = "yes"
            )
          )
        ),
        uiOutput("home_groups_result")
      )
    )
  )
}

home_finder_server <- function(input, output, session) {
  output$home_design_hint <- renderUI({
    fam <- Find(function(f) identical(f$id, input$home_design_family), study_design_families)
    req(fam)
    p(class = "text-muted", fam$hint)
  })

  output$home_design_result <- renderUI({
    fam <- Find(function(f) identical(f$id, input$home_design_family), study_design_families)
    req(fam)
    if (length(fam$catalog_keys) == 0) return(.coming_soon_note())
    entries <- lapply(fam$catalog_keys, catalog_entry)
    tagList(lapply(entries, .render_catalog_entry, prefix = "design"))
  })

  output$home_groups_result <- renderUI({
    req(input$home_outcome_type, input$home_groups)
    if (identical(input$home_groups, "2")) req(input$home_dependency)
    if (identical(input$home_groups, "1")) req(input$home_has_reference)

    wants_reference <- identical(input$home_has_reference, "yes")
    match_entry <- Find(function(e) {
      identical(e$outcome_type, input$home_outcome_type) &&
        identical(e$groups, input$home_groups) &&
        (!identical(input$home_groups, "2") || identical(e$dependency, input$home_dependency)) &&
        (!identical(input$home_groups, "1") || is.na(e$reference_based) ||
           identical(e$reference_based, wants_reference))
    }, calculator_catalog)
    if (is.null(match_entry)) return(.coming_soon_note())
    .render_catalog_entry(match_entry, prefix = "groups")
  })

  # One click-observer per (finder tab prefix) x (built catalog entry). Button
  # ids are prefixed per finder tab so the same calculator can be offered as a
  # result in both tabs without colliding DOM ids.
  for (prefix in c("design", "groups")) {
    lapply(calculator_catalog, function(entry) {
      if (!isTRUE(entry$built)) return(invisible(NULL))
      btn_id <- paste0("jump_", prefix, "_", entry$key)
      observeEvent(input[[btn_id]], {
        nav_select("main_nav", entry$nav_target, session = session)
        if (!is.na(entry$module_input_id)) {
          updateRadioButtons(session, entry$module_input_id, selected = entry$design_value)
        }
      }, ignoreInit = TRUE)
    })
  }
}

.render_catalog_entry <- function(entry, prefix) {
  answers_p <- if (!is.null(entry$answers) && !is.na(entry$answers)) {
    p(class = "text-muted small mb-1", entry$answers)
  }
  if (isTRUE(entry$built)) {
    div(class = "mb-3",
        answers_p,
        actionButton(paste0("jump_", prefix, "_", entry$key), entry$label,
                     class = "btn-primary"))
  } else {
    div(class = "mb-3",
        answers_p,
        div(class = "text-muted", paste(entry$label, "— coming soon")))
  }
}

.coming_soon_note <- function() {
  div(class = "text-muted",
      "Not yet implemented in the app — see ", code("docs/SDD.md"),
      " for the roadmap.")
}
