# Analyze: Vaccine Efficacy module (ROADMAP Track B1): Calculate / Formula-Help /
# Reference sub-tabs, design-radio contract as in mod_rate.R (docs/SDD.md #8).
# "risk": cases and participants; "rate": cases and person-time; "odds": case-control
# or test-negative counts. VE = 1 - (relative risk, rate ratio or odds ratio).

analyze_vaccine_meta <- list(
  id = "analyze_vaccine",
  nav_title = "Vaccine Efficacy"
)

mod_analyze_vaccine_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Vaccine efficacy (trial) or effectiveness (observational) = 1 - relative risk, from counts you already have.",
        "This tool does not plan a study; for sample size use the calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What data do you have?",
        choices = c("Cases and number of participants in each group (attack rates)" = "risk",
                    "Cases and person-time in each group (incidence rates)" = "rate",
                    "Vaccinated and unvaccinated cases and controls (case-control / test-negative)" = "odds"),
        selected = "risk"
      ),
      conditionalPanel(
        condition = design_is("risk"),
        fluidRow(column(4, strong("")), column(4, strong("Cases")), column(4, strong("Participants"))),
        fluidRow(column(4, strong("Vaccinated")),
                 column(4, numericInput(ns("r_cv"), NULL, value = 8, min = 0, step = 1)),
                 column(4, numericInput(ns("r_nv"), NULL, value = 1000, min = 1, step = 1))),
        fluidRow(column(4, strong("Unvaccinated / placebo")),
                 column(4, numericInput(ns("r_cu"), NULL, value = 160, min = 0, step = 1)),
                 column(4, numericInput(ns("r_nu"), NULL, value = 1000, min = 1, step = 1)))
      ),
      conditionalPanel(
        condition = design_is("rate"),
        fluidRow(column(4, strong("")), column(4, strong("Cases")), column(4, strong("Person-time"))),
        fluidRow(column(4, strong("Vaccinated")),
                 column(4, numericInput(ns("t_cv"), NULL, value = 8, min = 0, step = 1)),
                 column(4, numericInput(ns("t_tv"), NULL, value = 2000, min = 0.0001, step = 1))),
        fluidRow(column(4, strong("Unvaccinated / placebo")),
                 column(4, numericInput(ns("t_cu"), NULL, value = 160, min = 0, step = 1)),
                 column(4, numericInput(ns("t_tu"), NULL, value = 2100, min = 0.0001, step = 1)))
      ),
      conditionalPanel(
        condition = design_is("odds"),
        fluidRow(column(4, strong("")), column(4, strong("Vaccinated")), column(4, strong("Unvaccinated"))),
        fluidRow(column(4, strong("Cases")),
                 column(4, numericInput(ns("o_a"), NULL, value = 10, min = 0, step = 1)),
                 column(4, numericInput(ns("o_b"), NULL, value = 40, min = 0, step = 1))),
        fluidRow(column(4, strong("Controls")),
                 column(4, numericInput(ns("o_c"), NULL, value = 50, min = 0, step = 1)),
                 column(4, numericInput(ns("o_d"), NULL, value = 50, min = 0, step = 1)))
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
      h4(analyze_vaccine_content$risk$title),
      render_formula_block(analyze_vaccine_content$risk$formula_latex),
      shiny::markdown(analyze_vaccine_content$risk$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_vaccine_content$risk$worked_example),
      hr(),
      h4(analyze_vaccine_content$rate$title),
      render_formula_block(analyze_vaccine_content$rate$formula_latex),
      shiny::markdown(analyze_vaccine_content$rate$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_vaccine_content$rate$worked_example),
      hr(),
      h4(analyze_vaccine_content$odds$title),
      render_formula_block(analyze_vaccine_content$odds$formula_latex),
      shiny::markdown(analyze_vaccine_content$odds$explanation),
      h5("Worked example"),
      shiny::markdown(analyze_vaccine_content$odds$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(analyze_vaccine_content$risk$citation),
      hr(),
      p(strong("Implemented via: "), code(analyze_vaccine_content$risk$backend)),
      p(strong("Implemented via: "), code(analyze_vaccine_content$rate$backend)),
      p(strong("Implemented via: "), code(analyze_vaccine_content$odds$backend))
    )
  )
}

.ve_pct <- function(x) if (is.na(x)) "n/a" else sprintf("%.1f%%", 100 * x)

mod_analyze_vaccine_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$conf_level)
      tryCatch({
        value <- switch(input$design,
          risk = {
            req(input$r_cv, input$r_nv, input$r_cu, input$r_nu)
            calc_analyze_vaccine_efficacy("risk", input$r_cv, input$r_cu, input$r_nv, input$r_nu, conf_level = input$conf_level)
          },
          rate = {
            req(input$t_cv, input$t_tv, input$t_cu, input$t_tu)
            calc_analyze_vaccine_efficacy("rate", input$t_cv, input$t_cu, input$t_tv, input$t_tu, conf_level = input$conf_level)
          },
          odds = {
            req(input$o_a, input$o_b, input$o_c, input$o_d)
            calc_analyze_vaccine_efficacy("odds", input$o_a, input$o_b, controls_vaccinated = input$o_c,
                                          controls_unvaccinated = input$o_d, conf_level = input$conf_level)
          })
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
      tb <- analyze_vaccine_table(v)
      rows <- lapply(seq_len(nrow(tb)), function(i) {
        tags$tr(tags$td(tb$method[i]), tags$td(.ve_pct(tb$estimate[i])),
                tags$td(paste(.ve_pct(tb$lower[i]), "to", .ve_pct(tb$upper[i]))),
                tags$td(class = "text-muted small", tb$note[i]))
      })
      what <- switch(res$design,
        risk = sprintf("Attack rate %s in the vaccinated and %s in the unvaccinated; risk ratio %s.",
                       .ve_pct(v$attack_rate_vaccinated), .ve_pct(v$attack_rate_unvaccinated), formatC(v$ratio, digits = 3, format = "fg", flag = "#")),
        rate = sprintf("Incidence rate ratio %s (vaccinated vs unvaccinated).", formatC(v$ratio, digits = 3, format = "fg", flag = "#")),
        odds = sprintf("Odds ratio of vaccination, cases vs controls: %s.", formatC(v$ratio, digits = 3, format = "fg", flag = "#")))
      notes <- character()
      if (is.na(v$ve)) notes <- c(notes, "The ratio is undefined (no cases in the comparison group), so vaccine efficacy cannot be computed.")
      if (!is.na(v$ve) && v$ve < 0) notes <- c(notes, "Negative efficacy: more disease among the vaccinated than the unvaccinated.")
      if (res$design == "odds") notes <- c(notes, "VE = 1 - OR approximates 1 - RR when the controls represent the source population (rare disease or density sampling).")
      tagList(
        p(what),
        div(strong(sprintf("Vaccine efficacy = %s", .ve_pct(v$ve)))),
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(tags$th("Interval method"), tags$th("VE"), tags$th(paste0(lvl, " CI")), tags$th("Note"))),
          tags$tbody(rows)
        ),
        div(class = "text-muted",
            "The methods are shown side by side so you can compare them; the choice is yours. These are crude (unadjusted) estimates."),
        p(sprintf("Test of no association (%s): p = %s.", if (res$design == "rate") "exact conditional" else "Fisher's exact",
                  if (is.na(v$test_p)) "n/a" else formatC(v$test_p, digits = 3, format = "fg"))),
        lapply(notes, function(n) div(class = "text-muted", n))
      )
    })

    render_export_handlers(output, result, function() analyze_vaccine_content[[input$design]])
  })
}
