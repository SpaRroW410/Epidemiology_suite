# ROC / AUC module: Calculate / Formula-Help / Reference sub-tabs. Follows
# the same module contract as mod_cohort.R (docs/SDD.md #8) -- a single
# calculation, no design radio needed.

roc_meta <- list(
  id = "roc",
  nav_title = "ROC / AUC"
)

mod_roc_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("auc"), "Expected AUC", value = 0.73, min = 0.501, max = 0.999, step = 0.01),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      numericInput(ns("kappa"), "Ratio of controls to cases (kappa)", value = 1.7, min = 0.1, step = 0.1),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(roc_content$single_auc$title),
      withMathJax(HTML(roc_content$single_auc$formula_latex)),
      shiny::markdown(roc_content$single_auc$explanation),
      h5("Worked example"),
      shiny::markdown(roc_content$single_auc$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(roc_content$single_auc$title),
      p(strong("Citation: "), roc_content$single_auc$citation),
      p(strong("Implemented via: "), code(roc_content$single_auc$backend))
    )
  )
}

mod_roc_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$auc, input$alpha, input$power, input$kappa)
      tryCatch(
        list(ok = TRUE, value = calc_roc_auc(
          auc = input$auc, alpha = input$alpha, power = input$power, kappa = input$kappa
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
        p(strong("Required cases (diseased): "), v$n_cases),
        p(strong("Required controls (non-diseased): "), v$n_controls),
        p(strong("Total sample size: "), v$n_total)
      )
    })
  })
}
