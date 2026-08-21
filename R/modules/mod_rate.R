# Incidence Rate module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed.

rate_meta <- list(
  id = "rate",
  nav_title = "Incidence Rate"
)

mod_rate_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("rate"), "Expected rate (events per unit person-time)", value = 2.5, min = 0.0001),
      numericInput(ns("conf_width"), "Desired confidence interval width (same units as rate)", value = 2.243, min = 0.0001),
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      selectInput(ns("method"), "Method",
                  choices = c("Score (general-purpose default)" = "score",
                              "Exact (recommended if < 5 events expected)" = "exact",
                              "Variance-stabilizing" = "vs",
                              "Wald" = "wald")),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(rate_content$precision$title),
      withMathJax(HTML(rate_content$precision$formula_latex)),
      shiny::markdown(rate_content$precision$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$precision$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(rate_content$precision$title),
      p(strong("Citation: "), rate_content$precision$citation),
      p(strong("Implemented via: "), code(rate_content$precision$backend))
    )
  )
}

mod_rate_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$rate, input$conf_width, input$conf_level, input$method)
      tryCatch(
        list(ok = TRUE, value = calc_rate_precision(
          rate = input$rate, conf_width = input$conf_width,
          conf_level = input$conf_level, method = input$method
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
        p(strong("Required number of events: "), v$n_events),
        p(strong("Required person-time: "), sprintf("%.2f", v$person_time)),
        p(sprintf("Achieved CI width at this n: %.4f", v$achieved_conf_width))
      )
    })
  })
}
