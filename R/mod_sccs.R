# Self-Controlled Case Series (SCCS) module: Calculate / Formula-Help /
# Reference sub-tabs. Follows the same module contract as mod_roc.R
# (docs/SDD.md #8) -- a single calculation, no outer design radio -- with a
# nested "age effects?" toggle (same nested-radio pattern as
# mod_prediction.R's r2_method) since eage/agegrp are optional together.

sccs_meta <- list(
  id = "sccs",
  nav_title = "Self-Controlled Case Series"
)

mod_sccs_ui <- function(id) {
  ns <- NS(id)

  age_is <- function(value) sprintf("input['%s'] == '%s'", ns("age_effects"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      numericInput(ns("eexpo"), "Design relative incidence (eexpo)", value = 2.5, min = 0.001, step = 0.1),
      numericInput(ns("risk"), "Risk period length", value = 21, min = 0.001, step = 1),
      numericInput(ns("astart"), "Start of observation period", value = 366, min = 0, step = 1),
      numericInput(ns("aend"), "End of observation period", value = 730, min = 0.001, step = 1),
      radioButtons(ns("age_effects"), "Does the baseline event rate vary by age group?",
                   choices = c("No -- single overall exposed proportion" = "no",
                               "Yes -- age groups with different baseline rates" = "yes")),
      conditionalPanel(
        condition = age_is("no"),
        numericInput(ns("p_flat"), "Proportion of cases exposed (p)", value = 1, min = 0.001, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = age_is("yes"),
        p(class = "text-muted",
          "Enter one value per age group, comma-separated (age groups = length of p = length of eage + 1 = length of agegrp + 1)."),
        textInput(ns("p_vec"), "Proportion of cases exposed, per age group (p)", value = "0.50, 0.35, 0.1, 0.05"),
        textInput(ns("eage_vec"), "Age-group relative incidences (eage)", value = "1.2, 1.6, 2.0"),
        textInput(ns("agegrp_vec"), "Age-group cut points (agegrp)", value = "457, 548, 639")
      ),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(sccs_content$samplesize$title),
      render_formula_block(sccs_content$samplesize$formula_latex),
      shiny::markdown(sccs_content$samplesize$explanation),
      h5("Worked example"),
      shiny::markdown(sccs_content$samplesize$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(sccs_content$samplesize$title),
      p(strong("Citation: "), sccs_content$samplesize$citation),
      p(strong("Implemented via: "), code(sccs_content$samplesize$backend))
    )
  )
}

.parse_numeric_vec <- function(x) {
  vals <- suppressWarnings(as.numeric(trimws(strsplit(x, ",")[[1]])))
  if (any(is.na(vals)) || length(vals) == 0) stop("Could not parse a comma-separated list of numbers.")
  vals
}

mod_sccs_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$eexpo, input$risk, input$astart, input$aend, input$age_effects,
          input$alpha, input$power)

      tryCatch({
        if (input$age_effects == "no") {
          req(input$p_flat)
          value <- calc_sccs_samplesize(
            eexpo = input$eexpo, risk = input$risk, astart = input$astart, aend = input$aend,
            p = input$p_flat, alpha = input$alpha, power = input$power
          )
        } else {
          req(input$p_vec, input$eage_vec, input$agegrp_vec)
          value <- calc_sccs_samplesize(
            eexpo = input$eexpo, risk = input$risk, astart = input$astart, aend = input$aend,
            p = .parse_numeric_vec(input$p_vec), alpha = input$alpha, power = input$power,
            eage = .parse_numeric_vec(input$eage_vec), agegrp = .parse_numeric_vec(input$agegrp_vec)
          )
        }
        list(ok = TRUE, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      tagList(
        p(strong("Required number of cases: "), res$value$n)
      )
    })

    render_export_handlers(output, result, function() sccs_content$samplesize)

    # Power curves (ROADMAP P1 item 10): wired only for the flat (no
    # age-effects) branch, whose p is a single scalar; the age-groups
    # branch's p/eage/agegrp are vectors and are left for a later batch.
    render_power_curves(output, function() {
      req(input$eexpo, input$risk, input$astart, input$aend, input$age_effects,
          input$alpha, input$power)
      if (input$age_effects == "yes") {
        req(input$p_vec, input$eage_vec, input$agegrp_vec)
        return(list(
          calc_fn = calc_sccs_samplesize,
          args = list(eexpo = input$eexpo, risk = input$risk, astart = input$astart, aend = input$aend,
                       p = .parse_numeric_vec(input$p_vec), alpha = input$alpha, power = input$power,
                       eage = .parse_numeric_vec(input$eage_vec), agegrp = .parse_numeric_vec(input$agegrp_vec)),
          effect = list(param = "eexpo", values = curve_range_ratio(), label = "Design relative incidence (eexpo)"),
          power = list(param = "power", values = curve_range_power())
        ))
      }
      req(input$p_flat)
      list(
        calc_fn = calc_sccs_samplesize,
        args = list(eexpo = input$eexpo, risk = input$risk, astart = input$astart,
                     aend = input$aend, p = input$p_flat, alpha = input$alpha, power = input$power),
        effect = list(param = "eexpo", values = curve_range_ratio(), label = "Design relative incidence (eexpo)"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
