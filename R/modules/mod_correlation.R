# Correlation module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed.

correlation_meta <- list(
  id = "correlation",
  nav_title = "Correlation"
)

mod_correlation_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("r"), "Expected correlation (r)", value = 0.3, min = -0.99, max = 0.99, step = 0.01),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      selectInput(
        ns("alternative"), "Alternative hypothesis",
        choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(correlation_content$pearson$title),
      render_formula_block(correlation_content$pearson$formula_latex),
      shiny::markdown(correlation_content$pearson$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$pearson$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(correlation_content$pearson$title),
      p(strong("Citation: "), correlation_content$pearson$citation),
      p(strong("Implemented via: "), code(correlation_content$pearson$backend))
    )
  )
}

mod_correlation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$r, input$alpha, input$power, input$alternative)
      tryCatch(
        list(ok = TRUE, value = calc_correlation(
          r = input$r, alpha = input$alpha, power = input$power,
          alternative = input$alternative
        )),
        error = function(e) list(ok = FALSE, message = conditionMessage(e))
      )
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }
      p(strong("Required sample size: "), res$value$n)
    })
  })
}
