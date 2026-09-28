# Bayesian Design Analysis module: Calculate / Formula-Help / Reference
# sub-tabs. Outer "design" radio (docs/SDD.md #8) selects between two
# genuinely different Bayesian sample-size methods: assurance for a
# two-arm proportions trial (calc_bayesian_assurance_or()), with its own
# inner radio for the prior shape; and Bayes Factor Design Analysis for a
# two-sample means comparison (calc_bfda_ttest()).

bayesian_meta <- list(
  id = "bayesian",
  nav_title = "Bayesian Design Analysis"
)

mod_bayesian_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  prior_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("prior_type"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Assurance, two-arm proportions trial (log odds ratio)" = "assurance_or",
          "Bayes Factor Design Analysis, two-sample means" = "bfda"
        ),
        selected = "assurance_or"
      ),
      conditionalPanel(
        condition = design_is("assurance_or"),
        numericInput(ns("p1"), "Anticipated response probability, group 1 (p1)",
                     value = 0.3, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2"), "Anticipated response probability, group 2 (p2)",
                     value = 0.3, min = 0.001, max = 0.999, step = 0.01),
        radioButtons(
          ns("prior_type"), "Prior on the log odds ratio",
          choices = c("Normal (mean, SD)" = "normal", "Uniform (lower, upper)" = "uniform")
        ),
        conditionalPanel(
          condition = prior_is("normal"),
          numericInput(ns("prior_mean"), "Prior mean (log odds ratio)", value = 1, step = 0.1),
          numericInput(ns("prior_sd"), "Prior SD (log odds ratio)", value = 1, min = 0.0001, step = 0.1)
        ),
        conditionalPanel(
          condition = prior_is("uniform"),
          numericInput(ns("prior_lower"), "Prior lower bound (log odds ratio)", value = log(1.2), step = 0.05),
          numericInput(ns("prior_upper"), "Prior upper bound (log odds ratio)", value = log(1.3), step = 0.05)
        ),
        numericInput(ns("delta_w"), "Minimally worthwhile log odds ratio (delta_w)", value = 0, step = 0.1),
        numericInput(ns("n_ratio"), "Allocation ratio n2/n1", value = 1, min = 0.01, step = 0.1),
        numericInput(ns("alpha_or"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_or"), "Target assurance", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("bfda"),
        numericInput(ns("effect_size_bfda"), "Cohen's d effect size", value = 0.5, min = 0.01, step = 0.05),
        numericInput(ns("bf_threshold"), "Target Bayes factor (BF10) threshold", value = 10, min = 1.01, step = 1),
        numericInput(ns("nsim_bfda"), "Monte Carlo replicates per candidate n (nsim)",
                     value = 100, min = 50, max = 1000, step = 50),
        numericInput(ns("alpha_bfda"), "Significance level (alpha, for the classical warm-start n only)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_bfda"), "Target probability BF10 exceeds the threshold",
                     value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        monte_carlo_calculate_ui(ns, "may take up to 10-15 seconds. Set the inputs above, then click Calculate.")
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(bayesian_content$assurance_or$title),
      render_formula_block(bayesian_content$assurance_or$formula_latex),
      shiny::markdown(bayesian_content$assurance_or$explanation),
      h5("Worked example"),
      shiny::markdown(bayesian_content$assurance_or$worked_example),
      hr(),
      h4(bayesian_content$bfda$title),
      render_formula_block(bayesian_content$bfda$formula_latex),
      shiny::markdown(bayesian_content$bfda$explanation),
      h5("Worked example"),
      shiny::markdown(bayesian_content$bfda$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(bayesian_content$assurance_or$title),
      p(strong("Citation: "), bayesian_content$assurance_or$citation),
      p(strong("Implemented via: "), code(bayesian_content$assurance_or$backend)),
      hr(),
      h4(bayesian_content$bfda$title),
      p(strong("Citation: "), bayesian_content$bfda$citation),
      p(strong("Implemented via: "), code(bayesian_content$bfda$backend))
    )
  )
}

mod_bayesian_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # bfda is Monte Carlo (ROADMAP F9/P1#7): once that design is selected,
    # recompute only on Calculate, not on every keystroke -- see
    # monte_carlo_calculate_ui()'s comment in mod_shared_ui.R.
    SLOW_DESIGNS <- "bfda"

    result <- reactive({
      req(input$design)
      is_slow <- input$design %in% SLOW_DESIGNS
      if (is_slow) input$calculate

      compute <- function() {
      if (input$design == "assurance_or") {
        req(input$p1, input$p2, input$prior_type, input$delta_w, input$n_ratio,
            input$alpha_or, input$power_or)

        if (input$prior_type == "normal") {
          req(input$prior_mean, input$prior_sd)
          tryCatch(
            list(ok = TRUE, design = "assurance_or", value = calc_bayesian_assurance_or(
              p1 = input$p1, p2 = input$p2, prior_type = "normal",
              prior_mean = input$prior_mean, prior_sd = input$prior_sd,
              delta_w = input$delta_w, n_ratio = input$n_ratio,
              alpha = input$alpha_or, power = input$power_or
            )),
            error = function(e) list(ok = FALSE, message = conditionMessage(e))
          )
        } else {
          req(input$prior_lower, input$prior_upper)
          tryCatch(
            list(ok = TRUE, design = "assurance_or", value = calc_bayesian_assurance_or(
              p1 = input$p1, p2 = input$p2, prior_type = "uniform",
              prior_lower = input$prior_lower, prior_upper = input$prior_upper,
              delta_w = input$delta_w, n_ratio = input$n_ratio,
              alpha = input$alpha_or, power = input$power_or
            )),
            error = function(e) list(ok = FALSE, message = conditionMessage(e))
          )
        }
      } else {
        req(input$effect_size_bfda, input$bf_threshold, input$nsim_bfda,
            input$alpha_bfda, input$power_bfda)
        tryCatch(
          list(ok = TRUE, design = "bfda", value = calc_bfda_ttest(
            effect_size = input$effect_size_bfda, bf_threshold = input$bf_threshold,
            alpha = input$alpha_bfda, power = input$power_bfda, nsim = input$nsim_bfda
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }
      }

      if (is_slow) isolate(compute()) else compute()
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (res$design == "assurance_or") {
        tagList(
          p(strong("Required n, group 1: "), v$n1),
          p(strong("Required n, group 2: "), v$n2),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Achieved assurance at this n: %.4f", v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Required sample size per group: "), v$n1),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Simulated probability BF10 > threshold at this n: %.3f (Monte Carlo estimate)",
                     v$achieved_power)),
          p(sprintf("(For comparison, the classical two-sample t-test would need n = %d per group)",
                     v$n_classical))
        )
      }
    })
  })
}
