# Capture-Recapture module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_pilot.R (docs/SDD.md #8) -- a
# single precision-based calculation, no design radio needed. See
# R/calc/calc_capture_recapture.R and R/content/content_capture_recapture.R.

capture_recapture_meta <- list(
  id = "capture_recapture",
  nav_title = "Capture-Recapture"
)

mod_capture_recapture_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      div(class = "alert alert-info",
          strong("Precision-based, not a hypothesis test: "),
          "plans the second-sample size n2 to achieve a target precision on ",
          "the estimated population size N, given an already-fixed first ",
          "sample size n1 and an assumed planning value of N."),
      numericInput(ns("N"), "Assumed true population size (N, planning estimate)", value = 1000, min = 2, step = 1),
      numericInput(ns("n1"), "First-sample (marking) size, n1", value = 100, min = 1, step = 1),
      numericInput(ns("precision"), "Target relative precision (fraction of N, e.g. 0.10 for +/-10%)",
                   value = 0.10, min = 0.001, max = 0.99, step = 0.01),
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(capture_recapture_content$chapman_precision$title),
      render_formula_block(capture_recapture_content$chapman_precision$formula_latex),
      shiny::markdown(capture_recapture_content$chapman_precision$explanation),
      h5("Worked example"),
      shiny::markdown(capture_recapture_content$chapman_precision$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(capture_recapture_content$chapman_precision$title),
      p(strong("Citation: "), capture_recapture_content$chapman_precision$citation),
      p(strong("Implemented via: "), code(capture_recapture_content$chapman_precision$backend))
    )
  )
}

mod_capture_recapture_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$N, input$n1, input$precision, input$conf_level)
      tryCatch(
        list(ok = TRUE, value = calc_capture_recapture_n2(
          N = input$N, n1 = input$n1, precision = input$precision, conf_level = input$conf_level
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
        p(sprintf("Second-sample size needed: n2 = %d (expecting about %.1f recaptures).",
                  v$n2, v$expected_recaptures)),
        p(sprintf("Achieved precision at this n2: +/-%.2f%% (target was +/-%.2f%%) at %.0f%% confidence.",
                  v$achieved_precision * 100, v$precision * 100, v$conf_level * 100)),
        div(class = "text-muted small",
            "Remember: this plan depends on the assumed population size N -- ",
            "if the true N differs substantially, the achieved precision will too.")
      )
    })

    render_export_handlers(output, result, function() capture_recapture_content$chapman_precision)

    # Precision curves (ROADMAP P1 item 10): a precision-based design has no
    # power, so its two curves are n against the key assumption and n against
    # the precision target.
    render_power_curves(output, function() {
      req(input$N, input$n1, input$precision, input$conf_level)
      list(
        calc_fn = calc_capture_recapture_n2,
        args = list(N = input$N, n1 = input$n1, precision = input$precision, conf_level = input$conf_level),
        effect = list(param = "N", values = curve_range_multiplicative(input$N),
                      label = "Assumed population size (N)",
                      title = "Required second-sample size vs. population size"),
        power = list(param = "precision", values = curve_range_multiplicative(input$precision, 0.3, 3),
                      label = "Desired precision",
                      title = "Required second-sample size vs. precision")
      )
    })
  })
}
