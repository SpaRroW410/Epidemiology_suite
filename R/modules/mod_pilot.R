# Pilot / Feasibility module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed. Unlike every other module,
# this one is guidance (a rule of thumb + a precision illustration), not a
# sample-size formula -- see R/calc/calc_pilot.R and
# R/content/content_pilot.R.

pilot_meta <- list(
  id = "pilot",
  nav_title = "Pilot / Feasibility"
)

mod_pilot_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      div(class = "alert alert-info",
          strong("Rule of thumb: "), "12 subjects per arm (Julious 2005). ",
          "There is no sample-size formula for pilot studies -- use the tool ",
          "below to see how precisely a given pilot size will estimate the ",
          "variance you'll use to plan your main trial."),
      numericInput(ns("n"), "Pilot sample size per arm", value = 12, min = 2, step = 1),
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(pilot_content$rule_of_thumb$title),
      render_formula_block(pilot_content$rule_of_thumb$formula_latex),
      shiny::markdown(pilot_content$rule_of_thumb$explanation),
      h5("Worked example"),
      shiny::markdown(pilot_content$rule_of_thumb$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(pilot_content$rule_of_thumb$title),
      p(strong("Citation: "), pilot_content$rule_of_thumb$citation),
      p(strong("Implemented via: "), code(pilot_content$rule_of_thumb$backend))
    )
  )
}

mod_pilot_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$n, input$conf_level)
      tryCatch(
        list(ok = TRUE, value = calc_pilot_sd_precision(n = input$n, conf_level = input$conf_level)),
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
        p(sprintf("At n = %d, the %.0f%% CI for the true SD spans %.2fx to %.2fx whatever SD you observe in the pilot.",
                  input$n, input$conf_level * 100, v$lower_mult, v$upper_mult)),
        if (input$n < 12) {
          div(class = "text-warning", "This is below the commonly-used 12-per-arm rule of thumb.")
        }
      )
    })
  })
}
