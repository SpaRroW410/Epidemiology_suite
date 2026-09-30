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
  lp_method_is <- function(value) sprintf("input['%s'] == '%s'", ns("lp_method"), value)
  include_nb_is_true <- sprintf("input['%s']", ns("include_nb"))

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Outcome type",
        choices = c(
          "Binary" = "binary",
          "Continuous" = "continuous",
          "Survival (time-to-event)" = "survival",
          "External validation (binary outcome)" = "external_validation"
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
      conditionalPanel(
        condition = design_is("external_validation"),
        numericInput(ns("prevalence_ev"), "Expected outcome prevalence", value = 0.018, min = 0.0001, max = 0.9999, step = 0.001),
        numericInput(ns("cstatistic_ev"), "Anticipated C-statistic (AUC)", value = 0.8, min = 0.501, max = 0.999, step = 0.001),
        radioButtons(ns("lp_method"), "LP distribution (for calibration-slope criterion)",
                     choices = c("Normal (mean, SD of the linear predictor)" = "normal",
                                 "Beta (shape parameters of predicted probabilities)" = "beta")),
        conditionalPanel(
          condition = lp_method_is("normal"),
          numericInput(ns("lp_mean"), "LP mean", value = -5),
          numericInput(ns("lp_sd"), "LP standard deviation", value = 2.5, min = 0.0001)
        ),
        conditionalPanel(
          condition = lp_method_is("beta"),
          numericInput(ns("lp_shape1"), "Beta shape1 (alpha)", value = 0.5, min = 0.0001),
          numericInput(ns("lp_shape2"), "Beta shape2 (beta)", value = 0.5, min = 0.0001)
        ),
        numericInput(ns("oe_ev"), "Anticipated O/E ratio", value = 1, min = 0.0001),
        numericInput(ns("oeciwidth_ev"), "Target CI width for O/E", value = 1, min = 0.0001),
        numericInput(ns("cslope_ev"), "Anticipated calibration slope", value = 1),
        numericInput(ns("csciwidth_ev"), "Target CI width for calibration slope", value = 0.2, min = 0.0001),
        numericInput(ns("cstatciwidth_ev"), "Target CI width for C-statistic", value = 0.1, min = 0.0001),
        checkboxInput(ns("include_nb"), "Also assess standardised net benefit (optional 4th criterion)", value = FALSE),
        conditionalPanel(
          condition = include_nb_is_true,
          numericInput(ns("sensitivity_ev"), "Anticipated sensitivity at threshold", value = 0.6, min = 0.0001, max = 0.9999, step = 0.001),
          numericInput(ns("specificity_ev"), "Anticipated specificity at threshold", value = 0.7, min = 0.0001, max = 0.9999, step = 0.001),
          numericInput(ns("threshold_ev"), "Risk threshold", value = 0.2, min = 0.0001, max = 0.9999, step = 0.001),
          numericInput(ns("nbciwidth_ev"), "Target CI width for standardised net benefit", value = 0.2, min = 0.0001)
        ),
        numericInput(ns("simobs_ev"), "Simulated observations (LP distribution)", value = 100000, min = 1000, step = 1000)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
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
      shiny::markdown(prediction_content$survival$worked_example),
      hr(),
      h4(prediction_content$external_validation$title),
      render_formula_block(prediction_content$external_validation$formula_latex),
      shiny::markdown(prediction_content$external_validation$explanation),
      h5("Worked example"),
      shiny::markdown(prediction_content$external_validation$worked_example)
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
      p(strong("Implemented via: "), code(prediction_content$survival$backend)),
      hr(),
      h4(prediction_content$external_validation$title),
      p(strong("Citation: "), prediction_content$external_validation$citation),
      p(strong("Implemented via: "), code(prediction_content$external_validation$backend))
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
      } else if (input$design == "survival") {
        req(input$parameters_s, input$rate, input$timepoint, input$meanfup,
            input$csrsquared_s, input$shrinkage_s)
        tryCatch(
          list(ok = TRUE, value = calc_prediction_survival(
            parameters = input$parameters_s, rate = input$rate, timepoint = input$timepoint,
            meanfup = input$meanfup, csrsquared = input$csrsquared_s, shrinkage = input$shrinkage_s
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$prevalence_ev, input$cstatistic_ev, input$lp_method,
            input$oe_ev, input$oeciwidth_ev, input$cslope_ev, input$csciwidth_ev,
            input$cstatciwidth_ev, input$simobs_ev)
        if (input$lp_method == "normal") {
          req(input$lp_mean, input$lp_sd)
          lp_param1 <- input$lp_mean; lp_param2 <- input$lp_sd
        } else {
          req(input$lp_shape1, input$lp_shape2)
          lp_param1 <- input$lp_shape1; lp_param2 <- input$lp_shape2
        }
        nb_args <- list(sensitivity = NULL, specificity = NULL, threshold = NULL, nbciwidth = 0.2)
        if (isTRUE(input$include_nb)) {
          req(input$sensitivity_ev, input$specificity_ev, input$threshold_ev, input$nbciwidth_ev)
          nb_args <- list(sensitivity = input$sensitivity_ev, specificity = input$specificity_ev,
                           threshold = input$threshold_ev, nbciwidth = input$nbciwidth_ev)
        }
        tryCatch(
          list(ok = TRUE, value = do.call(calc_prediction_external_validation, c(
            list(prevalence = input$prevalence_ev, cstatistic = input$cstatistic_ev,
                 lp_method = input$lp_method, lp_param1 = lp_param1, lp_param2 = lp_param2,
                 oe = input$oe_ev, oeciwidth = input$oeciwidth_ev,
                 cslope = input$cslope_ev, csciwidth = input$csciwidth_ev,
                 cstatciwidth = input$cstatciwidth_ev, simobs = input$simobs_ev),
            nb_args
          ))),
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
      } else if (input$design == "external_validation") {
        rows <- tagList(
          p(strong("Required sample size: "), v$n),
          p(strong("Required events: "), v$events),
          p(sprintf("Criterion 1 (O/E): n = %d (SE(ln OE) = %.4f)", v$n1, v$se_oe)),
          p(sprintf("Criterion 2 (calibration slope): n = %d (SE = %.4f)", v$n2, v$se_cslope)),
          p(sprintf("Criterion 3 (C-statistic): n = %d (SE = %.4f)", v$n3, v$se_cstat))
        )
        if (!is.null(v$n4)) {
          rows <- tagList(rows, p(sprintf(
            "Criterion 4 (standardised net benefit): n = %d (standardised NB = %.3f, SE = %.4f)",
            v$n4, v$standardised_nb, v$se_nb
          )))
        }
        rows
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

    render_export_handlers(output, result, function() prediction_content[[input$design]])
  })
}
