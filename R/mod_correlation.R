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
          "Compare two dependent (overlapping) correlations" = "two_dependent",
          "Point-biserial correlation" = "point_biserial",
          "Regression coefficient (bivariate slope)" = "regression_slope",
          "Partial correlation (controlling for k covariates)" = "partial",
          "Spearman rank correlation (ARE-inflated)" = "spearman"
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
        condition = design_is("two_dependent"),
        numericInput(ns("r_yx1"), "Correlation between Y and X1 (r_yx1)", value = 0.4, min = -0.99, max = 0.99, step = 0.01),
        numericInput(ns("r_yx2"), "Correlation between Y and X2 (r_yx2)", value = 0.6, min = -0.99, max = 0.99, step = 0.01),
        numericInput(ns("r_x1x2"), "Correlation between X1 and X2 (r_x1x2)", value = 0.3, min = -0.99, max = 0.99, step = 0.01)
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
      conditionalPanel(
        condition = design_is("spearman"),
        numericInput(ns("r_spearman"), "Expected Spearman correlation (r)", value = 0.3, min = -0.99, max = 0.99, step = 0.01)
      ),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      advanced_options_ui(
        ns,
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
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
      h4(correlation_content$two_dependent$title),
      render_formula_block(correlation_content$two_dependent$formula_latex),
      shiny::markdown(correlation_content$two_dependent$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$two_dependent$worked_example),
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
      shiny::markdown(correlation_content$partial$worked_example),
      hr(),
      h4(correlation_content$spearman$title),
      render_formula_block(correlation_content$spearman$formula_latex),
      shiny::markdown(correlation_content$spearman$explanation),
      h5("Worked example"),
      shiny::markdown(correlation_content$spearman$worked_example)
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
      h4(correlation_content$two_dependent$title),
      p(strong("Citation: "), correlation_content$two_dependent$citation),
      p(strong("Implemented via: "), code(correlation_content$two_dependent$backend)),
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
      p(strong("Implemented via: "), code(correlation_content$partial$backend)),
      hr(),
      h4(correlation_content$spearman$title),
      p(strong("Citation: "), correlation_content$spearman$citation),
      p(strong("Implemented via: "), code(correlation_content$spearman$backend))
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
        } else if (input$design == "two_dependent") {
          req(input$r_yx1, input$r_yx2, input$r_x1x2)
          calc_correlation_two_dependent(
            r_yx1 = input$r_yx1, r_yx2 = input$r_yx2, r_x1x2 = input$r_x1x2,
            alpha = input$alpha, power = input$power,
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
        } else if (input$design == "partial") {
          req(input$r_partial, input$k_partial)
          calc_correlation_partial(
            r = input$r_partial, k = input$k_partial,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )
        } else {
          req(input$r_spearman)
          calc_correlation_spearman(
            r = input$r_spearman, alpha = input$alpha, power = input$power,
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
      } else if (res$design == "two_dependent") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Fisher z' covariance c = %.4f", v$c))
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
      } else if (res$design == "spearman") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("(Equivalent Pearson-correlation design would need n = %d; ARE = %.4f)",
                     v$n_pearson, v$are))
        )
      } else {
        p(strong("Required sample size: "), v$n)
      }
    })

    render_export_handlers(output, result, function() {
      key <- input$design
      remap <- c("single" = "pearson")
      correlation_content[[if (key %in% names(remap)) remap[[key]] else key]]
    })

    # Power curves (ROADMAP P1 item 10): wired for the six designs with one
    # scalar correlation-like (or slope) effect. "two_dependent" needs
    # three jointly-constrained correlations and is left for a later
    # batch, same incremental rollout as items 8/9.
    render_power_curves(output, function() {
      if (input$design == "single") {
        req(input$r, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_correlation,
          args = list(r = input$r, alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "r", values = curve_range_correlation(), label = "r (expected correlation)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "two_independent") {
        req(input$r1, input$r2, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_correlation_two_independent,
          args = list(r1 = input$r1, r2 = input$r2, alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "r2", values = curve_range_correlation(), label = "r2 (group 2 correlation)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "point_biserial") {
        req(input$r_pb, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_correlation_point_biserial,
          args = list(r = input$r_pb, alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "r", values = curve_range_correlation(), label = "r (point-biserial correlation)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "regression_slope") {
        req(input$slope_reg, input$sdx_reg, input$sdy_reg, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_regression_slope,
          args = list(slope = input$slope_reg, sd_x = input$sdx_reg, sd_y = input$sdy_reg,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "slope", values = curve_range_around(0, 3 * abs(input$slope_reg)), label = "Regression slope"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "partial") {
        req(input$r_partial, input$k_partial, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_correlation_partial,
          args = list(r = input$r_partial, k = input$k_partial, alpha = input$alpha,
                       power = input$power, alternative = input$alternative),
          effect = list(param = "r", values = curve_range_correlation(), label = "r (partial correlation)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "spearman") {
        req(input$r_spearman, input$alpha, input$power, input$alternative)
        list(
          calc_fn = calc_correlation_spearman,
          args = list(r = input$r_spearman, alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "r", values = curve_range_correlation(), label = "r (Spearman correlation)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "two_dependent") {
        req(input$r_yx1, input$r_yx2, input$r_x1x2, input$alpha, input$power, input$alternative)
        # r_yx2 is only free inside the range that keeps the 3x3 correlation
        # matrix positive definite, given the other two correlations.
        half <- sqrt((1 - input$r_yx1^2) * (1 - input$r_x1x2^2))
        mid <- input$r_yx1 * input$r_x1x2
        list(
          calc_fn = calc_correlation_two_dependent,
          args = list(r_yx1 = input$r_yx1, r_yx2 = input$r_yx2, r_x1x2 = input$r_x1x2,
                       alpha = input$alpha, power = input$power, alternative = input$alternative),
          effect = list(param = "r_yx2", values = curve_range_within(mid - half, mid + half),
                        label = "r_yx2 (within the range a valid correlation matrix allows)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else {
        NULL
      }
    })
  })
}
