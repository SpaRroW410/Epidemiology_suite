# Analyze: Rates module (ROADMAP Track B1): Calculate / Formula-Help / Reference
# sub-tabs, design-radio contract as in mod_rate.R (docs/SDD.md #8). "single":
# confidence intervals for one incidence rate from events and person-time.
# "ratio": rate ratio, rate difference, attributable fractions and tests for two
# groups.

analyze_rates_meta <- list(
  id = "analyze_rates",
  nav_title = "Rates and Rate Ratios"
)

mod_analyze_rates_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Analyze events and person-time you already have. This tool does not plan a study; for sample size use",
        "the Incidence Rate calculator under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c("Confidence interval for one incidence rate" = "single",
                    "Compare two rates: rate ratio, rate difference, attributable fractions" = "ratio"),
        selected = "single"
      ),
      conditionalPanel(
        condition = design_is("single"),
        numericInput(ns("events"), "Number of events", value = 7, min = 0, step = 1),
        numericInput(ns("pt"), "Person-time at risk (e.g. person-years)", value = 1000, min = 0.0001, step = 1)
      ),
      conditionalPanel(
        condition = design_is("ratio"),
        fluidRow(
          column(4, strong("")), column(4, strong("Events")), column(4, strong("Person-time"))
        ),
        fluidRow(
          column(4, strong("Exposed")),
          column(4, numericInput(ns("d1"), NULL, value = 136, min = 0, step = 1)),
          column(4, numericInput(ns("t1"), NULL, value = 22050, min = 0.0001, step = 1))
        ),
        fluidRow(
          column(4, strong("Unexposed")),
          column(4, numericInput(ns("d0"), NULL, value = 1709, min = 0, step = 1)),
          column(4, numericInput(ns("t0"), NULL, value = 127650, min = 0.0001, step = 1))
        )
      ),
      numericInput(ns("multiplier"), "Report rates per this many units of person-time (e.g. 1000 person-years)",
                   value = 1000, min = 1, step = 1),
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(analyze_rates_content$single$title),
      render_formula_block(analyze_rates_content$single$formula_latex),
      shiny::markdown(analyze_rates_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_rates_content$single$worked_example),
      hr(),
      h4(analyze_rates_content$ratio$title),
      render_formula_block(analyze_rates_content$ratio$formula_latex),
      shiny::markdown(analyze_rates_content$ratio$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_rates_content$ratio$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(analyze_rates_content$single$title),
      p(strong("Citation: "), analyze_rates_content$single$citation),
      p(strong("Implemented via: "), code(analyze_rates_content$single$backend)),
      hr(),
      h4(analyze_rates_content$ratio$title),
      p(strong("Citation: "), analyze_rates_content$ratio$citation),
      p(strong("Implemented via: "), code(analyze_rates_content$ratio$backend))
    )
  )
}

.fmt_num <- function(x, digits = 4) {
  if (is.na(x)) return("n/a")
  if (is.infinite(x)) return(if (x > 0) "infinity" else "-infinity")
  formatC(x, digits = digits, format = "fg", flag = "#")
}
.fmt_ci_pair <- function(est, lo, hi, digits = 4) {
  if (is.na(lo) && is.na(hi)) return(.fmt_num(est, digits))
  sprintf("%s (%s to %s)", .fmt_num(est, digits), .fmt_num(lo, digits), .fmt_num(hi, digits))
}
.fmt_pct_pair <- function(est, lo, hi) {
  p <- function(x) if (is.na(x)) "n/a" else sprintf("%.1f%%", 100 * x)
  if (is.na(est)) return("n/a")
  if (is.na(lo) && is.na(hi)) return(p(est))
  sprintf("%s (%s to %s)", p(est), p(lo), p(hi))
}

mod_analyze_rates_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level, input$multiplier)
      tryCatch({
        value <- if (input$design == "single") {
          req(input$events, input$pt)
          calc_analyze_rate_single(input$events, input$pt, multiplier = input$multiplier, conf_level = input$conf_level)
        } else {
          req(input$d1, input$t1, input$d0, input$t0)
          calc_analyze_rate_ratio(input$d1, input$t1, input$d0, input$t0,
                                  multiplier = input$multiplier, conf_level = input$conf_level)
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
      per <- format(v$multiplier, big.mark = ",", scientific = FALSE)

      if (res$design == "single") {
        tb <- analyze_rate_single_table(v)
        tagList(
          p(sprintf("%d events in %s person-time: rate = %s per %s.", v$events, format(v$person_time, big.mark = ",", scientific = FALSE),
                    .fmt_num(v$rate), per)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Method"), tags$th(paste0(lvl, " CI, lower (per ", per, ")")), tags$th("upper"))),
            tags$tbody(lapply(seq_len(nrow(tb)), function(i) {
              tags$tr(tags$td(tb$method[i]), tags$td(.fmt_num(tb$lower[i])), tags$td(.fmt_num(tb$upper[i])))
            }))
          ),
          div(class = "text-muted", "The exact (Garwood) interval is the usual choice; the Wald interval is shown for comparison only.")
        )
      } else {
        notes <- character()
        if (v$inputs$events_exposed == 0 || v$inputs$events_unexposed == 0) {
          notes <- c(notes, "A group has zero events: the rate ratio is not estimable (n/a); the exact interval still gives a one-sided limit, and the Wald interval is undefined.")
        }
        notes <- c(notes, "The population attributable fraction assumes the study's exposed share of person-time represents the population; a negative value means the exposure is protective.")
        tagList(
          p(sprintf("%d events in %s person-time in total.", v$events_total, format(v$person_time_total, big.mark = ",", scientific = FALSE))),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Group"), tags$th(paste0("Rate per ", per, " (exact ", lvl, " CI)")))),
            tags$tbody(
              tags$tr(tags$td("Exposed"), tags$td(.fmt_ci_pair(v$rate_exposed, v$rate_exposed_lower, v$rate_exposed_upper))),
              tags$tr(tags$td("Unexposed"), tags$td(.fmt_ci_pair(v$rate_unexposed, v$rate_unexposed_lower, v$rate_unexposed_upper)))
            )
          ),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Measure"), tags$th(paste0("Estimate (", lvl, " CI)")))),
            tags$tbody(
              tags$tr(tags$td("Rate ratio -- exact"), tags$td(.fmt_ci_pair(v$rate_ratio, v$rate_ratio_exact_lower, v$rate_ratio_exact_upper, 3))),
              tags$tr(tags$td("Rate ratio -- mid-P exact"), tags$td(.fmt_ci_pair(v$rate_ratio, v$rate_ratio_mid_p_lower, v$rate_ratio_mid_p_upper, 3))),
              tags$tr(tags$td("Rate ratio -- Wald (log)"), tags$td(.fmt_ci_pair(v$rate_ratio, v$rate_ratio_wald_lower, v$rate_ratio_wald_upper, 3))),
              tags$tr(tags$td(paste0("Rate difference (per ", per, ")")), tags$td(.fmt_ci_pair(v$rate_difference, v$rate_difference_lower, v$rate_difference_upper, 3))),
              tags$tr(tags$td("Attributable fraction among the exposed"),
                      tags$td(.fmt_pct_pair(v$attributable_fraction_exposed, v$attributable_fraction_exposed_lower, v$attributable_fraction_exposed_upper))),
              tags$tr(tags$td("Population attributable fraction"),
                      tags$td(.fmt_pct_pair(v$population_attributable_fraction, v$population_attributable_fraction_lower, v$population_attributable_fraction_upper)))
            )
          ),
          h6("Tests of no difference in rates"),
          tags$ul(
            tags$li(sprintf("Exact conditional test: p = %s;  mid-P: p = %s", .fmt_num(v$exact_test_p, 3), .fmt_num(v$mid_p_test_p, 3))),
            tags$li(sprintf("Score chi-square (1 df) = %s, p = %s", .fmt_num(v$score_chisq, 4), .fmt_num(v$score_test_p, 3)))
          ),
          lapply(notes, function(n) div(class = "text-muted", n))
        )
      }
    })

    render_export_handlers(output, result, function() analyze_rates_content[[input$design]])
  })
}
