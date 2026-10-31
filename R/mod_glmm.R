# Monte Carlo GLMM module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the design-radio pattern (docs/SDD.md #8). Unlike
# every other calculator in this app, this one takes noticeably longer
# to compute (a genuine Monte Carlo search over lme4 model refits, not a
# closed-form formula) -- typically 5-25 seconds depending on the design
# and nsim -- so the UI includes an explicit note about this.

glmm_meta <- list(
  id = "glmm",
  nav_title = "Monte Carlo Mixed Models"
)

mod_glmm_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      div(
        class = "alert alert-warning",
        strong("This calculator is slower than the others: "),
        "it directly simulates and refits many mixed models rather than solving a formula. ",
        "Expect roughly 5-25 seconds to compute, depending on the design and nsim."
      ),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Cluster-randomized trial, continuous outcome (LMM)" = "lmm_continuous",
          "Cluster-randomized trial, binary outcome (GLMM, logistic)" = "glmm_binary",
          "Growth curve model, group difference in slope" = "growth_curve"
        )
      ),
      conditionalPanel(
        condition = design_is("lmm_continuous"),
        numericInput(ns("cluster_size_lmm"), "Individuals per cluster", value = 10, min = 2, step = 1),
        numericInput(ns("icc"), "Intraclass correlation (ICC)", value = 0.05, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("sigma_total"), "Total outcome standard deviation", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("delta_lmm"), "Treatment-control mean difference to detect", value = 0.5, step = 0.1),
        numericInput(ns("alpha_lmm"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_lmm"), "Desired power", value = 0.8, min = 0.5, max = 0.95, step = 0.01),
        numericInput(ns("nsim_lmm"), "Monte Carlo replicates per candidate n (nsim)", value = 50, min = 10, max = 500, step = 10),
        numericInput(ns("seed_lmm"), "Random seed", value = 12345, step = 1)
      ),
      conditionalPanel(
        condition = design_is("glmm_binary"),
        numericInput(ns("cluster_size_glmm"), "Individuals per cluster", value = 20, min = 2, step = 1),
        numericInput(ns("sigma_u"), "Random-intercept standard deviation (log-odds scale)", value = 0.3, min = 0.0001, step = 0.1),
        numericInput(ns("baseline_prob"), "Expected control-arm outcome probability", value = 0.3, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("or"), "Odds ratio (treatment vs. control) to detect", value = 2, min = 0.001, step = 0.1),
        numericInput(ns("alpha_glmm"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_glmm"), "Desired power", value = 0.8, min = 0.5, max = 0.95, step = 0.01),
        numericInput(ns("nsim_glmm"), "Monte Carlo replicates per candidate n (nsim)", value = 30, min = 10, max = 300, step = 10),
        numericInput(ns("seed_glmm"), "Random seed", value = 12345, step = 1)
      ),
      conditionalPanel(
        condition = design_is("growth_curve"),
        numericInput(ns("ntimes_gc"), "Time points per subject (T)", value = 4, min = 2, step = 1),
        numericInput(ns("delta_slope_gc"), "Group difference in slope (rate of change) to detect", value = 0.4, step = 0.05),
        numericInput(ns("sigma2_intercept_gc"), "Random-intercept variance", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("sigma2_slope_gc"), "Random-slope variance", value = 0.2, min = 0.0001, step = 0.05),
        numericInput(ns("cor_is_gc"), "Intercept-slope correlation", value = 0.1, min = -1, max = 1, step = 0.05),
        numericInput(ns("sigma2_residual_gc"), "Residual variance", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("baseline_slope_gc"), "Common (control-arm) slope", value = 0, step = 0.05),
        numericInput(ns("alpha_gc"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_gc"), "Desired power", value = 0.8, min = 0.5, max = 0.95, step = 0.01),
        numericInput(ns("nsim_gc"), "Monte Carlo replicates per candidate n (nsim)", value = 50, min = 10, max = 500, step = 10),
        numericInput(ns("seed_gc"), "Random seed", value = 12345, step = 1)
      ),
      monte_carlo_calculate_ui(ns),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(glmm_content$lmm_continuous$title),
      render_formula_block(glmm_content$lmm_continuous$formula_latex),
      shiny::markdown(glmm_content$lmm_continuous$explanation),
      h5("Worked example"),
      shiny::markdown(glmm_content$lmm_continuous$worked_example),
      hr(),
      h4(glmm_content$glmm_binary$title),
      render_formula_block(glmm_content$glmm_binary$formula_latex),
      shiny::markdown(glmm_content$glmm_binary$explanation),
      h5("Worked example"),
      shiny::markdown(glmm_content$glmm_binary$worked_example),
      hr(),
      h4(glmm_content$growth_curve$title),
      render_formula_block(glmm_content$growth_curve$formula_latex),
      shiny::markdown(glmm_content$growth_curve$explanation),
      h5("Worked example"),
      shiny::markdown(glmm_content$growth_curve$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(glmm_content$lmm_continuous$title),
      p(strong("Citation: "), glmm_content$lmm_continuous$citation),
      p(strong("Implemented via: "), code(glmm_content$lmm_continuous$backend)),
      hr(),
      h4(glmm_content$glmm_binary$title),
      p(strong("Citation: "), glmm_content$glmm_binary$citation),
      p(strong("Implemented via: "), code(glmm_content$glmm_binary$backend)),
      hr(),
      h4(glmm_content$growth_curve$title),
      p(strong("Citation: "), glmm_content$growth_curve$citation),
      p(strong("Implemented via: "), code(glmm_content$growth_curve$backend))
    )
  )
}

mod_glmm_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # the simulations run in a background R process on a server (background.R); `result` is the finished calculation
    bg <- background_calc()
    result <- bg$result(function() result_now())

    # Monte Carlo (ROADMAP F9/P1#7): recompute only when the design changes
    # or Calculate is clicked, not on every keystroke -- see
    # monte_carlo_calculate_ui()'s comment in mod_shared_ui.R.
    result_now <- reactive({
      req(input$design)
      input$calculate
      isolate({

      if (input$design == "lmm_continuous") {
        req(input$cluster_size_lmm, input$icc, input$sigma_total, input$delta_lmm,
            input$alpha_lmm, input$power_lmm, input$nsim_lmm, input$seed_lmm)
        tryCatch(
          list(ok = TRUE, value = bg$calc("calc_glmm_lmm_power",
            cluster_size = input$cluster_size_lmm, icc = input$icc, sigma_total = input$sigma_total,
            delta = input$delta_lmm, alpha = input$alpha_lmm, power = input$power_lmm,
            nsim = input$nsim_lmm, seed = input$seed_lmm
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "glmm_binary") {
        req(input$cluster_size_glmm, input$sigma_u, input$baseline_prob, input$or,
            input$alpha_glmm, input$power_glmm, input$nsim_glmm, input$seed_glmm)
        tryCatch(
          list(ok = TRUE, value = bg$calc("calc_glmm_logistic_power",
            cluster_size = input$cluster_size_glmm, sigma_u = input$sigma_u,
            baseline_prob = input$baseline_prob, or = input$or,
            alpha = input$alpha_glmm, power = input$power_glmm,
            nsim = input$nsim_glmm, seed = input$seed_glmm
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$ntimes_gc, input$delta_slope_gc, input$sigma2_intercept_gc, input$sigma2_slope_gc,
            input$cor_is_gc, input$sigma2_residual_gc, input$baseline_slope_gc,
            input$alpha_gc, input$power_gc, input$nsim_gc, input$seed_gc)
        tryCatch(
          list(ok = TRUE, value = bg$calc("calc_growth_curve_power",
            ntimes = input$ntimes_gc, delta_slope = input$delta_slope_gc,
            sigma2_intercept = input$sigma2_intercept_gc, sigma2_slope = input$sigma2_slope_gc,
            cor_intercept_slope = input$cor_is_gc, sigma2_residual = input$sigma2_residual_gc,
            baseline_slope = input$baseline_slope_gc, alpha = input$alpha_gc, power = input$power_gc,
            nsim = input$nsim_gc, seed = input$seed_gc
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }

      })
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (input$design == "growth_curve") {
        tagList(
          p(strong("Required subjects per group: "), v$n_per_group),
          p(strong("Required total sample size: "), v$n_total),
          p(sprintf("Achieved power at this n (Monte Carlo estimate): %.3f", v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Required number of clusters: "), v$n_clusters),
          p(strong("Required total sample size: "), v$n_total),
          p(sprintf("Achieved power at this n (Monte Carlo estimate): %.3f", v$achieved_power))
        )
      }
    })

    render_export_handlers(output, result, function() glmm_content[[input$design]])
  })
}
