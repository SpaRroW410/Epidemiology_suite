# Cohort / RR module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_diagnostic.R (docs/SDD.md #8), but
# has only one design -- see R/calc_cohort.R and
# R/content_cohort.R for the formula and citation.

cohort_meta <- list(
  id = "cohort",
  nav_title = "Cohort / RR"
)

mod_cohort_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("p0"), "p0 (incidence risk in unexposed group)",
                   value = 0.15, min = 0.001, max = 0.999, step = 0.01),
      p(class = "text-muted small mb-1", "Fill in ONE of the following for the exposed group; the others are calculated."),
      prop_given_ui(ns, "cohort", "p1", "p1 (incidence risk in exposed group)", 0.30, ref_label = "the unexposed group"),
      numericInput(ns("ratio"), with_tip("Exposed:unexposed ratio", "allocation_ratio"), value = 1, min = 0.1, step = 0.5),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      advanced_options_ui(
        ns,
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        ),
        numericInput(ns("N"), "Eligible population size N (optional; leave blank if effectively unlimited)",
                     value = NA, min = 1)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(cohort_content$cohort$title),
      render_formula_block(cohort_content$cohort$formula_latex),
      shiny::markdown(cohort_content$cohort$explanation),
      h5("Worked example"),
      shiny::markdown(cohort_content$cohort$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(cohort_content$cohort$title),
      p(strong("Citation: "), cohort_content$cohort$citation),
      p(strong("Implemented via: "), code(cohort_content$cohort$backend))
    )
  )
}

mod_cohort_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    prop_given_server(input, output, "cohort", "p1", ref = function() input$p0, ref_name = "the unexposed group")
    result <- reactive({
      req(input$p0, input$ratio, input$alpha, input$power, input$alternative)

      N <- input$N
      if (is.null(N) || is.na(N)) N <- NULL

      tryCatch(
        list(ok = TRUE, value = do.call(calc_cohort, c(list(
          p0 = input$p0, power = input$power, ratio = input$ratio,
          alpha = input$alpha, alternative = input$alternative, N = N
        ), prop_given_args(input, "cohort", "p1")))),
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
        p(strong("Total sample size: "), v$n_total),
        p(sprintf("Exposed: %d, Unexposed: %d", v$n_exposed, v$n_unexposed)),
        p(sprintf("Implied relative risk (RR): %.3f; odds ratio %.3f; risk difference %.3f; exposed-group risk p1 = %.4f",
                  v$rr, v$odds_ratio, v$risk_difference, v$p1))
      )
    })

    render_export_handlers(output, result, function() cohort_content$cohort)

    render_power_curves(output, function() {
      p1 <- prop_given_p1(input, "cohort", "p1", input$p0)
      req(input$p0, p1, input$ratio, input$alpha, input$power, input$alternative)
      N <- input$N
      if (is.null(N) || is.na(N)) N <- NULL
      list(
        calc_fn = calc_cohort,
        args = list(p0 = input$p0, p1 = p1, ratio = input$ratio, alpha = input$alpha,
                     power = input$power, alternative = input$alternative, N = N),
        effect = list(param = "p1", values = curve_range_proportion(), label = "p1 (incidence risk in exposed group)"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
