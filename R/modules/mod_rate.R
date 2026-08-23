# Incidence Rate module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8).

rate_meta <- list(
  id = "rate",
  nav_title = "Incidence Rate"
)

mod_rate_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Single rate, precision-based (no comparison)" = "precision",
          "Comparison of two rates" = "comparison"
        )
      ),
      conditionalPanel(
        condition = design_is("precision"),
        numericInput(ns("rate"), "Expected rate (events per unit person-time)", value = 2.5, min = 0.0001),
        numericInput(ns("conf_width"), "Desired confidence interval width (same units as rate)", value = 2.243, min = 0.0001),
        numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        selectInput(ns("method"), "Method",
                    choices = c("Score (general-purpose default)" = "score",
                                "Exact (recommended if < 5 events expected)" = "exact",
                                "Variance-stabilizing" = "vs",
                                "Wald" = "wald"))
      ),
      conditionalPanel(
        condition = design_is("comparison"),
        numericInput(ns("rate_ref"), "Reference (unexposed) group rate (events per unit person-time)", value = 2.798, min = 0.0001),
        numericInput(ns("rate_ratio"), "Expected rate ratio (exposed / reference)", value = 0.8938, min = 0.0001),
        numericInput(ns("prop_exposed"), "Proportion of the sample in the exposed group", value = 0.53, min = 0.01, max = 0.99, step = 0.01),
        numericInput(ns("alpha_comp"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_comp"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative_comp"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(rate_content$precision$title),
      render_formula_block(rate_content$precision$formula_latex),
      shiny::markdown(rate_content$precision$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$precision$worked_example),
      hr(),
      h4(rate_content$comparison$title),
      render_formula_block(rate_content$comparison$formula_latex),
      shiny::markdown(rate_content$comparison$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$comparison$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(rate_content$precision$title),
      p(strong("Citation: "), rate_content$precision$citation),
      p(strong("Implemented via: "), code(rate_content$precision$backend)),
      hr(),
      h4(rate_content$comparison$title),
      p(strong("Citation: "), rate_content$comparison$citation),
      p(strong("Implemented via: "), code(rate_content$comparison$backend))
    )
  )
}

mod_rate_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "precision") {
        req(input$rate, input$conf_width, input$conf_level, input$method)
        tryCatch(
          list(ok = TRUE, value = calc_rate_precision(
            rate = input$rate, conf_width = input$conf_width,
            conf_level = input$conf_level, method = input$method
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$rate_ref, input$rate_ratio, input$prop_exposed,
            input$alpha_comp, input$power_comp, input$alternative_comp)
        tryCatch(
          list(ok = TRUE, value = calc_rate_comparison(
            rate_ref = input$rate_ref, rate_ratio = input$rate_ratio,
            prop_exposed = input$prop_exposed, alpha = input$alpha_comp,
            power = input$power_comp, alternative = input$alternative_comp
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
      if (input$design == "precision") {
        tagList(
          p(strong("Required number of events: "), v$n_events),
          p(strong("Required person-time: "), sprintf("%.2f", v$person_time)),
          p(sprintf("Achieved CI width at this n: %.4f", v$achieved_conf_width))
        )
      } else {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Exposed group: %d, Reference group: %d", v$n_exposed, v$n_reference))
        )
      }
    })
  })
}
