# Interrupted Time Series module: Calculate / Formula-Help / Reference sub-tabs. Two designs (change in level, change in slope) of a
# segmented regression with AR(1) errors, each solved for the number of time points or for the power with the time points you have.
# Follows the design-radio pattern of mod_mendelian.R (docs/SDD.md #8).

its_meta <- list(
  id = "its",
  nav_title = "Interrupted Time Series"
)

mod_its_ui <- function(id) {
  ns <- NS(id)
  solve_is <- function(value) sprintf("input['%s'] == '%s'", ns("solve"), value)
  help_block <- function(d) tagList(
    h4(its_content[[d]]$title),
    render_formula_block(its_content[[d]]$formula_latex),
    shiny::markdown(its_content[[d]]$explanation),
    h5("Worked example"),
    shiny::markdown(its_content[[d]]$worked_example))
  ref_block <- function(d) tagList(
    h4(its_content[[d]]$title),
    p(strong("Citation: "), its_content[[d]]$citation),
    p(strong("Implemented via: "), code(its_content[[d]]$backend)))

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Change to detect at the interruption",
        choices = c("A change in level: an immediate, lasting step" = "level",
                    "A change in slope: the trend afterwards differs from the trend before" = "slope"),
        selected = "level"
      ),
      radioButtons(
        ns("solve"), "Find",
        choices = c("Time points needed (for a chosen power)" = "n", "Power (for the time points you have)" = "power"),
        selected = "n"
      ),
      numericInput(ns("effect"), "Change to detect (units of the outcome; for a slope, units per time point)", value = 2, step = 0.1),
      numericInput(ns("sd"), "SD of the series around its trend", value = 1.5, min = 0.0001, step = 0.1),
      numericInput(ns("rho"), "Autocorrelation between neighbouring time points (rho; 0 if independent)", value = 0.3,
                   min = -0.99, max = 0.99, step = 0.05),
      conditionalPanel(
        condition = solve_is("n"),
        numericInput(ns("pre_fraction"), "Share of the time points before the interruption (0.5 = midpoint)", value = 0.5,
                     min = 0.05, max = 0.95, step = 0.05),
        numericInput(ns("power"), "Power", value = 0.8, min = 0.5, max = 0.999, step = 0.05)
      ),
      conditionalPanel(
        condition = solve_is("power"),
        numericInput(ns("n_pre"), "Time points before the interruption", value = 24, min = 3, step = 1),
        numericInput(ns("n_post"), "Time points after the interruption", value = 24, min = 3, step = 1)
      ),
      numericInput(ns("alpha"), "Significance level (two-sided)", value = 0.05, min = 0.0001, max = 0.5, step = 0.01),
      checkboxInput(ns("baseline_trend"), "Baseline trend in the model (the series may rise or fall before the interruption)", value = TRUE),
      checkboxInput(ns("both_changes"), "Level and slope change estimated together (the usual segmented regression)", value = TRUE),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel("Formula / Help", br(), help_block("level"), hr(), help_block("slope")),
    tabPanel("Reference", br(), ref_block("level"), hr(), ref_block("slope"))
  )
}

mod_its_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    spec <- reactive({
      req(input$design, input$solve, input$effect, input$sd, input$alpha)
      req(!is.null(input$rho), !is.na(input$rho))
      common <- list(effect = input$effect, effect_type = input$design, sd = input$sd, rho = input$rho, alpha = input$alpha,
                     baseline_trend = isTRUE(input$baseline_trend), both_changes = isTRUE(input$both_changes))
      if (input$solve == "n") {
        req(input$power, input$pre_fraction)
        list(fn = calc_its_n, args = c(common, list(power = input$power, pre_fraction = input$pre_fraction)))
      } else {
        req(input$n_pre, input$n_post)
        list(fn = calc_its_power, args = c(list(n_pre = input$n_pre, n_post = input$n_post), common))
      }
    })

    result <- reactive({
      s <- spec()
      tryCatch(list(ok = TRUE, value = do.call(s$fn, s$args)),
               error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      pw <- sprintf("%.1f%%", 100 * v$achieved_power)
      pts <- sprintf("%s time points (%s before the interruption, %s after)", v$n_total, v$n_pre, v$n_post)
      tagList(
        if (input$solve == "n") tagList(p(strong("Time points needed: "), pts), p(class = "text-muted", "Power at that length: ", pw))
        else tagList(p(strong("Power: "), pw), p(class = "text-muted", paste0("With ", pts, "."))),
        p(class = "text-muted", sprintf("Standard error of the change: %s.", format(signif(v$se, 3)))),
        if (v$n_total < 50) div(class = "alert alert-warning small", role = "status",
          "Fewer than 50 time points: the autocorrelation cannot be estimated well from so short a series, and fitted tests then ",
          "reject too often when nothing changed. Treat this power as a rough guide.")
      )
    })

    render_export_handlers(output, result, function() its_content[[input$design]])

    # Curves (time points solved for only): time points against the autocorrelation, and against power.
    render_power_curves(output, function() {
      s <- spec()
      if (input$solve != "n") return(NULL)
      list(
        calc_fn = s$fn, args = s$args,
        effect = list(param = "rho", values = curve_range_within(0, 0.8), label = "Autocorrelation (rho)",
                      title = "Required time points vs. autocorrelation"),
        power = list(param = "power", values = curve_range_power())
      )
    })
  })
}
