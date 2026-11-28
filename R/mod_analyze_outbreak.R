# Analyze: Outbreak Measures module (ROADMAP Track B4, item 20): Calculate / Formula-Help / Reference sub-tabs,
# design-radio contract as in mod_rate.R (docs/SDD.md #8). "attack": attack rate; "exposure": exposure-specific
# attack-rate table; "secondary": secondary attack rate; "cfr": case fatality (crude and among resolved cases).

analyze_outbreak_meta <- list(
  id = "analyze_outbreak",
  nav_title = "Outbreak Measures"
)

.ob_max_exposures <- 6
.ob_default_exposures <- list(list("Salad", 40, 50, 4, 30), list("Chicken", 25, 60, 19, 20), list("Dessert", 10, 12, 34, 68),
                              list("", 10, 20, 10, 20), list("", 10, 20, 10, 20), list("", 10, 20, 10, 20))

mod_analyze_outbreak_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  rows <- lapply(seq_len(.ob_max_exposures), function(i) {
    v <- .ob_default_exposures[[i]]
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_exp"), i),
      fluidRow(
        column(3, textInput(ns(paste0("label", i)), NULL, value = v[[1]], placeholder = sprintf("Exposure %d", i))),
        column(2, numericInput(ns(paste0("ie", i)), NULL, value = v[[2]], min = 0, step = 1)),
        column(2, numericInput(ns(paste0("te", i)), NULL, value = v[[3]], min = 0, step = 1)),
        column(2, numericInput(ns(paste0("iu", i)), NULL, value = v[[4]], min = 0, step = 1)),
        column(2, numericInput(ns(paste0("tu", i)), NULL, value = v[[5]], min = 0, step = 1))
      )
    )
  })
  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted", "Outbreak measures from counts you already have. Line lists, epidemic curves and reproduction-number estimation are not part of this tool."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c("Attack rate" = "attack",
                    "Exposure-specific attack rates and risk ratios (which food or event?)" = "exposure",
                    "Secondary attack rate among contacts" = "secondary",
                    "Case fatality (crude and among resolved cases)" = "cfr"),
        selected = "attack"
      ),
      conditionalPanel(
        condition = design_is("attack"),
        numericInput(ns("cases"), "Number of cases", value = 30, min = 0, step = 1),
        numericInput(ns("at_risk"), "Population at risk", value = 120, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("exposure"),
        numericInput(ns("n_exp"), "Number of exposures (1-6)", value = 3, min = 1, max = .ob_max_exposures, step = 1),
        fluidRow(column(3, strong("Exposure")), column(2, strong("Ill, exposed")), column(2, strong("Total exposed")),
                 column(2, strong("Ill, unexposed")), column(2, strong("Total unexposed"))),
        rows
      ),
      conditionalPanel(
        condition = design_is("secondary"),
        numericInput(ns("sec_cases"), "Secondary cases", value = 9, min = 0, step = 1),
        numericInput(ns("contacts"), "Susceptible contacts exposed to the primary cases", value = 60, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("cfr"),
        numericInput(ns("deaths"), "Deaths", value = 6, min = 0, step = 1),
        numericInput(ns("cfr_cases"), "Cases", value = 80, min = 1, step = 1),
        numericInput(ns("recovered"), "Recovered (optional, for the ratio among resolved cases)", value = 34, min = 0, step = 1)
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
      lapply(c("attack", "exposure", "secondary", "cfr"), function(d) {
        x <- analyze_outbreak_content[[d]]
        tagList(h4(x$title), render_formula_block(x$formula_latex), shiny::markdown(x$explanation),
                h5("Worked example"), shiny::markdown(x$worked_example), hr())
      })
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(analyze_outbreak_content$attack$citation),
      hr(),
      p(strong("Implemented via: "), code(analyze_outbreak_content$attack$backend))
    )
  )
}

mod_analyze_outbreak_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level)
      cl <- input$conf_level
      tryCatch({
        if (is.na(cl) || cl <= 0.5 || cl >= 1) stop("The confidence level must be between 0.5 and 1.")
        value <- switch(input$design,
          attack = { req(input$cases, input$at_risk); calc_analyze_attack_rate(input$cases, input$at_risk, cl) },
          exposure = {
            req(input$n_exp)
            k <- as.integer(input$n_exp)
            if (is.na(k) || k < 1 || k > .ob_max_exposures) stop("Give between 1 and 6 exposures.")
            cell <- function(prefix) vapply(seq_len(k), function(i) { v <- input[[paste0(prefix, i)]]; if (is.null(v)) NA_real_ else v }, 0)
            m <- cbind(cell("ie"), cell("te"), cell("iu"), cell("tu"))
            req(!anyNA(m))
            labs <- vapply(seq_len(k), function(i) { v <- input[[paste0("label", i)]]; if (is.null(v) || !nzchar(trimws(v))) paste("Exposure", i) else trimws(v) }, "")
            calc_analyze_exposure_table(m, labs, cl)
          },
          secondary = { req(input$sec_cases, input$contacts); calc_analyze_secondary_attack(input$sec_cases, input$contacts, cl) },
          cfr = {
            req(input$deaths, input$cfr_cases)
            calc_analyze_case_fatality(input$deaths, input$cfr_cases, if (is.null(input$recovered) || is.na(input$recovered)) NULL else input$recovered, cl)
          })
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      cl <- 100 * v$inputs$conf_level
      ci_rows <- function(prefix, pretty = c(wilson = "Wilson", exact = "Clopper-Pearson (exact)", agresti_coull = "Agresti-Coull",
                                              jeffreys = "Jeffreys", mid_p = "Mid-P exact", wald = "Wald")) {
        tags$table(class = "table table-sm", tags$thead(tags$tr(tags$th("Interval method"), tags$th(sprintf("%g%% limits", cl)))),
          tags$tbody(lapply(names(pretty), function(m) tags$tr(tags$td(pretty[[m]]),
            tags$td(sprintf("%.1f%% to %.1f%%", 100 * v[[paste0(prefix, m, "_lower")]], 100 * v[[paste0(prefix, m, "_upper")]]))
          ))))
      }
      switch(res$design,
        attack = tagList(
          h5(sprintf("Attack rate %.1f%% (%d of %d)", v$attack_rate_per_100, v$cases, v$at_risk)),
          ci_rows(""),
          div(class = "text-muted", "The denominator must be the population at risk: people who were not exposed or were already immune are not in it.")
        ),
        secondary = tagList(
          h5(sprintf("Secondary attack rate %.1f%% (%d of %d susceptible contacts)", v$secondary_attack_rate_per_100, v$secondary_cases, v$contacts)),
          ci_rows(""),
          div(class = "text-warning", "The intervals treat contacts as independent; contacts in the same household are not, so they are too narrow when households contribute several contacts.")
        ),
        cfr = tagList(
          h5(sprintf("Case fatality %.1f%% (%d deaths among %d cases)", v$case_fatality_percent, v$deaths, v$cases)),
          p("Crude ratio, with intervals:"),
          ci_rows("crude_", c(exact = "Clopper-Pearson (exact)", wilson = "Wilson", agresti_coull = "Agresti-Coull", jeffreys = "Jeffreys", mid_p = "Mid-P exact", wald = "Wald")),
          if (!is.null(v$case_fatality_resolved)) tagList(
            p(sprintf("Among the %d resolved cases (%d deaths + %d recovered; %d not yet resolved): %.1f%%.", v$deaths + v$recovered, v$deaths, v$recovered, v$unresolved, 100 * v$case_fatality_resolved)),
            ci_rows("resolved_", c(exact = "Clopper-Pearson (exact)", wilson = "Wilson", agresti_coull = "Agresti-Coull", jeffreys = "Jeffreys", mid_p = "Mid-P exact", wald = "Wald"))
          ),
          div(class = "text-warning", "While cases are unresolved the crude ratio is biased low and the ratio among resolved cases high; the true value lies between them once the outbreak has settled.")
        ),
        exposure = {
          tb <- attr(v, "table")
          pc <- function(x) sprintf("%.1f%%", 100 * x)
          g <- function(x, d = 3) if (is.na(x)) "n/a" else if (is.infinite(x)) "infinity" else formatC(x, digits = d, format = "fg", flag = "#")
          tagList(
            tags$table(
              class = "table table-sm",
              tags$thead(tags$tr(lapply(c("Exposure", "Ill / total, exposed", "Attack rate, exposed", "Ill / total, unexposed", "Attack rate, unexposed",
                                          "Risk ratio (CI)", "Risk difference", "Fisher p", "% of cases exposed"), tags$th))),
              tags$tbody(lapply(seq_len(nrow(tb)), function(i) tags$tr(
                tags$td(tb$exposure[i]), tags$td(sprintf("%d / %d", tb$ill_exposed[i], tb$total_exposed[i])), tags$td(pc(tb$attack_rate_exposed[i])),
                tags$td(sprintf("%d / %d", tb$ill_unexposed[i], tb$total_unexposed[i])), tags$td(pc(tb$attack_rate_unexposed[i])),
                tags$td(sprintf("%s (%s to %s)", g(tb$risk_ratio[i]), g(tb$risk_ratio_lower[i]), g(tb$risk_ratio_upper[i]))),
                tags$td(pc(tb$risk_difference[i])), tags$td(g(tb$fisher_p[i], 3)),
                tags$td(if (is.na(tb$percent_of_cases_exposed[i])) "n/a" else sprintf("%.0f%%", tb$percent_of_cases_exposed[i]))
              )))
            ),
            if (!is.na(v$highest_risk_ratio_exposure)) p(sprintf("Highest risk ratio: %s (%s).", v$highest_risk_ratio_exposure, g(v$highest_risk_ratio))),
            div(class = "text-muted", "A screening table: several exposures are tested at once and exposures eaten together are correlated, so the p-values are descriptive.")
          )
        }
      )
    })

    render_export_handlers(output, result, function() analyze_outbreak_content[[input$design]])
  })
}
