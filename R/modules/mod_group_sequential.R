# Group Sequential Design module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_tost.R (docs/SDD.md
# #8) -- three outcome-type designs (continuous, binary, survival) sharing
# a common set of interim-monitoring inputs (number of looks, boundary
# shape, futility, allocation ratio, alpha/power/alternative).

group_sequential_meta <- list(
  id = "group_sequential",
  nav_title = "Group Sequential Design"
)

mod_group_sequential_ui <- function(id) {
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
        ns("design"), "Outcome type",
        choices = c(
          "Continuous (means)" = "normal",
          "Binary (proportions)" = "binary",
          "Time-to-event (survival)" = "survival"
        ),
        selected = "normal"
      ),
      conditionalPanel(
        condition = design_is("normal"),
        numericInput(ns("delta_normal"), "Assumed difference in means (delta)", value = 0.25),
        numericInput(ns("sd_normal"), "Common standard deviation (SD)", value = 1, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("binary"),
        numericInput(ns("pC_binary"), "pC (control-arm event/response probability)",
                     value = 0.30, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("pE_binary"), "pE (experimental-arm event/response probability)",
                     value = 0.50, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("survival"),
        numericInput(ns("hr_survival"), "Assumed hazard ratio (experimental vs. control)",
                     value = 0.5, min = 0.001, step = 0.01)
      ),
      hr(),
      selectInput(ns("n_looks"), "Number of planned analyses (including the final one)",
                  choices = 1:6, selected = 4),
      sliderInput(ns("boundary_shape"), "Boundary shape (0 = Pocock, 0.5 = O'Brien-Fleming)",
                  value = 0.5, min = 0, max = 0.5, step = 0.05),
      checkboxInput(ns("futility"), "Include a (non-binding) futility boundary", value = TRUE),
      numericInput(ns("r"), "Allocation ratio, experimental:control (r)", value = 1, min = 0.01, step = 0.1),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      selectInput(ns("alternative"), "Alternative hypothesis",
                  choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided")),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(group_sequential_content$normal$title),
      render_formula_block(group_sequential_content$normal$formula_latex),
      shiny::markdown(group_sequential_content$normal$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$normal$worked_example),
      hr(),
      h4(group_sequential_content$binary$title),
      render_formula_block(group_sequential_content$binary$formula_latex),
      shiny::markdown(group_sequential_content$binary$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$binary$worked_example),
      hr(),
      h4(group_sequential_content$survival$title),
      render_formula_block(group_sequential_content$survival$formula_latex),
      shiny::markdown(group_sequential_content$survival$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$survival$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(group_sequential_content$normal$title),
      p(strong("Citation: "), group_sequential_content$normal$citation),
      p(strong("Implemented via: "), code(group_sequential_content$normal$backend)),
      hr(),
      h4(group_sequential_content$binary$title),
      p(strong("Citation: "), group_sequential_content$binary$citation),
      p(strong("Implemented via: "), code(group_sequential_content$binary$backend)),
      hr(),
      h4(group_sequential_content$survival$title),
      p(strong("Citation: "), group_sequential_content$survival$citation),
      p(strong("Implemented via: "), code(group_sequential_content$survival$backend))
    )
  )
}

mod_group_sequential_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$n_looks, input$boundary_shape, input$r,
          input$alpha, input$power, input$alternative)
      n_looks <- as.integer(input$n_looks)

      if (input$design == "normal") {
        req(input$delta_normal, input$sd_normal)
        tryCatch(
          list(ok = TRUE, value = calc_group_sequential_normal(
            delta = input$delta_normal, sd = input$sd_normal, n_looks = n_looks,
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative, boundary_shape = input$boundary_shape,
            futility = input$futility
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "binary") {
        req(input$pC_binary, input$pE_binary)
        tryCatch(
          list(ok = TRUE, value = calc_group_sequential_binary(
            pC = input$pC_binary, pE = input$pE_binary, n_looks = n_looks,
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative, boundary_shape = input$boundary_shape,
            futility = input$futility
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$hr_survival)
        tryCatch(
          list(ok = TRUE, value = calc_group_sequential_survival(
            haz_ratio = input$hr_survival, n_looks = n_looks,
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative, boundary_shape = input$boundary_shape,
            futility = input$futility
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
      boundary_rows <- tagList(
        p(strong("Information fraction: "), paste(round(v$ifrac, 3), collapse = ", ")),
        p(strong("Efficacy boundary (Z-scale): "), paste(round(v$efficacy_boundary, 3), collapse = ", "))
      )
      if (!is.null(v$futility_boundary)) {
        boundary_rows <- tagList(
          boundary_rows,
          p(strong("Futility boundary (Z-scale): "), paste(round(v$futility_boundary, 3), collapse = ", "))
        )
      }

      if (input$design == "survival") {
        tagList(
          p(strong("Maximum required number of events: "), v$n_events_total),
          boundary_rows,
          p(class = "text-muted", "Convert to enrolled subjects using a separate accrual/censoring assumption.")
        )
      } else {
        tagList(
          p(strong("Maximum total sample size: "), v$n_total),
          p(sprintf("Per arm: control = %d, experimental = %d", v$n_control, v$n_experimental)),
          boundary_rows
        )
      }
    })
  })
}
