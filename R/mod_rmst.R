# RMST Comparison module: Calculate / Formula-Help / Reference sub-tabs.
# Single design (no design radio, following mod_manova.R's pattern).

rmst_meta <- list(
  id = "rmst",
  nav_title = "RMST Comparison"
)

mod_rmst_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("ac_period"), "Accrual period (time of last enrollment)", value = 35, min = 0.001, step = 1),
      numericInput(ns("tot_time"), "Total study time (time of final analysis)", value = 510, min = 0.001, step = 1),
      numericInput(ns("tau"), "RMST truncation time (tau)", value = 500, min = 0.001, step = 1),
      numericInput(ns("shape0"), "Weibull shape, arm 0 (control)", value = 1, min = 0.001, step = 0.1),
      numericInput(ns("scale0"), "Weibull scale, arm 0 (control)", value = 8500, min = 0.001, step = 100),
      numericInput(ns("shape1"), "Weibull shape, arm 1 (treatment)", value = 1, min = 0.001, step = 0.1),
      numericInput(ns("scale1"), "Weibull scale, arm 1 (treatment)", value = 8500, min = 0.001, step = 100),
      numericInput(ns("margin"), "Non-inferiority margin (0 = superiority test)", value = 0, min = 0, step = 1),
      numericInput(ns("allocation1"), "Allocation proportion to arm 1", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("alpha"), "Significance level (alpha, two-sided)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      monte_carlo_calculate_ui(ns),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(rmst_content$comparison$title),
      render_formula_block(rmst_content$comparison$formula_latex),
      shiny::markdown(rmst_content$comparison$explanation),
      h5("Worked example"),
      shiny::markdown(rmst_content$comparison$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(rmst_content$comparison$title),
      p(strong("Citation: "), rmst_content$comparison$citation),
      p(strong("Implemented via: "), code(rmst_content$comparison$backend))
    )
  )
}

mod_rmst_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Monte Carlo (ROADMAP F9/P1#7): recompute only on Calculate, not on every
    # keystroke -- see monte_carlo_calculate_ui()'s comment in mod_shared_ui.R.
    result <- reactive({
      input$calculate
      isolate({
        req(input$ac_period, input$tot_time, input$tau, input$shape0, input$scale0,
            input$shape1, input$scale1, input$margin, input$allocation1, input$alpha, input$power)
        tryCatch(
          list(ok = TRUE, value = calc_rmst_comparison(
            ac_period = input$ac_period, tot_time = input$tot_time, tau = input$tau,
            shape0 = input$shape0, scale0 = input$scale0,
            shape1 = input$shape1, scale1 = input$scale1,
            margin = input$margin, allocation1 = input$allocation1,
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      })
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      tagList(
        p(strong("Sample size: "),
          sprintf("n = %d per arm (%d total): %d expected events on arm 0, %d on arm 1",
                  v$n0, v$n_total, v$n0_events, v$n1_events)),
        p(strong("Achieved power (separate variance): "), sprintf("%.3f", v$achieved_power_separate)),
        p(strong("Achieved power (pooled variance): "), sprintf("%.3f", v$achieved_power_pooled))
      )
    })

    render_export_handlers(output, result, function() rmst_content$comparison)
  })
}
