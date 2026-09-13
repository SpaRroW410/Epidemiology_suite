# Monte Carlo GLMM module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the design-radio pattern (docs/SDD.md #8). Unlike
# every other calculator in this app, this one takes noticeably longer
# to compute (a genuine Monte Carlo search over lme4 model refits, not a
# closed-form formula) -- typically 5-25 seconds depending on the design
# and nsim -- so the UI includes an explicit note about this.

glmm_meta <- list(
  id = "glmm",
  nav_title = "Monte Carlo GLMM (Cluster-Randomized Trial)"
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
          "Continuous outcome (LMM)" = "lmm_continuous",
          "Binary outcome (GLMM, logistic)" = "glmm_binary"
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
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
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
      shiny::markdown(glmm_content$glmm_binary$worked_example)
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
      p(strong("Implemented via: "), code(glmm_content$glmm_binary$backend))
    )
  )
}

mod_glmm_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "lmm_continuous") {
        req(input$cluster_size_lmm, input$icc, input$sigma_total, input$delta_lmm,
            input$alpha_lmm, input$power_lmm, input$nsim_lmm, input$seed_lmm)
        tryCatch(
          list(ok = TRUE, value = calc_glmm_lmm_power(
            cluster_size = input$cluster_size_lmm, icc = input$icc, sigma_total = input$sigma_total,
            delta = input$delta_lmm, alpha = input$alpha_lmm, power = input$power_lmm,
            nsim = input$nsim_lmm, seed = input$seed_lmm
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$cluster_size_glmm, input$sigma_u, input$baseline_prob, input$or,
            input$alpha_glmm, input$power_glmm, input$nsim_glmm, input$seed_glmm)
        tryCatch(
          list(ok = TRUE, value = calc_glmm_logistic_power(
            cluster_size = input$cluster_size_glmm, sigma_u = input$sigma_u,
            baseline_prob = input$baseline_prob, or = input$or,
            alpha = input$alpha_glmm, power = input$power_glmm,
            nsim = input$nsim_glmm, seed = input$seed_glmm
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
      tagList(
        p(strong("Required number of clusters: "), v$n_clusters),
        p(strong("Required total sample size: "), v$n_total),
        p(sprintf("Achieved power at this n (Monte Carlo estimate): %.3f", v$achieved_power))
      )
    })
  })
}
