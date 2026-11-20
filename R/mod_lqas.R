# LQAS module: Calculate / Formula-Help / Reference sub-tabs. Follows the
# same single-design module contract as mod_manova.R (docs/SDD.md #8) --
# one calculation, no design radio needed.

lqas_meta <- list(
  id = "lqas",
  nav_title = "LQAS"
)

mod_lqas_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("p_upper"), "Upper threshold (acceptable/high-performing proportion)",
                   value = 0.80, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("p_lower"), "Lower threshold (unacceptable/low-performing proportion)",
                   value = 0.50, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("alpha"), "Producer's risk (alpha)", value = 0.10, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("beta"), "Consumer's risk (beta)", value = 0.10, min = 0.001, max = 0.5, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(lqas_content$standard$title),
      render_formula_block(lqas_content$standard$formula_latex),
      shiny::markdown(lqas_content$standard$explanation),
      h5("Worked example"),
      shiny::markdown(lqas_content$standard$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(lqas_content$standard$title),
      p(strong("Citation: "), lqas_content$standard$citation),
      p(strong("Implemented via: "), code(lqas_content$standard$backend))
    )
  )
}

mod_lqas_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$p_upper, input$p_lower, input$alpha, input$beta)
      tryCatch(
        list(ok = TRUE, value = calc_lqas(
          p_upper = input$p_upper, p_lower = input$p_lower,
          alpha = input$alpha, beta = input$beta
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
        p(strong("Required sample size: "), v$n),
        p(strong("Decision threshold (accept if X >= d): "), v$d),
        p(sprintf("Achieved producer's risk (alpha): %.4f", v$alpha_achieved)),
        p(sprintf("Achieved consumer's risk (beta): %.4f", v$beta_achieved))
      )
    })

    render_export_handlers(output, result, function() lqas_content$standard)

    # Power curves (ROADMAP P1 item 10): LQAS has no power input, but its
    # consumer's risk beta is the type II error -- the chance a bad lot
    # (p = p_lower) is wrongly accepted -- so power = 1 - beta. calc_lqas()
    # is called through an adapter that exposes it as `power`.
    lqas_by_power <- function(p_upper, p_lower, alpha, power) {
      calc_lqas(p_upper = p_upper, p_lower = p_lower, alpha = alpha, beta = 1 - power)
    }
    render_power_curves(output, function() {
      req(input$p_upper, input$p_lower, input$alpha, input$beta)
      list(
        calc_fn = lqas_by_power,
        args = list(p_upper = input$p_upper, p_lower = input$p_lower, alpha = input$alpha,
                     power = 1 - input$beta),
        effect = list(param = "p_lower", values = curve_range_within(0, input$p_upper),
                      label = "p_lower (unacceptable proportion)"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
