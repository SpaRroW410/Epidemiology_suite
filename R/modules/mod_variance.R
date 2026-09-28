# Variance Tests module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_rate.R (docs/SDD.md #8):
# a single-variance chi-squared test against a reference SD, or a
# two-variance F test comparing two groups' SDs.

variance_meta <- list(
  id = "variance",
  nav_title = "Variance Tests"
)

mod_variance_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Single-variance test (vs. a reference SD)" = "single",
          "Two-variance test (compare two groups)" = "two",
          "Precision-based SD estimation (CI width, no test)" = "sd_precision"
        ),
        selected = "single"
      ),
      conditionalPanel(
        condition = design_is("single"),
        numericInput(ns("sigma0"), "Reference standard deviation (sigma0)", value = 10, min = 0.0001, step = 0.1),
        numericInput(ns("sigma1"), "Assumed true standard deviation (sigma1)", value = 14, min = 0.0001, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("two"),
        numericInput(ns("sigma1_two"), "Assumed standard deviation, group 1", value = 10, min = 0.0001, step = 0.1),
        numericInput(ns("sigma2_two"), "Assumed standard deviation, group 2", value = 14, min = 0.0001, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("sd_precision"),
        numericInput(ns("target_width"), "Target CI width for sigma (as a multiple of the observed SD)",
                     value = 0.5, min = 0.001, step = 0.05)
      ),
      conditionalPanel(
        condition = paste0("!(", design_is("sd_precision"), ")"),
        numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Greater" = "greater", "Less" = "less")
        )
      ),
      conditionalPanel(
        condition = design_is("sd_precision"),
        numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(variance_content$single$title),
      render_formula_block(variance_content$single$formula_latex),
      shiny::markdown(variance_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(variance_content$single$worked_example),
      hr(),
      h4(variance_content$two$title),
      render_formula_block(variance_content$two$formula_latex),
      shiny::markdown(variance_content$two$explanation),
      h5("Worked example"),
      shiny::markdown(variance_content$two$worked_example),
      hr(),
      h4(variance_content$sd_precision$title),
      render_formula_block(variance_content$sd_precision$formula_latex),
      shiny::markdown(variance_content$sd_precision$explanation),
      h5("Worked example"),
      shiny::markdown(variance_content$sd_precision$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(variance_content$single$title),
      p(strong("Citation: "), variance_content$single$citation),
      p(strong("Implemented via: "), code(variance_content$single$backend)),
      hr(),
      h4(variance_content$two$title),
      p(strong("Citation: "), variance_content$two$citation),
      p(strong("Implemented via: "), code(variance_content$two$backend)),
      hr(),
      h4(variance_content$sd_precision$title),
      p(strong("Citation: "), variance_content$sd_precision$citation),
      p(strong("Implemented via: "), code(variance_content$sd_precision$backend))
    )
  )
}

mod_variance_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      tryCatch({
        value <- if (input$design == "single") {
          req(input$sigma0, input$sigma1, input$alpha, input$power, input$alternative)
          calc_variance_single(
            sigma0 = input$sigma0, sigma1 = input$sigma1,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else if (input$design == "two") {
          req(input$sigma1_two, input$sigma2_two, input$alpha, input$power, input$alternative)
          calc_variance_two(
            sigma1 = input$sigma1_two, sigma2 = input$sigma2_two,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else {
          req(input$target_width, input$conf_level)
          calc_variance_sd_precision(
            target_width = input$target_width, conf_level = input$conf_level
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
      } else if (res$design == "two") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total)
        )
      } else {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("At this n, the %.0f%% CI for sigma spans %.2fx to %.2fx whatever SD is observed.",
                     v$inputs$conf_level * 100, v$lower_mult, v$upper_mult))
        )
      }
    })

    render_export_handlers(output, result, function() variance_content[[input$design]])
  })
}
