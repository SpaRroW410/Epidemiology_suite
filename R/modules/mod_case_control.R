# Case-Control module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R (docs/SDD.md #8):
# a `design` radioButtons()/conditionalPanel() switch across unmatched and
# matched designs -- see R/calc/calc_case_control.R and
# R/content/content_case_control.R for the formulas and citations.

case_control_meta <- list(
  id = "case_control",
  nav_title = "Case-Control"
)

mod_case_control_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Unmatched case-control" = "unmatched",
          "Matched case-control (1:1 or 1:m)" = "matched"
        ),
        selected = "unmatched"
      ),
      numericInput(ns("p0"), "p0 (prevalence of exposure among controls)",
                   value = 0.30, min = 0.001, max = 0.999, step = 0.01),
      numericInput(ns("OR"), "Expected odds ratio (OR)", value = 2, min = 0.01, step = 0.1),
      conditionalPanel(
        condition = design_is("matched"),
        numericInput(ns("phi_coef"), "Correlation between matched case/control exposures (phi)",
                     value = 0.2, min = -0.99, max = 0.99, step = 0.01)
      ),
      numericInput(ns("ratio"), "Controls per case (ratio)", value = 1, min = 0.1, step = 0.5),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      selectInput(
        ns("alternative"), "Alternative hypothesis",
        choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
      ),
      numericInput(ns("N"), "Eligible population size N (optional; leave blank if effectively unlimited)",
                   value = NA, min = 1),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(case_control_content$unmatched$title),
      render_formula_block(case_control_content$unmatched$formula_latex),
      shiny::markdown(case_control_content$unmatched$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$unmatched$worked_example),
      hr(),
      h4(case_control_content$matched$title),
      render_formula_block(case_control_content$matched$formula_latex),
      shiny::markdown(case_control_content$matched$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$matched$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(case_control_content$unmatched$title),
      p(strong("Citation: "), case_control_content$unmatched$citation),
      p(strong("Implemented via: "), code(case_control_content$unmatched$backend)),
      hr(),
      h4(case_control_content$matched$title),
      p(strong("Citation: "), case_control_content$matched$citation),
      p(strong("Implemented via: "), code(case_control_content$matched$backend))
    )
  )
}

mod_case_control_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$p0, input$OR, input$ratio, input$alpha,
          input$power, input$alternative)

      N <- input$N
      if (is.null(N) || is.na(N)) N <- NULL

      if (input$design == "unmatched") {
        tryCatch(
          list(ok = TRUE, value = calc_case_control_unmatched(
            p0 = input$p0, OR = input$OR, power = input$power, ratio = input$ratio,
            alpha = input$alpha, alternative = input$alternative, N = N
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$phi_coef)
        tryCatch(
          list(ok = TRUE, value = calc_case_control_matched(
            p0 = input$p0, OR = input$OR, phi_coef = input$phi_coef,
            power = input$power, ratio = input$ratio, alpha = input$alpha,
            alternative = input$alternative, N = N
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      tagList(
        p(strong("Total sample size: "), v$n_total),
        p(sprintf("Cases: %d, Controls: %d", v$n_case, v$n_control))
      )
    })
  })
}
