# EFA/CFA Subjects-Per-Item Guidance module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same module contract as mod_pilot.R
# (docs/SDD.md #8) -- a rule-of-thumb calculator, not a hypothesis-test
# formula. See R/calc/calc_efa_cfa.R and R/content/content_efa_cfa.R.

efa_cfa_meta <- list(
  id = "efa_cfa",
  nav_title = "EFA/CFA Sample Size Guidance"
)

mod_efa_cfa_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      div(class = "alert alert-info",
          strong("Rule of thumb, not a formula: "),
          "there is no accepted power calculation for factor analysis sample ",
          "size -- these are published participant-to-item ratios, refined ",
          "over decades of practice, not a solved hypothesis test."),
      numericInput(ns("n_items"), "Number of items (EFA) or free parameters (CFA/SEM)",
                   value = 20, min = 1, step = 1),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(efa_cfa_content$rule_of_thumb$title),
      render_formula_block(efa_cfa_content$rule_of_thumb$formula_latex),
      shiny::markdown(efa_cfa_content$rule_of_thumb$explanation),
      h5("Worked example"),
      shiny::markdown(efa_cfa_content$rule_of_thumb$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(efa_cfa_content$rule_of_thumb$title),
      p(strong("Citation: "), efa_cfa_content$rule_of_thumb$citation),
      p(strong("Implemented via: "), code(efa_cfa_content$rule_of_thumb$backend))
    )
  )
}

mod_efa_cfa_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$n_items)
      tryCatch(
        list(ok = TRUE, value = calc_efa_cfa_sample_size(n_items = input$n_items)),
        error = function(e) list(ok = FALSE, message = conditionMessage(e))
      )
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      tagList(
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th("Ratio"), tags$th("Recommended N"), tags$th("Comrey & Lee (1992) label"))),
          tags$tbody(
            tags$tr(tags$td("5:1 (minimum)"), tags$td(v$n_5to1), tags$td(v$adjective_5to1)),
            tags$tr(tags$td("10:1 (commonly recommended)"), tags$td(v$n_10to1), tags$td(v$adjective_10to1)),
            tags$tr(tags$td("20:1 (more robust)"), tags$td(v$n_20to1), tags$td(v$adjective_20to1))
          )
        ),
        div(class = "text-muted small",
            "These ratios assume nothing else is known about expected communalities ",
            "or factor overdetermination -- see the Formula/Help tab's caveat ",
            "(MacCallum et al. 1999) before treating any of these as a firm target.")
      )
    })
  })
}
