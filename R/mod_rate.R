# Incidence Rate module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8).

rate_meta <- list(
  id = "rate",
  nav_title = "Incidence Rate"
)

mod_rate_ui <- function(id) {
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
          "Single rate, precision-based (no comparison)" = "precision",
          "Comparison of two rates" = "comparison",
          "Poisson regression, continuous predictor" = "poisson_regression",
          "Comparison of two negative binomial rates" = "negative_binomial"
        )
      ),
      conditionalPanel(
        condition = design_is("precision"),
        numericInput(ns("rate"), "Expected rate (events per unit person-time)", value = 2.5, min = 0.0001),
        precision_type_input(ns("error_rate"),
                             absolute = "Absolute (the full width of the interval, in the units of the rate)",
                             relative = "Relative (+/- a fraction of the rate)"),
        conditionalPanel(
          condition = sprintf("input['%s'] != 'relative'", ns("error_rate")),
          numericInput(ns("conf_width"), "Desired confidence interval width (same units as rate)", value = 2.243, min = 0.0001)
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'relative'", ns("error_rate")),
          numericInput(ns("epsilon_rate"), "Relative margin of error (fraction of the rate, e.g. 0.20 = +/- 20%)",
                       value = 0.20, min = 0.001, max = 0.99, step = 0.01)
        ),
        numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        selectInput(ns("method"), "Method",
                    choices = c("Score (general-purpose default)" = "score",
                                "Exact (recommended if < 5 events expected)" = "exact",
                                "Variance-stabilizing" = "vs",
                                "Wald" = "wald")),
        nonresponse_input(ns("nonresponse_rate"),
                          "Expected loss of person-time to follow-up (fraction; 0 = none, 0.1 = 10%)"),
        uiOutput(ns("precision_equiv")),
        precision_guidance_ui("rate")
      ),
      conditionalPanel(
        condition = design_is("comparison"),
        numericInput(ns("rate_ref"), "Reference (unexposed) group rate (events per unit person-time)", value = 2.798, min = 0.0001),
        numericInput(ns("rate_ratio"), "Expected rate ratio (exposed / reference)", value = 0.8938, min = 0.0001),
        numericInput(ns("prop_exposed"), "Proportion of the sample in the exposed group", value = 0.53, min = 0.01, max = 0.99, step = 0.01),
        numericInput(ns("alpha_comp"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_comp"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative_comp"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      conditionalPanel(
        condition = design_is("poisson_regression"),
        numericInput(ns("beta0_pr"), "Intercept (beta0, log scale)", value = 0.1, step = 0.01),
        numericInput(ns("beta1_pr"), "Slope (beta1, log rate ratio per unit increase)", value = 0.5, step = 0.01),
        numericInput(ns("mu_x1_pr"), "Predictor mean (mu.x1)", value = 0, step = 0.1),
        numericInput(ns("sigma2_x1_pr"), "Predictor variance (sigma2.x1)", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("mu_T_pr"), "Mean exposure/follow-up time (mu.T)", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("phi_pr"), "Over-dispersion (phi = var(y)/mean(y); 1 = none)", value = 1, min = 1, step = 0.1),
        numericInput(ns("alpha_pr"), "Significance level, two-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_pr"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("negative_binomial"),
        numericInput(ns("mu0_nb"), "Control-group event rate per time unit (mu0)", value = 10, min = 0.0001, step = 0.5),
        numericInput(ns("rr_nb"), "Rate ratio to detect (treatment / control)", value = 1.5, min = 0.0001, step = 0.05),
        numericInput(ns("theta_nb"), "Dispersion parameter (theta, MASS::rnegbin parameterization)", value = 0.2, min = 0.0001, step = 0.05),
        numericInput(ns("duration_nb"), "Average treatment/follow-up duration", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("ratio_nb"), "Treatment:control sample size ratio", value = 1.5, min = 0.01, step = 0.1),
        selectInput(ns("approach_nb"), "Variance-estimator approach (Zhu & Lakkis 2014)",
                    choices = c("Approach 3 (recommended)" = 3, "Approach 2 (recommended)" = 2,
                                "Approach 1" = 1)),
        selectInput(ns("alternative_nb"), "Alternative hypothesis",
                    choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided")),
        numericInput(ns("alpha_nb"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_nb"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(rate_content$precision$title),
      render_formula_block(rate_content$precision$formula_latex),
      shiny::markdown(rate_content$precision$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$precision$worked_example),
      hr(),
      h4(rate_content$comparison$title),
      render_formula_block(rate_content$comparison$formula_latex),
      shiny::markdown(rate_content$comparison$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$comparison$worked_example),
      hr(),
      h4(rate_content$poisson_regression$title),
      render_formula_block(rate_content$poisson_regression$formula_latex),
      shiny::markdown(rate_content$poisson_regression$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$poisson_regression$worked_example),
      hr(),
      h4(rate_content$negative_binomial$title),
      render_formula_block(rate_content$negative_binomial$formula_latex),
      shiny::markdown(rate_content$negative_binomial$explanation),
      h5("Worked example"),
      shiny::markdown(rate_content$negative_binomial$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(rate_content$precision$title),
      p(strong("Citation: "), rate_content$precision$citation),
      p(strong("Implemented via: "), code(rate_content$precision$backend)),
      hr(),
      h4(rate_content$comparison$title),
      p(strong("Citation: "), rate_content$comparison$citation),
      p(strong("Implemented via: "), code(rate_content$comparison$backend)),
      hr(),
      h4(rate_content$poisson_regression$title),
      p(strong("Citation: "), rate_content$poisson_regression$citation),
      p(strong("Implemented via: "), code(rate_content$poisson_regression$backend)),
      hr(),
      h4(rate_content$negative_binomial$title),
      p(strong("Citation: "), rate_content$negative_binomial$citation),
      p(strong("Implemented via: "), code(rate_content$negative_binomial$backend))
    )
  )
}

mod_rate_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    rate_relative <- reactive(identical(input$error_rate, "relative"))
    rate_precision <- reactive(if (rate_relative()) input$epsilon_rate else input$conf_width)
    # conf_width (absolute) or epsilon (relative), as calc_rate_precision() takes them
    rate_precision_args <- function() {
      if (rate_relative()) list(conf_width = NULL, epsilon = input$epsilon_rate) else list(conf_width = input$conf_width, epsilon = NULL)
    }
    output$precision_equiv <- renderUI({
      precision_equivalents_ui(precision_equivalents_text(input$rate, rate_precision(),
                                                          if (rate_relative()) "relative" else "absolute",
                                                          input$conf_level, "rate"))
    })

    result <- reactive({
      req(input$design)

      if (input$design == "precision") {
        req(input$rate, rate_precision(), input$conf_level, input$method)
        tryCatch(
          list(ok = TRUE, value = do.call(calc_rate_precision, c(
            list(rate = input$rate, conf_level = input$conf_level, method = input$method,
                 nonresponse = .nonresponse_value(input$nonresponse_rate)),
            rate_precision_args()
          ))),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "comparison") {
        req(input$rate_ref, input$rate_ratio, input$prop_exposed,
            input$alpha_comp, input$power_comp, input$alternative_comp)
        tryCatch(
          list(ok = TRUE, value = calc_rate_comparison(
            rate_ref = input$rate_ref, rate_ratio = input$rate_ratio,
            prop_exposed = input$prop_exposed, alpha = input$alpha_comp,
            power = input$power_comp, alternative = input$alternative_comp
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "poisson_regression") {
        req(input$beta0_pr, input$beta1_pr, input$mu_x1_pr, input$sigma2_x1_pr,
            input$mu_T_pr, input$phi_pr, input$alpha_pr, input$power_pr)
        tryCatch(
          list(ok = TRUE, value = calc_poisson_regression_continuous(
            beta0 = input$beta0_pr, beta1 = input$beta1_pr, mu_x1 = input$mu_x1_pr,
            sigma2_x1 = input$sigma2_x1_pr, mu_T = input$mu_T_pr, phi = input$phi_pr,
            alpha = input$alpha_pr, power = input$power_pr
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$mu0_nb, input$rr_nb, input$theta_nb, input$duration_nb, input$ratio_nb,
            input$approach_nb, input$alternative_nb, input$alpha_nb, input$power_nb)
        tryCatch(
          list(ok = TRUE, value = calc_negative_binomial_rates(
            mu0 = input$mu0_nb, RR = input$rr_nb, theta = input$theta_nb,
            duration = input$duration_nb, ssize_ratio = input$ratio_nb,
            alpha = input$alpha_nb, power = input$power_nb,
            alternative = input$alternative_nb, approach = as.numeric(input$approach_nb)
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
      if (input$design == "precision") {
        tagList(
          p(strong("Required number of events: "), v$n_events),
          p(strong("Required person-time: "), sprintf("%.2f", v$person_time)),
          if (!is.null(v$person_time_planned)) {
            p(strong(sprintf("Person-time to plan, allowing for %s loss to follow-up: ", .prec_pct(v$inputs$nonresponse))),
              sprintf("%.2f", v$person_time_planned),
              span(class = "text-muted", sprintf(" (%.2f / (1 - %s))", v$person_time, format(v$inputs$nonresponse, trim = TRUE))))
          },
          p(sprintf("Achieved CI width at this n: %.4f", v$achieved_conf_width)),
          p(sprintf("Precision (%s): interval width %s (+/- %s) = +/- %s of the rate.", v$inputs$error,
                    .prec_fmt(2 * v$d_absolute), .prec_fmt(v$d_absolute), .prec_pct(v$epsilon_relative))),
          precision_notes_ui(v$precision_notes)
        )
      } else if (input$design == "comparison") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Exposed group: %d, Reference group: %d", v$n_exposed, v$n_reference))
        )
      } else if (input$design == "negative_binomial") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Control group: %d, Treatment group: %d", v$n0, v$n1))
        )
      } else {
        tagList(
          p(strong("Required total sample size: "), v$n_total)
        )
      }
    })

    render_export_handlers(output, result, function() rate_content[[input$design]])

    # Power curves (ROADMAP P1 item 10): wired for the three designs with
    # a power argument. "precision" has none (it isn't a hypothesis test).
    render_power_curves(output, function() {
      if (input$design == "comparison") {
        req(input$rate_ref, input$rate_ratio, input$prop_exposed,
            input$alpha_comp, input$power_comp, input$alternative_comp)
        list(
          calc_fn = calc_rate_comparison,
          args = list(rate_ref = input$rate_ref, rate_ratio = input$rate_ratio,
                       prop_exposed = input$prop_exposed, alpha = input$alpha_comp,
                       power = input$power_comp, alternative = input$alternative_comp),
          effect = list(param = "rate_ratio", values = curve_range_ratio(), label = "Rate ratio (exposed / reference)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "poisson_regression") {
        req(input$beta0_pr, input$beta1_pr, input$mu_x1_pr, input$sigma2_x1_pr,
            input$mu_T_pr, input$phi_pr, input$alpha_pr, input$power_pr)
        list(
          calc_fn = calc_poisson_regression_continuous,
          args = list(beta0 = input$beta0_pr, beta1 = input$beta1_pr, mu_x1 = input$mu_x1_pr,
                       sigma2_x1 = input$sigma2_x1_pr, mu_T = input$mu_T_pr, phi = input$phi_pr,
                       alpha = input$alpha_pr, power = input$power_pr),
          effect = list(param = "beta1", values = curve_range_around(0, 3 * abs(input$beta1_pr)),
                        label = "beta1 (log rate ratio per unit increase)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "negative_binomial") {
        req(input$mu0_nb, input$rr_nb, input$theta_nb, input$duration_nb, input$ratio_nb,
            input$approach_nb, input$alternative_nb, input$alpha_nb, input$power_nb)
        list(
          calc_fn = calc_negative_binomial_rates,
          args = list(mu0 = input$mu0_nb, RR = input$rr_nb, theta = input$theta_nb,
                       duration = input$duration_nb, ssize_ratio = input$ratio_nb,
                       alpha = input$alpha_nb, power = input$power_nb,
                       alternative = input$alternative_nb, approach = as.numeric(input$approach_nb)),
          effect = list(param = "RR", values = curve_range_ratio(), label = "Rate ratio (treatment / control)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "precision") {
        req(input$rate, rate_precision(), input$conf_level, input$method)
        rel <- rate_relative()
        list(
          calc_fn = calc_rate_precision,
          args = c(list(rate = input$rate, conf_level = input$conf_level, method = input$method),
                   if (rel) list(epsilon = input$epsilon_rate) else list(conf_width = input$conf_width)),
          effect = list(param = "rate", values = curve_range_multiplicative(input$rate),
                      label = "Expected rate",
                      title = "Required events vs. expected rate"),
          power = if (rel) {
            list(param = "epsilon", values = curve_range_multiplicative(input$epsilon_rate, 0.3, 3),
                 label = "Relative margin of error (fraction of the rate)",
                 title = "Required events vs. relative precision")
          } else {
            list(param = "conf_width", values = curve_range_multiplicative(input$conf_width, 0.3, 3),
                 label = "Desired confidence interval width",
                 title = "Required events vs. precision (CI width)")
          }
        )
      } else {
        NULL
      }
    })
  })
}
