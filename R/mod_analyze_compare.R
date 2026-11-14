# Analyze: Compare Two Groups module (ROADMAP Track B1): Calculate / Formula-Help /
# Reference sub-tabs, design-radio contract as in mod_rate.R (docs/SDD.md #8).
# "proportions": difference, ratio and odds ratio of two independent proportions, by
# several interval methods side by side. "means": difference, variance ratio and
# standardized difference of two means from summary statistics.

analyze_compare_meta <- list(
  id = "analyze_compare",
  nav_title = "Compare Two Groups"
)

mod_analyze_compare_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Compare two independent groups from summary figures you already have. This tool does not plan a study; for",
        "sample size use the calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What are you comparing?",
        choices = c("Two proportions: difference, risk ratio, odds ratio" = "proportions",
                    "Two means (from n, mean, SD): difference, variance ratio, Cohen's d / Hedges' g" = "means"),
        selected = "proportions"
      ),
      conditionalPanel(
        condition = design_is("proportions"),
        fluidRow(column(4, strong("")), column(4, strong("Events")), column(4, strong("Sample size"))),
        fluidRow(column(4, strong("Group 1")),
                 column(4, numericInput(ns("x1"), NULL, value = 56, min = 0, step = 1)),
                 column(4, numericInput(ns("n1"), NULL, value = 70, min = 1, step = 1))),
        fluidRow(column(4, strong("Group 2")),
                 column(4, numericInput(ns("x2"), NULL, value = 48, min = 0, step = 1)),
                 column(4, numericInput(ns("n2"), NULL, value = 80, min = 1, step = 1)))
      ),
      conditionalPanel(
        condition = design_is("means"),
        fluidRow(column(3, strong("")), column(3, strong("Sample size")), column(3, strong("Mean")), column(3, strong("Standard deviation"))),
        fluidRow(column(3, strong("Group 1")),
                 column(3, numericInput(ns("mn1"), NULL, value = 25, min = 2, step = 1)),
                 column(3, numericInput(ns("mm1"), NULL, value = 52, step = 0.1)),
                 column(3, numericInput(ns("ms1"), NULL, value = 9, min = 0.0001, step = 0.1))),
        fluidRow(column(3, strong("Group 2")),
                 column(3, numericInput(ns("mn2"), NULL, value = 31, min = 2, step = 1)),
                 column(3, numericInput(ns("mm2"), NULL, value = 47, step = 0.1)),
                 column(3, numericInput(ns("ms2"), NULL, value = 12, min = 0.0001, step = 0.1)))
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
      h4(analyze_compare_content$proportions$title),
      render_formula_block(analyze_compare_content$proportions$formula_latex),
      shiny::markdown(analyze_compare_content$proportions$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_compare_content$proportions$worked_example),
      hr(),
      h4(analyze_compare_content$means$title),
      render_formula_block(analyze_compare_content$means$formula_latex),
      shiny::markdown(analyze_compare_content$means$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_compare_content$means$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(analyze_compare_content$proportions$title),
      p(strong("Citation: "), analyze_compare_content$proportions$citation),
      p(strong("Implemented via: "), code(analyze_compare_content$proportions$backend)),
      hr(),
      h4(analyze_compare_content$means$title),
      p(strong("Citation: "), analyze_compare_content$means$citation),
      p(strong("Implemented via: "), code(analyze_compare_content$means$backend))
    )
  )
}

.fmt_c <- function(x, digits = 4) {
  if (is.na(x)) return("n/a")
  if (is.infinite(x)) return(if (x > 0) "infinity" else "-infinity")
  formatC(x, digits = digits, format = "fg", flag = "#")
}
.fmt_cp <- function(p) if (is.na(p)) "n/a" else if (p < 0.0001) "< 0.0001" else formatC(p, digits = 3, format = "fg")

mod_analyze_compare_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level)
      tryCatch({
        value <- if (input$design == "proportions") {
          req(input$x1, input$n1, input$x2, input$n2)
          calc_analyze_compare_proportions(input$x1, input$n1, input$x2, input$n2, conf_level = input$conf_level)
        } else {
          req(input$mn1, input$mm1, input$ms1, input$mn2, input$mm2, input$ms2)
          calc_analyze_compare_means(input$mn1, input$mm1, input$ms1, input$mn2, input$mm2, input$ms2,
                                     conf_level = input$conf_level)
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

      if (res$design == "proportions") {
        tb <- analyze_compare_proportions_table(v)
        rows <- lapply(seq_len(nrow(tb)), function(i) {
          tags$tr(tags$td(tb$measure[i]), tags$td(tb$method[i]), tags$td(.fmt_c(tb$estimate[i], 3)),
                  tags$td(paste(.fmt_c(tb$lower[i], 3), "to", .fmt_c(tb$upper[i], 3))),
                  tags$td(class = "text-muted small", tb$note[i]))
        })
        tagList(
          p(sprintf("Group 1: %d/%d = %s;  group 2: %d/%d = %s.", v$inputs$x1, v$inputs$n1, .fmt_c(v$proportion_1, 3),
                    v$inputs$x2, v$inputs$n2, .fmt_c(v$proportion_2, 3))),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Measure"), tags$th("Interval method"), tags$th("Estimate"),
                               tags$th(paste0(lvl, " CI")), tags$th("Note"))),
            tags$tbody(rows)
          ),
          div(class = "text-muted",
              "The methods are shown side by side so you can compare them; none is the only correct one. For small samples or proportions near 0 or 1 they can differ a lot -- the score intervals are the ones usually recommended."),
          h6("Tests of no difference"),
          tags$ul(
            tags$li(sprintf("Pearson chi-square (uncorrected, 1 df) = %s, p = %s", .fmt_c(v$chisq), .fmt_cp(v$chisq_p))),
            tags$li(sprintf("Fisher's exact test: p = %s", .fmt_cp(v$fisher_p)))
          )
        )
      } else {
        tagList(
          p(sprintf("Difference in means (group 1 - group 2) = %s.", .fmt_c(v$mean_difference))),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Method"), tags$th(paste0(lvl, " CI for the difference")), tags$th("t (df)"), tags$th("p"))),
            tags$tbody(
              tags$tr(tags$td("Welch (unequal variances) -- the safer default"),
                      tags$td(paste(.fmt_c(v$welch_lower), "to", .fmt_c(v$welch_upper))),
                      tags$td(sprintf("%s (%s)", .fmt_c(v$welch_t, 3), .fmt_c(v$welch_df, 4))), tags$td(.fmt_cp(v$welch_p))),
              tags$tr(tags$td("Student, pooled variance (assumes equal variances)"),
                      tags$td(paste(.fmt_c(v$pooled_lower), "to", .fmt_c(v$pooled_upper))),
                      tags$td(sprintf("%s (%s)", .fmt_c(v$pooled_t, 3), .fmt_c(v$pooled_df, 4))), tags$td(.fmt_cp(v$pooled_p)))
            )
          ),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Measure"), tags$th(paste0("Estimate (", lvl, " CI)")))),
            tags$tbody(
              tags$tr(tags$td("Variance ratio (SD1^2 / SD2^2), F-based"),
                      tags$td(sprintf("%s (%s to %s); p = %s", .fmt_c(v$variance_ratio, 3), .fmt_c(v$variance_ratio_lower, 3),
                                      .fmt_c(v$variance_ratio_upper, 3), .fmt_cp(v$variance_ratio_p)))),
              tags$tr(tags$td("Cohen's d (pooled SD), noncentral-t CI"),
                      tags$td(sprintf("%s (%s to %s)", .fmt_c(v$cohens_d, 3), .fmt_c(v$cohens_d_lower, 3), .fmt_c(v$cohens_d_upper, 3)))),
              tags$tr(tags$td("Hedges' g (bias-corrected d)"),
                      tags$td(sprintf("%s (%s to %s)", .fmt_c(v$hedges_g, 3), .fmt_c(v$hedges_g_lower, 3), .fmt_c(v$hedges_g_upper, 3))))
            )
          ),
          div(class = "text-muted", "The F test and interval for the variance ratio are sensitive to non-normality. If the Welch and pooled intervals differ noticeably, trust Welch.")
        )
      }
    })

    render_export_handlers(output, result, function() analyze_compare_content[[input$design]])
  })
}
