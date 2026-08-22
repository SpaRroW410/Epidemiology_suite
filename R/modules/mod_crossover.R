# Crossover Trial (2x2) module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same module contract as mod_roc.R (docs/SDD.md #8)
# -- a single calculation, no design radio needed.

crossover_meta <- list(
  id = "crossover",
  nav_title = "Crossover Trial (2x2)"
)

mod_crossover_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("delta"), "True mean difference to detect (delta)", value = 0.2, step = 0.05),
      numericInput(ns("sigma"), "Within-subject standard deviation (sigma)",
                   value = 0.4, min = 0.0001, step = 0.05),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(crossover_content$crossover_2x2$title),
      withMathJax(HTML(crossover_content$crossover_2x2$formula_latex)),
      shiny::markdown(crossover_content$crossover_2x2$explanation),
      h5("Worked example"),
      shiny::markdown(crossover_content$crossover_2x2$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(crossover_content$crossover_2x2$title),
      p(strong("Citation: "), crossover_content$crossover_2x2$citation),
      p(strong("Implemented via: "), code(crossover_content$crossover_2x2$backend))
    )
  )
}

mod_crossover_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$delta, input$sigma, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = calc_crossover_2x2(
          delta = input$delta, sigma = input$sigma, alpha = input$alpha, power = input$power
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
        p(strong("Subjects per sequence: "), v$n_per_sequence),
        p(strong("Total sample size (both sequences): "), v$n_total)
      )
    })
  })
}
