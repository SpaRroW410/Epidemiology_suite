# Group Sequential Design module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_tost.R (docs/SDD.md
# #8) -- three outcome-type designs (continuous, binary, survival) sharing
# a common set of interim-monitoring inputs (number of looks, boundary
# shape, futility, allocation ratio, alpha/power/alternative).

group_sequential_meta <- list(
  id = "group_sequential",
  nav_title = "Group Sequential Design"
)

mod_group_sequential_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Outcome type / boundary method",
        choices = c(
          "Continuous (means), power-family boundary" = "normal",
          "Binary (proportions), power-family boundary" = "binary",
          "Time-to-event (survival), power-family boundary" = "survival",
          "Continuous (means), Lan-DeMets alpha spending (2 looks)" = "lan_demets_normal"
        ),
        selected = "normal"
      ),
      conditionalPanel(
        condition = design_is("normal"),
        numericInput(ns("delta_normal"), "Assumed difference in means (delta)", value = 0.25),
        numericInput(ns("sd_normal"), "Common standard deviation (SD)", value = 1, min = 0.0001)
      ),
      conditionalPanel(
        condition = design_is("binary"),
        numericInput(ns("pC_binary"), "pC (control-arm event/response probability)",
                     value = 0.30, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("pE_binary"), "pE (experimental-arm event/response probability)",
                     value = 0.50, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("survival"),
        numericInput(ns("hr_survival"), "Assumed hazard ratio (experimental vs. control)",
                     value = 0.5, min = 0.001, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("lan_demets_normal"),
        numericInput(ns("delta_ld"), "Assumed difference in means (delta)", value = 0.5),
        numericInput(ns("sd_ld"), "Common standard deviation (SD)", value = 1, min = 0.0001),
        sliderInput(ns("timing_ld"), "Interim look timing (information fraction)",
                    value = 0.5, min = 0.05, max = 0.95, step = 0.05),
        radioButtons(ns("spending_ld"), "Spending function",
                     choices = c("O'Brien-Fleming-type" = "OF", "Pocock-type" = "Pocock"),
                     selected = "OF")
      ),
      hr(),
      conditionalPanel(
        condition = paste0("!(", design_is("lan_demets_normal"), ")"),
        selectInput(ns("n_looks"), "Number of planned analyses (including the final one)",
                    choices = 1:6, selected = 4),
        sliderInput(ns("boundary_shape"), "Boundary shape (0 = Pocock, 0.5 = O'Brien-Fleming)",
                    value = 0.5, min = 0, max = 0.5, step = 0.05),
        checkboxInput(ns("futility"), "Include a (non-binding) futility boundary", value = TRUE),
        selectInput(ns("alternative"), "Alternative hypothesis",
                    choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"))
      ),
      numericInput(ns("r"), "Allocation ratio, experimental:control (r)", value = 1, min = 0.01, step = 0.1),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns),
      conditionalPanel(
        condition = design_is("lan_demets_normal"),
        hr(),
        checkboxInput(ns("has_interim"), "I have an observed interim result -- compute conditional power / SSR", value = FALSE),
        conditionalPanel(
          condition = sprintf("input['%s']", ns("has_interim")),
          numericInput(ns("z1_interim"), "Observed interim Z-statistic", value = 1.5, step = 0.1),
          numericInput(ns("target_cp"), "Target conditional power for re-estimation", value = 0.9, min = 0.5, max = 0.999, step = 0.01),
          numericInput(ns("maxinc"), "Maximum fold-increase in sample size allowed", value = 3, min = 1.1, step = 0.5),
          h5("Interim result"),
          uiOutput(ns("interim_result"))
        )
      )
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(group_sequential_content$normal$title),
      render_formula_block(group_sequential_content$normal$formula_latex),
      shiny::markdown(group_sequential_content$normal$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$normal$worked_example),
      hr(),
      h4(group_sequential_content$binary$title),
      render_formula_block(group_sequential_content$binary$formula_latex),
      shiny::markdown(group_sequential_content$binary$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$binary$worked_example),
      hr(),
      h4(group_sequential_content$survival$title),
      render_formula_block(group_sequential_content$survival$formula_latex),
      shiny::markdown(group_sequential_content$survival$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$survival$worked_example),
      hr(),
      h4(group_sequential_content$lan_demets_normal$title),
      render_formula_block(group_sequential_content$lan_demets_normal$formula_latex),
      shiny::markdown(group_sequential_content$lan_demets_normal$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$lan_demets_normal$worked_example),
      hr(),
      h4(group_sequential_content$conditional_power_ssr$title),
      render_formula_block(group_sequential_content$conditional_power_ssr$formula_latex),
      shiny::markdown(group_sequential_content$conditional_power_ssr$explanation),
      h5("Worked example"),
      shiny::markdown(group_sequential_content$conditional_power_ssr$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(group_sequential_content$normal$title),
      p(strong("Citation: "), group_sequential_content$normal$citation),
      p(strong("Implemented via: "), code(group_sequential_content$normal$backend)),
      hr(),
      h4(group_sequential_content$binary$title),
      p(strong("Citation: "), group_sequential_content$binary$citation),
      p(strong("Implemented via: "), code(group_sequential_content$binary$backend)),
      hr(),
      h4(group_sequential_content$survival$title),
      p(strong("Citation: "), group_sequential_content$survival$citation),
      p(strong("Implemented via: "), code(group_sequential_content$survival$backend)),
      hr(),
      h4(group_sequential_content$lan_demets_normal$title),
      p(strong("Citation: "), group_sequential_content$lan_demets_normal$citation),
      p(strong("Implemented via: "), code(group_sequential_content$lan_demets_normal$backend)),
      hr(),
      h4(group_sequential_content$conditional_power_ssr$title),
      p(strong("Citation: "), group_sequential_content$conditional_power_ssr$citation),
      p(strong("Implemented via: "), code(group_sequential_content$conditional_power_ssr$backend))
    )
  )
}

mod_group_sequential_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design, input$r, input$alpha, input$power)

      if (input$design == "lan_demets_normal") {
        req(input$delta_ld, input$sd_ld, input$timing_ld, input$spending_ld)
        return(tryCatch(
          list(ok = TRUE, value = calc_lan_demets_normal(
            delta = input$delta_ld, sd = input$sd_ld, timing = input$timing_ld,
            r = input$r, alpha = input$alpha, power = input$power,
            spending = input$spending_ld
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        ))
      }

      req(input$n_looks, input$boundary_shape, input$alternative)
      n_looks <- as.integer(input$n_looks)

      if (input$design == "normal") {
        req(input$delta_normal, input$sd_normal)
        tryCatch(
          list(ok = TRUE, value = calc_group_sequential_normal(
            delta = input$delta_normal, sd = input$sd_normal, n_looks = n_looks,
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative, boundary_shape = input$boundary_shape,
            futility = input$futility
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "binary") {
        req(input$pC_binary, input$pE_binary)
        tryCatch(
          list(ok = TRUE, value = calc_group_sequential_binary(
            pC = input$pC_binary, pE = input$pE_binary, n_looks = n_looks,
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative, boundary_shape = input$boundary_shape,
            futility = input$futility
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$hr_survival)
        tryCatch(
          list(ok = TRUE, value = calc_group_sequential_survival(
            haz_ratio = input$hr_survival, n_looks = n_looks,
            r = input$r, alpha = input$alpha, power = input$power,
            alternative = input$alternative, boundary_shape = input$boundary_shape,
            futility = input$futility
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value

      if (input$design == "lan_demets_normal") {
        return(tagList(
          p(strong("Maximum total sample size: "), v$n_total),
          p(sprintf("Per arm: control = %d, experimental = %d", v$n_control, v$n_experimental)),
          p(strong("Interim boundary (Z-scale): "), round(v$boundary_interim, 3)),
          p(strong("Final boundary (Z-scale): "), round(v$boundary_final, 3)),
          p(sprintf("Cumulative alpha spent: %.5f at the interim, %.4f at the final look",
                     v$alpha_spent[1], v$alpha_spent[2])),
          p(sprintf("Sample-size inflation vs. a single-look fixed design: %.1f%%",
                     (v$inflation_factor - 1) * 100))
        ))
      }

      boundary_rows <- tagList(
        p(strong("Information fraction: "), paste(round(v$ifrac, 3), collapse = ", ")),
        p(strong("Efficacy boundary (Z-scale): "), paste(round(v$efficacy_boundary, 3), collapse = ", "))
      )
      if (!is.null(v$futility_boundary)) {
        boundary_rows <- tagList(
          boundary_rows,
          p(strong("Futility boundary (Z-scale): "), paste(round(v$futility_boundary, 3), collapse = ", "))
        )
      }

      if (input$design == "survival") {
        tagList(
          p(strong("Maximum required number of events: "), v$n_events_total),
          boundary_rows,
          p(class = "text-muted", "Convert to enrolled subjects using a separate accrual/censoring assumption.")
        )
      } else {
        tagList(
          p(strong("Maximum total sample size: "), v$n_total),
          p(sprintf("Per arm: control = %d, experimental = %d", v$n_control, v$n_experimental)),
          boundary_rows
        )
      }
    })

    interim_result <- reactive({
      req(input$design == "lan_demets_normal", isTRUE(input$has_interim))
      res <- result()
      req(res$ok)
      req(input$z1_interim, input$target_cp, input$maxinc)

      v <- res$value
      tryCatch(
        list(ok = TRUE, value = calc_ssr_normal(
          z1 = input$z1_interim, timing = v$inputs$timing, n_max = v$n_total,
          boundary_final = v$boundary_final, target_power = input$target_cp,
          maxinc = input$maxinc
        )),
        error = function(e) list(ok = FALSE, message = conditionMessage(e))
      )
    })

    output$interim_result <- renderUI({
      res <- interim_result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      tagList(
        p(strong("Observed trend (theta): "), round(v$theta, 4)),
        p(strong("Conditional power at the originally planned sample size: "),
          sprintf("%.1f%%", v$conditional_power_at_planned_n * 100)),
        if (v$adapted) {
          tagList(
            p(class = "text-success",
              sprintf("Recommendation: increase the total sample size to %d (%d more participants beyond the interim).",
                       v$n_total_new, v$n_remaining)),
            p(class = "text-muted", "This uses a fixed-weight inverse-normal combination test at the final analysis to preserve the type-I error -- do not simply re-test the pooled data at the new size with the original test statistic.")
          )
        } else {
          p(class = "text-muted", "No sample-size adaptation recommended (the trend is non-positive, or conditional power at the planned size is already outside the adaptation window) -- keep the originally planned sample size.")
        }
      )
    })

    render_export_handlers(output, result, function() group_sequential_content[[input$design]])

    # Power curves (ROADMAP P1 item 10): all four designs. The three
    # power-family designs measured ~140ms/call (boundary computation), so
    # they use a 12-point grid (~1.7s per curve) instead of 40; the
    # Lan-DeMets 2-look design is fast (~14ms/call) and keeps the full grid.
    render_power_curves(output, function() {
      req(input$design, input$r, input$alpha, input$power)
      if (input$design == "lan_demets_normal") {
        req(input$delta_ld, input$sd_ld, input$timing_ld, input$spending_ld)
        return(list(
          calc_fn = calc_lan_demets_normal,
          args = list(delta = input$delta_ld, sd = input$sd_ld, timing = input$timing_ld,
                       r = input$r, alpha = input$alpha, power = input$power,
                       spending = input$spending_ld),
          effect = list(param = "delta", values = curve_range_multiplicative(abs(input$delta_ld)),
                        label = "delta (difference in means)"),
          power = list(param = "power", values = curve_range_power())
        ))
      }

      req(input$n_looks, input$boundary_shape, input$alternative)
      n_looks <- as.integer(input$n_looks)
      power_axis <- list(param = "power", values = curve_range_power(n = 12))
      if (input$design == "normal") {
        req(input$delta_normal, input$sd_normal)
        list(
          calc_fn = calc_group_sequential_normal,
          args = list(delta = input$delta_normal, sd = input$sd_normal, n_looks = n_looks,
                       r = input$r, alpha = input$alpha, power = input$power,
                       alternative = input$alternative, boundary_shape = input$boundary_shape,
                       futility = input$futility),
          effect = list(param = "delta", values = curve_range_around(0, 3 * abs(input$delta_normal), n = 12),
                        label = "delta (difference in means)"),
          power = power_axis
        )
      } else if (input$design == "binary") {
        req(input$pC_binary, input$pE_binary)
        list(
          calc_fn = calc_group_sequential_binary,
          args = list(pC = input$pC_binary, pE = input$pE_binary, n_looks = n_looks,
                       r = input$r, alpha = input$alpha, power = input$power,
                       alternative = input$alternative, boundary_shape = input$boundary_shape,
                       futility = input$futility),
          effect = list(param = "pE", values = curve_range_proportion(n = 12),
                        label = "pE (experimental-arm probability)"),
          power = power_axis
        )
      } else {
        req(input$hr_survival)
        list(
          calc_fn = calc_group_sequential_survival,
          args = list(haz_ratio = input$hr_survival, n_looks = n_looks,
                       r = input$r, alpha = input$alpha, power = input$power,
                       alternative = input$alternative, boundary_shape = input$boundary_shape,
                       futility = input$futility),
          effect = list(param = "haz_ratio", values = curve_range_ratio(n = 12), label = "Hazard ratio"),
          power = power_axis
        )
      }
    })
  })
}
