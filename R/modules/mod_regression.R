# Multiple Regression module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed.

regression_meta <- list(
  id = "regression",
  nav_title = "Multiple Regression"
)

mod_regression_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("r2"), "Expected R-squared", value = 0.10, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("num_predictors"), "Number of predictors", value = 5, min = 1, step = 1),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(regression_content$r2$title),
      withMathJax(HTML(regression_content$r2$formula_latex)),
      shiny::markdown(regression_content$r2$explanation),
      h5("Worked example"),
      shiny::markdown(regression_content$r2$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(regression_content$r2$title),
      p(strong("Citation: "), regression_content$r2$citation),
      p(strong("Implemented via: "), code(regression_content$r2$backend))
    )
  )
}

mod_regression_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$r2, input$num_predictors, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = calc_regression_f2(
          r2 = input$r2, num_predictors = input$num_predictors,
          alpha = input$alpha, power = input$power
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
        p(strong("Required total sample size: "), v$n),
        p(sprintf("Effect size f2 = %.4f", v$f2))
      )
    })
  })
}
