# Analyze: 2x2 table module (ROADMAP Track B1): Calculate / Formula-Help /
# Reference sub-tabs, same design-radio contract as mod_rate.R (docs/SDD.md #8).
# It analyzes counts the user already has instead of planning a study, so it has
# no power curves; results still export through the shared export controls.

analyze_2x2_meta <- list(
  id = "analyze_2x2",
  nav_title = "2x2 Table Analysis"
)

mod_analyze_2x2_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Analyze counts you already have. This tool does not plan a study; for sample size use the",
        "calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "How were the subjects sampled?",
        choices = c(
          "Cohort / trial: followed from exposure to outcome" = "cohort",
          "Cross-sectional: exposure and outcome measured together" = "cross_sectional",
          "Case-control: sampled by outcome (cases and controls)" = "case_control"
        ),
        selected = "cohort"
      ),
      fluidRow(
        column(3, strong("")),
        column(4, strong("Outcome +")),
        column(4, strong("Outcome -"))
      ),
      fluidRow(
        column(3, strong("Exposed")),
        column(4, numericInput(ns("a"), NULL, value = 13, min = 0, step = 1)),
        column(4, numericInput(ns("b"), NULL, value = 2163, min = 0, step = 1))
      ),
      fluidRow(
        column(3, strong("Unexposed")),
        column(4, numericInput(ns("c"), NULL, value = 5, min = 0, step = 1)),
        column(4, numericInput(ns("d"), NULL, value = 3349, min = 0, step = 1))
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
      h4(analyze_2x2_content$cohort$title),
      render_formula_block(analyze_2x2_content$cohort$formula_latex),
      shiny::markdown(analyze_2x2_content$cohort$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_2x2_content$cohort$worked_example),
      hr(),
      h4(analyze_2x2_content$cross_sectional$title),
      shiny::markdown(analyze_2x2_content$cross_sectional$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_2x2_content$cross_sectional$worked_example),
      hr(),
      h4(analyze_2x2_content$case_control$title),
      shiny::markdown(analyze_2x2_content$case_control$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_2x2_content$case_control$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(analyze_2x2_content$cohort$citation),
      hr(),
      h4(analyze_2x2_content$cohort$title),
      p(strong("Implemented via: "), code(analyze_2x2_content$cohort$backend)),
      h4(analyze_2x2_content$cross_sectional$title),
      p(strong("Implemented via: "), code(analyze_2x2_content$cross_sectional$backend)),
      h4(analyze_2x2_content$case_control$title),
      p(strong("Implemented via: "), code(analyze_2x2_content$case_control$backend))
    )
  )
}

# One estimates row as table cells: "estimate (lower to upper)".
.fmt_est_row <- function(measure, est, lo, hi, digits = 3) {
  f <- function(x) if (is.na(x)) "n/a" else formatC(x, digits = digits, format = "fg", flag = "#")
  tags$tr(tags$td(measure), tags$td(f(est)),
          tags$td(if (is.na(lo) && is.na(hi)) "undefined" else paste(f(lo), "to", f(hi))))
}

mod_analyze_2x2_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level)
      cells <- list(input$a, input$b, input$c, input$d)
      req(!any(vapply(cells, is.null, logical(1))))
      tryCatch(
        list(ok = TRUE, design = input$design, value = calc_analyze_2x2(
          input$a, input$b, input$c, input$d, design = input$design, conf_level = input$conf_level
        )),
        error = function(e) list(ok = FALSE, message = conditionMessage(e))
      )
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }
      v <- res$value
      tb <- analyze_2x2_table(v)
      lvl <- sprintf("%.0f%%", 100 * v$inputs$conf_level)
      notes <- character()
      if (isTRUE(v$zero_cell)) {
        notes <- c(notes, "A cell is zero: the interval for any ratio that needs its logarithm is undefined (no 0.5 correction is applied).")
      }
      if (v$min_expected_count < 5) {
        notes <- c(notes, sprintf("The smallest expected count is %.1f (< 5): prefer Fisher's exact test to the chi-square test.", v$min_expected_count))
      }
      if (!is.null(v$number_needed) && !is.na(v$number_needed) &&
          is.na(v$number_needed_lower)) {
        notes <- c(notes, "The risk-difference interval includes 0, so the interval for the number needed is not finite (Altman 1998).")
      }
      tagList(
        if (v$design != "case_control") {
          p(sprintf("Risk in exposed: %.4f   Risk in unexposed: %.4f   (total N = %d)",
                    v$risk_exposed, v$risk_unexposed, v$n_total))
        } else {
          p(sprintf("Total N = %d", v$n_total))
        },
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(tags$th("Measure"), tags$th("Estimate"), tags$th(paste0(lvl, " CI")))),
          tags$tbody(lapply(seq_len(nrow(tb)), function(i) {
            .fmt_est_row(tb$measure[i], tb$estimate[i], tb$lower[i], tb$upper[i])
          }))
        ),
        p(sprintf("Pearson chi-square (uncorrected) = %.3f, p = %.4g;  Fisher's exact test p = %.4g",
                  v$chisq, v$chisq_p, v$fisher_p)),
        lapply(notes, function(n) div(class = "text-warning", n))
      )
    })

    render_export_handlers(output, result, function() analyze_2x2_content[[input$design]])
  })
}
