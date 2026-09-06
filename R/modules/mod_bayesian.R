# Bayesian Assurance module: Calculate / Formula-Help / Reference sub-tabs.
# Single design (no outer design radio, following mod_manova.R's pattern),
# but with an inner radio for the prior shape (normal vs. uniform), since
# calc_bayesian_assurance_or() accepts either.

bayesian_meta <- list(
  id = "bayesian",
  nav_title = "Bayesian Assurance"
)

mod_bayesian_ui <- function(id) {
  ns <- NS(id)

  prior_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("prior_type"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
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
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Target assurance", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
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
      shiny::markdown(bayesian_content$assurance_or$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(bayesian_content$assurance_or$title),
      p(strong("Citation: "), bayesian_content$assurance_or$citation),
      p(strong("Implemented via: "), code(bayesian_content$assurance_or$backend))
    )
  )
}

mod_bayesian_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$p1, input$p2, input$prior_type, input$delta_w, input$n_ratio,
          input$alpha, input$power)

      if (input$prior_type == "normal") {
        req(input$prior_mean, input$prior_sd)
        tryCatch(
          list(ok = TRUE, value = calc_bayesian_assurance_or(
            p1 = input$p1, p2 = input$p2, prior_type = "normal",
            prior_mean = input$prior_mean, prior_sd = input$prior_sd,
            delta_w = input$delta_w, n_ratio = input$n_ratio,
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$prior_lower, input$prior_upper)
        tryCatch(
          list(ok = TRUE, value = calc_bayesian_assurance_or(
            p1 = input$p1, p2 = input$p2, prior_type = "uniform",
            prior_lower = input$prior_lower, prior_upper = input$prior_upper,
            delta_w = input$delta_w, n_ratio = input$n_ratio,
            alpha = input$alpha, power = input$power
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
        p(strong("Required n, group 1: "), v$n1),
        p(strong("Required n, group 2: "), v$n2),
        p(strong("Total sample size: "), v$n_total),
        p(sprintf("Achieved assurance at this n: %.4f", v$achieved_power))
      )
    })
  })
}
