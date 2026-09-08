# Longitudinal / MMRM module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_logrank.R
# (docs/SDD.md #8) -- outer radio for "which method", with a
# conditionalPanel per design.

longitudinal_meta <- list(
  id = "longitudinal",
  nav_title = "Longitudinal / MMRM"
)

.parse_visit_times <- function(x) {
  vals <- suppressWarnings(as.numeric(trimws(strsplit(x, ",")[[1]])))
  if (any(is.na(vals)) || length(vals) == 0) stop("Could not parse a comma-separated list of visit times.")
  vals
}

mod_longitudinal_ui <- function(id) {
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
          "Group-slope difference (GEE/GLS, Liu & Liang)" = "slope_diff",
          "MMRM with dropout, AR(1) correlation (Lu, Luo & Chen)" = "mmrm_ar1"
        )
      ),
      conditionalPanel(
        condition = design_is("slope_diff"),
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
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("mmrm_ar1"),
        numericInput(ns("rho_mmrm"), "AR(1) correlation (rho, between adjacent visits)", value = 0.6, min = 0.001, max = 0.999, step = 0.01),
        textInput(ns("ra_mmrm"), "Arm 1 cumulative retention per visit (comma-separated, non-increasing)", value = "1, 0.76, 0.63, 0.52"),
        textInput(ns("rb_mmrm"), "Arm 2 cumulative retention per visit (blank = same as arm 1)", value = "1, 0.87, 0.81, 0.78"),
        numericInput(ns("sigma_mmrm"), "Residual standard deviation (sigma)", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("lambda_mmrm"), "Allocation ratio (n2/n1)", value = 1, min = 0.01, step = 0.1),
        numericInput(ns("delta_mmrm"), "Between-arm difference to detect (delta)", value = 0.9, step = 0.1),
        selectInput(ns("alternative_mmrm"), "Alternative hypothesis",
                    choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided")),
        numericInput(ns("alpha_mmrm"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_mmrm"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
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
      shiny::markdown(longitudinal_content$slope_diff$worked_example),
      hr(),
      h4(longitudinal_content$mmrm_ar1$title),
      render_formula_block(longitudinal_content$mmrm_ar1$formula_latex),
      shiny::markdown(longitudinal_content$mmrm_ar1$explanation),
      h5("Worked example"),
      shiny::markdown(longitudinal_content$mmrm_ar1$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(longitudinal_content$slope_diff$title),
      p(strong("Citation: "), longitudinal_content$slope_diff$citation),
      p(strong("Implemented via: "), code(longitudinal_content$slope_diff$backend)),
      hr(),
      h4(longitudinal_content$mmrm_ar1$title),
      p(strong("Citation: "), longitudinal_content$mmrm_ar1$citation),
      p(strong("Implemented via: "), code(longitudinal_content$mmrm_ar1$backend))
    )
  )
}

mod_longitudinal_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "slope_diff") {
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
      } else {
        req(input$rho_mmrm, input$ra_mmrm, input$sigma_mmrm, input$lambda_mmrm,
            input$delta_mmrm, input$alternative_mmrm, input$alpha_mmrm, input$power_mmrm)
        tryCatch(
          {
            ra <- .parse_visit_times(input$ra_mmrm)
            rb <- if (nzchar(trimws(input$rb_mmrm))) .parse_visit_times(input$rb_mmrm) else NULL
            list(ok = TRUE, value = calc_mmrm_ar1(
              rho = input$rho_mmrm, ra = ra, rb = rb, sigma = input$sigma_mmrm,
              lambda = input$lambda_mmrm, delta = input$delta_mmrm,
              alpha = input$alpha_mmrm, power = input$power_mmrm,
              alternative = input$alternative_mmrm
            ))
          },
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
      if (input$design == "slope_diff") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Group 1: %d, Group 0: %d", v$n1, v$n0))
        )
      } else {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Arm 1: %d, Arm 2: %d", v$n1, v$n2))
        )
      }
    })
  })
}
