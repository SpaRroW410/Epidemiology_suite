# Chi-Square Tests module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same module contract as mod_agreement.R (docs/SDD.md #8),
# including its dynamic-inputs pattern: the goodness-of-fit design needs one
# pair of proportion inputs per category, and the independence design needs
# an R x C grid of joint proportions, so both are built via renderUI() +
# session$ns() rather than statically in mod_chisq_ui().

chisq_meta <- list(
  id = "chisq",
  nav_title = "Chi-Square Tests"
)

mod_chisq_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Goodness of fit" = "gof",
          "Test of independence / association (R x C table)" = "independence",
          "McNemar's test (paired proportions)" = "mcnemar",
          "Mantel-Haenszel (stratified proportions)" = "mantelhaenszel",
          "Cochran-Armitage trend test (dose-response)" = "cochran_armitage",
          "Cochran's Q test (k >= 3 paired binary measurements, Monte Carlo)" = "cochran_q"
        ),
        selected = "gof"
      ),
      conditionalPanel(
        condition = design_is("gof"),
        selectInput(ns("k_gof"), "Number of categories (k)", choices = 2:8, selected = 4),
        uiOutput(ns("gof_props_ui"))
      ),
      conditionalPanel(
        condition = design_is("independence"),
        fluidRow(
          column(6, selectInput(ns("rows"), "Number of rows", choices = 2:5, selected = 2)),
          column(6, selectInput(ns("cols"), "Number of columns", choices = 2:5, selected = 2))
        ),
        p(class = "text-muted",
          "Enter the proportion of the TOTAL sample expected in each cell (all cells sum to 1)."),
        uiOutput(ns("indep_props_ui"))
      ),
      conditionalPanel(
        condition = design_is("mcnemar"),
        numericInput(ns("p10"), "p10 (proportion switching positive -> negative)",
                     value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p01"), "p01 (proportion switching negative -> positive)",
                     value = 0.2, min = 0.001, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("mantelhaenszel"),
        selectInput(ns("J_mh"), "Number of strata (J)", choices = 2:8, selected = 5),
        numericInput(ns("phi_mh"), "Assumed odds ratio (phi, group 2 vs group 1)",
                     value = 2, min = 0.001, step = 0.1),
        p(class = "text-muted",
          "For each stratum: a = share of the total sample, b = share of that",
          "stratum allocated to group 1, p1 = group-1 response probability."),
        uiOutput(ns("mh_strata_ui"))
      ),
      conditionalPanel(
        condition = design_is("cochran_armitage"),
        selectInput(ns("k_ca"), "Number of dose/exposure groups (k)", choices = 2:8, selected = 4),
        numericInput(ns("delta_ca"), "Clinically meaningful minimal difference (delta)",
                     value = 0, step = 0.1),
        p(class = "text-muted",
          "For each group: pi = expected response proportion, di = dose/exposure",
          "level, ni = planned relative allocation (only the ratios matter)."),
        uiOutput(ns("ca_groups_ui"))
      ),
      conditionalPanel(
        condition = design_is("cochran_q"),
        textInput(ns("p_cq"), "Each condition's success proportion (comma-separated, k >= 3)",
                  value = "0.2, 0.3, 0.4, 0.5"),
        numericInput(ns("sigma2_cq"), "Subject-level random-intercept variance (within-subject correlation)",
                     value = 1, min = 0.0001, step = 0.1),
        monte_carlo_calculate_ui(ns)
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
      h4(chisq_content$gof$title),
      render_formula_block(chisq_content$gof$formula_latex),
      shiny::markdown(chisq_content$gof$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$gof$worked_example),
      hr(),
      h4(chisq_content$independence$title),
      render_formula_block(chisq_content$independence$formula_latex),
      shiny::markdown(chisq_content$independence$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$independence$worked_example),
      hr(),
      h4(chisq_content$mcnemar$title),
      render_formula_block(chisq_content$mcnemar$formula_latex),
      shiny::markdown(chisq_content$mcnemar$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$mcnemar$worked_example),
      hr(),
      h4(chisq_content$mantelhaenszel$title),
      render_formula_block(chisq_content$mantelhaenszel$formula_latex),
      shiny::markdown(chisq_content$mantelhaenszel$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$mantelhaenszel$worked_example),
      hr(),
      h4(chisq_content$cochran_armitage$title),
      render_formula_block(chisq_content$cochran_armitage$formula_latex),
      shiny::markdown(chisq_content$cochran_armitage$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$cochran_armitage$worked_example),
      hr(),
      h4(chisq_content$cochran_q$title),
      render_formula_block(chisq_content$cochran_q$formula_latex),
      shiny::markdown(chisq_content$cochran_q$explanation),
      h5("Worked example"),
      shiny::markdown(chisq_content$cochran_q$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(chisq_content$gof$title),
      p(strong("Citation: "), chisq_content$gof$citation),
      p(strong("Implemented via: "), code(chisq_content$gof$backend)),
      hr(),
      h4(chisq_content$independence$title),
      p(strong("Citation: "), chisq_content$independence$citation),
      p(strong("Implemented via: "), code(chisq_content$independence$backend)),
      hr(),
      h4(chisq_content$mcnemar$title),
      p(strong("Citation: "), chisq_content$mcnemar$citation),
      p(strong("Implemented via: "), code(chisq_content$mcnemar$backend)),
      hr(),
      h4(chisq_content$mantelhaenszel$title),
      p(strong("Citation: "), chisq_content$mantelhaenszel$citation),
      p(strong("Implemented via: "), code(chisq_content$mantelhaenszel$backend)),
      hr(),
      h4(chisq_content$cochran_armitage$title),
      p(strong("Citation: "), chisq_content$cochran_armitage$citation),
      p(strong("Implemented via: "), code(chisq_content$cochran_armitage$backend)),
      hr(),
      h4(chisq_content$cochran_q$title),
      p(strong("Citation: "), chisq_content$cochran_q$citation),
      p(strong("Implemented via: "), code(chisq_content$cochran_q$backend))
    )
  )
}

mod_chisq_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$gof_props_ui <- renderUI({
      req(input$k_gof)
      k <- as.integer(input$k_gof)
      default <- round(1 / k, 3)
      tagList(
        h5("Null (expected) proportions"),
        lapply(seq_len(k), function(i) {
          numericInput(session$ns(paste0("p0_", i)), sprintf("P0, category %d", i),
                       value = default, min = 0.001, max = 0.999, step = 0.01)
        }),
        h5("Alternative (anticipated) proportions"),
        lapply(seq_len(k), function(i) {
          numericInput(session$ns(paste0("p1_", i)), sprintf("P1, category %d", i),
                       value = default, min = 0.001, max = 0.999, step = 0.01)
        })
      )
    })

    output$indep_props_ui <- renderUI({
      req(input$rows, input$cols)
      r <- as.integer(input$rows)
      cols <- as.integer(input$cols)
      default <- round(1 / (r * cols), 3)
      col_width <- max(1, floor(12 / cols))
      tagList(lapply(seq_len(r), function(i) {
        fluidRow(lapply(seq_len(cols), function(j) {
          column(col_width, numericInput(
            session$ns(sprintf("p_%d_%d", i, j)), sprintf("Row %d, Col %d", i, j),
            value = default, min = 0.001, max = 0.999, step = 0.01
          ))
        }))
      }))
    })

    output$mh_strata_ui <- renderUI({
      req(input$J_mh)
      J <- as.integer(input$J_mh)
      default_a <- round(1 / J, 3)
      tagList(lapply(seq_len(J), function(j) {
        fluidRow(
          column(4, numericInput(session$ns(paste0("mh_a_", j)), sprintf("Stratum %d: a", j),
                                  value = default_a, min = 0.001, max = 0.999, step = 0.01)),
          column(4, numericInput(session$ns(paste0("mh_b_", j)), sprintf("Stratum %d: b", j),
                                  value = 0.5, min = 0.001, max = 0.999, step = 0.01)),
          column(4, numericInput(session$ns(paste0("mh_p1_", j)), sprintf("Stratum %d: p1", j),
                                  value = 0.5, min = 0.001, max = 0.999, step = 0.01))
        )
      }))
    })

    output$ca_groups_ui <- renderUI({
      req(input$k_ca)
      k <- as.integer(input$k_ca)
      default_pi <- round(seq(0.2, 0.8, length.out = k), 2)
      tagList(lapply(seq_len(k), function(i) {
        fluidRow(
          column(4, numericInput(session$ns(paste0("pi_ca_", i)), sprintf("Group %d: pi", i),
                                  value = default_pi[i], min = 0.001, max = 0.999, step = 0.01)),
          column(4, numericInput(session$ns(paste0("di_ca_", i)), sprintf("Group %d: di (dose)", i),
                                  value = i, step = 1)),
          column(4, numericInput(session$ns(paste0("ni_ca_", i)), sprintf("Group %d: ni (allocation)", i),
                                  value = 1, min = 0.001, step = 0.1))
        )
      }))
    })

    # cochran_q is Monte Carlo (ROADMAP F9/P1#7): once selected, recompute
    # only on Calculate, not on every keystroke -- see
    # monte_carlo_calculate_ui()'s comment in mod_shared_ui.R.
    SLOW_DESIGNS <- "cochran_q"

    result <- reactive({
      req(input$design)
      is_slow <- input$design %in% SLOW_DESIGNS
      if (is_slow) input$calculate

      compute <- function() {
      req(input$alpha, input$power)

      if (input$design == "cochran_q") {
        req(input$p_cq, input$sigma2_cq)
        tryCatch(
          {
            p_vals <- .parse_numeric_vec(input$p_cq)
            list(ok = TRUE, value = memo_calc("calc_cochran_q",
              p = p_vals, sigma2_subject = input$sigma2_cq,
              alpha = input$alpha, power = input$power
            ))
          },
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "cochran_armitage") {
        req(input$k_ca, input$delta_ca)
        k <- as.integer(input$k_ca)
        pi_vals <- lapply(seq_len(k), function(i) input[[paste0("pi_ca_", i)]])
        di_vals <- lapply(seq_len(k), function(i) input[[paste0("di_ca_", i)]])
        ni_vals <- lapply(seq_len(k), function(i) input[[paste0("ni_ca_", i)]])
        req(!any(vapply(pi_vals, is.null, logical(1))),
            !any(vapply(di_vals, is.null, logical(1))),
            !any(vapply(ni_vals, is.null, logical(1))))

        tryCatch(
          list(ok = TRUE, value = calc_cochran_armitage_trend(
            pi = as.numeric(unlist(pi_vals)), di = as.numeric(unlist(di_vals)),
            ni = as.numeric(unlist(ni_vals)), delta = input$delta_ca,
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "mantelhaenszel") {
        req(input$J_mh, input$phi_mh)
        J <- as.integer(input$J_mh)
        a_vals <- lapply(seq_len(J), function(j) input[[paste0("mh_a_", j)]])
        b_vals <- lapply(seq_len(J), function(j) input[[paste0("mh_b_", j)]])
        p1_vals <- lapply(seq_len(J), function(j) input[[paste0("mh_p1_", j)]])
        req(!any(vapply(a_vals, is.null, logical(1))),
            !any(vapply(b_vals, is.null, logical(1))),
            !any(vapply(p1_vals, is.null, logical(1))))

        tryCatch(
          list(ok = TRUE, value = calc_mantelhaenszel(
            alpha = input$alpha, power = input$power,
            a = as.numeric(unlist(a_vals)), b = as.numeric(unlist(b_vals)),
            p1 = as.numeric(unlist(p1_vals)), phi = input$phi_mh
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "mcnemar") {
        req(input$p10, input$p01)
        tryCatch(
          list(ok = TRUE, value = calc_mcnemar(
            p10 = input$p10, p01 = input$p01, alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "gof") {
        req(input$k_gof)
        k <- as.integer(input$k_gof)
        p0_vals <- lapply(seq_len(k), function(i) input[[paste0("p0_", i)]])
        p1_vals <- lapply(seq_len(k), function(i) input[[paste0("p1_", i)]])
        req(!any(vapply(p0_vals, is.null, logical(1))),
            !any(vapply(p1_vals, is.null, logical(1))))

        tryCatch(
          list(ok = TRUE, value = calc_chisq_gof(
            P0 = as.numeric(unlist(p0_vals)), P1 = as.numeric(unlist(p1_vals)),
            alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$rows, input$cols)
        r <- as.integer(input$rows)
        cols <- as.integer(input$cols)
        vals <- lapply(seq_len(r), function(i) {
          lapply(seq_len(cols), function(j) input[[sprintf("p_%d_%d", i, j)]])
        })
        req(!any(vapply(unlist(vals, recursive = FALSE), is.null, logical(1))))
        P <- matrix(as.numeric(unlist(vals)), nrow = r, ncol = cols, byrow = TRUE)

        tryCatch(
          list(ok = TRUE, value = calc_chisq_independence(
            P = P, alpha = input$alpha, power = input$power
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }
      }

      if (is_slow) isolate(compute()) else compute()
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }

      v <- res$value
      if (input$design == "cochran_q") {
        tagList(
          p(strong("Required number of subjects: "), v$n),
          p(sprintf("Simulated achieved power at this n: %.4f", v$achieved_power))
        )
      } else if (input$design == "cochran_armitage") {
        tagList(
          p(strong("Reference (group 1) sample size: "), v$n_group1),
          p(strong("Per-group sample sizes: "), paste(v$n_per_group, collapse = ", ")),
          p(strong("Total sample size: "), v$n_total)
        )
      } else if (input$design == "mantelhaenszel") {
        tagList(
          p(strong("Stratified (Mantel-Haenszel) sample size: "), v$n_stratified),
          p(strong("Naive pooled sample size (ignoring strata): "), v$n_pooled)
        )
      } else if (input$design == "mcnemar") {
        tagList(
          p(strong("Required number of pairs: "), v$n)
        )
      } else {
        tagList(
          p(strong("Required total sample size (N): "), v$N),
          p(sprintf("Effect size w = %.4f, df = %d", v$w, v$df))
        )
      }
    })

    render_export_handlers(output, result, function() chisq_content[[input$design]])

    # Power curves (ROADMAP P1 item 10): wired for "mcnemar" only -- every
    # other design here takes a vector/matrix of proportions (gof,
    # independence, mantelhaenszel, cochran_armitage) or is Monte Carlo
    # (cochran_q), none of which has one scalar effect parameter to vary.
    render_power_curves(output, function() {
      if (input$design == "mcnemar") {
        req(input$p10, input$p01, input$alpha, input$power)
        list(
          calc_fn = calc_mcnemar,
          args = list(p10 = input$p10, p01 = input$p01, alpha = input$alpha, power = input$power),
          effect = list(param = "p10", values = curve_range_proportion(), label = "p10 (positive to negative)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "gof") {
        req(input$k_gof, input$alpha, input$power)
        k <- as.integer(input$k_gof)
        p0_vals <- lapply(seq_len(k), function(i) input[[paste0("p0_", i)]])
        p1_vals <- lapply(seq_len(k), function(i) input[[paste0("p1_", i)]])
        req(!any(vapply(p0_vals, is.null, logical(1))), !any(vapply(p1_vals, is.null, logical(1))))
        # The effect is the gap between two vectors of proportions, so the
        # curve scales that gap (1 = as entered) and rejects any multiplier
        # that pushes a proportion to zero or below.
        gof_by_scale <- function(P0, P1, scale, alpha, power) {
          P1s <- curve_scale_about(P1, P0, scale)
          if (any(P1s <= 0)) stop("scaled proportions must stay positive")
          calc_chisq_gof(P0 = P0, P1 = P1s, alpha = alpha, power = power)
        }
        list(
          calc_fn = gof_by_scale,
          args = list(P0 = as.numeric(unlist(p0_vals)), P1 = as.numeric(unlist(p1_vals)), scale = 1,
                       alpha = input$alpha, power = input$power),
          effect = list(param = "scale", values = curve_range_multiplicative(1),
                        label = "Multiplier on the gap between P1 and P0 (1 = as entered)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "independence") {
        req(input$rows, input$cols, input$alpha, input$power)
        r <- as.integer(input$rows)
        cols <- as.integer(input$cols)
        vals <- lapply(seq_len(r), function(i) {
          lapply(seq_len(cols), function(j) input[[sprintf("p_%d_%d", i, j)]])
        })
        req(!any(vapply(unlist(vals, recursive = FALSE), is.null, logical(1))))
        P <- matrix(as.numeric(unlist(vals)), nrow = r, ncol = cols, byrow = TRUE)
        # The effect is how far the table departs from independence, so the
        # curve scales that departure (1 = as entered).
        indep_by_scale <- function(P, scale, alpha, power) {
          P0 <- outer(rowSums(P), colSums(P))
          Ps <- curve_scale_about(P, P0, scale)
          if (any(Ps <= 0)) stop("scaled cell proportions must stay positive")
          calc_chisq_independence(P = Ps, alpha = alpha, power = power)
        }
        list(
          calc_fn = indep_by_scale,
          args = list(P = P, scale = 1, alpha = input$alpha, power = input$power),
          effect = list(param = "scale", values = curve_range_multiplicative(1),
                        label = "Multiplier on the departure from independence (1 = as entered)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "mantelhaenszel") {
        req(input$J_mh, input$phi_mh, input$alpha, input$power)
        J <- as.integer(input$J_mh)
        a_vals <- lapply(seq_len(J), function(j) input[[paste0("mh_a_", j)]])
        b_vals <- lapply(seq_len(J), function(j) input[[paste0("mh_b_", j)]])
        p1_vals <- lapply(seq_len(J), function(j) input[[paste0("mh_p1_", j)]])
        req(!any(vapply(a_vals, is.null, logical(1))), !any(vapply(b_vals, is.null, logical(1))),
            !any(vapply(p1_vals, is.null, logical(1))))
        list(
          calc_fn = calc_mantelhaenszel,
          args = list(alpha = input$alpha, power = input$power, a = as.numeric(unlist(a_vals)),
                       b = as.numeric(unlist(b_vals)), p1 = as.numeric(unlist(p1_vals)), phi = input$phi_mh),
          effect = list(param = "phi", values = curve_range_ratio(), label = "Odds ratio (phi)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else if (input$design == "cochran_armitage") {
        req(input$k_ca, input$delta_ca, input$alpha, input$power)
        k <- as.integer(input$k_ca)
        pi_vals <- lapply(seq_len(k), function(i) input[[paste0("pi_ca_", i)]])
        di_vals <- lapply(seq_len(k), function(i) input[[paste0("di_ca_", i)]])
        ni_vals <- lapply(seq_len(k), function(i) input[[paste0("ni_ca_", i)]])
        req(!any(vapply(pi_vals, is.null, logical(1))), !any(vapply(di_vals, is.null, logical(1))),
            !any(vapply(ni_vals, is.null, logical(1))))
        pis <- as.numeric(unlist(pi_vals))
        list(
          calc_fn = calc_cochran_armitage_trend,
          args = list(pi = pis, di = as.numeric(unlist(di_vals)), ni = as.numeric(unlist(ni_vals)),
                       delta = input$delta_ca, alpha = input$alpha, power = input$power),
          effect = list(param = "delta", values = curve_range_around(0, 0.5 * diff(range(pis))),
                        label = "delta (clinically meaningful minimal difference)"),
          power = list(param = "power", values = curve_range_power())
        )
      } else {
        NULL
      }
    })
  })
}
