# Diagnostic Accuracy module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R / mod_means.R (docs/
# SDD.md #8), but has only one design (sensitivity & specificity given
# prevalence) rather than several -- so there's no design radioButtons()/
# conditionalPanel() switch here, unlike the other modules.

diagnostic_meta <- list(
  id = "diagnostic",
  nav_title = "Diagnostic Accuracy"
)

mod_diagnostic_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("sens"), "Expected sensitivity (Sn)", value = 0.90, min = 0, max = 1, step = 0.01),
      numericInput(ns("spec"), "Expected specificity (Sp)", value = 0.85, min = 0, max = 1, step = 0.01),
      numericInput(ns("prevalence"), "Expected prevalence of the target condition (P)",
                   value = 0.30, min = 0, max = 1, step = 0.01),
      numericInput(ns("prec_sens"), "Desired precision for sensitivity (W_Sn)",
                   value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("prec_spec"), "Desired precision for specificity (W_Sp)",
                   value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("conf_level"), "Confidence level",
                   value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(diagnostic_content$sens_spec$title),
      withMathJax(HTML(diagnostic_content$sens_spec$formula_latex)),
      shiny::markdown(diagnostic_content$sens_spec$explanation),
      h5("Worked example"),
      shiny::markdown(diagnostic_content$sens_spec$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(diagnostic_content$sens_spec$title),
      p(strong("Citation: "), diagnostic_content$sens_spec$citation),
      p(strong("Implemented via: "), code(diagnostic_content$sens_spec$backend))
    )
  )
}

mod_diagnostic_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$sens, input$spec, input$prevalence, input$prec_sens,
          input$prec_spec, input$conf_level)
      tryCatch(
        list(ok = TRUE, value = calc_diagnostic_accuracy(
          sens = input$sens, spec = input$spec, prevalence = input$prevalence,
          prec_sens = input$prec_sens, prec_spec = input$prec_spec,
          conf_level = input$conf_level
        )),
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
        p(strong("Required total sample size: "), v$n,
          sprintf(" (%s binds)", v$binding)),
        p(sprintf("Sensitivity requires n = %d; specificity requires n = %d", v$n_sens, v$n_spec)),
        p(sprintf("At this prevalence, that's ~%d diseased and ~%d non-diseased subjects",
                  v$n_diseased, v$n_healthy)),
        p(sprintf("Z = %.4f", v$z))
      )
    })
  })
}
