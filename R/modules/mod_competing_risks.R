# Competing Risks module: Calculate / Formula-Help / Reference sub-tabs.
# Single design (no design radio, following mod_manova.R's pattern).

competing_risks_meta <- list(
  id = "competing_risks",
  nav_title = "Competing Risks"
)

mod_competing_risks_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("lambda_11"), "Cause-1 cause-specific hazard, group 1 (lambda_11)",
                   value = 0.3, min = 0.0001, step = 0.01),
      numericInput(ns("hr_1"), "Cause-1 cause-specific hazard ratio (hr_1)", value = 1.44, min = 0.001, step = 0.01),
      numericInput(ns("hr_all"), "Any-cause hazard ratio (hr_all)", value = 1.33, min = 0.001, step = 0.01),
      numericInput(ns("rr"), "Relative risk, cause-1 vs. any-cause failure, group 1 (rr)",
                   value = 0.8, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("accrual"), "Accrual (enrollment) period length", value = 1, min = 0, step = 0.1),
      numericInput(ns("follow_up"), "Total follow-up period", value = 8, min = 0.001, step = 0.5),
      numericInput(ns("attrition"), "Attrition (loss to follow-up) rate", value = 0.1, min = 0, max = 0.999, step = 0.01),
      numericInput(ns("a1"), "Allocation proportion to group 1", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
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
      h4(competing_risks_content$joint$title),
      render_formula_block(competing_risks_content$joint$formula_latex),
      shiny::markdown(competing_risks_content$joint$explanation),
      h5("Worked example"),
      shiny::markdown(competing_risks_content$joint$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(competing_risks_content$joint$title),
      p(strong("Citation: "), competing_risks_content$joint$citation),
      p(strong("Implemented via: "), code(competing_risks_content$joint$backend))
    )
  )
}

mod_competing_risks_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$lambda_11, input$hr_1, input$hr_all, input$rr, input$accrual,
          input$follow_up, input$attrition, input$a1, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = calc_competing_risks_joint(
          lambda_11 = input$lambda_11, hr_1 = input$hr_1, hr_all = input$hr_all,
          rr = input$rr, accrual = input$accrual, follow_up = input$follow_up,
          attrition = input$attrition, a1 = input$a1,
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
        p(strong("Chi-square joint test: "),
          sprintf("%d cause-1 events, %d total patients", v$chi2_events, v$chi2_n)),
        p(strong("Maximum joint test: "),
          sprintf("%d cause-1 events, %d total patients", v$max_events, v$max_n)),
        p(strong("Bonferroni joint test: "),
          sprintf("%d cause-1 events, %d total patients", v$bonferroni_events, v$bonferroni_n))
      )
    })

    render_export_handlers(output, result, function() competing_risks_content$joint)
  })
}
