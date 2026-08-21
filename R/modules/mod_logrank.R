# Log-Rank / Survival module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed.

logrank_meta <- list(
  id = "logrank",
  nav_title = "Log-Rank / Survival"
)

mod_logrank_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("pE"), "pE (cumulative event probability, experimental group)",
                   value = 0.3707, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("pC"), "pC (cumulative event probability, control group)",
                   value = 0.4890, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("hr"), "Postulated hazard ratio (HR)", value = 0.7, min = 0.01, step = 0.05),
      numericInput(ns("ratio"), "Experimental:control allocation ratio", value = 1, min = 0.1, step = 0.5),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(logrank_content$logrank$title),
      withMathJax(HTML(logrank_content$logrank$formula_latex)),
      shiny::markdown(logrank_content$logrank$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$logrank$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(logrank_content$logrank$title),
      p(strong("Citation: "), logrank_content$logrank$citation),
      p(strong("Implemented via: "), code(logrank_content$logrank$backend))
    )
  )
}

mod_logrank_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$pE, input$pC, input$hr, input$ratio, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = calc_logrank(
          pE = input$pE, pC = input$pC, hr = input$hr, ratio = input$ratio,
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
        p(strong("Total sample size: "), v$n_total),
        p(sprintf("Experimental group: %d, Control group: %d", v$n_exp, v$n_control))
      )
    })
  })
}
