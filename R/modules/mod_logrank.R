# Log-Rank / Survival module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8) --
# outer radio for "which method", with a conditionalPanel per design.

logrank_meta <- list(
  id = "logrank",
  nav_title = "Log-Rank / Survival"
)

mod_logrank_ui <- function(id) {
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
          "Log-rank test (two survival curves)" = "logrank",
          "Cox regression -- binary covariate" = "cox_binary",
          "Cox regression -- continuous covariate" = "cox_continuous"
        )
      ),
      conditionalPanel(
        condition = design_is("logrank"),
        numericInput(ns("pE"), "pE (cumulative event probability, experimental group)",
                     value = 0.3707, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("pC"), "pC (cumulative event probability, control group)",
                     value = 0.4890, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("hr_logrank"), "Postulated hazard ratio (HR)", value = 0.7, min = 0.01, step = 0.05),
        numericInput(ns("ratio"), "Experimental:control allocation ratio", value = 1, min = 0.1, step = 0.5),
        numericInput(ns("alpha_logrank"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_logrank"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("cox_binary"),
        numericInput(ns("theta_b"), "Postulated hazard ratio (theta)", value = 2, min = 0.01, step = 0.1),
        numericInput(ns("p_b"), "Proportion with covariate of interest = 1 (p)",
                     value = 0.39, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("psi_b"), "Overall event probability (psi)",
                     value = 0.505, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("rho2_b"), "Squared correlation with adjustment covariate (rho-squared)",
                     value = 0.132^2, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("alpha_b"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_b"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("cox_continuous"),
        numericInput(ns("theta_c"), "Postulated hazard ratio per unit increase (theta)",
                     value = exp(1), min = 0.01, step = 0.1),
        numericInput(ns("sigma2_c"), "Variance of the covariate of interest (sigma-squared)",
                     value = 0.3126^2, min = 0.0001, step = 0.01),
        numericInput(ns("psi_c"), "Overall event probability (psi)",
                     value = 0.738, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("rho2_c"), "Squared multiple correlation with other covariates (rho-squared)",
                     value = 0.1837, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("alpha_c"), "Significance level (alpha)", value = 0.1, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_c"), "Desired power", value = 0.806, min = 0.5, max = 0.999, step = 0.001)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(logrank_content$logrank$title),
      withMathJax(HTML(logrank_content$logrank$formula_latex)),
      shiny::markdown(logrank_content$logrank$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$logrank$worked_example),
      hr(),
      h4(logrank_content$cox_binary$title),
      withMathJax(HTML(logrank_content$cox_binary$formula_latex)),
      shiny::markdown(logrank_content$cox_binary$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$cox_binary$worked_example),
      hr(),
      h4(logrank_content$cox_continuous$title),
      withMathJax(HTML(logrank_content$cox_continuous$formula_latex)),
      shiny::markdown(logrank_content$cox_continuous$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$cox_continuous$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(logrank_content$logrank$title),
      p(strong("Citation: "), logrank_content$logrank$citation),
      p(strong("Implemented via: "), code(logrank_content$logrank$backend)),
      hr(),
      h4(logrank_content$cox_binary$title),
      p(strong("Citation: "), logrank_content$cox_binary$citation),
      p(strong("Implemented via: "), code(logrank_content$cox_binary$backend)),
      hr(),
      h4(logrank_content$cox_continuous$title),
      p(strong("Citation: "), logrank_content$cox_continuous$citation),
      p(strong("Implemented via: "), code(logrank_content$cox_continuous$backend))
    )
  )
}

mod_logrank_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "logrank") {
        req(input$pE, input$pC, input$hr_logrank, input$ratio, input$alpha_logrank, input$power_logrank)
        tryCatch(
          list(ok = TRUE, value = calc_logrank(
            pE = input$pE, pC = input$pC, hr = input$hr_logrank, ratio = input$ratio,
            alpha = input$alpha_logrank, power = input$power_logrank
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "cox_binary") {
        req(input$power_b, input$theta_b, input$p_b, input$psi_b, input$rho2_b, input$alpha_b)
        tryCatch(
          list(ok = TRUE, value = calc_cox_binary(
            power = input$power_b, theta = input$theta_b, p = input$p_b,
            psi = input$psi_b, rho2 = input$rho2_b, alpha = input$alpha_b
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$power_c, input$theta_c, input$sigma2_c, input$psi_c, input$rho2_c, input$alpha_c)
        tryCatch(
          list(ok = TRUE, value = calc_cox_continuous(
            power = input$power_c, theta = input$theta_c, sigma2 = input$sigma2_c,
            psi = input$psi_c, rho2 = input$rho2_c, alpha = input$alpha_c
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
      if (input$design == "logrank") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Experimental group: %d, Control group: %d", v$n_exp, v$n_control))
        )
      } else {
        tagList(
          p(strong("Required total sample size: "), v$n)
        )
      }
    })
  })
}
