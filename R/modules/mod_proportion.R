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
          "Single proportion - precision-based (no reference value)" = "precision",
          "Single proportion vs. known/reference value (hypothesis test)" = "single",
          "Two independent proportions" = "two_sample"
        ),
        selected = "precision"
      ),
      conditionalPanel(
        condition = design_is("precision"),
        numericInput(ns("p_precision"), "p (expected proportion; use 0.5 if unknown)",
                     value = 0.5, min = 0, max = 1, step = 0.01),
        numericInput(ns("d_precision"), "d (desired precision / margin of error)",
                     value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("conf_level"), "Confidence level",
                     value = 0.95, min = 0.5, max = 0.999, step = 0.01),
        numericInput(ns("N_precision"),
                     "Population size N (optional; leave blank for a large/community population)",
                     value = NA, min = 1)
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
      conditionalPanel(
        condition = design_is("single", "two_sample"),
        numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(proportion_content$precision$title),
      render_formula_block(proportion_content$precision$formula_latex),
      shiny::markdown(proportion_content$precision$explanation),
      h5("Worked example"),
      shiny::markdown(proportion_content$precision$worked_example),
      hr(),
      h4(proportion_content$single$title),
      render_formula_block(proportion_content$single$formula_latex),
      shiny::markdown(proportion_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(proportion_content$single$worked_example),
      hr(),
      h4(proportion_content$two_sample$title),
      render_formula_block(proportion_content$two_sample$formula_latex),
      shiny::markdown(proportion_content$two_sample$explanation),
      h5("Worked example"),
      shiny::markdown(proportion_content$two_sample$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(proportion_content$precision$title),
      p(strong("Citation: "), proportion_content$precision$citation),
      p(strong("Implemented via: "), code(proportion_content$precision$backend)),
      hr(),
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
      req(input$design)

      if (input$design == "precision") {
        req(input$p_precision, input$d_precision, input$conf_level)
        # N_precision is optional: numericInput(value = NA) renders an empty
        # field, which Shiny reports as NULL (untouched) or NA (cleared) --
        # either means "no finite population correction".
        N <- input$N_precision
        if (is.null(N) || is.na(N)) N <- NULL
        tryCatch(
          list(ok = TRUE, value = calc_proportion_precision(
            p = input$p_precision, d = input$d_precision,
            conf_level = input$conf_level, N = N
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "single") {
        req(input$p0, input$p1_single, input$alpha, input$power, input$alternative)
        tryCatch(
          list(ok = TRUE, value = calc_proportion_1s(
            p0 = input$p0, p1 = input$p1_single,
            alpha = input$alpha, power = input$power,
            alternative = input$alternative
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$p1_two, input$p2_two, input$alpha, input$power, input$alternative)
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
      if (input$design == "precision") {
        tagList(
          p(strong("Required sample size: "), v$n),
          if (!is.null(v$N)) {
            p(sprintf("(before finite population correction: %d, for population N = %s)",
                      v$n_unadjusted, v$N))
          },
          p(sprintf("Z = %.4f", v$z))
        )
      } else if (input$design == "single") {
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
