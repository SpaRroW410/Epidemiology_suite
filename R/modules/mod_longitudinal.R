# Longitudinal Slope Difference module: Calculate / Formula-Help /
# Reference sub-tabs. Single design (no design radio, following
# mod_manova.R's pattern).

longitudinal_meta <- list(
  id = "longitudinal",
  nav_title = "Longitudinal Slope Difference"
)

.parse_visit_times <- function(x) {
  vals <- suppressWarnings(as.numeric(trimws(strsplit(x, ",")[[1]])))
  if (any(is.na(vals)) || length(vals) == 0) stop("Could not parse a comma-separated list of visit times.")
  vals
}

mod_longitudinal_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      textInput(ns("visit_times"), "Visit times (comma-separated)", value = "0, 0.25, 0.5, 0.75, 1, 1.25, 1.5"),
      numericInput(ns("delta"), "Slope difference to detect (delta)", value = 1.5, step = 0.1),
      numericInput(ns("sigma2_intercept"), "Random-intercept variance", value = 55, min = 0.0001, step = 1),
      numericInput(ns("sigma2_slope"), "Random-slope variance", value = 24, min = 0.0001, step = 1),
      numericInput(ns("corr_intercept_slope"), "Intercept-slope correlation", value = 0.8, min = -0.999, max = 0.999, step = 0.01),
      numericInput(ns("sigma2_residual"), "Residual (within-subject) error variance", value = 10, min = 0.0001, step = 1),
      numericInput(ns("allocation1"), "Proportion of subjects in group 1", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
      selectInput(ns("alternative"), "Alternative hypothesis",
                  choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided")),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(longitudinal_content$slope_diff$title),
      render_formula_block(longitudinal_content$slope_diff$formula_latex),
      shiny::markdown(longitudinal_content$slope_diff$explanation),
      h5("Worked example"),
      shiny::markdown(longitudinal_content$slope_diff$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(longitudinal_content$slope_diff$title),
      p(strong("Citation: "), longitudinal_content$slope_diff$citation),
      p(strong("Implemented via: "), code(longitudinal_content$slope_diff$backend))
    )
  )
}

mod_longitudinal_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$visit_times, input$delta, input$sigma2_intercept, input$sigma2_slope,
          input$corr_intercept_slope, input$sigma2_residual, input$allocation1,
          input$alternative, input$alpha, input$power)
      tryCatch(
        {
          visit_times <- .parse_visit_times(input$visit_times)
          cov_intercept_slope <- input$corr_intercept_slope *
            sqrt(input$sigma2_intercept) * sqrt(input$sigma2_slope)
          list(ok = TRUE, value = calc_longitudinal_slope_diff(
            visit_times = visit_times, delta = input$delta,
            sigma2_intercept = input$sigma2_intercept, sigma2_slope = input$sigma2_slope,
            cov_intercept_slope = cov_intercept_slope, sigma2_residual = input$sigma2_residual,
            allocation1 = input$allocation1, alpha = input$alpha, power = input$power,
            alternative = input$alternative
          ))
        },
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
        p(strong("Total sample size: "), v$n_total),
        p(sprintf("Group 1: %d, Group 0: %d", v$n1, v$n0))
      )
    })
  })
}
