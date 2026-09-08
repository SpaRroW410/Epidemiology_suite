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
          "MMRM with dropout, AR(1) correlation (Lu, Luo & Chen)" = "mmrm_ar1",
          "Group-slope difference (Diggle et al)" = "diggle",
          "Group-slope difference (Ard & Edland)" = "edland",
          "Group-slope difference under attrition (Hu, Mackey & Thomas)" = "hu"
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
      conditionalPanel(
        condition = design_is("diggle"),
        textInput(ns("visit_times_diggle"), "Visit times (comma-separated)", value = "0, 2, 5"),
        numericInput(ns("delta_diggle"), "Slope difference to detect (delta)", value = 0.5, step = 0.1),
        numericInput(ns("sigma2_diggle"), "Marginal (residual) variance at a single visit", value = 100, min = 0.0001, step = 1),
        numericInput(ns("rho_diggle"), "Exchangeable working correlation (rho)", value = 0.2, min = 0.001, max = 0.999, step = 0.01),
        selectInput(ns("alternative_diggle"), "Alternative hypothesis",
                    choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"), selected = "one.sided"),
        numericInput(ns("alpha_diggle"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_diggle"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("edland"),
        textInput(ns("visit_times_edland"), "Visit times (comma-separated)", value = "0, 0.25, 0.5, 0.75, 1, 1.25, 1.5"),
        numericInput(ns("delta_edland"), "Slope difference to detect (delta)", value = 1.5, step = 0.1),
        numericInput(ns("sigma2_slope_edland"), "Random-slope variance", value = 24, min = 0.0001, step = 1),
        numericInput(ns("sigma2_residual_edland"), "Residual (within-subject) error variance", value = 10, min = 0.0001, step = 1),
        selectInput(ns("alternative_edland"), "Alternative hypothesis",
                    choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided")),
        numericInput(ns("alpha_edland"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_edland"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("hu"),
        textInput(ns("visit_times_hu"), "Visit times (comma-separated, must start at 0)", value = "0, 0.25, 0.5, 0.75, 1, 1.25, 1.5"),
        textInput(ns("p_hu"), "Attrition pattern: proportion whose last visit is each listed time (comma-separated, sums to 1)",
                  value = "0, 0, 0, 0, 0, 0, 1"),
        numericInput(ns("delta_hu"), "Slope difference to detect (delta)", value = 1.5, step = 0.1),
        numericInput(ns("sigma2_slope_hu"), "Random-slope variance", value = 24, min = 0.0001, step = 1),
        numericInput(ns("sigma2_residual_hu"), "Residual (within-subject) error variance", value = 10, min = 0.0001, step = 1),
        numericInput(ns("sigma2_intercept_hu"), "Random-intercept variance (0 if not applicable)", value = 0, min = 0, step = 1),
        numericInput(ns("corr_intercept_slope_hu"), "Intercept-slope correlation", value = 0.5, min = -0.999, max = 0.999, step = 0.01),
        numericInput(ns("lambda_hu"), "Allocation ratio (group 1 / group 2)", value = 1, min = 0.01, step = 0.1),
        selectInput(ns("alternative_hu"), "Alternative hypothesis",
                    choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided")),
        numericInput(ns("alpha_hu"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_hu"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
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
      shiny::markdown(longitudinal_content$mmrm_ar1$worked_example),
      hr(),
      h4(longitudinal_content$diggle$title),
      render_formula_block(longitudinal_content$diggle$formula_latex),
      shiny::markdown(longitudinal_content$diggle$explanation),
      h5("Worked example"),
      shiny::markdown(longitudinal_content$diggle$worked_example),
      hr(),
      h4(longitudinal_content$edland$title),
      render_formula_block(longitudinal_content$edland$formula_latex),
      shiny::markdown(longitudinal_content$edland$explanation),
      h5("Worked example"),
      shiny::markdown(longitudinal_content$edland$worked_example),
      hr(),
      h4(longitudinal_content$hu$title),
      render_formula_block(longitudinal_content$hu$formula_latex),
      shiny::markdown(longitudinal_content$hu$explanation),
      h5("Worked example"),
      shiny::markdown(longitudinal_content$hu$worked_example)
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
      p(strong("Implemented via: "), code(longitudinal_content$mmrm_ar1$backend)),
      hr(),
      h4(longitudinal_content$diggle$title),
      p(strong("Citation: "), longitudinal_content$diggle$citation),
      p(strong("Implemented via: "), code(longitudinal_content$diggle$backend)),
      hr(),
      h4(longitudinal_content$edland$title),
      p(strong("Citation: "), longitudinal_content$edland$citation),
      p(strong("Implemented via: "), code(longitudinal_content$edland$backend)),
      hr(),
      h4(longitudinal_content$hu$title),
      p(strong("Citation: "), longitudinal_content$hu$citation),
      p(strong("Implemented via: "), code(longitudinal_content$hu$backend))
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
      } else if (input$design == "mmrm_ar1") {
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
      } else if (input$design == "diggle") {
        req(input$visit_times_diggle, input$delta_diggle, input$sigma2_diggle, input$rho_diggle,
            input$alternative_diggle, input$alpha_diggle, input$power_diggle)
        tryCatch(
          {
            visit_times <- .parse_visit_times(input$visit_times_diggle)
            list(ok = TRUE, value = calc_longitudinal_diggle(
              visit_times = visit_times, delta = input$delta_diggle, sigma2 = input$sigma2_diggle,
              rho = input$rho_diggle, alpha = input$alpha_diggle, power = input$power_diggle,
              alternative = input$alternative_diggle
            ))
          },
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "edland") {
        req(input$visit_times_edland, input$delta_edland, input$sigma2_slope_edland,
            input$sigma2_residual_edland, input$alternative_edland, input$alpha_edland, input$power_edland)
        tryCatch(
          {
            visit_times <- .parse_visit_times(input$visit_times_edland)
            list(ok = TRUE, value = calc_longitudinal_edland(
              visit_times = visit_times, delta = input$delta_edland,
              sigma2_slope = input$sigma2_slope_edland, sigma2_residual = input$sigma2_residual_edland,
              alpha = input$alpha_edland, power = input$power_edland,
              alternative = input$alternative_edland
            ))
          },
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$visit_times_hu, input$p_hu, input$delta_hu, input$sigma2_slope_hu,
            input$sigma2_residual_hu, input$sigma2_intercept_hu, input$corr_intercept_slope_hu,
            input$lambda_hu, input$alternative_hu, input$alpha_hu, input$power_hu)
        tryCatch(
          {
            visit_times <- .parse_visit_times(input$visit_times_hu)
            p <- .parse_visit_times(input$p_hu)
            list(ok = TRUE, value = calc_longitudinal_hu(
              visit_times = visit_times, p = p, delta = input$delta_hu,
              sigma2_slope = input$sigma2_slope_hu, sigma2_residual = input$sigma2_residual_hu,
              sigma2_intercept = input$sigma2_intercept_hu, cor_intercept_slope = input$corr_intercept_slope_hu,
              lambda = input$lambda_hu, alpha = input$alpha_hu, power = input$power_hu,
              alternative = input$alternative_hu
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
      } else if (input$design %in% c("mmrm_ar1", "hu")) {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Group 1: %d, Group 2: %d", v$n1, v$n2))
        )
      } else {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Per group: %d", v$n_per_group))
        )
      }
    })
  })
}
