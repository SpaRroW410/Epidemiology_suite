# Analyze: Standardization module (ROADMAP Track B1): Calculate / Formula-Help /
# Reference sub-tabs, design-radio contract as in mod_rate.R (docs/SDD.md #8).
# "direct": directly standardized rate(s) over 2-12 strata, optionally comparing two
# groups. "indirect": expected events from reference rates, then the SMR.
# "smr": SMR from observed and expected counts.

analyze_std_meta <- list(
  id = "analyze_std",
  nav_title = "Standardization and SMR"
)

.std_max_strata <- 12
.std_default <- list(
  events_a = c(15, 46, rep(10, 10)), pt_a = c(48, 212, rep(100, 10)), standard = c(250, 250, rep(100, 10)),
  events_b = c(53, 16, rep(10, 10)), pt_b = c(180, 71, rep(100, 10)),
  ind_pt = c(550, 450, rep(100, 10)), ind_rate = c(25, 85, rep(10, 10)))

mod_analyze_std_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  cell <- function(name, i, value, width = 2, min = 0) column(width, numericInput(ns(paste0(name, i)), NULL, value = value, min = min))

  direct_rows <- lapply(seq_len(.std_max_strata), function(i) {
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_strata"), i),
      fluidRow(
        column(2, textInput(ns(paste0("label", i)), NULL, value = "", placeholder = sprintf("Stratum %d", i))),
        cell("ea", i, .std_default$events_a[i]), cell("ta", i, .std_default$pt_a[i]),
        cell("std", i, .std_default$standard[i]),
        column(2, conditionalPanel(condition = sprintf("input['%s']", ns("compare")),
                                   numericInput(ns(paste0("eb", i)), NULL, value = .std_default$events_b[i], min = 0))),
        column(2, conditionalPanel(condition = sprintf("input['%s']", ns("compare")),
                                   numericInput(ns(paste0("tb", i)), NULL, value = .std_default$pt_b[i], min = 0)))
      )
    )
  })
  indirect_rows <- lapply(seq_len(.std_max_strata), function(i) {
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_strata_ind"), i),
      fluidRow(
        column(3, textInput(ns(paste0("ilabel", i)), NULL, value = "", placeholder = sprintf("Stratum %d", i))),
        cell("ipt", i, .std_default$ind_pt[i], 4), cell("irate", i, .std_default$ind_rate[i], 4)
      )
    )
  })

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Standardize rates you already have. This tool does not plan a study; for sample size use the calculators",
        "under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c(
          "Direct standardization: standardized rate(s) against a standard population" = "direct",
          "Indirect standardization: expected events from reference rates, then the SMR" = "indirect",
          "SMR from observed and expected events" = "smr"
        ),
        selected = "direct"
      ),
      conditionalPanel(
        condition = design_is("direct"),
        numericInput(ns("n_strata"), "Number of strata (2-12)", value = 2, min = 2, max = .std_max_strata, step = 1),
        checkboxInput(ns("compare"), "Compare with a second group (same strata)", value = FALSE),
        fluidRow(
          column(2, strong("Stratum")), column(2, strong("Events (group A)")), column(2, strong("Person-time (A)")),
          column(2, strong("Standard population")),
          column(2, conditionalPanel(condition = sprintf("input['%s']", ns("compare")), strong("Events (group B)"))),
          column(2, conditionalPanel(condition = sprintf("input['%s']", ns("compare")), strong("Person-time (B)")))
        ),
        direct_rows
      ),
      conditionalPanel(
        condition = design_is("indirect"),
        numericInput(ns("n_strata_ind"), "Number of strata (2-12)", value = 2, min = 2, max = .std_max_strata, step = 1),
        numericInput(ns("observed_ind"), "Observed events in the study group (all strata)", value = 58, min = 0, step = 1),
        fluidRow(column(3, strong("Stratum")), column(4, strong("Person-time of the study group")),
                 column(4, strong("Reference rate (per the unit below)"))),
        indirect_rows
      ),
      conditionalPanel(
        condition = design_is("smr"),
        numericInput(ns("observed"), "Observed events", value = 58, min = 0, step = 1),
        numericInput(ns("expected"), "Expected events", value = 52, min = 0.0001, step = 0.1)
      ),
      conditionalPanel(
        condition = paste0("!(", design_is("smr"), ")"),
        numericInput(ns("multiplier"), "Rates per this many units of person-time (e.g. 1000)", value = 1000, min = 1, step = 1)
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
      h4(analyze_std_content$direct$title),
      render_formula_block(analyze_std_content$direct$formula_latex),
      shiny::markdown(analyze_std_content$direct$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_std_content$direct$worked_example),
      hr(),
      h4(analyze_std_content$indirect$title),
      render_formula_block(analyze_std_content$indirect$formula_latex),
      shiny::markdown(analyze_std_content$indirect$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_std_content$indirect$worked_example),
      hr(),
      h4(analyze_std_content$smr$title),
      render_formula_block(analyze_std_content$smr$formula_latex),
      shiny::markdown(analyze_std_content$smr$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_std_content$smr$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(analyze_std_content$direct$title),
      p(strong("Citation: "), analyze_std_content$direct$citation),
      p(strong("Implemented via: "), code(analyze_std_content$direct$backend)),
      hr(),
      h4(analyze_std_content$indirect$title),
      p(strong("Citation: "), analyze_std_content$indirect$citation),
      p(strong("Implemented via: "), code(analyze_std_content$indirect$backend)),
      hr(),
      h4(analyze_std_content$smr$title),
      p(strong("Citation: "), analyze_std_content$smr$citation),
      p(strong("Implemented via: "), code(analyze_std_content$smr$backend))
    )
  )
}

.fmt_s <- function(x, digits = 4) {
  if (is.na(x)) return("n/a")
  if (is.infinite(x)) return(if (x > 0) "infinity" else "-infinity")
  formatC(x, digits = digits, format = "fg", flag = "#")
}
.fmt_sci <- function(est, lo, hi, digits = 4) {
  if (is.na(est)) return("n/a")
  if (is.na(lo) && is.na(hi)) return(.fmt_s(est, digits))
  sprintf("%s (%s to %s)", .fmt_s(est, digits), .fmt_s(lo, digits), .fmt_s(hi, digits))
}
.fmt_sp <- function(p) if (is.na(p)) "n/a" else if (p < 0.0001) "< 0.0001" else formatC(p, digits = 3, format = "fg")

mod_analyze_std_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    vec <- function(prefix, n) vapply(seq_len(n), function(i) {
      v <- input[[paste0(prefix, i)]]; if (is.null(v)) NA_real_ else v
    }, numeric(1))

    result <- reactive({
      req(input$design, input$conf_level)
      tryCatch({
        value <- if (input$design == "direct") {
          req(input$n_strata, input$multiplier)
          g <- as.integer(input$n_strata)
          if (is.na(g) || g < 2 || g > .std_max_strata) stop("Use between 2 and 12 strata.")
          ea <- vec("ea", g); ta <- vec("ta", g); sd <- vec("std", g)
          req(!anyNA(ea), !anyNA(ta), !anyNA(sd))
          if (isTRUE(input$compare)) {
            eb <- vec("eb", g); tb <- vec("tb", g)
            req(!anyNA(eb), !anyNA(tb))
            calc_analyze_dsr(ea, ta, sd, eb, tb, multiplier = input$multiplier, conf_level = input$conf_level)
          } else {
            calc_analyze_dsr(ea, ta, sd, multiplier = input$multiplier, conf_level = input$conf_level)
          }
        } else if (input$design == "indirect") {
          req(input$n_strata_ind, input$observed_ind, input$multiplier)
          g <- as.integer(input$n_strata_ind)
          if (is.na(g) || g < 2 || g > .std_max_strata) stop("Use between 2 and 12 strata.")
          pt <- vec("ipt", g); rt <- vec("irate", g)
          req(!anyNA(pt), !anyNA(rt))
          calc_analyze_indirect(pt, rt, input$observed_ind, multiplier = input$multiplier, conf_level = input$conf_level)
        } else {
          req(input$observed, input$expected)
          calc_analyze_smr(input$observed, input$expected, conf_level = input$conf_level)
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

      smr_block <- function(v) {
        tb <- analyze_smr_table(v)
        tagList(
          p(sprintf("Observed %s, expected %s: SMR = %s.", .fmt_s(v$observed), .fmt_s(v$expected), .fmt_s(v$smr))),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Interval method"), tags$th(paste0(lvl, " CI, lower")), tags$th("upper"), tags$th("Note"))),
            tags$tbody(lapply(seq_len(nrow(tb)), function(i) {
              tags$tr(tags$td(tb$method[i]), tags$td(.fmt_s(tb$lower[i])), tags$td(.fmt_s(tb$upper[i])),
                      tags$td(class = "text-muted small", tb$note[i]))
            }))
          ),
          div(class = "text-muted",
              "The methods are shown side by side so you can compare them; none is the only correct one. With 5 or fewer observed events the exact and mid-P intervals are the usual choice; with more events the approximations agree closely with the exact one (see the Formula / Help tab for what each assumes)."),
          h6("Tests of SMR = 1"),
          tags$ul(
            tags$li(sprintf("Exact Poisson test: p = %s;  mid-P exact: p = %s", .fmt_sp(v$exact_test_p), .fmt_sp(v$mid_p_test_p))),
            tags$li(sprintf("Chi-square (O - E)^2 / E = %s (1 df): p = %s", .fmt_s(v$chisq), .fmt_sp(v$chisq_p))),
            tags$li(sprintf("Byar's normal approximation: z = %s, p = %s", .fmt_s(v$byar_z), .fmt_sp(v$byar_test_p)))
          ),
          div(class = "text-muted", "The intervals treat the expected count as fixed. SMRs of different groups are not strictly comparable with each other; compare each with 1, or use direct standardization.")
        )
      }

      if (res$design == "direct") {
        per <- format(v$multiplier, big.mark = ",", scientific = FALSE)
        two <- !is.null(v$b_standardized_rate)
        rows <- list(
          tags$tr(tags$td(if (two) "Group A" else "Study group"), tags$td(.fmt_sci(v$crude_rate, v$crude_rate_lower, v$crude_rate_upper)),
                  tags$td(.fmt_sci(v$standardized_rate, v$standardized_rate_lower, v$standardized_rate_upper))))
        if (two) rows <- c(rows, list(tags$tr(tags$td("Group B"), tags$td(.fmt_sci(v$b_crude_rate, v$b_crude_rate_lower, v$b_crude_rate_upper)),
                  tags$td(.fmt_sci(v$b_standardized_rate, v$b_standardized_rate_lower, v$b_standardized_rate_upper)))))
        tagList(
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Group"), tags$th(paste0("Crude rate per ", per, " (exact ", lvl, " CI)")),
                               tags$th(paste0("Directly standardized rate per ", per, " (", lvl, " CI)")))),
            tags$tbody(rows)
          ),
          if (two) tagList(
            h6("Comparison of the standardized rates (A vs B)"),
            tags$ul(
              tags$li("Ratio: ", .fmt_sci(v$standardized_rate_ratio, v$standardized_rate_ratio_lower, v$standardized_rate_ratio_upper, 3),
                      sprintf(" (p = %s)", .fmt_sp(v$standardized_rate_ratio_p))),
              tags$li(paste0("Difference per ", per, ": "), .fmt_sci(v$standardized_rate_difference, v$standardized_rate_difference_lower, v$standardized_rate_difference_upper, 3))
            ),
            div(class = "text-muted", "Normal-scale intervals for the ratio and difference are first-order approximations.")),
          div(class = "text-muted", "The standardized-rate interval is the Fay-Feuer gamma interval; with few events in a stratum it is wide, as it should be.")
        )
      } else if (res$design == "indirect") {
        tagList(
          p(sprintf("%d strata; rates in the reference were given per %s units of person-time.", v$strata,
                    format(v$multiplier, big.mark = ",", scientific = FALSE))),
          smr_block(v)
        )
      } else {
        smr_block(v)
      }
    })

    render_export_handlers(output, result, function() analyze_std_content[[input$design]])
  })
}
