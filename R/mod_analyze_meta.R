# Analyze: Meta-Analysis module (CHECKLIST WB-01): Calculate / Formula-Help / Reference sub-tabs, design-radio contract as in
# mod_analyze_mh.R (docs/SDD.md #8). Pools study results typed one per line (estimate with its confidence interval or standard
# error): fixed-effect and DerSimonian-Laird random-effects estimates, heterogeneity, a table of weights and a forest plot.

analyze_meta_meta <- list(
  id = "analyze_meta",
  nav_title = "Meta-Analysis (pooling study results)"
)

.meta_default_text <- c(
  ratio = "Study A, 0.75, 0.55, 1.02\nStudy B, 0.90, 0.70, 1.16\nStudy C, 0.62, 0.40, 0.96\nStudy D, 1.05, 0.80, 1.38",
  difference = "Trial 1, -2.1, 0.9\nTrial 2, -0.8, 0.7\nTrial 3, -3.0, 1.2"
)

mod_analyze_meta_ui <- function(id) {
  ns <- NS(id)
  help_block <- function(d) tagList(
    h4(analyze_meta_content[[d]]$title),
    render_formula_block(analyze_meta_content[[d]]$formula_latex),
    shiny::markdown(analyze_meta_content[[d]]$explanation),
    h5("Worked example"),
    shiny::markdown(analyze_meta_content[[d]]$worked_example))
  ref_block <- function(d) tagList(
    h4(analyze_meta_content[[d]]$title),
    p(strong("Citation: "), analyze_meta_content[[d]]$citation),
    p(strong("Implemented via: "), code(analyze_meta_content[[d]]$backend)))

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Pool the results of studies you already have. For planning a meta-analysis (number of studies, information size) use the",
        "calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What does each study report?",
        choices = c("A ratio: odds ratio, risk ratio, rate ratio or hazard ratio" = "ratio",
                    "A difference: mean difference, risk difference (or any estimate with a standard error)" = "difference"),
        selected = "ratio"
      ),
      textAreaInput(ns("studies"), "Studies, one per line: label, estimate, lower limit, upper limit -- or label, estimate, SE",
                    value = .meta_default_text[["ratio"]], rows = 7, width = "100%", resize = "vertical"),
      p(class = "text-muted small", "For a ratio given with a standard error, the SE is that of the log ratio."),
      numericInput(ns("ci_level"), "Confidence level of the studies' intervals as entered", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      numericInput(ns("conf_level"), "Confidence level of the pooled result", value = 0.95, min = 0.5, max = 0.999, step = 0.01),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      plotOutput(ns("forest"), height = "auto"),
      export_controls_ui(ns)
    ),
    tabPanel("Formula / Help", br(), help_block("ratio"), hr(), help_block("difference")),
    tabPanel("Reference", br(), ref_block("ratio"), hr(), ref_block("difference"))
  )
}

.meta_fmt <- function(x) formatC(x, digits = 3, format = "fg", flag = "#")

# The forest plot: one row per study (square sized by its random-effects weight, with its interval), then the two pooled
# estimates as diamonds. Ratios are drawn on a log axis. Colours from the page's light / dark palette.
.meta_forest <- function(v, pal) {
  s <- attr(v, "studies")
  ratio <- v$inputs$measure == "ratio"
  tr <- if (ratio) log else identity
  k <- nrow(s)
  rows <- c(rev(seq_len(k)) + 3, 2, 1)
  est <- c(s$estimate, v$fixed_estimate, v$random_estimate)
  lo <- c(s$lower, v$fixed_lower, v$random_lower)
  hi <- c(s$upper, v$fixed_upper, v$random_upper)
  labels <- c(s$label, "Fixed effect", "Random effects")
  null <- if (ratio) 1 else 0
  xlim <- range(tr(c(lo, hi, null)))
  xlim <- xlim + c(-1, 1) * 0.04 * diff(xlim)
  graphics::par(mar = c(4.2, max(8, 0.55 * max(nchar(labels)) + 1), 1, 1))
  graphics::plot(NA, xlim = xlim, ylim = c(0.4, k + 3.6), yaxt = "n", xaxt = "n", ylab = "", bty = "n",
                 xlab = if (ratio) "Ratio (log scale)" else "Difference")
  ticks <- if (ratio) { t <- grDevices::axisTicks(xlim / log(10), log = TRUE); t[tr(t) >= xlim[1] & tr(t) <= xlim[2]] } else graphics::axTicks(1)
  if (ratio && length(ticks) < 2) ticks <- signif(exp(pretty(xlim, 4)), 2)
  graphics::axis(1, at = tr(ticks), labels = ticks)
  graphics::axis(2, at = rows, labels = labels, las = 1, tick = FALSE, line = -0.5)
  graphics::abline(v = tr(null), lty = 2, col = pal$muted)
  graphics::abline(h = 2.9, col = pal$grey)
  i <- seq_len(k)
  graphics::segments(tr(lo[i]), rows[i], tr(hi[i]), rows[i], col = pal$line, lwd = 1.5)
  graphics::points(tr(est[i]), rows[i], pch = 15, col = pal$line, cex = 0.7 + 1.8 * sqrt(s$weight_random / max(s$weight_random)))
  for (j in k + 1:2) {
    graphics::polygon(tr(c(lo[j], est[j], hi[j], est[j])), rows[j] + c(0, 0.28, 0, -0.28), col = pal$accent, border = pal$accent)
  }
  invisible()
}

mod_analyze_meta_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # switching the kind of estimate loads that kind's example, unless the box holds the user's own studies
    observeEvent(input$design, {
      if (trimws(if (is.null(input$studies)) "" else input$studies) %in% c("", trimws(unname(.meta_default_text)))) {
        updateTextAreaInput(session, "studies", value = .meta_default_text[[input$design]])
      }
    }, ignoreInit = TRUE)

    result <- reactive({
      req(input$design, input$conf_level, input$ci_level)
      tryCatch({
        st <- .meta_parse_studies(input$studies)
        list(ok = TRUE, design = input$design, value = calc_analyze_meta(
          estimate = st$estimate, lower = st$lower, upper = st$upper, se = st$se, measure = input$design,
          labels = st$labels, ci_level = input$ci_level, conf_level = input$conf_level))
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      s <- attr(v, "studies")
      lvl <- sprintf("%.0f%%", 100 * v$inputs$conf_level)
      ci <- function(e, l, u) sprintf("%s (%s to %s)", .meta_fmt(e), .meta_fmt(l), .meta_fmt(u))
      tagList(
        tags$table(class = "table table-sm w-auto",
          tags$caption(class = "visually-hidden", "Pooled estimates"),
          tags$thead(tags$tr(tags$th(scope = "col", "Model"), tags$th(scope = "col", paste0("Pooled estimate (", lvl, " CI)")),
                             tags$th(scope = "col", "p"))),
          tags$tbody(
            tags$tr(tags$th(scope = "row", "Fixed effect"), tags$td(ci(v$fixed_estimate, v$fixed_lower, v$fixed_upper)), tags$td(.fmt_p(v$fixed_p))),
            tags$tr(tags$th(scope = "row", "Random effects (DerSimonian-Laird)"),
                    tags$td(ci(v$random_estimate, v$random_lower, v$random_upper)), tags$td(.fmt_p(v$random_p))))),
        p(strong("Heterogeneity: "), sprintf("Q = %.2f on %d df, p = %s; I-squared = %.1f%%; tau-squared = %s.",
                                             v$Q, v$Q_df, .fmt_p(v$Q_p), v$I2, .meta_fmt(v$tau2))),
        if (v$k < 5) p(class = "text-muted small", sprintf(
          "With %d studies the between-study variance is poorly estimated: treat the random-effects interval as optimistic.", v$k)),
        tags$table(class = "table table-sm w-auto",
          tags$caption(class = "visually-hidden", "Studies and their weights"),
          tags$thead(tags$tr(tags$th(scope = "col", "Study"), tags$th(scope = "col", paste0("Estimate (", lvl, " CI)")),
                             tags$th(scope = "col", "Weight, fixed"), tags$th(scope = "col", "Weight, random"))),
          tags$tbody(lapply(seq_len(nrow(s)), function(i) tags$tr(
            tags$th(scope = "row", s$label[i]), tags$td(ci(s$estimate[i], s$lower[i], s$upper[i])),
            tags$td(sprintf("%.1f%%", s$weight_fixed[i])), tags$td(sprintf("%.1f%%", s$weight_random[i]))))))
      )
    })

    output$forest <- renderPlot({
      res <- result()
      req(res$ok)
      st <- .plot_start()
      on.exit(graphics::par(st$op))
      .meta_forest(res$value, st$pal)
    }, res = 96, height = function() { res <- result(); if (isTRUE(res$ok)) 150 + 26 * (res$value$k + 2) else 1 },
    alt = function() {
      res <- result()
      req(res$ok)
      v <- res$value
      sprintf(paste0("Forest plot of %d studies with their confidence intervals and two pooled estimates. Fixed effect: %s (%s to %s). ",
                     "Random effects: %s (%s to %s). The dashed line marks no effect (%s). The table above gives every study's figures."),
              v$k, .meta_fmt(v$fixed_estimate), .meta_fmt(v$fixed_lower), .meta_fmt(v$fixed_upper),
              .meta_fmt(v$random_estimate), .meta_fmt(v$random_lower), .meta_fmt(v$random_upper),
              if (v$inputs$measure == "ratio") "a ratio of 1" else "a difference of 0")
    })

    render_export_handlers(output, result, function() analyze_meta_content[[input$design]])
  })
}
