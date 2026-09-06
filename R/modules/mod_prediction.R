# Prediction Model module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8),
# with a nested radio inside the "binary" design for how the expected R^2
# is specified (Cox-Snell R^2 directly, or a reported C-statistic).

prediction_meta <- list(
  id = "prediction",
  nav_title = "Prediction Model"
)

mod_prediction_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }
  r2_method_is <- function(value) sprintf("input['%s'] == '%s'", ns("r2_method"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Outcome type",
        choices = c(
          "Binary" = "binary",
          "Continuous" = "continuous",
          "Survival (time-to-event)" = "survival"
        )
      ),
      conditionalPanel(
        condition = design_is("binary"),
        numericInput(ns("parameters_b"), "Number of candidate predictor parameters", value = 24, min = 1, step = 1),
        numericInput(ns("prevalence"), "Expected outcome prevalence", value = 0.174, min = 0.001, max = 0.999, step = 0.001),
        radioButtons(ns("r2_method"), "R-squared input method",
                     choices = c("Cox-Snell R-squared from an existing model" = "csrsquared",
                                 "C-statistic (AUC) from an existing model" = "cstatistic")),
        conditionalPanel(
          condition = r2_method_is("csrsquared"),
          numericInput(ns("csrsquared_b"), "Expected Cox-Snell R-squared", value = 0.288, min = 0.001, max = 0.999, step = 0.001)
        ),
        conditionalPanel(
          condition = r2_method_is("cstatistic"),
          numericInput(ns("cstatistic"), "Reported C-statistic (AUC)", value = 0.89, min = 0.501, max = 0.999, step = 0.001)
        ),
        numericInput(ns("shrinkage_b"), "Desired shrinkage factor", value = 0.9, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("continuous"),
        numericInput(ns("parameters_c"), "Number of candidate predictor parameters", value = 25, min = 1, step = 1),
        numericInput(ns("intercept"), "Expected mean outcome value", value = 1.9),
        numericInput(ns("sd"), "Expected standard deviation of the outcome", value = 0.6, min = 0.0001),
        numericInput(ns("rsquared_c"), "Expected R-squared", value = 0.2, min = 0.001, max = 0.999, step = 0.001),
        numericInput(ns("shrinkage_c"), "Desired shrinkage factor", value = 0.9, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("mmoe"), "Acceptable multiplicative margin of error (intercept)", value = 1.1, min = 1.001, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("survival"),
        numericInput(ns("parameters_s"), "Number of candidate predictor parameters", value = 30, min = 1, step = 1),
        numericInput(ns("rate"), "Expected overall event rate", value = 0.065, min = 0.0001, step = 0.001),
        numericInput(ns("timepoint"), "Prediction timepoint of interest", value = 2, min = 0.0001),
        numericInput(ns("meanfup"), "Expected mean follow-up time", value = 2.07, min = 0.0001),
        numericInput(ns("csrsquared_s"), "Expected Cox-Snell R-squared", value = 0.051, min = 0.001, max = 0.999, step = 0.001),
        numericInput(ns("shrinkage_s"), "Desired shrinkage factor", value = 0.9, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(prediction_content$binary$title),
      render_formula_block(prediction_content$binary$formula_latex),
      shiny::markdown(prediction_content$binary$explanation),
      h5("Worked example"),
      shiny::markdown(prediction_content$binary$worked_example),
      hr(),
      h4(prediction_content$continuous$title),
      render_formula_block(prediction_content$continuous$formula_latex),
      shiny::markdown(prediction_content$continuous$explanation),
      h5("Worked example"),
      shiny::markdown(prediction_content$continuous$worked_example),
      hr(),
      h4(prediction_content$survival$title),
      render_formula_block(prediction_content$survival$formula_latex),
      shiny::markdown(prediction_content$survival$explanation),
      h5("Worked example"),
      shiny::markdown(prediction_content$survival$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(prediction_content$binary$title),
      p(strong("Citation: "), prediction_content$binary$citation),
      p(strong("Implemented via: "), code(prediction_content$binary$backend)),
      hr(),
      h4(prediction_content$continuous$title),
      p(strong("Citation: "), prediction_content$continuous$citation),
      p(strong("Implemented via: "), code(prediction_content$continuous$backend)),
      hr(),
      h4(prediction_content$survival$title),
      p(strong("Citation: "), prediction_content$survival$citation),
      p(strong("Implemented via: "), code(prediction_content$survival$backend))
    )
  )
}

mod_prediction_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "binary") {
        req(input$parameters_b, input$prevalence, input$r2_method, input$shrinkage_b)
        if (input$r2_method == "csrsquared") {
          req(input$csrsquared_b)
          tryCatch(
            list(ok = TRUE, value = calc_prediction_binary(
              parameters = input$parameters_b, prevalence = input$prevalence,
              csrsquared = input$csrsquared_b, shrinkage = input$shrinkage_b
            )),
            error = function(e) list(ok = FALSE, message = conditionMessage(e))
          )
        } else {
          req(input$cstatistic)
          tryCatch(
            list(ok = TRUE, value = calc_prediction_binary(
              parameters = input$parameters_b, prevalence = input$prevalence,
              cstatistic = input$cstatistic, shrinkage = input$shrinkage_b
            )),
            error = function(e) list(ok = FALSE, message = conditionMessage(e))
          )
        }
      } else if (input$design == "continuous") {
        req(input$parameters_c, input$intercept, input$sd, input$rsquared_c,
            input$shrinkage_c, input$mmoe)
        tryCatch(
          list(ok = TRUE, value = calc_prediction_continuous(
            parameters = input$parameters_c, intercept = input$intercept, sd = input$sd,
            rsquared = input$rsquared_c, shrinkage = input$shrinkage_c, mmoe = input$mmoe
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$parameters_s, input$rate, input$timepoint, input$meanfup,
            input$csrsquared_s, input$shrinkage_s)
        tryCatch(
          list(ok = TRUE, value = calc_prediction_survival(
            parameters = input$parameters_s, rate = input$rate, timepoint = input$timepoint,
            meanfup = input$meanfup, csrsquared = input$csrsquared_s, shrinkage = input$shrinkage_s
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
      if (input$design == "continuous") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("SPP (subjects per parameter): %.1f", v$spp)),
          p(sprintf("Expected intercept 95%% CI: [%.3f, %.3f]", v$intercept_lci, v$intercept_uci))
        )
      } else {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(strong("Required events: "), v$events),
          p(sprintf("Cox-Snell R-squared used: %.4f (max attainable: %.4f, Nagelkerke: %.4f)",
                    v$csrsquared, v$max_r2a, v$nag_r2)),
          p(sprintf("EPP (events per parameter): %.2f", v$epp))
        )
      }
    })
  })
}
