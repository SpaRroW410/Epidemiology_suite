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

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }
  exposure_is <- function(value) sprintf("input['%s'] == '%s'", ns("exposure_type"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Unmatched case-control" = "unmatched",
          "Matched case-control (1:1 or 1:m)" = "matched",
          "Nested case-control" = "nested",
          "Case-cohort" = "case_cohort"
        ),
        selected = "unmatched"
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched"),
        numericInput(ns("p0"), "p0 (prevalence of exposure among controls)",
                     value = 0.30, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched", "nested"),
        numericInput(ns("OR"), "Expected odds ratio (OR)", value = 2, min = 0.01, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("matched"),
        numericInput(ns("phi_coef"), "Correlation between matched case/control exposures (phi)",
                     value = 0.2, min = -0.99, max = 0.99, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched"),
        numericInput(ns("ratio"), "Controls per case (ratio)", value = 1, min = 0.1, step = 0.5),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        ),
        numericInput(ns("N"), "Eligible population size N (optional; leave blank if effectively unlimited)",
                     value = NA, min = 1)
      ),
      conditionalPanel(
        condition = design_is("nested"),
        radioButtons(ns("exposure_type"), "Exposure type",
                     choices = c("Binary exposure" = "binary", "Continuous exposure" = "continuous")),
        conditionalPanel(
          condition = exposure_is("binary"),
          numericInput(ns("pE"), "Prevalence of exposure among matched sets (pE)",
                       value = 0.15, min = 0.001, max = 0.999, step = 0.01)
        ),
        conditionalPanel(
          condition = exposure_is("continuous"),
          numericInput(ns("sigma"), "Standard deviation of exposure (sigma)",
                       value = 1, min = 0.001, step = 0.1)
        ),
        numericInput(ns("nD"), "Cases per matched set (nD)", value = 1, min = 1, step = 1),
        numericInput(ns("nH"), "Controls per matched set (nH)", value = 2, min = 1, step = 1),
        numericInput(ns("R2"), "R-squared explained by other covariates (0 if none)",
                     value = 0, min = 0, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("case_cohort"),
        numericInput(ns("n_full"), "Full cohort size (n)", value = 15792, min = 1, step = 1),
        numericInput(ns("pD"), "Proportion of the cohort expected to fail (pD)",
                     value = 0.03, min = 0.001, max = 0.999, step = 0.001),
        numericInput(ns("p1"), "Proportion of the cohort in exposure group 1 (p1)",
                     value = 0.25, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("hr"), "Hazard ratio to detect (HR)", value = 1.35, min = 0.01, step = 0.05)
      ),
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
      shiny::markdown(case_control_content$matched$worked_example),
      hr(),
      h4(case_control_content$nested$title),
      render_formula_block(case_control_content$nested$formula_latex),
      shiny::markdown(case_control_content$nested$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$nested$worked_example),
      hr(),
      h4(case_control_content$case_cohort$title),
      render_formula_block(case_control_content$case_cohort$formula_latex),
      shiny::markdown(case_control_content$case_cohort$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$case_cohort$worked_example)
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
      p(strong("Implemented via: "), code(case_control_content$matched$backend)),
      hr(),
      h4(case_control_content$nested$title),
      p(strong("Citation: "), case_control_content$nested$citation),
      p(strong("Implemented via: "), code(case_control_content$nested$backend)),
      hr(),
      h4(case_control_content$case_cohort$title),
      p(strong("Citation: "), case_control_content$case_cohort$citation),
      p(strong("Implemented via: "), code(case_control_content$case_cohort$backend))
    )
  )
}

mod_case_control_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$alpha, input$power)

      tryCatch({
        value <- if (input$design == "unmatched") {
          req(input$p0, input$OR, input$ratio, input$alternative)
          N <- input$N
          if (is.null(N) || is.na(N)) N <- NULL
          calc_case_control_unmatched(
            p0 = input$p0, OR = input$OR, power = input$power, ratio = input$ratio,
            alpha = input$alpha, alternative = input$alternative, N = N
          )
        } else if (input$design == "matched") {
          req(input$p0, input$OR, input$phi_coef, input$ratio, input$alternative)
          N <- input$N
          if (is.null(N) || is.na(N)) N <- NULL
          calc_case_control_matched(
            p0 = input$p0, OR = input$OR, phi_coef = input$phi_coef,
            power = input$power, ratio = input$ratio, alpha = input$alpha,
            alternative = input$alternative, N = N
          )
        } else if (input$design == "nested") {
          req(input$exposure_type, input$OR, input$nD, input$nH, input$R2)
          if (input$exposure_type == "binary") {
            req(input$pE)
            calc_case_control_nested_binary(
              OR = input$OR, pE = input$pE, nD = input$nD, nH = input$nH,
              R2 = input$R2, alpha = input$alpha, power = input$power
            )
          } else {
            req(input$sigma)
            calc_case_control_nested_continuous(
              OR = input$OR, sigma = input$sigma, nD = input$nD, nH = input$nH,
              R2 = input$R2, alpha = input$alpha, power = input$power
            )
          }
        } else {
          req(input$n_full, input$pD, input$p1, input$hr)
          calc_case_control_case_cohort(
            n = input$n_full, pD = input$pD, p1 = input$p1, hr = input$hr,
            alpha = input$alpha, power = input$power
          )
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (res$design %in% c("unmatched", "matched")) {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Cases: %d, Controls: %d", v$n_case, v$n_control))
        )
      } else if (res$design == "nested") {
        tagList(
          p(strong("Matched sets required: "), v$n_sets),
          p(sprintf("Total subjects: %d", v$n_total))
        )
      } else {
        tagList(
          p(strong("Required subcohort size: "), v$subcohort_n),
          p(sprintf("Out of a full cohort of %d", v$full_cohort_n))
        )
      }
    })

    render_export_handlers(output, result, function() case_control_content[[input$design]])
  })
}
