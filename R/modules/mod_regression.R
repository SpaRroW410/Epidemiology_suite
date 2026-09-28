# Multiple Regression module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_means.R (docs/SDD.md #8) -- a
# design radio selects between the R-squared-vs-zero test and the
# hierarchical R-squared-increase test.

regression_meta <- list(
  id = "regression",
  nav_title = "Multiple Regression"
)

mod_regression_ui <- function(id) {
  ns <- NS(id)

  # See mod_proportion.R for why conditionalPanel() conditions are built
  # with ns() rather than hardcoded -- same reasoning applies here.
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
          "R-squared deviation from zero" = "r2",
          "R-squared increase (hierarchical)" = "r2_increase"
        ),
        selected = "r2"
      ),
      conditionalPanel(
        condition = design_is("r2"),
        numericInput(ns("r2"), "Expected R-squared", value = 0.10, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("num_predictors"), "Number of predictors", value = 5, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("r2_increase"),
        numericInput(ns("r2_reduced"), "R-squared of the reduced (existing) model",
                     value = 0.30, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("r2_full"), "R-squared of the full model (with new predictors added)",
                     value = 0.40, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("num_predictors_added"), "Number of predictors being added",
                     value = 2, min = 1, step = 1),
        numericInput(ns("num_predictors_total"), "Total number of predictors in the full model",
                     value = 5, min = 2, step = 1)
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
      conditionalPanel(
        condition = design_is("r2"),
        h4(regression_content$r2$title),
        render_formula_block(regression_content$r2$formula_latex),
        shiny::markdown(regression_content$r2$explanation),
        h5("Worked example"),
        shiny::markdown(regression_content$r2$worked_example)
      ),
      conditionalPanel(
        condition = design_is("r2_increase"),
        h4(regression_content$r2_increase$title),
        render_formula_block(regression_content$r2_increase$formula_latex),
        shiny::markdown(regression_content$r2_increase$explanation),
        h5("Worked example"),
        shiny::markdown(regression_content$r2_increase$worked_example)
      )
    ),
    tabPanel(
      "Reference",
      br(),
      conditionalPanel(
        condition = design_is("r2"),
        h4(regression_content$r2$title),
        p(strong("Citation: "), regression_content$r2$citation),
        p(strong("Implemented via: "), code(regression_content$r2$backend))
      ),
      conditionalPanel(
        condition = design_is("r2_increase"),
        h4(regression_content$r2_increase$title),
        p(strong("Citation: "), regression_content$r2_increase$citation),
        p(strong("Implemented via: "), code(regression_content$r2_increase$backend))
      )
    )
  )
}

mod_regression_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$alpha, input$power)
      tryCatch(
        list(ok = TRUE, value = switch(
          input$design,
          r2 = {
            req(input$r2, input$num_predictors)
            calc_regression_f2(
              r2 = input$r2, num_predictors = input$num_predictors,
              alpha = input$alpha, power = input$power
            )
          },
          r2_increase = {
            req(input$r2_reduced, input$r2_full, input$num_predictors_added, input$num_predictors_total)
            calc_regression_r2_increase(
              r2_reduced = input$r2_reduced, r2_full = input$r2_full,
              num_predictors_added = input$num_predictors_added,
              num_predictors_total = input$num_predictors_total,
              alpha = input$alpha, power = input$power
            )
          }
        )),
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
        p(strong("Required total sample size: "), v$n),
        p(sprintf("Effect size f2 = %.4f", v$f2))
      )
    })

    render_export_handlers(output, result, function() regression_content[[input$design]])
  })
}
