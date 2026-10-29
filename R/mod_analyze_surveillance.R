# Analyze: Aberration Detection module (ROADMAP Track B4, item 20): Calculate / Formula-Help / Reference sub-tabs,
# design-radio contract as in mod_rate.R (docs/SDD.md #8). "ears": EARS C1, C2, C3; "cusum": normal or Poisson CUSUM.
# The input is a pasted series of counts in time order; the plot is base R graphics.

analyze_surveillance_meta <- list(
  id = "analyze_surveillance",
  nav_title = "Aberration Detection"
)

.surv_default_counts <- "4 0 5 1 2 9 2 4 8 2 3 5 8 7 6 5 5 4 3 5 3 6 4 4 2 5 4 1 3 4 12 11 15 9 21 4 12 11"

mod_analyze_surveillance_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted", "Detect an unusual rise in a series of counts you paste in (daily or weekly cases, in time order). A signal is a prompt to investigate, not a finding."),
      radioButtons(
        ns("design"), "Method",
        choices = c("EARS C1, C2, C3 (compare with the last few days)" = "ears",
                    "CUSUM (accumulates small excesses; normal or Poisson form)" = "cusum"),
        selected = "ears"
      ),
      textAreaInput(ns("counts"), "Counts in time order (spaces, commas or new lines)", value = .surv_default_counts, rows = 4, width = "100%"),
      conditionalPanel(
        condition = design_is("ears"),
        selectInput(ns("ears_method"), "Method", choices = c("C1" = "C1", "C2 (2-day gap)" = "C2", "C3 (sum of recent excesses)" = "C3"), selected = "C2"),
        numericInput(ns("ears_baseline"), "Baseline length (observations before each day)", value = 7, min = 3, step = 1),
        numericInput(ns("ears_threshold"), "Signal threshold (empty = 3, or 2 for C3)", value = NA, min = 0.1, step = 0.1),
        numericInput(ns("ears_min_sd"), "Smallest baseline SD allowed (0 = none)", value = 0, min = 0, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("cusum"),
        selectInput(ns("cusum_type"), "Form", choices = c("Normal (standardized counts)" = "normal", "Poisson (small counts)" = "poisson"), selected = "normal"),
        numericInput(ns("cusum_baseline"), "Baseline period (first observations, not monitored)", value = 14, min = 3, step = 1),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'normal'", ns("cusum_type")),
          numericInput(ns("cusum_k"), "Reference value k (in SD units)", value = 0.5, min = 0, step = 0.1)
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'poisson'", ns("cusum_type")),
          numericInput(ns("cusum_ratio"), "Rise to detect (out-of-control mean as a multiple of the usual mean)", value = 2, min = 1.01, step = 0.1)
        ),
        numericInput(ns("cusum_h"), "Decision threshold h (SD units for normal, cases for Poisson)", value = 4, min = 0.1, step = 0.5),
        checkboxInput(ns("cusum_reset"), "Restart at 0 after a signal", value = TRUE)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      plotOutput(ns("plot"), height = "380px"),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      lapply(c("ears", "cusum"), function(d) {
        x <- analyze_surveillance_content[[d]]
        tagList(h4(x$title), render_formula_block(x$formula_latex), shiny::markdown(x$explanation),
                h5("Worked example"), shiny::markdown(x$worked_example), hr())
      })
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(analyze_surveillance_content$ears$citation),
      hr(),
      p(strong("Implemented via: "), code(analyze_surveillance_content$ears$backend))
    )
  )
}

mod_analyze_surveillance_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)
      tryCatch({
        x <- suppressWarnings(as.numeric(strsplit(trimws(input$counts), "[,;[:space:]]+")[[1]]))
        if (length(x) == 0 || anyNA(x)) stop("Enter counts as numbers separated by spaces, commas or new lines.")
        value <- if (input$design == "ears") {
          req(input$ears_method, input$ears_baseline, !is.null(input$ears_min_sd))
          thr <- if (is.null(input$ears_threshold) || is.na(input$ears_threshold)) NULL else input$ears_threshold
          calc_surveillance_ears(x, input$ears_method, input$ears_baseline, thr, if (is.na(input$ears_min_sd)) 0 else input$ears_min_sd)
        } else {
          req(input$cusum_type, input$cusum_baseline, input$cusum_h)
          calc_surveillance_cusum(x, input$cusum_type, input$cusum_baseline,
                                  k = if (is.null(input$cusum_k) || is.na(input$cusum_k)) 0.5 else input$cusum_k, h = input$cusum_h,
                                  shift_ratio = if (is.null(input$cusum_ratio) || is.na(input$cusum_ratio)) 2 else input$cusum_ratio,
                                  reset = isTRUE(input$cusum_reset))
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      s <- attr(v, "series")
      g <- function(x, d = 4) formatC(x, digits = d, format = "fg", flag = "#")
      tagList(
        h5(sprintf("%s: %d signal%s in %d monitored observations", v$method, v$n_alarms, if (v$n_alarms == 1) "" else "s", v$n_monitored)),
        if (v$n_alarms > 0) p(sprintf("Signal on observation%s %s (the first is observation %d).", if (v$n_alarms == 1) "" else "s",
                                      paste(utils::head(which(s$alarm), 40), collapse = ", "), v$first_alarm))
        else p("No signal."),
        if (res$design == "cusum") p(sprintf("Usual level (baseline mean) %s%s; reference value %s; threshold %s.", g(v$baseline_mean),
                                             if (is.na(v$baseline_sd)) "" else sprintf(", SD %s", g(v$baseline_sd)), g(v$reference_value), g(v$threshold)))
        else p(sprintf("Baseline %d observations; threshold %s.", v$baseline, g(v$threshold))),
        if (!is.null(v$n_undefined) && v$n_undefined > 0) div(class = "text-warning", sprintf("%d observation%s could not be assessed because the baseline had no variation (set a smallest SD).", v$n_undefined, if (v$n_undefined == 1) "" else "s")),
        div(class = "text-muted", "A signal is a prompt to look at the data and the cause, not a finding. Seasonal or day-of-week patterns are not modelled; the usual false-signal rate depends on the threshold.")
      )
    })

    output$plot <- renderPlot({
      res <- result()
      req(res$ok)
      s <- attr(res$value, "series")
      op <- graphics::par(mfrow = c(2, 1), mar = c(3.2, 4.2, 2, 1), mgp = c(2.2, 0.7, 0))
      on.exit(graphics::par(op))
      al <- s$alarm
      graphics::plot(s$t, s$count, type = "h", lwd = 3, col = ifelse(al, "#C0392B", "#7F8C8D"), xlab = "", ylab = "Count", main = "Counts (signals in red)")
      graphics::points(s$t[al], s$count[al], pch = 19, col = "#C0392B")
      graphics::plot(s$t, s$statistic, type = "b", pch = 16, cex = 0.6, col = "#2C3E50", xlab = "Observation", ylab = "Statistic", main = "Detection statistic and threshold")
      graphics::abline(h = s$threshold[1], lty = 2, col = "#C0392B")
      graphics::points(s$t[al], s$statistic[al], pch = 19, col = "#C0392B")
    }, res = 96, alt = function() {
      res <- result()
      req(res$ok)
      v <- res$value; s <- attr(v, "series")
      sprintf(paste0("Two charts over %d observations. Top: the count at each observation, with signals in red; %s. ",
                     "Bottom: the detection statistic at each observation against a dashed threshold of %s; a signal is a point above the threshold."),
              nrow(s), if (v$n_alarms == 0) "there are no signals" else sprintf("there %s %d signal%s, the first at observation %d",
                                                                            if (v$n_alarms == 1) "is" else "are", v$n_alarms, if (v$n_alarms == 1) "" else "s", v$first_alarm),
              format(signif(v$threshold, 3)))
    })

    render_export_handlers(output, result, function() analyze_surveillance_content[[input$design]])
  })
}
