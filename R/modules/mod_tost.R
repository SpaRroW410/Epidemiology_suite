# TOST Equivalence module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_cohort.R (docs/SDD.md #8) -- a
# single calculation, no design radio needed.

tost_meta <- list(
  id = "tost",
  nav_title = "Equivalence (TOST)"
)

mod_tost_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("mean_diff"), "Expected difference in means (test - reference)", value = 0.5),
      numericInput(ns("margin"), "Equivalence margin (+/-)", value = 2, min = 0.0001),
      numericInput(ns("sd"), "Common/pooled standard deviation", value = 5, min = 0.0001),
      numericInput(ns("alpha"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(tost_content$means$title),
      withMathJax(HTML(tost_content$means$formula_latex)),
      shiny::markdown(tost_content$means$explanation),
      h5("Worked example"),
      shiny::markdown(tost_content$means$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(tost_content$means$title),
      p(strong("Citation: "), tost_content$means$citation),
      p(strong("Implemented via: "), code(tost_content$means$backend))
    )
  )
}

mod_tost_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$mean_diff, input$margin, input$sd, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = calc_tost_means(
          mean_diff = input$mean_diff, margin = input$margin, sd = input$sd,
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
        p(strong("Required sample size per group: "), v$n_per_group),
        p(strong("Total sample size: "), v$n_total),
        p(sprintf("Achieved power at this n: %.4f", v$achieved_power))
      )
    })
  })
}
