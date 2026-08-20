# Proportions module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the module contract in docs/SDD.md #8 -- UI + server + metadata,
# so a future module (e.g. mod_means.R) can copy this file and swap the
# calculation call, content list, and input fields.

proportion_meta <- list(
  id = "proportion",
  nav_title = "Proportions"
)

mod_proportion_ui <- function(id) {
  ns <- NS(id)

  # Non-idiomatic-for-plain-R note: conditionalPanel() evaluates a JS
  # expression in the browser, so a module input id must be referenced as
  # input['<namespaced id>'] rather than the bare R variable name. ns("design")
  # returns the namespaced id (e.g. "proportion-design") as a string.
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Single proportion vs. known value" = "single",
          "Two independent proportions" = "two_sample"
        )
      ),
      conditionalPanel(
        condition = design_is("single"),
        numericInput(ns("p0"), "p0 (reference proportion)", value = 0.20, min = 0, max = 1, step = 0.01),
        numericInput(ns("p1_single"), "p1 (expected proportion)", value = 0.30, min = 0, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("two_sample"),
        numericInput(ns("p1_two"), "p1 (group 1 proportion)", value = 0.10, min = 0, max = 1, step = 0.01),
        numericInput(ns("p2_two"), "p2 (group 2 proportion)", value = 0.25, min = 0, max = 1, step = 0.01)
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
      h4("Single proportion vs. known value"),
      withMathJax(HTML(proportion_content$single$formula_latex)),
      shiny::markdown(proportion_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(proportion_content$single$worked_example),
      hr(),
      h4("Two independent proportions"),
      withMathJax(HTML(proportion_content$two_sample$formula_latex)),
      shiny::markdown(proportion_content$two_sample$explanation),
      h5("Worked example"),
      shiny::markdown(proportion_content$two_sample$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(proportion_content$single$title),
      p(strong("Citation: "), proportion_content$single$citation),
      p(strong("Implemented via: "), code(proportion_content$single$backend)),
      hr(),
      h4(proportion_content$two_sample$title),
      p(strong("Citation: "), proportion_content$two_sample$citation),
      p(strong("Implemented via: "), code(proportion_content$two_sample$backend))
    )
  )
}

mod_proportion_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$alpha, input$power, input$alternative)

      if (input$design == "single") {
        req(input$p0, input$p1_single)
        tryCatch(
          list(ok = TRUE, value = calc_proportion_1s(
            p0 = input$p0, p1 = input$p1_single,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p1_two, input$p2_two)
        tryCatch(
          list(ok = TRUE, value = calc_proportion_2s(
            p1 = input$p1_two, p2 = input$p2_two,
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
      if (input$design == "single") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Effect size h = %.4f", v$h))
        )
      } else {
        tagList(
          p(strong("Required sample size per group: "), v$n_per_group),
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Effect size h = %.4f", v$h))
        )
      }
    })
  })
}
