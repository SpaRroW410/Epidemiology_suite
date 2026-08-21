# Non-Inferiority module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_proportion.R (docs/SDD.md #8).

noninferiority_meta <- list(
  id = "noninferiority",
  nav_title = "Non-Inferiority"
)

mod_noninferiority_ui <- function(id) {
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
          "Two means" = "means",
          "Two proportions" = "proportions"
        )
      ),
      conditionalPanel(
        condition = design_is("means"),
        numericInput(ns("mean_new"), "Expected mean, new-treatment group", value = 0.20),
        numericInput(ns("mean_standard"), "Expected mean, standard-treatment group", value = 0.20),
        numericInput(ns("sd"), "Expected standard deviation", value = 0.10, min = 0.0001),
        numericInput(ns("margin"), "Non-inferiority margin (> 0)", value = 0.05, min = 0.0001),
        numericInput(ns("alpha"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio"), "Allocation ratio (new : standard)", value = 1, min = 0.1, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("proportions"),
        numericInput(ns("p_new"), "p (new-treatment group proportion)", value = 0.85, min = 0, max = 1, step = 0.01),
        numericInput(ns("p_standard"), "p (standard-treatment group proportion)", value = 0.65, min = 0, max = 1, step = 0.01),
        numericInput(ns("margin_prop"), "Non-inferiority margin (0-1)", value = 0.10, min = 0.001, max = 0.99, step = 0.01),
        numericInput(ns("alpha_prop"), "Significance level, one-sided (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_prop"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("ratio_prop"), "Allocation ratio (new : standard)", value = 1, min = 0.1, step = 0.1)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(noninferiority_content$means$title),
      withMathJax(HTML(noninferiority_content$means$formula_latex)),
      shiny::markdown(noninferiority_content$means$explanation),
      h5("Worked example"),
      shiny::markdown(noninferiority_content$means$worked_example),
      hr(),
      h4(noninferiority_content$proportions$title),
      withMathJax(HTML(noninferiority_content$proportions$formula_latex)),
      shiny::markdown(noninferiority_content$proportions$explanation),
      h5("Worked example"),
      shiny::markdown(noninferiority_content$proportions$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(noninferiority_content$means$title),
      p(strong("Citation: "), noninferiority_content$means$citation),
      p(strong("Implemented via: "), code(noninferiority_content$means$backend)),
      hr(),
      h4(noninferiority_content$proportions$title),
      p(strong("Citation: "), noninferiority_content$proportions$citation),
      p(strong("Implemented via: "), code(noninferiority_content$proportions$backend))
    )
  )
}

mod_noninferiority_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)

      if (input$design == "means") {
        req(input$mean_new, input$mean_standard, input$sd, input$margin,
            input$alpha, input$power, input$ratio)
        tryCatch(
          list(ok = TRUE, value = calc_noninferiority_means(
            mean_new = input$mean_new, mean_standard = input$mean_standard,
            sd = input$sd, margin = input$margin,
            alpha = input$alpha, power = input$power, ratio = input$ratio
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p_new, input$p_standard, input$margin_prop, input$alpha_prop,
            input$power_prop, input$ratio_prop)
        tryCatch(
          list(ok = TRUE, value = calc_noninferiority_proportions(
            p_new = input$p_new, p_standard = input$p_standard, margin = input$margin_prop,
            alpha = input$alpha_prop, power = input$power_prop, ratio = input$ratio_prop
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
        p(strong("Required sample size, new group: "), v$n_new),
        p(strong("Required sample size, standard group: "), v$n_standard),
        p(strong("Total sample size: "), v$n_total)
      )
    })
  })
}
