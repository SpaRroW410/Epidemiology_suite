# Mendelian Randomisation module: Calculate / Formula-Help / Reference sub-tabs. Two designs (continuous or binary outcome, single
# genetic instrument; Burgess 2014), each solved for the sample size or for the power at a given sample size. Follows the
# design-radio pattern of mod_patient_units.R (docs/SDD.md #8).

mendelian_meta <- list(
  id = "mendelian",
  nav_title = "Mendelian Randomisation"
)

mod_mendelian_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  solve_is <- function(value) sprintf("input['%s'] == '%s'", ns("solve"), value)
  both <- function(a, b) sprintf("(%s) && (%s)", a, b)
  help_block <- function(d) tagList(
    h4(mendelian_content[[d]]$title),
    render_formula_block(mendelian_content[[d]]$formula_latex),
    shiny::markdown(mendelian_content[[d]]$explanation),
    h5("Worked example"),
    shiny::markdown(mendelian_content[[d]]$worked_example))
  ref_block <- function(d) tagList(
    h4(mendelian_content[[d]]$title),
    p(strong("Citation: "), mendelian_content[[d]]$citation),
    p(strong("Implemented via: "), code(mendelian_content[[d]]$backend)))

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Outcome",
        choices = c("A measurement (continuous outcome, e.g. blood pressure)" = "continuous",
                    "A disease or event, yes / no (binary outcome, cases and controls)" = "binary"),
        selected = "continuous"
      ),
      radioButtons(
        ns("solve"), "Find",
        choices = c("Sample size (for a chosen power)" = "n", "Power (for a sample size you have)" = "power"),
        selected = "n"
      ),
      conditionalPanel(
        condition = design_is("continuous"),
        numericInput(ns("beta"), "Causal effect to detect: SD change in the outcome per SD increase in the exposure (beta1)",
                     value = 0.2, step = 0.05)
      ),
      conditionalPanel(
        condition = design_is("binary"),
        numericInput(ns("or"), "Causal odds ratio to detect, per SD increase in the exposure (OR)", value = 1.2, min = 0.001, step = 0.05),
        numericInput(ns("controls_per_case"), "Controls per case", value = 1, min = 0.01, step = 0.5)
      ),
      numericInput(ns("r2"), "Share of the exposure's variance explained by the genetic instrument (R-squared, 0 to 1; 0.02 = 2%)",
                   value = 0.02, min = 0.0001, max = 0.999, step = 0.005),
      numericInput(ns("alpha"), "Significance level (two-sided)", value = 0.05, min = 0.0001, max = 0.5, step = 0.01),
      conditionalPanel(
        condition = solve_is("n"),
        numericInput(ns("power"), "Power", value = 0.8, min = 0.5, max = 0.999, step = 0.05)
      ),
      conditionalPanel(
        condition = both(solve_is("power"), design_is("continuous")),
        numericInput(ns("n"), "Participants available", value = 5000, min = 3, step = 100)
      ),
      conditionalPanel(
        condition = both(solve_is("power"), design_is("binary")),
        numericInput(ns("n_cases"), "Cases available (controls = cases x controls per case)", value = 5000, min = 3, step = 100)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel("Formula / Help", br(), help_block("continuous"), hr(), help_block("binary")),
    tabPanel("Reference", br(), ref_block("continuous"), hr(), ref_block("binary"))
  )
}

mod_mendelian_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # the calc function and its arguments for the current outcome and "Find" choice (NULL while an input is empty)
    spec <- reactive({
      req(input$design, input$solve, input$r2, input$alpha)
      find_n <- input$solve == "n"
      if (find_n) req(input$power)
      if (input$design == "continuous") {
        req(input$beta)
        if (!find_n) req(input$n)
        list(fn = calc_mr_continuous, args = list(beta = input$beta, r2 = input$r2, alpha = input$alpha, power = input$power,
                                                  n = if (!find_n) input$n))
      } else {
        req(input$or, input$controls_per_case)
        if (!find_n) req(input$n_cases)
        list(fn = calc_mr_binary, args = list(or = input$or, r2 = input$r2, controls_per_case = input$controls_per_case,
                                              alpha = input$alpha, power = input$power, n_cases = if (!find_n) input$n_cases))
      }
    })

    result <- reactive({
      s <- spec()
      tryCatch(list(ok = TRUE, value = do.call(s$fn, s$args)),
               error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      pw <- sprintf("%.1f%%", 100 * v$achieved_power)
      size <- if (input$design == "continuous") sprintf("%s participants", format(v$n, big.mark = ","))
              else sprintf("%s cases and %s controls (%s in total)", format(v$n_cases, big.mark = ","),
                           format(v$n_controls, big.mark = ","), format(v$n_total, big.mark = ","))
      tagList(
        if (input$solve == "n") tagList(p(strong("Sample size needed: "), size), p(class = "text-muted", "Power at that size: ", pw))
        else tagList(p(strong("Power: "), pw), p(class = "text-muted", paste0("With ", size, "."))),
        p(class = "text-muted small", sprintf(
          "The instrument explains %s%% of the exposure, so this study needs about %s times the sample of a direct study of exposure and outcome.",
          format(100 * input$r2), format(round(1 / input$r2))))
      )
    })

    render_export_handlers(output, result, function() mendelian_content[[input$design]])

    # Curves (sample size solved for only): sample size against the instrument's R-squared, the input the source says to vary,
    # and against power.
    render_power_curves(output, function() {
      s <- spec()
      if (input$solve != "n") return(NULL)
      list(
        calc_fn = s$fn, args = s$args[setdiff(names(s$args), c("n", "n_cases"))],
        effect = list(param = "r2", values = curve_range_within(0.002, 0.2),
                      label = "Share of the exposure explained by the instrument (R-squared)",
                      title = "Required sample size vs. instrument strength"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
