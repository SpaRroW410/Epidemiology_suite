# Means module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R (docs/SDD.md #8) --
# UI + server + metadata, so this file is itself a template for the next
# t-test-adjacent module.

means_meta <- list(
  id = "means",
  nav_title = "Means"
)

mod_means_ui <- function(id) {
  ns <- NS(id)

  # See mod_proportion.R for why conditionalPanel() conditions are built
  # with ns() rather than hardcoded -- same reasoning applies here.
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
          "Single mean vs. known/reference value (hypothesis test)" = "single",
          "Two independent means" = "two_sample",
          "Two paired means (before-after, matched pairs)" = "paired"
        )
      ),
      conditionalPanel(
        condition = design_is("single"),
        numericInput(ns("mu0"), "mu0 (reference mean)", value = 120),
        numericInput(ns("mu1_single"), "mu1 (expected mean)", value = 125),
        numericInput(ns("sd_single"), "sd (expected standard deviation)",
                     value = 15, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("two_sample"),
        numericInput(ns("mu1_two"), "mu1 (group 1 mean)", value = 12.5),
        numericInput(ns("mu2_two"), "mu2 (group 2 mean)", value = 11.5),
        numericInput(ns("sd_two"), "sd (common/pooled standard deviation)",
                     value = 2, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("paired"),
        numericInput(ns("mean_diff"), "Mean of the paired differences", value = 2),
        numericInput(ns("sd_diff"), "SD of the paired differences",
                     value = 5, min = 0.0001)
      ),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      selectInput(
        ns("alternative"), "Alternative hypothesis",
        choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(means_content$single$title),
      withMathJax(HTML(means_content$single$formula_latex)),
      shiny::markdown(means_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$single$worked_example),
      hr(),
      h4(means_content$two_sample$title),
      withMathJax(HTML(means_content$two_sample$formula_latex)),
      shiny::markdown(means_content$two_sample$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$two_sample$worked_example),
      hr(),
      h4(means_content$paired$title),
      withMathJax(HTML(means_content$paired$formula_latex)),
      shiny::markdown(means_content$paired$explanation),
      h5("Worked example"),
      shiny::markdown(means_content$paired$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(means_content$single$title),
      p(strong("Citation: "), means_content$single$citation),
      p(strong("Implemented via: "), code(means_content$single$backend)),
      hr(),
      h4(means_content$two_sample$title),
      p(strong("Citation: "), means_content$two_sample$citation),
      p(strong("Implemented via: "), code(means_content$two_sample$backend)),
      hr(),
      h4(means_content$paired$title),
      p(strong("Citation: "), means_content$paired$citation),
      p(strong("Implemented via: "), code(means_content$paired$backend))
    )
  )
}

mod_means_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$alpha, input$power, input$alternative)

      if (input$design == "single") {
        req(input$mu0, input$mu1_single, input$sd_single)
        tryCatch(
          list(ok = TRUE, value = calc_means_1s(
            mu0 = input$mu0, mu1 = input$mu1_single, sd = input$sd_single,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "two_sample") {
        req(input$mu1_two, input$mu2_two, input$sd_two)
        tryCatch(
          list(ok = TRUE, value = calc_means_2s_indep(
            mu1 = input$mu1_two, mu2 = input$mu2_two, sd = input$sd_two,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$mean_diff, input$sd_diff)
        tryCatch(
          list(ok = TRUE, value = calc_means_paired(
            mean_diff = input$mean_diff, sd_diff = input$sd_diff,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
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
      if (input$design == "two_sample") {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Effect size d = %.4f", v$d))
        )
      } else {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Effect size d = %.4f", v$d))
        )
      }
    })
  })
}
