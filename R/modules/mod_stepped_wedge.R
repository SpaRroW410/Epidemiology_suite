# Stepped-Wedge CRT module: Calculate / Formula-Help / Reference sub-tabs.
# Single-design module (continuous outcome only), following the same
# simple pattern as mod_evpi.R.

stepped_wedge_meta <- list(
  id = "stepped_wedge",
  nav_title = "Stepped-Wedge CRT"
)

mod_stepped_wedge_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("nsubjects"), "Subjects per cluster per time point (m)",
                   value = 10, min = 0.001, step = 1),
      numericInput(ns("ntimes"), "Number of post-baseline time points (T)",
                   value = 4, min = 2, step = 1),
      numericInput(ns("d"), "Expected (absolute) treatment effect (d)",
                   value = 0.25, step = 0.05),
      numericInput(ns("icc"), "Intracluster correlation (ICC)",
                   value = 0.05, min = 0, max = 0.999, step = 0.01),
      numericInput(ns("rho_c"), "Cluster autocorrelation (rho_c)",
                   value = 0.5, min = 0, max = 1, step = 0.05),
      numericInput(ns("rho_s"), "Individual autocorrelation (rho_s; 0 = cross-sectional)",
                   value = 0, min = 0, max = 1, step = 0.05),
      numericInput(ns("vart"), "Total outcome variance", value = 1, min = 0.0001, step = 0.1),
      numericInput(ns("alpha"), "Two-sided alpha", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(stepped_wedge_content$normal$title),
      render_formula_block(stepped_wedge_content$normal$formula_latex),
      shiny::markdown(stepped_wedge_content$normal$explanation),
      h5("Worked example"),
      shiny::markdown(stepped_wedge_content$normal$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      p(strong("Citation: "), stepped_wedge_content$normal$citation),
      p(strong("Implemented via: "), code(stepped_wedge_content$normal$backend))
    )
  )
}

mod_stepped_wedge_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$nsubjects, input$ntimes, input$d, input$icc, input$rho_c,
          input$rho_s, input$vart, input$alpha, input$power)

      tryCatch(
        list(ok = TRUE, value = calc_stepped_wedge_normal(
          nsubjects = input$nsubjects, ntimes = input$ntimes, d = input$d,
          icc = input$icc, rho_c = input$rho_c, rho_s = input$rho_s,
          vart = input$vart, alpha = input$alpha, power = input$power
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
        p(strong("Required clusters crossing over at each step: "), v$nclusters),
        p(strong("Total clusters (steps x nclusters per step): "), v$nclusters * (input$ntimes)),
        p(sprintf("Achieved power = %.3f (design effect: cluster %.3f x time %.3f = VIF %.3f)",
                   v$achieved_power, v$deff_cluster, v$deff_time, v$vif))
      )
    })

    render_export_handlers(output, result, function() stepped_wedge_content$normal)
  })
}
