# Analyze: Diagnostic Test Evaluation module (ROADMAP Track B1): Calculate /
# Formula-Help / Reference sub-tabs, design-radio contract as in mod_rate.R
# (docs/SDD.md #8). "single": one test from a 2x2 table of counts. "combined":
# serial and parallel combinations of 2-6 tests from their Se/Sp.

analyze_dx_meta <- list(
  id = "analyze_dx",
  nav_title = "Diagnostic Test Evaluation"
)

.dx_max_tests <- 6

mod_analyze_dx_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  test_rows <- lapply(seq_len(.dx_max_tests), function(i) {
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_tests"), i),
      fluidRow(
        column(2, strong(sprintf("Test %d", i))),
        column(2, numericInput(ns(paste0("se", i)), NULL, value = c(90, 80, 85, 75, 70, 65)[i], min = 0, max = 100, step = 1)),
        column(2, numericInput(ns(paste0("sp", i)), NULL, value = c(70, 90, 80, 85, 90, 95)[i], min = 0, max = 100, step = 1)),
        column(3, numericInput(ns(paste0("nd", i)), NULL, value = NA, min = 1, step = 1)),
        column(3, numericInput(ns(paste0("nn", i)), NULL, value = NA, min = 1, step = 1))
      )
    )
  })

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Analyze counts or published sensitivities/specificities you already have. This tool does not",
        "plan a study; for the sample size of a diagnostic study use the Diagnostic Accuracy calculator."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c(
          "Evaluate one test from its 2x2 table of counts" = "single",
          "Combine 2-6 tests: serial and parallel testing" = "combined"
        ),
        selected = "single"
      ),
      conditionalPanel(
        condition = design_is("single"),
        fluidRow(
          column(3, strong("")), column(4, strong("Disease +")), column(4, strong("Disease -"))
        ),
        fluidRow(
          column(3, strong("Test +")),
          column(4, numericInput(ns("tp"), NULL, value = 670, min = 0, step = 1)),
          column(4, numericInput(ns("fp"), NULL, value = 202, min = 0, step = 1))
        ),
        fluidRow(
          column(3, strong("Test -")),
          column(4, numericInput(ns("fn"), NULL, value = 74, min = 0, step = 1)),
          column(4, numericInput(ns("tn"), NULL, value = 640, min = 0, step = 1))
        ),
        selectInput(ns("ci_method"), "Interval for proportions",
                    choices = c("Clopper-Pearson (exact)" = "exact", "Wilson (score)" = "wilson")),
        radioButtons(
          ns("pv_basis"), "Predictive values (PPV, NPV)",
          choices = c("From these counts (the sample's prevalence is the one of interest)" = "counts",
                      "At a stated prevalence (e.g. case-control sampling, or another setting)" = "stated"),
          selected = "counts"
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'stated'", ns("pv_basis")),
          numericInput(ns("prevalence_single"), "Disease prevalence (%)", value = 10, min = 0.01, max = 99.99, step = 1)
        )
      ),
      conditionalPanel(
        condition = design_is("combined"),
        numericInput(ns("n_tests"), "Number of tests to combine (2-6)", value = 3, min = 2, max = .dx_max_tests, step = 1),
        fluidRow(
          column(2, strong("")), column(2, strong("Sensitivity (%)")), column(2, strong("Specificity (%)")),
          column(3, strong("Diseased subjects (optional)")), column(3, strong("Non-diseased subjects (optional)"))
        ),
        test_rows,
        numericInput(ns("prevalence_combined"), "Disease prevalence where the tests will be used (%)",
                     value = 10, min = 0.01, max = 99.99, step = 1)
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
      h4(analyze_dx_content$single$title),
      render_formula_block(analyze_dx_content$single$formula_latex),
      shiny::markdown(analyze_dx_content$single$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_dx_content$single$worked_example),
      hr(),
      h4(analyze_dx_content$combined$title),
      render_formula_block(analyze_dx_content$combined$formula_latex),
      shiny::markdown(analyze_dx_content$combined$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_dx_content$combined$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(analyze_dx_content$single$title),
      p(strong("Citation: "), analyze_dx_content$single$citation),
      p(strong("Implemented via: "), code(analyze_dx_content$single$backend)),
      hr(),
      h4(analyze_dx_content$combined$title),
      p(strong("Citation: "), analyze_dx_content$combined$citation),
      p(strong("Implemented via: "), code(analyze_dx_content$combined$backend))
    )
  )
}

# "estimate (lower to upper)" in percent, or "estimate" alone when no interval.
.fmt_pct_ci <- function(est, lo, hi, digits = 1) {
  f <- function(x) sprintf(paste0("%.", digits, "f"), 100 * x)
  if (is.na(est)) return("n/a")
  if (is.na(lo) || is.na(hi)) return(paste0(f(est), "%"))
  sprintf("%s%% (%s to %s)", f(est), f(lo), f(hi))
}
.fmt_ratio <- function(est, lo = NA_real_, hi = NA_real_) {
  g <- function(x) formatC(x, digits = 3, format = "fg", flag = "#")
  if (is.na(est) || !is.finite(est)) return("n/a")
  if (is.na(lo) || is.na(hi)) return(g(est))
  sprintf("%s (%s to %s)", g(est), g(lo), g(hi))
}

mod_analyze_dx_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level)
      tryCatch({
        value <- if (input$design == "single") {
          req(input$tp, input$fp, input$fn, input$tn)
          prev <- NULL
          if (identical(input$pv_basis, "stated")) {
            req(input$prevalence_single)
            prev <- input$prevalence_single / 100
          }
          calc_analyze_dx_single(input$tp, input$fp, input$fn, input$tn,
                                 conf_level = input$conf_level, ci_method = input$ci_method, prevalence = prev)
        } else {
          req(input$n_tests, input$prevalence_combined)
          k <- as.integer(input$n_tests)
          if (is.na(k) || k < 2 || k > .dx_max_tests) stop("Give between 2 and 6 tests.")
          idx <- seq_len(k)
          get <- function(prefix) vapply(idx, function(i) { v <- input[[paste0(prefix, i)]]; if (is.null(v)) NA_real_ else v }, numeric(1))
          se <- get("se"); sp <- get("sp"); nd <- get("nd"); nn <- get("nn")
          req(!anyNA(se), !anyNA(sp))
          have_n <- !anyNA(nd) && !anyNA(nn)
          calc_analyze_dx_combined(se / 100, sp / 100, input$prevalence_combined / 100,
                                   n_diseased = if (have_n) nd else NULL, n_nondiseased = if (have_n) nn else NULL,
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

      if (res$design == "single") {
        tb <- analyze_dx_single_table(v)
        is_pct <- !grepl("likelihood", tb$measure)
        cells <- vapply(seq_len(nrow(tb)), function(i) {
          if (is_pct[i]) .fmt_pct_ci(tb$estimate[i], tb$lower[i], tb$upper[i])
          else .fmt_ratio(tb$estimate[i], tb$lower[i], tb$upper[i])
        }, character(1))
        pv_note <- if (identical(v$predictive_values_from, "counts")) {
          sprintf("PPV and NPV are read from these counts, so they apply only where the disease prevalence is like the sample's (%.1f%%).",
                  100 * v$prevalence_in_sample)
        } else {
          sprintf("PPV and NPV are recomputed at the stated prevalence of %.1f%% (approximate delta-method interval).",
                  100 * v$prevalence_used_for_pv)
        }
        notes <- c(pv_note)
        if (min(c(v$inputs$tp, v$inputs$fp, v$inputs$fn, v$inputs$tn)) == 0) {
          notes <- c(notes, "A cell is zero: some intervals are undefined (nothing is added to the cells).")
        }
        tagList(
          p(sprintf("Total N = %d;  Youden's index = %.3f", v$n_total, v$youden_index)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Measure"), tags$th(paste0("Estimate (", lvl, " CI)")))),
            tags$tbody(lapply(seq_len(nrow(tb)), function(i) tags$tr(tags$td(tb$measure[i]), tags$td(cells[i]))))
          ),
          lapply(notes, function(n) div(class = "text-muted", n))
        )
      } else {
        tb <- analyze_dx_combined_table(v)
        ci_given <- !is.na(v$parallel_sensitivity_lower)
        tagList(
          p(sprintf("%d tests; disease prevalence %.1f%%. Tests are assumed conditionally independent given disease status.",
                    v$n_tests, 100 * v$inputs$prevalence)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(
              tags$th("Strategy"), tags$th("Sensitivity"), tags$th("Specificity"), tags$th("PPV"), tags$th("NPV"),
              tags$th("LR+"), tags$th("LR-"))),
            tags$tbody(lapply(seq_len(nrow(tb)), function(i) {
              r <- tb[i, ]
              tags$tr(
                tags$td(r$strategy),
                tags$td(.fmt_pct_ci(r$sensitivity, r$sensitivity_lower, r$sensitivity_upper)),
                tags$td(.fmt_pct_ci(r$specificity, r$specificity_lower, r$specificity_upper)),
                tags$td(.fmt_pct_ci(r$ppv, r$ppv_lower, r$ppv_upper)),
                tags$td(.fmt_pct_ci(r$npv, r$npv_lower, r$npv_upper)),
                tags$td(.fmt_ratio(r$lr_positive)), tags$td(.fmt_ratio(r$lr_negative)))
            }))
          ),
          if (!ci_given) div(class = "text-muted",
            "Enter the numbers of diseased and non-diseased subjects behind every test to get confidence intervals."),
          div(class = "text-muted",
            "If the tests are not conditionally independent the real combined performance is usually worse than shown (Vacek 1985).")
        )
      }
    })

    render_export_handlers(output, result, function() analyze_dx_content[[input$design]])
  })
}
