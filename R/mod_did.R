# Difference-in-Differences module: Calculate / Formula-Help / Reference sub-tabs. A single calculation (like mod_sccs.R), solved for
# the number of units or for the power with the units available (docs/SDD.md #8).

did_meta <- list(
  id = "did",
  nav_title = "Difference-in-Differences"
)

mod_did_ui <- function(id) {
  ns <- NS(id)
  solve_is <- function(value) sprintf("input['%s'] == '%s'", ns("solve"), value)
  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("solve"), "Find",
        choices = c("Units needed (for a chosen power)" = "n", "Power (for the units you have)" = "power"),
        selected = "n"
      ),
      numericInput(ns("delta"), "Effect to detect: extra change in the intervention group (units of the outcome)", value = 0.5, step = 0.1),
      numericInput(ns("sd"), "SD of the outcome between units", value = 1, min = 0.0001, step = 0.1),
      numericInput(ns("rho"), "Correlation between two measurements of the same unit (rho)", value = 0.55, min = 0, max = 0.99, step = 0.05),
      numericInput(ns("n_pre"), "Time points before the intervention starts (b)", value = 1, min = 1, step = 1),
      numericInput(ns("n_post"), "Time points after it starts (k)", value = 3, min = 1, step = 1),
      numericInput(ns("ratio"), "Comparison units per intervention unit", value = 1, min = 0.1, step = 0.5),
      numericInput(ns("alpha"), "Significance level (two-sided)", value = 0.05, min = 0.0001, max = 0.5, step = 0.01),
      conditionalPanel(condition = solve_is("n"),
        numericInput(ns("power"), "Power", value = 0.8, min = 0.5, max = 0.999, step = 0.05)),
      conditionalPanel(condition = solve_is("power"),
        numericInput(ns("n_intervention"), "Intervention units available", value = 30, min = 2, step = 1)),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(did_content$did$title),
      render_formula_block(did_content$did$formula_latex),
      shiny::markdown(did_content$did$explanation),
      h5("Worked example"),
      shiny::markdown(did_content$did$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(did_content$did$title),
      p(strong("Citation: "), did_content$did$citation),
      p(strong("Implemented via: "), code(did_content$did$backend))
    )
  )
}

mod_did_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    args <- reactive({
      req(input$solve, input$delta, input$sd, input$n_pre, input$n_post, input$ratio, input$alpha)
      req(!is.null(input$rho), !is.na(input$rho))
      a <- list(delta = input$delta, sd = input$sd, rho = input$rho, n_pre = input$n_pre, n_post = input$n_post, ratio = input$ratio,
                alpha = input$alpha)
      if (input$solve == "n") { req(input$power); a$power <- input$power } else { req(input$n_intervention); a$n_intervention <- input$n_intervention }
      a
    })

    result <- reactive({
      a <- args()
      tryCatch(list(ok = TRUE, value = do.call(calc_did, a)), error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      pw <- sprintf("%.1f%%", 100 * v$achieved_power)
      size <- sprintf("%s intervention and %s comparison units (%s in all), each measured %s times", v$n_intervention, v$n_comparison,
                      v$n_total, v$inputs$n_pre + v$inputs$n_post)
      tagList(
        if (input$solve == "n") tagList(p(strong("Units needed: "), size), p(class = "text-muted", "Power at that size: ", pw))
        else tagList(p(strong("Power: "), pw), p(class = "text-muted", paste0("With ", size, "."))),
        p(class = "text-muted", sprintf("Standard error of the effect: %s.", format(signif(v$se, 3)))),
        p(class = "text-muted small", "This assumes the two groups would have changed alike without the intervention (parallel trends).")
      )
    })

    render_export_handlers(output, result, function() did_content$did)

    # Curves (units solved for only): units against the within-unit correlation, and against power.
    render_power_curves(output, function() {
      a <- args()
      if (input$solve != "n") return(NULL)
      list(
        calc_fn = calc_did, args = a,
        effect = list(param = "rho", values = curve_range_within(0, 0.95), label = "Correlation between a unit's measurements (rho)",
                      title = "Required units vs. within-unit correlation"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
