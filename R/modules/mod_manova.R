# MANOVA / Hotelling's T-Squared module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same module contract as mod_cohort.R
# (docs/SDD.md #8) -- a single calculation, no design radio needed.

manova_meta <- list(
  id = "manova",
  nav_title = "MANOVA / Hotelling's T²"
)

mod_manova_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("p"), "Number of response variables (p)", value = 3, min = 1, step = 1),
      numericInput(ns("d2"), "Squared Mahalanobis distance (D-squared)",
                   value = 0.25, min = 0.0001, step = 0.01),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(manova_content$hotelling$title),
      render_formula_block(manova_content$hotelling$formula_latex),
      shiny::markdown(manova_content$hotelling$explanation),
      h5("Worked example"),
      shiny::markdown(manova_content$hotelling$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(manova_content$hotelling$title),
      p(strong("Citation: "), manova_content$hotelling$citation),
      p(strong("Implemented via: "), code(manova_content$hotelling$backend))
    )
  )
}

mod_manova_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$p, input$d2, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = calc_manova_hotelling(
          p = input$p, d2 = input$d2, alpha = input$alpha, power = input$power
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

    render_export_handlers(output, result, function() manova_content$hotelling)
  })
}
