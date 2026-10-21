# Analyze: Mantel-Haenszel module (ROADMAP Track B1): Calculate / Formula-Help /
# Reference sub-tabs, design-radio contract as in mod_rate.R (docs/SDD.md #8).
# Stratified 2x2 tables (2-8 strata): crude vs Mantel-Haenszel adjusted estimates,
# the Cochran-Mantel-Haenszel test and homogeneity tests.

analyze_mh_meta <- list(
  id = "analyze_mh",
  nav_title = "Stratified Analysis (Mantel-Haenszel)"
)

.mh_max_strata <- 8
.mh_default_strata <- list(c(20, 10, 15, 45), c(30, 25, 20, 60), c(12, 8, 40, 70),
                           c(10, 10, 10, 10), c(10, 10, 10, 10), c(10, 10, 10, 10),
                           c(10, 10, 10, 10), c(10, 10, 10, 10))

mod_analyze_mh_ui <- function(id) {
  ns <- NS(id)
  rows <- lapply(seq_len(.mh_max_strata), function(i) {
    v <- .mh_default_strata[[i]]
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_strata"), i),
      fluidRow(
        column(3, textInput(ns(paste0("label", i)), NULL, value = "", placeholder = sprintf("Stratum %d", i))),
        column(2, numericInput(ns(paste0("a", i)), NULL, value = v[1], min = 0, step = 1)),
        column(2, numericInput(ns(paste0("b", i)), NULL, value = v[2], min = 0, step = 1)),
        column(2, numericInput(ns(paste0("c", i)), NULL, value = v[3], min = 0, step = 1)),
        column(2, numericInput(ns(paste0("d", i)), NULL, value = v[4], min = 0, step = 1))
      )
    )
  })

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Adjust a 2x2 association for a confounder by stratifying on it. This tool works on counts you already",
        "have; for sample size use the calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "How were the subjects sampled?",
        choices = c(
          "Cohort / trial / cross-sectional (risks can be estimated)" = "cohort",
          "Case-control (odds ratio only)" = "case_control"
        ),
        selected = "cohort"
      ),
      numericInput(ns("n_strata"), "Number of strata (2-8)", value = 3, min = 2, max = .mh_max_strata, step = 1),
      fluidRow(
        column(3, strong("Stratum label (optional)")), column(2, strong("a: exposed, outcome +")),
        column(2, strong("b: exposed, outcome -")), column(2, strong("c: unexposed, outcome +")),
        column(2, strong("d: unexposed, outcome -"))
      ),
      rows,
      numericInput(ns("conf_level"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(analyze_mh_content$cohort$title),
      render_formula_block(analyze_mh_content$cohort$formula_latex),
      shiny::markdown(analyze_mh_content$cohort$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_mh_content$cohort$worked_example),
      hr(),
      h4(analyze_mh_content$case_control$title),
      shiny::markdown(analyze_mh_content$case_control$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_mh_content$case_control$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(analyze_mh_content$cohort$citation),
      hr(),
      p(strong("Implemented via: "), code(analyze_mh_content$cohort$backend))
    )
  )
}

.fmt_ci3 <- function(est, lo, hi) {
  g <- function(x) if (is.na(x)) "n/a" else formatC(x, digits = 3, format = "fg", flag = "#")
  if (is.na(est)) return("n/a")
  if (is.na(lo) || is.na(hi)) return(g(est))
  sprintf("%s (%s to %s)", g(est), g(lo), g(hi))
}
.fmt_p <- function(p) if (is.na(p)) "n/a" else if (p < 0.0001) "< 0.0001" else formatC(p, digits = 3, format = "fg")
.fmt_stat <- function(x, df, p) if (is.na(x)) "n/a (too few strata with all four cells non-zero)" else sprintf("%.3f (%d df), p = %s", x, df, .fmt_p(p))

mod_analyze_mh_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    labels <- reactive({
      k <- as.integer(input$n_strata)
      vapply(seq_len(k), function(i) { v <- input[[paste0("label", i)]]; if (is.null(v)) "" else v }, character(1))
    })

    result <- reactive({
      req(input$design, input$conf_level, input$n_strata)
      tryCatch({
        k <- as.integer(input$n_strata)
        if (is.na(k) || k < 2 || k > .mh_max_strata) stop("Give between 2 and 8 strata.")
        cell <- function(prefix) vapply(seq_len(k), function(i) {
          v <- input[[paste0(prefix, i)]]; if (is.null(v)) NA_real_ else v
        }, numeric(1))
        tb <- cbind(a = cell("a"), b = cell("b"), c = cell("c"), d = cell("d"))
        req(!anyNA(tb))
        list(ok = TRUE, design = input$design, value = calc_analyze_mantel_haenszel(
          tb, design = input$design, conf_level = input$conf_level))
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }
      v <- res$value
      lvl <- sprintf("%.0f%%", 100 * v$inputs$conf_level)
      cohort <- v$design == "cohort"

      est_rows <- list(tags$tr(tags$td("Odds ratio"),
        tags$td(.fmt_ci3(v$crude_odds_ratio, v$crude_odds_ratio_lower, v$crude_odds_ratio_upper)),
        tags$td(.fmt_ci3(v$mh_odds_ratio, v$mh_odds_ratio_lower, v$mh_odds_ratio_upper)),
        tags$td(if (is.na(v$odds_ratio_change_percent)) "n/a" else sprintf("%+.1f%%", v$odds_ratio_change_percent))))
      if (cohort) {
        est_rows <- c(est_rows, list(
          tags$tr(tags$td("Risk ratio"),
            tags$td(.fmt_ci3(v$crude_risk_ratio, v$crude_risk_ratio_lower, v$crude_risk_ratio_upper)),
            tags$td(.fmt_ci3(v$mh_risk_ratio, v$mh_risk_ratio_lower, v$mh_risk_ratio_upper)),
            tags$td(if (is.na(v$risk_ratio_change_percent)) "n/a" else sprintf("%+.1f%%", v$risk_ratio_change_percent))),
          tags$tr(tags$td("Risk difference"),
            tags$td(.fmt_ci3(v$crude_risk_difference, v$crude_risk_difference_lower, v$crude_risk_difference_upper)),
            tags$td(.fmt_ci3(v$mh_risk_difference, v$mh_risk_difference_lower, v$mh_risk_difference_upper)),
            tags$td("-"))))
      }

      st <- analyze_mh_strata_table(v, labels())
      strata_rows <- lapply(seq_len(nrow(st)), function(i) {
        r <- st[i, ]
        tags$tr(tags$td(r$stratum), tags$td(sprintf("%d / %d / %d / %d", r$a, r$b, r$c, r$d)),
                tags$td(.fmt_ci3(r$odds_ratio, r$odds_ratio_lower, r$odds_ratio_upper)),
                if (cohort) tags$td(.fmt_ci3(r$risk_ratio, r$risk_ratio_lower, r$risk_ratio_upper)))
      })

      notes <- character()
      hom_p <- c(v$woolf_or_p, v$breslow_day_p, v$tarone_p)
      if (any(!is.na(hom_p) & hom_p < 0.05)) {
        notes <- c(notes, "A homogeneity test is significant at 5%: the effect seems to differ between strata (effect modification). Report the stratum-specific estimates rather than only the pooled one.")
      }
      chg <- if (is.na(v$odds_ratio_change_percent)) NA else abs(v$odds_ratio_change_percent)
      if (!is.na(chg) && chg >= 10) {
        notes <- c(notes, sprintf("The adjusted odds ratio differs from the crude by %.0f%% (rule of thumb: >= 10%% suggests confounding by the stratifying variable).", chg))
      }
      if (v$zero_cell_strata > 0) {
        notes <- c(notes, sprintf("%d stratum/strata contain a zero cell: the Mantel-Haenszel estimates use them, the Woolf-type tests do not.", v$zero_cell_strata))
      }

      tagList(
        p(sprintf("%d strata, total N = %d.", v$n_strata, v$n_total)),
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(tags$th("Measure"), tags$th(paste0("Crude (collapsed), ", lvl, " CI")),
                             tags$th(paste0("Mantel-Haenszel adjusted, ", lvl, " CI")), tags$th("Crude vs adjusted"))),
          tags$tbody(est_rows)
        ),
        h6("Stratum-specific estimates"),
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(tags$th("Stratum"), tags$th("a / b / c / d"), tags$th("Odds ratio (Woolf CI)"),
                             if (cohort) tags$th("Risk ratio (Katz CI)"))),
          tags$tbody(strata_rows)
        ),
        h6("Tests"),
        tags$ul(
          tags$li(sprintf("Cochran-Mantel-Haenszel chi-square (1 df): %.3f, p = %s; with continuity correction %.3f, p = %s",
                          v$cmh_chisq, .fmt_p(v$cmh_p), v$cmh_chisq_corrected, .fmt_p(v$cmh_p_corrected))),
          tags$li("Homogeneity of the odds ratios -- Woolf: ", .fmt_stat(v$woolf_or_chisq, v$woolf_or_df, v$woolf_or_p)),
          tags$li("Breslow-Day: ", .fmt_stat(v$breslow_day_chisq, v$breslow_day_df, v$breslow_day_p)),
          tags$li("Breslow-Day with Tarone's correction: ", .fmt_stat(v$tarone_chisq, v$breslow_day_df, v$tarone_p)),
          if (cohort) tags$li("Homogeneity of the risk ratios -- Woolf type: ", .fmt_stat(v$woolf_rr_chisq, v$woolf_rr_df, v$woolf_rr_p))
        ),
        lapply(notes, function(n) div(class = "text-warning", n))
      )
    })

    render_export_handlers(output, result, function() analyze_mh_content[[input$design]])
  })
}
