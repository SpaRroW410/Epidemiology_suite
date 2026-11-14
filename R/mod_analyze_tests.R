# Analyze: Paired, Agreement and Trend Tests module (ROADMAP Track B1): Calculate /
# Formula-Help / Reference sub-tabs, design-radio contract as in mod_rate.R
# (docs/SDD.md #8). "mcnemar": paired 2x2 table. "kappa": agreement of two raters in a
# 2-6 category table. "trend": chi-square for trend across 2-8 ordered groups.

analyze_tests_meta <- list(
  id = "analyze_tests",
  nav_title = "Paired, Agreement and Trend Tests"
)

.tt_max_k <- 6
.tt_max_groups <- 8
.tt_default_kappa <- matrix(c(20, 5, 2, 0, 0, 0,
                              4, 25, 6, 0, 0, 0,
                              1, 5, 32, 0, 0, 0,
                              0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0), 6, byrow = TRUE)
.tt_default_events <- c(10, 20, 35, 50, 60, 70, 80, 90)
.tt_default_totals <- c(100, 100, 100, 100, 100, 100, 100, 100)

mod_analyze_tests_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  kappa_rows <- lapply(seq_len(.tt_max_k), function(i) {
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("k"), i),
      fluidRow(
        column(2, strong(paste("Rater 1:", i))),
        # the conditionalPanel goes INSIDE the column: a panel between a row and its columns breaks the grid
        lapply(seq_len(.tt_max_k), function(j) {
          column(2, conditionalPanel(
            condition = sprintf("input['%s'] >= %d", ns("k"), j),
            numericInput(ns(sprintf("k_%d_%d", i, j)), NULL, value = .tt_default_kappa[i, j], min = 0, step = 1)
          ))
        })
      )
    )
  })
  trend_rows <- lapply(seq_len(.tt_max_groups), function(i) {
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("g"), i),
      fluidRow(
        column(3, strong(paste("Group", i))),
        column(3, numericInput(ns(paste0("ev", i)), NULL, value = .tt_default_events[i], min = 0, step = 1)),
        column(3, numericInput(ns(paste0("tot", i)), NULL, value = .tt_default_totals[i], min = 1, step = 1)),
        column(3, numericInput(ns(paste0("sc", i)), NULL, value = i, step = 1))
      )
    )
  })

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Analyze counts you already have. This tool does not plan a study; for sample size use the calculators",
        "under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c(
          "Paired binary data: McNemar's test and matched-pair odds ratio" = "mcnemar",
          "Agreement between two raters or tests: Cohen's kappa" = "kappa",
          "Trend in proportions across ordered groups: chi-square for trend" = "trend"
        ),
        selected = "mcnemar"
      ),
      conditionalPanel(
        condition = design_is("mcnemar"),
        fluidRow(column(3, strong("")), column(4, strong("Test 2 +")), column(4, strong("Test 2 -"))),
        fluidRow(column(3, strong("Test 1 +")),
                 column(4, numericInput(ns("a"), NULL, value = 30, min = 0, step = 1)),
                 column(4, numericInput(ns("b"), NULL, value = 12, min = 0, step = 1))),
        fluidRow(column(3, strong("Test 1 -")),
                 column(4, numericInput(ns("c"), NULL, value = 5, min = 0, step = 1)),
                 column(4, numericInput(ns("d"), NULL, value = 53, min = 0, step = 1)))
      ),
      conditionalPanel(
        condition = design_is("kappa"),
        numericInput(ns("k"), "Number of categories (2-6)", value = 3, min = 2, max = .tt_max_k, step = 1),
        selectInput(ns("weights"), "Weights",
                    choices = c("Unweighted (nominal categories)" = "unweighted",
                                "Linear (ordered categories)" = "linear",
                                "Quadratic / Fleiss-Cohen (ordered categories)" = "quadratic")),
        p(class = "text-muted", "Rows are rater 1, columns are rater 2."),
        fluidRow(
          column(2, strong("")),
          lapply(seq_len(.tt_max_k), function(j) {
            column(2, conditionalPanel(condition = sprintf("input['%s'] >= %d", ns("k"), j), strong(paste("Rater 2:", j))))
          })
        ),
        kappa_rows
      ),
      conditionalPanel(
        condition = design_is("trend"),
        numericInput(ns("g"), "Number of ordered groups (2-8)", value = 4, min = 2, max = .tt_max_groups, step = 1),
        fluidRow(column(3, strong("")), column(3, strong("Events")), column(3, strong("Subjects")),
                 column(3, strong("Score (e.g. dose)"))),
        trend_rows
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
      h4(analyze_tests_content$mcnemar$title),
      render_formula_block(analyze_tests_content$mcnemar$formula_latex),
      shiny::markdown(analyze_tests_content$mcnemar$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_tests_content$mcnemar$worked_example),
      hr(),
      h4(analyze_tests_content$kappa$title),
      render_formula_block(analyze_tests_content$kappa$formula_latex),
      shiny::markdown(analyze_tests_content$kappa$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_tests_content$kappa$worked_example),
      hr(),
      h4(analyze_tests_content$trend$title),
      render_formula_block(analyze_tests_content$trend$formula_latex),
      shiny::markdown(analyze_tests_content$trend$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_tests_content$trend$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(analyze_tests_content$mcnemar$title),
      p(strong("Citation: "), analyze_tests_content$mcnemar$citation),
      p(strong("Implemented via: "), code(analyze_tests_content$mcnemar$backend)),
      hr(),
      h4(analyze_tests_content$kappa$title),
      p(strong("Citation: "), analyze_tests_content$kappa$citation),
      p(strong("Implemented via: "), code(analyze_tests_content$kappa$backend)),
      hr(),
      h4(analyze_tests_content$trend$title),
      p(strong("Citation: "), analyze_tests_content$trend$citation),
      p(strong("Implemented via: "), code(analyze_tests_content$trend$backend))
    )
  )
}

.fmt_g <- function(x, digits = 4) {
  if (is.na(x)) return("n/a")
  if (is.infinite(x)) return(if (x > 0) "infinity" else "-infinity")
  formatC(x, digits = digits, format = "fg", flag = "#")
}
.fmt_gci <- function(est, lo, hi, digits = 3) {
  if (is.na(est)) return("n/a")
  if (is.na(lo) && is.na(hi)) return(.fmt_g(est, digits))
  sprintf("%s (%s to %s)", .fmt_g(est, digits), .fmt_g(lo, digits), .fmt_g(hi, digits))
}
.fmt_gp <- function(p) if (is.na(p)) "n/a" else if (p < 0.0001) "< 0.0001" else formatC(p, digits = 3, format = "fg")

mod_analyze_tests_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    num_vec <- function(prefix, n) vapply(seq_len(n), function(i) {
      v <- input[[paste0(prefix, i)]]; if (is.null(v)) NA_real_ else v
    }, numeric(1))

    result <- reactive({
      req(input$design, input$conf_level)
      tryCatch({
        value <- if (input$design == "mcnemar") {
          req(input$a, input$b, input$c, input$d)
          calc_analyze_mcnemar(input$a, input$b, input$c, input$d, conf_level = input$conf_level)
        } else if (input$design == "kappa") {
          req(input$k, input$weights)
          k <- as.integer(input$k)
          if (is.na(k) || k < 2 || k > .tt_max_k) stop("Use between 2 and 6 categories.")
          tb <- matrix(NA_real_, k, k)
          for (i in seq_len(k)) for (j in seq_len(k)) {
            v <- input[[sprintf("k_%d_%d", i, j)]]; tb[i, j] <- if (is.null(v)) NA_real_ else v
          }
          req(!anyNA(tb))
          w <- if (k == 2) "unweighted" else input$weights
          calc_analyze_kappa(tb, weights = w, conf_level = input$conf_level)
        } else {
          req(input$g)
          g <- as.integer(input$g)
          if (is.na(g) || g < 2 || g > .tt_max_groups) stop("Use between 2 and 8 groups.")
          ev <- num_vec("ev", g); tot <- num_vec("tot", g); sc <- num_vec("sc", g)
          req(!anyNA(ev), !anyNA(tot))
          if (anyNA(sc)) sc <- seq_len(g)
          calc_analyze_trend(ev, tot, sc, conf_level = input$conf_level)
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

      if (res$design == "mcnemar") {
        notes <- character()
        if (v$discordant_pairs < 25) {
          notes <- c(notes, "Fewer than 25 discordant pairs: prefer the exact test to the chi-square approximation.")
        }
        if (is.na(v$matched_odds_ratio)) {
          notes <- c(notes, "One discordant cell is zero: the matched odds ratio is not estimable (the exact interval still gives a one-sided limit).")
        }
        tagList(
          p(sprintf("%d pairs, %d discordant. Positive on test 1: %.1f%%; on test 2: %.1f%%.",
                    v$n_pairs, v$discordant_pairs, 100 * v$positive_test1, 100 * v$positive_test2)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Measure"), tags$th(paste0("Estimate (", lvl, " CI)")))),
            tags$tbody(
              tags$tr(tags$td("Matched-pair odds ratio (b/c) -- exact"),
                      tags$td(.fmt_gci(v$matched_odds_ratio, v$matched_odds_ratio_exact_lower, v$matched_odds_ratio_exact_upper))),
              tags$tr(tags$td("Matched-pair odds ratio -- Wald (log)"),
                      tags$td(.fmt_gci(v$matched_odds_ratio, v$matched_odds_ratio_wald_lower, v$matched_odds_ratio_wald_upper))),
              tags$tr(tags$td("Difference in positive proportions (test 1 - test 2)"),
                      tags$td(.fmt_gci(v$paired_difference, v$paired_difference_lower, v$paired_difference_upper)))
            )
          ),
          h6("Tests of no difference between the two"),
          tags$ul(
            tags$li(sprintf("McNemar chi-square (1 df) = %s, p = %s", .fmt_g(v$mcnemar_chisq), .fmt_gp(v$mcnemar_p))),
            tags$li(sprintf("With continuity correction = %s, p = %s", .fmt_g(v$mcnemar_chisq_corrected), .fmt_gp(v$mcnemar_p_corrected))),
            tags$li(sprintf("Exact binomial test: p = %s;  mid-P: p = %s", .fmt_gp(v$exact_p), .fmt_gp(v$mid_p)))
          ),
          lapply(notes, function(n) div(class = "text-muted", n))
        )
      } else if (res$design == "kappa") {
        tagList(
          p(sprintf("%d subjects, %d categories, %s kappa.", v$n_total, v$categories, v$weights)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Measure"), tags$th("Value"))),
            tags$tbody(
              tags$tr(tags$td(paste0("Kappa (", lvl, " CI)")), tags$td(.fmt_gci(v$kappa, v$kappa_lower, v$kappa_upper))),
              tags$tr(tags$td("Landis-Koch label (convention only)"), tags$td(analyze_kappa_label(v$kappa))),
              tags$tr(tags$td("Observed agreement"), tags$td(sprintf("%.1f%%", 100 * v$observed_agreement))),
              tags$tr(tags$td("Agreement expected by chance"), tags$td(sprintf("%.1f%%", 100 * v$expected_agreement))),
              if (!is.na(v$pabak)) tags$tr(tags$td("PABAK (prevalence- and bias-adjusted kappa)"), tags$td(.fmt_g(v$pabak, 3))),
              if (!is.na(v$z_test_kappa0)) tags$tr(tags$td("Test of kappa = 0"),
                tags$td(sprintf("z = %s, p = %s", .fmt_g(v$z_test_kappa0, 3), .fmt_gp(v$p_value_kappa0))))
            )
          ),
          if (is.na(v$kappa)) div(class = "text-warning", "Kappa is undefined: all subjects fall in one category."),
          div(class = "text-muted", "Kappa depends on how common the categories are; report observed agreement alongside it.")
        )
      } else {
        g <- v$groups
        rows <- lapply(seq_len(g), function(i) {
          tags$tr(tags$td(paste("Group", i)),
                  tags$td(sprintf("%.1f%% (%.1f to %.1f)", 100 * v[[paste0("group", i, "_proportion")]],
                                  100 * v[[paste0("group", i, "_wilson_lower")]], 100 * v[[paste0("group", i, "_wilson_upper")]])))
        })
        tagList(
          p(sprintf("%d subjects, %d events (overall proportion %.1f%%).", v$n_total, v$events_total, 100 * v$overall_proportion)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Group"), tags$th(paste0("Proportion (Wilson ", lvl, " CI), %")))),
            tags$tbody(rows)
          ),
          p(strong("Chi-square for trend (1 df): "),
            if (is.na(v$trend_chisq)) "n/a (no events or all events)" else
              sprintf("%s, p = %s (%s trend)", .fmt_g(v$trend_chisq), .fmt_gp(v$trend_p), v$trend_direction)),
          div(class = "text-muted", "The test looks for a linear trend only; it does not show that the relationship is linear.")
        )
      }
    })

    render_export_handlers(output, result, function() analyze_tests_content[[input$design]])
  })
}
