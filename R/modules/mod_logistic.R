# Logistic Regression module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_tost.R
# (docs/SDD.md #8).

logistic_meta <- list(
  id = "logistic",
  nav_title = "Logistic Regression"
)

mod_logistic_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Predictor type",
        choices = c("Binary predictor" = "binary", "Continuous predictor" = "continuous",
                    "Ordinal outcome (proportional odds), two groups" = "ordinal",
                    "Binary predictor, covariate-adjusted (multiple regression)" = "binary_adjusted",
                    "Continuous predictor, covariate-adjusted (multiple regression)" = "continuous_adjusted")
      ),
      conditionalPanel(
        condition = design_is("binary"),
        numericInput(ns("p1_b"), "Event rate at X = 0 (p1)", value = 0.4, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_b"), "Event rate at X = 1 (p2)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("prop_x1"), "Proportion of sample with X = 1", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("alpha_b"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_b"), "Desired power", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("continuous"),
        numericInput(ns("p1_c"), "Event rate at the mean of the predictor (p1)",
                     value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("or"), "Expected odds ratio per one-SD increase", value = exp(0.405), min = 0.001, step = 0.1),
        numericInput(ns("alpha_c"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_c"), "Desired power", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("ordinal"),
        selectInput(ns("k_ord"), "Number of ordered categories (k)", choices = 3:8, selected = 4),
        p(class = "text-muted", "Category probabilities, averaged over the two groups, must sum to 1."),
        uiOutput(ns("ordcat_ui")),
        numericInput(ns("or_ord"), "Odds ratio between the two groups", value = 1.2, min = 0.001, step = 0.1),
        numericInput(ns("fraction_ord"), "Allocation fraction (proportion in group 1)",
                     value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("alpha_ord"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_ord"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("binary_adjusted"),
        numericInput(ns("p1_ba"), "Event rate at X = 0 (p1)", value = 0.4, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2_ba"), "Event rate at X = 1 (p2)", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("prop_x1_ba"), "Proportion of sample with X = 1", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("r2_ba"), "R-squared with other covariates", value = 0.3, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("alpha_ba"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_ba"), "Desired power", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("continuous_adjusted"),
        numericInput(ns("p1_ca"), "Event rate at the mean of the predictor (p1)",
                     value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("or_ca"), "Expected odds ratio per one-SD increase", value = exp(0.405), min = 0.001, step = 0.1),
        numericInput(ns("r2_ca"), "R-squared with other covariates", value = 0.3, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("alpha_ca"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_ca"), "Desired power", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(logistic_content$binary$title),
      render_formula_block(logistic_content$binary$formula_latex),
      shiny::markdown(logistic_content$binary$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$binary$worked_example),
      hr(),
      h4(logistic_content$continuous$title),
      render_formula_block(logistic_content$continuous$formula_latex),
      shiny::markdown(logistic_content$continuous$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$continuous$worked_example),
      hr(),
      h4(logistic_content$ordinal$title),
      render_formula_block(logistic_content$ordinal$formula_latex),
      shiny::markdown(logistic_content$ordinal$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$ordinal$worked_example),
      hr(),
      h4(logistic_content$binary_adjusted$title),
      render_formula_block(logistic_content$binary_adjusted$formula_latex),
      shiny::markdown(logistic_content$binary_adjusted$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$binary_adjusted$worked_example),
      hr(),
      h4(logistic_content$continuous_adjusted$title),
      render_formula_block(logistic_content$continuous_adjusted$formula_latex),
      shiny::markdown(logistic_content$continuous_adjusted$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$continuous_adjusted$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(logistic_content$binary$title),
      p(strong("Citation: "), logistic_content$binary$citation),
      p(strong("Implemented via: "), code(logistic_content$binary$backend)),
      hr(),
      h4(logistic_content$continuous$title),
      p(strong("Citation: "), logistic_content$continuous$citation),
      p(strong("Implemented via: "), code(logistic_content$continuous$backend)),
      hr(),
      h4(logistic_content$ordinal$title),
      p(strong("Citation: "), logistic_content$ordinal$citation),
      p(strong("Implemented via: "), code(logistic_content$ordinal$backend)),
      hr(),
      h4(logistic_content$binary_adjusted$title),
      p(strong("Citation: "), logistic_content$binary_adjusted$citation),
      p(strong("Implemented via: "), code(logistic_content$binary_adjusted$backend)),
      hr(),
      h4(logistic_content$continuous_adjusted$title),
      p(strong("Citation: "), logistic_content$continuous_adjusted$citation),
      p(strong("Implemented via: "), code(logistic_content$continuous_adjusted$backend))
    )
  )
}

mod_logistic_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$ordcat_ui <- renderUI({
      req(input$k_ord)
      k <- as.integer(input$k_ord)
      default_p <- round(1 / k, 3)
      tagList(lapply(seq_len(k), function(i) {
        numericInput(session$ns(paste0("ordcat_p_", i)),
                     sprintf("Category %d probability", i), value = default_p,
                     min = 0.001, max = 0.999, step = 0.01)
      }))
    })

    result <- reactive({
      req(input$design)

      if (input$design == "binary") {
        req(input$p1_b, input$p2_b, input$prop_x1, input$alpha_b, input$power_b)
        tryCatch(
          list(ok = TRUE, value = calc_logistic_binary(
            p1 = input$p1_b, p2 = input$p2_b, prop_x1 = input$prop_x1,
            alpha = input$alpha_b, power = input$power_b
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "continuous") {
        req(input$p1_c, input$or, input$alpha_c, input$power_c)
        tryCatch(
          list(ok = TRUE, value = calc_logistic_continuous(
            p1 = input$p1_c, or = input$or, alpha = input$alpha_c, power = input$power_c
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "ordinal") {
        req(input$k_ord, input$or_ord, input$fraction_ord, input$alpha_ord, input$power_ord)
        k <- as.integer(input$k_ord)
        p_vals <- sapply(seq_len(k), function(i) input[[paste0("ordcat_p_", i)]])
        req(!any(sapply(p_vals, is.null)))
        tryCatch(
          list(ok = TRUE, value = calc_ordinal_proportional_odds(
            p = unlist(p_vals), odds_ratio = input$or_ord, fraction = input$fraction_ord,
            alpha = input$alpha_ord, power = input$power_ord
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "binary_adjusted") {
        req(input$p1_ba, input$p2_ba, input$prop_x1_ba, input$r2_ba, input$alpha_ba, input$power_ba)
        tryCatch(
          list(ok = TRUE, value = calc_logistic_binary_adjusted(
            p1 = input$p1_ba, p2 = input$p2_ba, prop_x1 = input$prop_x1_ba, r2 = input$r2_ba,
            alpha = input$alpha_ba, power = input$power_ba
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p1_ca, input$or_ca, input$r2_ca, input$alpha_ca, input$power_ca)
        tryCatch(
          list(ok = TRUE, value = calc_logistic_continuous_adjusted(
            p1 = input$p1_ca, or = input$or_ca, r2 = input$r2_ca,
            alpha = input$alpha_ca, power = input$power_ca
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

      if (!is.null(res$value$eff)) {
        tagList(
          p(strong("Required total sample size: "), res$value$n),
          p(sprintf("Efficiency relative to a continuous response: %.3f", res$value$eff))
        )
      } else if (!is.null(res$value$n_unadjusted)) {
        tagList(
          p(strong("Required total sample size (covariate-adjusted): "), res$value$n),
          p(sprintf("Unadjusted (simple-model) sample size: %d", res$value$n_unadjusted))
        )
      } else {
        tagList(
          p(strong("Required total sample size: "), res$value$n)
        )
      }
    })

    render_export_handlers(output, result, function() logistic_content[[input$design]])
  })
}
