# Trial Sequential Analysis module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same outcome-type-radio pattern as
# mod_group_sequential.R (docs/SDD.md #8) -- computes the fixed-effect
# Required/Optimal Information Size (RIS/OIS) for a planned meta-analysis
# across four outcome types.

tsa_meta <- list(
  id = "tsa",
  nav_title = "Trial Sequential Analysis"
)

mod_tsa_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("outcome"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("outcome"), "Outcome type",
        choices = c(
          "Risk ratio (RR)" = "RR",
          "Odds ratio (OR)" = "OR",
          "Risk difference (RD)" = "RD",
          "Mean difference (MD)" = "MD"
        ),
        selected = "RR"
      ),
      conditionalPanel(
        condition = paste0(design_is("RR"), " || ", design_is("OR")),
        numericInput(ns("pC_ratio"), "pC (control-arm event probability)",
                     value = 0.12, min = 0.0001, max = 0.9999, step = 0.01),
        numericInput(ns("mc_ratio"), "Anticipated ratio (RR or OR)", value = 0.8, min = 0.0001, step = 0.05)
      ),
      conditionalPanel(
        condition = design_is("RD"),
        numericInput(ns("pC_rd"), "pC (control-arm event probability)",
                     value = 0.30, min = 0.0001, max = 0.9999, step = 0.01),
        numericInput(ns("p1_rd"), "p1 (intervention-arm event probability)",
                     value = 0.25, min = 0.0001, max = 0.9999, step = 0.01),
        numericInput(ns("mc_rd"), "Anticipated risk difference (mc)", value = 0.05, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("MD"),
        numericInput(ns("mc_md"), "Anticipated mean difference (mc)", value = 0.3, step = 0.05),
        numericInput(ns("sd_md"), "Standard deviation of the effect (sd_mc)", value = 1, min = 0.0001, step = 0.1)
      ),
      hr(),
      numericInput(ns("alpha"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Desired power", value = 0.9, min = 0.5, max = 0.999, step = 0.01),
      selectInput(ns("side"), "Test sidedness",
                  choices = c("Two-sided" = "2", "One-sided" = "1")),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      shiny::markdown(tsa_content$shared$explanation),
      hr(),
      h4(tsa_content$rr$title),
      render_formula_block(tsa_content$rr$formula_latex),
      hr(),
      h4(tsa_content$or$title),
      render_formula_block(tsa_content$or$formula_latex),
      hr(),
      h4(tsa_content$rd$title),
      render_formula_block(tsa_content$rd$formula_latex),
      hr(),
      h4(tsa_content$md$title),
      render_formula_block(tsa_content$md$formula_latex),
      hr(),
      h5("Worked example"),
      shiny::markdown(tsa_content$shared$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      p(strong("Citation: "), tsa_content$shared$citation),
      p(strong("Implemented via: "), code(tsa_content$rr$backend))
    )
  )
}

mod_tsa_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$outcome, input$alpha, input$power, input$side)
      side <- as.integer(input$side)
      beta <- 1 - input$power

      tryCatch({
        value <- if (input$outcome %in% c("RR", "OR")) {
          req(input$pC_ratio, input$mc_ratio)
          calc_tsa_information_size(
            outcome = input$outcome, mc = input$mc_ratio, pC = input$pC_ratio,
            alpha = input$alpha, beta = beta, side = side
          )
        } else if (input$outcome == "RD") {
          req(input$pC_rd, input$p1_rd, input$mc_rd)
          calc_tsa_information_size(
            outcome = "RD", mc = input$mc_rd, pC = input$pC_rd, p1 = input$p1_rd,
            alpha = input$alpha, beta = beta, side = side
          )
        } else {
          req(input$mc_md, input$sd_md)
          calc_tsa_information_size(
            outcome = "MD", mc = input$mc_md, sd_mc = input$sd_md,
            alpha = input$alpha, beta = beta, side = side
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

      v <- res$value
      tagList(
        p(strong("Required (fixed-effect) information size: "), v$n_total, " participants total"),
        p(class = "text-muted",
          "Divide by the anticipated number of participants per trial to estimate",
          "the minimum number of trials the meta-analysis needs.")
      )
    })

    # tsa_content's per-outcome entries (rr/or/rd/md) carry title/backend
    # but not citation -- that's on the shared entry, same as evpi_content
    # and multilevel_content (see mod_evpi.R/mod_multilevel.R).
    render_export_handlers(output, result, function() {
      modifyList(tsa_content[[tolower(input$outcome)]], list(citation = tsa_content$shared$citation))
    })

    # Power curves (ROADMAP P1 item 10): calc_tsa_information_size() takes
    # beta (= 1 - power), not power, so the curve calls it through a small
    # adapter that exposes a `power` argument -- the power axis then reads
    # as power, not beta.
    tsa_by_power <- function(outcome, mc, pC = NULL, p1 = NULL, sd_mc = NULL, alpha, power, side) {
      calc_tsa_information_size(outcome = outcome, mc = mc, pC = pC, p1 = p1, sd_mc = sd_mc,
                                alpha = alpha, beta = 1 - power, side = side)
    }
    render_power_curves(output, function() {
      req(input$outcome, input$alpha, input$power, input$side)
      side <- as.integer(input$side)
      if (input$outcome %in% c("RR", "OR")) {
        req(input$pC_ratio, input$mc_ratio)
        list(
          calc_fn = tsa_by_power,
          args = list(outcome = input$outcome, mc = input$mc_ratio, pC = input$pC_ratio,
                       alpha = input$alpha, power = input$power, side = side),
          effect = list(param = "mc", values = curve_range_ratio(), label = paste("Anticipated", input$outcome)),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$outcome == "RD") {
        req(input$pC_rd, input$p1_rd, input$mc_rd)
        list(
          calc_fn = tsa_by_power,
          args = list(outcome = "RD", mc = input$mc_rd, pC = input$pC_rd, p1 = input$p1_rd,
                       alpha = input$alpha, power = input$power, side = side),
          effect = list(param = "mc", values = curve_range_around(0, 3 * abs(input$mc_rd)),
                        label = "Anticipated risk difference (mc)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else {
        req(input$mc_md, input$sd_md)
        list(
          calc_fn = tsa_by_power,
          args = list(outcome = "MD", mc = input$mc_md, sd_mc = input$sd_md,
                       alpha = input$alpha, power = input$power, side = side),
          effect = list(param = "mc", values = curve_range_around(0, 3 * input$sd_md),
                        label = "Anticipated mean difference (mc)"),
          power = list(param = "power", values = curve_range_power())
        )
      }
    })
  })
}
