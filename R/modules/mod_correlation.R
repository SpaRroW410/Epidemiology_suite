# Correlation module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_logistic.R (docs/SDD.md #8):
# a single Pearson correlation vs. zero, or a comparison of two independent
# correlations.

correlation_meta <- list(
  id = "correlation",
  nav_title = "Correlation"
)

mod_correlation_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Single correlation vs. zero" = "single",
          "Compare two independent correlations" = "two_independent",
          "Point-biserial correlation" = "point_biserial",
          "Regression coefficient (bivariate slope)" = "regression_slope",
          "Partial correlation (controlling for k covariates)" = "partial"
        ),
        selected = "single"
      ),
      conditionalPanel(
        condition = design_is("single"),
        numericInput(ns("r"), "Expected correlation (r)", value = 0.3, min = -0.99, max = 0.99, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("two_independent"),
        numericInput(ns("r1"), "Expected correlation, group 1 (r1)", value = 0.89, min = -0.99, max = 0.99, step = 0.01),
        numericInput(ns("r2"), "Expected correlation, group 2 (r2)", value = 0.76, min = -0.99, max = 0.99, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("point_biserial"),
        numericInput(ns("r_pb"), "Expected point-biserial correlation (r)", value = 0.5, min = -0.99, max = 0.99, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("regression_slope"),
        numericInput(ns("slope_reg"), "Assumed regression slope", value = 0.5, step = 0.01),
        numericInput(ns("sdx_reg"), "SD of predictor (SDx)", value = 2, min = 0.0001, step = 0.1),
        numericInput(ns("sdy_reg"), "SD of outcome (SDy)", value = 4, min = 0.0001, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("partial"),
        numericInput(ns("r_partial"), "Expected partial correlation (r)", value = 0.3, min = -0.99, max = 0.99, step = 0.01),
        numericInput(ns("k_partial"), "Number of covariates controlled for (k)", value = 2, min = 1, step = 1)
      ),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      selectInput(
        ns("alternative"), "Alternative hypothesis",
        choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(correlation_content$pearson$title),
      render_formula_block(correlation_content$pearson$formula_latex),
      shiny::markdown(correlation_content$pearson$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$pearson$worked_example),
      hr(),
      h4(correlation_content$two_independent$title),
      render_formula_block(correlation_content$two_independent$formula_latex),
      shiny::markdown(correlation_content$two_independent$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$two_independent$worked_example),
      hr(),
      h4(correlation_content$point_biserial$title),
      render_formula_block(correlation_content$point_biserial$formula_latex),
      shiny::markdown(correlation_content$point_biserial$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$point_biserial$worked_example),
      hr(),
      h4(correlation_content$regression_slope$title),
      render_formula_block(correlation_content$regression_slope$formula_latex),
      shiny::markdown(correlation_content$regression_slope$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$regression_slope$worked_example),
      hr(),
      h4(correlation_content$partial$title),
      render_formula_block(correlation_content$partial$formula_latex),
      shiny::markdown(correlation_content$partial$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$partial$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(correlation_content$pearson$title),
      p(strong("Citation: "), correlation_content$pearson$citation),
      p(strong("Implemented via: "), code(correlation_content$pearson$backend)),
      hr(),
      h4(correlation_content$two_independent$title),
      p(strong("Citation: "), correlation_content$two_independent$citation),
      p(strong("Implemented via: "), code(correlation_content$two_independent$backend)),
      hr(),
      h4(correlation_content$point_biserial$title),
      p(strong("Citation: "), correlation_content$point_biserial$citation),
      p(strong("Implemented via: "), code(correlation_content$point_biserial$backend)),
      hr(),
      h4(correlation_content$regression_slope$title),
      p(strong("Citation: "), correlation_content$regression_slope$citation),
      p(strong("Implemented via: "), code(correlation_content$regression_slope$backend)),
      hr(),
      h4(correlation_content$partial$title),
      p(strong("Citation: "), correlation_content$partial$citation),
      p(strong("Implemented via: "), code(correlation_content$partial$backend))
    )
  )
}

mod_correlation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$alpha, input$power, input$alternative)

      tryCatch({
        value <- if (input$design == "single") {
          req(input$r)
          calc_correlation(
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else if (input$design == "two_independent") {
          req(input$r1, input$r2)
          calc_correlation_two_independent(
            r1 = input$r1, r2 = input$r2, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else if (input$design == "point_biserial") {
          req(input$r_pb)
          calc_correlation_point_biserial(
            r = input$r_pb, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else if (input$design == "regression_slope") {
          req(input$slope_reg, input$sdx_reg, input$sdy_reg)
          calc_regression_slope(
            slope = input$slope_reg, sd_x = input$sdx_reg, sd_y = input$sdy_reg,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else {
          req(input$r_partial, input$k_partial)
          calc_correlation_partial(
            r = input$r_partial, k = input$k_partial,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
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
      if (res$design == "single") {
        p(strong("Required sample size: "), v$n)
      } else if (res$design == "two_independent") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(sprintf("Cohen's q = %.4f", v$q))
        )
      } else if (res$design == "point_biserial") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Cohen's d (equivalent) = %.4f", v$d))
        )
      } else if (res$design == "regression_slope") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Implied correlation r = %.4f", v$r))
        )
      } else {
        p(strong("Required sample size: "), v$n)
      }
    })
  })
}
