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
        choices = c("Binary predictor" = "binary", "Continuous predictor" = "continuous")
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
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(logistic_content$binary$title),
      withMathJax(HTML(logistic_content$binary$formula_latex)),
      shiny::markdown(logistic_content$binary$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$binary$worked_example),
      hr(),
      h4(logistic_content$continuous$title),
      withMathJax(HTML(logistic_content$continuous$formula_latex)),
      shiny::markdown(logistic_content$continuous$explanation),
      h5("Worked example"),
      shiny::markdown(logistic_content$continuous$worked_example)
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
      p(strong("Implemented via: "), code(logistic_content$continuous$backend))
    )
  )
}

mod_logistic_server <- function(id) {
  moduleServer(id, function(input, output, session) {
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
      } else {
        req(input$p1_c, input$or, input$alpha_c, input$power_c)
        tryCatch(
          list(ok = TRUE, value = calc_logistic_continuous(
            p1 = input$p1_c, or = input$or, alpha = input$alpha_c, power = input$power_c
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

      tagList(
        p(strong("Required total sample size: "), res$value$n)
      )
    })
  })
}
