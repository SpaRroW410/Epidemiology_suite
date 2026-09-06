# Ratio Estimation module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_agreement.R (docs/SDD.md #8)
# -- three precision-based (CI-width) designs, each wrapping a presize::
# function, same convention as the Agreement module's kappa/ICC/Cronbach/
# Bland-Altman designs.

ratio_meta <- list(
  id = "ratio",
  nav_title = "Ratio Estimation"
)

mod_ratio_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Risk ratio (relative risk)" = "risk_ratio",
          "Odds ratio" = "odds_ratio",
          "Rate ratio" = "rate_ratio"
        ),
        selected = "risk_ratio"
      ),
      conditionalPanel(
        condition = design_is("risk_ratio"),
        numericInput(ns("p1_rr"), "p1 (risk in exposed group)", value = 0.2, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_rr"), "p2 (risk in unexposed group)", value = 0.03, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("r_rr"), "Allocation ratio (r = n2/n1)", value = 1, min = 0.1, step = 0.1),
        numericInput(ns("conf_width_rr"), "Desired CI width", value = 5, min = 0.01, step = 0.5),
        numericInput(ns("conf_level_rr"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        selectInput(ns("method_rr"), "Method", choices = c("Koopman (recommended)" = "koopman", "Katz" = "katz"))
      ),
      conditionalPanel(
        condition = design_is("odds_ratio"),
        numericInput(ns("p1_or"), "p1 (proportion with outcome, group 1)", value = 0.1, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_or"), "p2 (proportion with outcome, group 2)", value = 0.15, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("r_or"), "Allocation ratio (r = n2/n1)", value = 1, min = 0.1, step = 0.1),
        numericInput(ns("conf_width_or"), "Desired CI width", value = 1.2, min = 0.01, step = 0.1),
        numericInput(ns("conf_level_or"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        selectInput(ns("method_or"), "Method", choices = c("indip_smooth (recommended)" = "indip_smooth", "Gart" = "gart", "Woolf" = "woolf"))
      ),
      conditionalPanel(
        condition = design_is("rate_ratio"),
        numericInput(ns("rate1_rrt"), "Rate in exposed group", value = 0.5, min = 0.001, step = 0.1),
        numericInput(ns("rate2_rrt"), "Rate in unexposed group", value = 3, min = 0.001, step = 0.1),
        numericInput(ns("r_rrt"), "Allocation ratio (r = n2/n1)", value = 1, min = 0.1, step = 0.1),
        numericInput(ns("prec_level_rrt"), "Desired precision level (CI upper/lower ratio)", value = 3.81, min = 1.01, step = 0.1),
        numericInput(ns("conf_level_rrt"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(ratio_content$risk_ratio$title),
      render_formula_block(ratio_content$risk_ratio$formula_latex),
      shiny::markdown(ratio_content$risk_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(ratio_content$risk_ratio$worked_example),
      hr(),
      h4(ratio_content$odds_ratio$title),
      render_formula_block(ratio_content$odds_ratio$formula_latex),
      shiny::markdown(ratio_content$odds_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(ratio_content$odds_ratio$worked_example),
      hr(),
      h4(ratio_content$rate_ratio$title),
      render_formula_block(ratio_content$rate_ratio$formula_latex),
      shiny::markdown(ratio_content$rate_ratio$explanation),
      h5("Worked example"),
      shiny::markdown(ratio_content$rate_ratio$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(ratio_content$risk_ratio$title),
      p(strong("Citation: "), ratio_content$risk_ratio$citation),
      p(strong("Implemented via: "), code(ratio_content$risk_ratio$backend)),
      hr(),
      h4(ratio_content$odds_ratio$title),
      p(strong("Citation: "), ratio_content$odds_ratio$citation),
      p(strong("Implemented via: "), code(ratio_content$odds_ratio$backend)),
      hr(),
      h4(ratio_content$rate_ratio$title),
      p(strong("Citation: "), ratio_content$rate_ratio$citation),
      p(strong("Implemented via: "), code(ratio_content$rate_ratio$backend))
    )
  )
}

mod_ratio_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      tryCatch({
        value <- if (input$design == "risk_ratio") {
          req(input$p1_rr, input$p2_rr, input$r_rr, input$conf_width_rr, input$conf_level_rr, input$method_rr)
          calc_precision_riskratio(
            p1 = input$p1_rr, p2 = input$p2_rr, r = input$r_rr,
            conf_width = input$conf_width_rr, conf_level = input$conf_level_rr,
            method = input$method_rr
          )
        } else if (input$design == "odds_ratio") {
          req(input$p1_or, input$p2_or, input$r_or, input$conf_width_or, input$conf_level_or, input$method_or)
          calc_precision_or(
            p1 = input$p1_or, p2 = input$p2_or, r = input$r_or,
            conf_width = input$conf_width_or, conf_level = input$conf_level_or,
            method = input$method_or
          )
        } else {
          req(input$rate1_rrt, input$rate2_rrt, input$r_rrt, input$prec_level_rrt, input$conf_level_rrt)
          calc_precision_rateratio(
            rate1 = input$rate1_rrt, rate2 = input$rate2_rrt, r = input$r_rrt,
            prec_level = input$prec_level_rrt, conf_level = input$conf_level_rrt
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
      if (res$design == "rate_ratio") {
        tagList(
          p(strong("Required sample size: "), sprintf("n1 = %d, n2 = %d (total = %d)", v$n1, v$n2, v$n_total)),
          p(sprintf("Achieved precision level at this n: %.4f", v$achieved_prec_level))
        )
      } else {
        tagList(
          p(strong("Required sample size: "), sprintf("n1 = %d, n2 = %d (total = %d)", v$n1, v$n2, v$n_total)),
          p(sprintf("Achieved CI width at this n: %.4f", v$achieved_width))
        )
      }
    })
  })
}
