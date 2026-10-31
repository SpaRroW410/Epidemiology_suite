# Analyze: Confidence Intervals module (ROADMAP Track B1): Calculate /
# Formula-Help / Reference sub-tabs, design-radio contract as in mod_rate.R
# (docs/SDD.md #8). "proportion": six interval methods for x of n. "mean":
# t interval for a mean and chi-square interval for the SD, from n, mean, SD.

analyze_ci_meta <- list(
  id = "analyze_ci",
  nav_title = "Confidence Intervals"
)

mod_analyze_ci_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Confidence intervals from summary figures you already have. This tool does not plan a study;",
        "for sample size use the calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "Interval for a ...",
        choices = c("Proportion (x events out of n)" = "proportion",
                    "Mean and standard deviation (from n, mean, SD)" = "mean"),
        selected = "proportion"
      ),
      conditionalPanel(
        condition = design_is("proportion"),
        numericInput(ns("x"), "Number of events (successes), x", value = 7, min = 0, step = 1),
        numericInput(ns("n_prop"), "Sample size, n", value = 20, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("mean"),
        numericInput(ns("n_mean"), "Sample size, n", value = 30, min = 2, step = 1),
        numericInput(ns("mean"), "Sample mean", value = 10, step = 0.1),
        numericInput(ns("sd"), "Sample standard deviation", value = 2, min = 0.0001, step = 0.1)
      ),
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(analyze_ci_content$proportion$title),
      render_formula_block(analyze_ci_content$proportion$formula_latex),
      shiny::markdown(analyze_ci_content$proportion$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_ci_content$proportion$worked_example),
      hr(),
      h4(analyze_ci_content$mean$title),
      render_formula_block(analyze_ci_content$mean$formula_latex),
      shiny::markdown(analyze_ci_content$mean$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_ci_content$mean$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(analyze_ci_content$proportion$title),
      p(strong("Citation: "), analyze_ci_content$proportion$citation),
      p(strong("Implemented via: "), code(analyze_ci_content$proportion$backend)),
      hr(),
      h4(analyze_ci_content$mean$title),
      p(strong("Citation: "), analyze_ci_content$mean$citation),
      p(strong("Implemented via: "), code(analyze_ci_content$mean$backend))
    )
  )
}

mod_analyze_ci_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level)
      tryCatch({
        value <- if (input$design == "proportion") {
          req(input$x, input$n_prop)
          calc_analyze_ci_proportion(input$x, input$n_prop, conf_level = input$conf_level)
        } else {
          req(input$n_mean, input$mean, input$sd)
          calc_analyze_ci_mean(input$n_mean, input$mean, input$sd, conf_level = input$conf_level)
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }
      v <- res$value
      lvl <- sprintf("%.0f%%", 100 * v$inputs$conf_level)
      fmt <- function(x, digits = 4) formatC(x, digits = digits, format = "fg", flag = "#")
      if (res$design == "proportion") {
        tb <- analyze_ci_proportion_table(v)
        tagList(
          p(sprintf("Proportion = %d / %d = %s (%.1f%%)", v$successes, v$n_total, fmt(v$proportion),
                    100 * v$proportion)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Method"), tags$th(paste0(lvl, " CI, lower")), tags$th("upper"))),
            tags$tbody(lapply(seq_len(nrow(tb)), function(i) {
              tags$tr(tags$td(tb$method[i]), tags$td(fmt(tb$lower[i])), tags$td(fmt(tb$upper[i])))
            }))
          ),
          div(class = "text-muted",
              "Wilson score or Clopper-Pearson (exact) are the usual choices; the Wald interval is shown for comparison only.")
        )
      } else {
        tagList(
          p(sprintf("n = %d, mean = %s, SD = %s, standard error = %s", v$n_total, fmt(v$mean), fmt(v$sd),
                    fmt(v$standard_error))),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Quantity"), tags$th("Estimate"), tags$th(paste0(lvl, " CI")))),
            tags$tbody(
              tags$tr(tags$td("Mean (t interval)"), tags$td(fmt(v$mean)),
                      tags$td(paste(fmt(v$mean_lower), "to", fmt(v$mean_upper)))),
              tags$tr(tags$td("Mean (normal quantile; large n or known SD)"), tags$td(fmt(v$mean)),
                      tags$td(paste(fmt(v$mean_z_lower), "to", fmt(v$mean_z_upper)))),
              tags$tr(tags$td("Standard deviation (chi-square; assumes normal data)"), tags$td(fmt(v$sd)),
                      tags$td(paste(fmt(v$sd_lower), "to", fmt(v$sd_upper))))
            )
          )
        )
      }
    })

    render_export_handlers(output, result, function() analyze_ci_content[[input$design]])
  })
}
