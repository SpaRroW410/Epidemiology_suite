# Case-Control module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_proportion.R (docs/SDD.md #8):
# a `design` radioButtons()/conditionalPanel() switch across unmatched and
# matched designs -- see R/calc_case_control.R and
# R/content_case_control.R for the formulas and citations.

case_control_meta <- list(
  id = "case_control",
  nav_title = "Case-Control"
)

mod_case_control_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }
  exposure_is <- function(value) sprintf("input['%s'] == '%s'", ns("exposure_type"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Unmatched case-control" = "unmatched",
          "Matched case-control (1:1 or 1:m)" = "matched",
          "Nested case-control" = "nested",
          "Case-cohort" = "case_cohort"
        ),
        selected = "unmatched"
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched"),
        numericInput(ns("p0"), with_tip("p0 (prevalence of exposure among controls)", "p0_controls"),
                     value = 0.30, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched"),
        radioButtons(ns("effect_as"), "Effect to detect, given as",
                     choices = c("Odds ratio (OR)" = "or", "Proportion of cases exposed (p1)" = "p1"), inline = TRUE)
      ),
      conditionalPanel(
        condition = sprintf("(%s) && input['%s'] == 'p1'", design_is("unmatched", "matched"), ns("effect_as")),
        numericInput(ns("p1_cases"), "p1 (expected proportion of cases exposed)",
                     value = 0.46, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = sprintf("(%s) || ((%s) && input['%s'] != 'p1')", design_is("nested"), design_is("unmatched", "matched"),
                            ns("effect_as")),
        numericInput(ns("OR"), with_tip("Expected odds ratio (OR)", "odds_ratio"), value = 2, min = 0.01, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched"),
        uiOutput(ns("effect_equiv"))
      ),
      conditionalPanel(
        condition = design_is("matched"),
        radioButtons(ns("phi_as"), with_tip("Correlation of exposure within matched pairs (phi)", "phi"),
                     choices = c("Enter phi (0.2 if unknown)" = "value",
                                 "Calculate from a table of matched pairs (pilot or published)" = "table")),
        conditionalPanel(
          condition = sprintf("input['%s'] != 'table'", ns("phi_as")),
          numericInput(ns("phi_coef"), with_tip("phi", "phi"), value = 0.2, min = -0.99, max = 0.99, step = 0.01)
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'table'", ns("phi_as")),
          p(class = "small text-muted mb-1", "Number of matched pairs in which:"),
          div(class = "row g-2",
            div(class = "col-6", numericInput(ns("pairs_both"), "both were exposed", value = 30, min = 0, step = 1)),
            div(class = "col-6", numericInput(ns("pairs_case"), "only the case was exposed", value = 25, min = 0, step = 1)),
            div(class = "col-6", numericInput(ns("pairs_control"), "only the control was exposed", value = 10, min = 0, step = 1)),
            div(class = "col-6", numericInput(ns("pairs_neither"), "neither was exposed", value = 35, min = 0, step = 1))
          ),
          uiOutput(ns("phi_table_result"))
        )
      ),
      conditionalPanel(
        condition = design_is("unmatched", "matched"),
        numericInput(ns("ratio"), "Controls per case (ratio)", value = 1, min = 0.1, step = 0.5)
      ),
      advanced_options_ui(
        ns, condition = design_is("unmatched", "matched"),
        selectInput(
          ns("alternative"), "Alternative hypothesis",
          choices = c("Two-sided" = "two.sided", "Less" = "less", "Greater" = "greater")
        ),
        numericInput(ns("N"), "Eligible population size N (optional; leave blank if effectively unlimited)",
                     value = NA, min = 1)
      ),
      conditionalPanel(
        condition = design_is("nested"),
        radioButtons(ns("exposure_type"), "Exposure type",
                     choices = c("Binary exposure" = "binary", "Continuous exposure" = "continuous")),
        conditionalPanel(
          condition = exposure_is("binary"),
          numericInput(ns("pE"), "Prevalence of exposure among matched sets (pE)",
                       value = 0.15, min = 0.001, max = 0.999, step = 0.01)
        ),
        conditionalPanel(
          condition = exposure_is("continuous"),
          numericInput(ns("sigma"), "Standard deviation of exposure (sigma)",
                       value = 1, min = 0.001, step = 0.1)
        ),
        numericInput(ns("nD"), "Cases per matched set (nD)", value = 1, min = 1, step = 1),
        numericInput(ns("nH"), "Controls per matched set (nH)", value = 2, min = 1, step = 1),
        numericInput(ns("R2"), "R-squared explained by other covariates (0 if none)",
                     value = 0, min = 0, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("case_cohort"),
        numericInput(ns("n_full"), "Full cohort size (n)", value = 15792, min = 1, step = 1),
        numericInput(ns("pD"), "Proportion of the cohort expected to fail (pD)",
                     value = 0.03, min = 0.001, max = 0.999, step = 0.001),
        numericInput(ns("p1"), "Proportion of the cohort in exposure group 1 (p1)",
                     value = 0.25, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("hr"), "Hazard ratio to detect (HR)", value = 1.35, min = 0.01, step = 0.05)
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
      h4(case_control_content$unmatched$title),
      render_formula_block(case_control_content$unmatched$formula_latex),
      shiny::markdown(case_control_content$unmatched$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$unmatched$worked_example),
      hr(),
      h4(case_control_content$matched$title),
      render_formula_block(case_control_content$matched$formula_latex),
      shiny::markdown(case_control_content$matched$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$matched$worked_example),
      hr(),
      h4(case_control_content$nested$title),
      render_formula_block(case_control_content$nested$formula_latex),
      shiny::markdown(case_control_content$nested$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$nested$worked_example),
      hr(),
      h4(case_control_content$case_cohort$title),
      render_formula_block(case_control_content$case_cohort$formula_latex),
      shiny::markdown(case_control_content$case_cohort$explanation),
      h5("Worked example"),
      shiny::markdown(case_control_content$case_cohort$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(case_control_content$unmatched$title),
      p(strong("Citation: "), case_control_content$unmatched$citation),
      p(strong("Implemented via: "), code(case_control_content$unmatched$backend)),
      hr(),
      h4(case_control_content$matched$title),
      p(strong("Citation: "), case_control_content$matched$citation),
      p(strong("Implemented via: "), code(case_control_content$matched$backend)),
      hr(),
      h4(case_control_content$nested$title),
      p(strong("Citation: "), case_control_content$nested$citation),
      p(strong("Implemented via: "), code(case_control_content$nested$backend)),
      hr(),
      h4(case_control_content$case_cohort$title),
      p(strong("Citation: "), case_control_content$case_cohort$citation),
      p(strong("Implemented via: "), code(case_control_content$case_cohort$backend))
    )
  )
}

mod_case_control_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # the effect as calc_case_control_*() takes it: list(OR = ...) or list(p1 = ...)
    effect_args <- function() {
      if (identical(input$effect_as, "p1")) { req(input$p1_cases); list(p1 = input$p1_cases) } else { req(input$OR); list(OR = input$OR) }
    }
    pairs_table <- reactive({
      req(identical(input$phi_as, "table"))
      calc_matched_pairs_phi(input$pairs_both, input$pairs_case, input$pairs_control, input$pairs_neither)
    })
    phi_value <- function() if (identical(input$phi_as, "table")) pairs_table()$phi else { req(input$phi_coef); input$phi_coef }

    output$effect_equiv <- renderUI({
      p0 <- input$p0
      ok <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
      if (!ok(p0) || p0 <= 0 || p0 >= 1) return(NULL)
      txt <- if (identical(input$effect_as, "p1")) {
        p1 <- input$p1_cases
        if (!ok(p1) || p1 <= 0 || p1 >= 1) return(NULL)
        sprintf("p1 = %s with p0 = %s is an odds ratio of %s.", format(p1), format(p0), format(round(p1 * (1 - p0) / (p0 * (1 - p1)), 3)))
      } else {
        or <- input$OR
        if (!ok(or) || or <= 0) return(NULL)
        sprintf("OR = %s with p0 = %s means %s of cases exposed (p1).", format(or), format(p0), format(round(or * p0 / (1 - p0 + or * p0), 3)))
      }
      div(class = "text-muted small mb-2", txt)
    })
    output$phi_table_result <- renderUI({
      t <- tryCatch(pairs_table(), error = function(e) e)
      if (inherits(t, "error")) return(div(class = "text-danger small", conditionMessage(t)))
      div(class = "text-muted small mb-2",
          sprintf("phi = %.3f from %d pairs. The same table has %.1f%% of controls and %.1f%% of cases exposed (odds ratio %.2f; matched-pairs odds ratio %s); enter those above if they are the values you plan for.",
                  t$phi, t$n_pairs, 100 * t$p0, 100 * t$p1, t$OR, if (is.finite(t$OR_matched)) sprintf("%.2f", t$OR_matched) else "not finite"))
    })

    result <- reactive({
      req(input$design, input$alpha, input$power)

      tryCatch({
        value <- if (input$design == "unmatched") {
          req(input$p0, input$ratio, input$alternative)
          N <- input$N
          if (is.null(N) || is.na(N)) N <- NULL
          do.call(calc_case_control_unmatched, c(list(
            p0 = input$p0, power = input$power, ratio = input$ratio,
            alpha = input$alpha, alternative = input$alternative, N = N
          ), effect_args()))
        } else if (input$design == "matched") {
          req(input$p0, input$ratio, input$alternative)
          N <- input$N
          if (is.null(N) || is.na(N)) N <- NULL
          do.call(calc_case_control_matched, c(list(
            p0 = input$p0, phi_coef = phi_value(),
            power = input$power, ratio = input$ratio, alpha = input$alpha,
            alternative = input$alternative, N = N
          ), effect_args()))
        } else if (input$design == "nested") {
          req(input$exposure_type, input$OR, input$nD, input$nH, input$R2)
          if (input$exposure_type == "binary") {
            req(input$pE)
            calc_case_control_nested_binary(
              OR = input$OR, pE = input$pE, nD = input$nD, nH = input$nH,
              R2 = input$R2, alpha = input$alpha, power = input$power
            )
          } else {
            req(input$sigma)
            calc_case_control_nested_continuous(
              OR = input$OR, sigma = input$sigma, nD = input$nD, nH = input$nH,
              R2 = input$R2, alpha = input$alpha, power = input$power
            )
          }
        } else {
          req(input$n_full, input$pD, input$p1, input$hr)
          calc_case_control_case_cohort(
            n = input$n_full, pD = input$pD, p1 = input$p1, hr = input$hr,
            alpha = input$alpha, power = input$power
          )
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
      if (res$design %in% c("unmatched", "matched")) {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Cases: %d, Controls: %d", v$n_case, v$n_control)),
          p(class = "text-muted small", sprintf("Odds ratio %.3f; proportion of cases exposed %.3f; of controls %s%s.", v$OR, v$p1,
                                                format(v$inputs$p0),
                                                if (res$design == "matched") sprintf("; phi %.3f", v$inputs$phi_coef) else ""))
        )
      } else if (res$design == "nested") {
        tagList(
          p(strong("Matched sets required: "), v$n_sets),
          p(sprintf("Total subjects: %d", v$n_total))
        )
      } else {
        tagList(
          p(strong("Required subcohort size: "), v$subcohort_n),
          p(sprintf("Out of a full cohort of %d", v$full_cohort_n))
        )
      }
    })

    render_export_handlers(output, result, function() case_control_content[[input$design]])

    # Power curves (ROADMAP P1 item 10): wired for the three designs with a
    # single scalar effect parameter (an odds/hazard ratio). "nested" has a
    # more complex R2/nD/nH structure and is left for a later batch, same
    # incremental rollout as items 8/9.
    render_power_curves(output, function() {
      if (input$design == "unmatched") {
        req(input$p0, input$ratio, input$alpha, input$power, input$alternative, isTRUE(result()$ok))
        N <- input$N
        if (is.null(N) || is.na(N)) N <- NULL
        list(
          calc_fn = calc_case_control_unmatched,
          args = list(p0 = input$p0, OR = result()$value$OR, power = input$power, ratio = input$ratio,
                       alpha = input$alpha, alternative = input$alternative, N = N),
          effect = list(param = "OR", values = curve_range_ratio(), label = "Odds ratio (OR)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "matched") {
        req(input$p0, input$ratio, input$alpha, input$power, input$alternative, isTRUE(result()$ok))
        N <- input$N
        if (is.null(N) || is.na(N)) N <- NULL
        list(
          calc_fn = calc_case_control_matched,
          args = list(p0 = input$p0, OR = result()$value$OR, phi_coef = result()$value$inputs$phi_coef, power = input$power,
                       ratio = input$ratio, alpha = input$alpha, alternative = input$alternative, N = N),
          effect = list(param = "OR", values = curve_range_ratio(), label = "Odds ratio (OR)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "case_cohort") {
        req(input$n_full, input$pD, input$p1, input$hr, input$alpha, input$power)
        list(
          calc_fn = calc_case_control_case_cohort,
          args = list(n = input$n_full, pD = input$pD, p1 = input$p1, hr = input$hr,
                       alpha = input$alpha, power = input$power),
          effect = list(param = "hr", values = curve_range_ratio(), label = "Hazard ratio (HR)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "nested") {
        req(input$exposure_type, input$OR, input$nD, input$nH, input$R2, input$alpha, input$power)
        if (input$exposure_type == "binary") {
          req(input$pE)
          list(
            calc_fn = calc_case_control_nested_binary,
            args = list(OR = input$OR, pE = input$pE, nD = input$nD, nH = input$nH,
                         R2 = input$R2, alpha = input$alpha, power = input$power),
            effect = list(param = "OR", values = curve_range_ratio(), label = "Odds ratio (OR)"),
            power = list(param = "power", values = curve_range_power())
          )
        } else {
          req(input$sigma)
          list(
            calc_fn = calc_case_control_nested_continuous,
            args = list(OR = input$OR, sigma = input$sigma, nD = input$nD, nH = input$nH,
                         R2 = input$R2, alpha = input$alpha, power = input$power),
            effect = list(param = "OR", values = curve_range_ratio(), label = "Odds ratio (OR)"),
            power = list(param = "power", values = curve_range_power())
          )
        }
      } else {
        NULL
      }
    })
  })
}
