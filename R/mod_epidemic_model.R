# Epidemic Models and Herd Immunity module (ROADMAP Track B5, item 20): Calculate / Formula-Help / Reference sub-tabs,
# design-radio contract as in mod_rate.R (docs/SDD.md #8). "herd": herd-immunity threshold and coverage needed;
# "sim": SIR / SEIR epidemic with vaccination (base R Runge-Kutta, plotted); "r0": R0 from a growth rate or final size.

epidemic_model_meta <- list(
  id = "epidemic_model",
  nav_title = "Epidemic Models and Herd Immunity"
)

mod_epidemic_model_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted", "Textbook models for teaching and rough planning (random mixing, closed population, constant rates). They show how the quantities relate; they do not forecast a real epidemic."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c("Herd-immunity threshold and vaccination coverage needed" = "herd",
                    "Simulate an SIR / SEIR epidemic with vaccination" = "sim",
                    "Estimate R0 from a growth rate or a final attack fraction" = "r0"),
        selected = "herd"
      ),
      conditionalPanel(
        condition = sprintf("input['%s'] != 'r0'", ns("design")),
        numericInput(ns("r0"), "R0 (basic reproduction number)", value = 12, min = 0.1, max = 50, step = 0.1),
        numericInput(ns("efficacy"), "Vaccine efficacy against infection (0-1)", value = 0.95, min = 0.01, max = 1, step = 0.01),
        numericInput(ns("coverage"), "Vaccination coverage (0-1)", value = 0.9, min = 0, max = 1, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("sim"),
        numericInput(ns("infectious"), "Mean infectious period (days)", value = 7, min = 0.5, step = 0.5),
        numericInput(ns("latent"), "Mean latent period (days; 0 = SIR model)", value = 0, min = 0, step = 0.5),
        numericInput(ns("population"), "Population size", value = 100000, min = 10, step = 1000),
        numericInput(ns("seed_cases"), "Infectious people at the start", value = 10, min = 1, step = 1),
        numericInput(ns("days"), "Days to simulate (up to 1825)", value = 365, min = 10, max = 1825, step = 5)
      ),
      conditionalPanel(
        condition = design_is("r0"),
        radioButtons(ns("r0_method"), "Estimate from", choices = c("Growth rate or doubling time (early phase)" = "growth", "Final attack fraction (completed epidemic)" = "final_size"), selected = "growth"),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'growth'", ns("r0_method")),
          numericInput(ns("doubling"), "Doubling time (days)", value = 3, min = 0.1, step = 0.1),
          numericInput(ns("r0_infectious"), "Mean infectious period (days)", value = 5, min = 0.5, step = 0.5),
          numericInput(ns("r0_latent"), "Mean latent period (days; 0 = SIR form)", value = 0, min = 0, step = 0.5)
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'final_size'", ns("r0_method")),
          numericInput(ns("final_attack"), "Share of the whole population infected over the whole epidemic (0-1)", value = 0.8, min = 0.001, max = 0.999, step = 0.01),
          numericInput(ns("immune_share"), "Share immune before the epidemic (0-1)", value = 0, min = 0, max = 0.99, step = 0.01)
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      conditionalPanel(condition = design_is("sim"), plotOutput(ns("plot"), height = "380px")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      lapply(c("herd", "sim", "r0"), function(d) {
        x <- epidemic_model_content[[d]]
        tagList(h4(x$title), render_formula_block(x$formula_latex), shiny::markdown(x$explanation),
                h5("Worked example"), shiny::markdown(x$worked_example), hr())
      })
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(epidemic_model_content$herd$citation),
      hr(),
      p(strong("Implemented via: "), code(epidemic_model_content$sim$backend))
    )
  )
}

mod_epidemic_model_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)
      tryCatch({
        value <- switch(input$design,
          herd = { req(input$r0, input$efficacy, !is.null(input$coverage)); calc_herd_immunity(input$r0, input$efficacy, if (is.na(input$coverage)) NULL else input$coverage) },
          sim = {
            req(input$r0, input$infectious, input$population, input$seed_cases, input$days, input$efficacy, !is.null(input$coverage), !is.null(input$latent))
            calc_epidemic_sim(input$r0, input$infectious, input$latent, if (is.na(input$coverage)) 0 else input$coverage, input$efficacy,
                              input$population, input$seed_cases, input$days)
          },
          r0 = {
            req(input$r0_method)
            if (input$r0_method == "growth") {
              req(input$doubling, input$r0_infectious, !is.null(input$r0_latent))
              calc_r0_estimate("growth", doubling_time = input$doubling, infectious_period = input$r0_infectious, latent_period = input$r0_latent)
            } else {
              req(input$final_attack, !is.null(input$immune_share))
              calc_r0_estimate("final_size", final_attack = input$final_attack, immune_share = input$immune_share)
            }
          })
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      pct <- function(x) sprintf("%.1f%%", 100 * x)
      g <- function(x, d = 4) formatC(x, digits = d, format = "fg", flag = "#")
      switch(res$design,
        herd = tagList(
          h5(sprintf("Herd-immunity threshold %s", pct(v$herd_immunity_threshold))),
          p(if (v$attainable == 1) sprintf("Coverage needed with this vaccine: %s.", pct(v$coverage_needed))
            else sprintf("Coverage needed would be %s: vaccination alone cannot reach the threshold with this efficacy.", pct(v$coverage_needed))),
          if (!is.null(v$coverage)) tagList(
            p(sprintf("At %s coverage %s are immune; effective reproduction number Re = %s (%s).", pct(v$coverage), pct(v$immune_share), g(v$effective_r0),
                      if (v$above_threshold == 1) "below 1: an introduced case does not start an epidemic" else "1 or more: outbreaks are still possible")),
            p(sprintf("Share of the whole population eventually infected after one introduction: %s with this coverage, %s with none.", pct(v$final_attack_rate), pct(v$final_attack_rate_no_vaccination)))
          ),
          div(class = "text-muted", "Assumes random mixing and evenly spread immunity; clusters of unvaccinated people raise the real threshold.")
        ),
        sim = tagList(
          h5(sprintf("%s epidemic: %s of the population infected (%s people)", v$model, pct(v$final_size_fraction), format(round(v$final_size_cases), big.mark = ","))),
          tags$table(class = "table table-sm", tags$tbody(
            tags$tr(tags$td("Effective reproduction number at the start"), tags$td(g(v$effective_r0))),
            tags$tr(tags$td("Peak number infectious"), tags$td(sprintf("%s on day %d", format(round(v$peak_infectious), big.mark = ","), v$peak_day))),
            tags$tr(tags$td("Early growth rate per day; doubling time"), tags$td(sprintf("%s; %s", g(v$growth_rate, 3), if (is.na(v$doubling_time)) "none (not growing)" else sprintf("%s days", g(v$doubling_time, 3))))),
            tags$tr(tags$td("Infections averted by the vaccination"), tags$td(format(round(v$infections_averted), big.mark = ","))),
            tags$tr(tags$td("Final size without vaccination (closed form)"), tags$td(pct(v$final_size_fraction_no_vaccination)))
          )),
          if (v$model == "SIR") p(sprintf("Peak by the closed formula: %s infectious (the simulation agrees to %.2f%%).", format(round(v$peak_infectious_analytic), big.mark = ","),
                                          100 * abs(v$peak_infectious - v$peak_infectious_analytic) / max(v$peak_infectious_analytic, 1))),
          if (v$epidemic_over == 0) div(class = "text-warning", "The epidemic is still running at the end of the simulated period; lengthen it to see the final size reached."),
          div(class = "text-muted", "A teaching model: random mixing, closed population, constant rates, vaccination before the start only.")
        ),
        r0 = if (v$method == "growth") tagList(
          h5(sprintf("R0 = %s (%s form)", g(v$r0, 3), v$model)),
          p(sprintf("Growth rate %s per day; doubling time %s days.", g(v$growth_rate, 3), if (is.na(v$doubling_time)) "none" else g(v$doubling_time, 3))),
          div(class = "text-muted", "Assumes exponentially distributed infectious and latent periods; a more peaked generation interval gives a lower R0 for the same growth rate.")
        ) else tagList(
          h5(sprintf("R0 = %s", g(v$r0, 3))),
          p(sprintf("Herd-immunity threshold %s.", pct(v$herd_immunity_threshold))),
          div(class = "text-muted", "Use the infected share of the whole population over a completed epidemic, counting all infections and not only detected cases.")
        )
      )
    })

    output$plot <- renderPlot({
      res <- result()
      req(res$ok, res$design == "sim")
      s <- attr(res$value, "series")
      cols <- c(susceptible = "#2C7BB6", exposed = "#E69F00", infectious = "#C0392B", removed = "#7F8C8D")
      keep <- names(cols)[c(TRUE, res$value$model == "SEIR", TRUE, TRUE)]
      graphics::matplot(s$day, s[, keep, drop = FALSE], type = "l", lty = 1, lwd = 2, col = cols[keep], xlab = "Day", ylab = "People",
                        main = sprintf("%s epidemic", res$value$model))
      graphics::legend("right", legend = keep, col = cols[keep], lwd = 2, bty = "n")
    }, res = 96, alt = function() {
      res <- result()
      req(res$ok, res$design == "sim")
      v <- res$value
      sprintf(paste0("Line chart of a %s epidemic over %d days: the number of people who are %s over time. ",
                     "The number infectious peaks at %s people (%.1f%% of the population) on day %s; in the end about %.1f%% of the population has been infected."),
              v$model, max(attr(v, "series")$day), if (v$model == "SEIR") "susceptible, exposed, infectious and removed" else "susceptible, infectious and removed",
              format(round(v$peak_infectious), big.mark = ","), 100 * v$peak_infectious_fraction, format(round(v$peak_day, 1)),
              100 * v$simulated_attack_fraction)
    })

    render_export_handlers(output, result, function() epidemic_model_content[[input$design]])
  })
}
