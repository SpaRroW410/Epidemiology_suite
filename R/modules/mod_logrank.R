# Log-Rank / Survival module: Calculate / Formula-Help / Reference sub-tabs.
# Follows the same design-radio pattern as mod_tost.R (docs/SDD.md #8) --
# outer radio for "which method", with a conditionalPanel per design. The
# "stratified" design additionally follows mod_stratified.R's dynamic-inputs
# pattern (renderUI() + session$ns()) since its number of strata is itself a
# user choice.

logrank_meta <- list(
  id = "logrank",
  nav_title = "Log-Rank / Survival"
)

mod_logrank_ui <- function(id) {
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
        ns("design"), "Design",
        choices = c(
          "Log-rank test (two survival curves)" = "logrank",
          "Cox regression -- binary covariate" = "cox_binary",
          "Cox regression -- continuous covariate" = "cox_continuous",
          "Stratified log-rank, exponential survival" = "stratified",
          "Log-rank with accrual, follow-up & noncompliance" = "noncompliance",
          "Weighted log-rank (non-proportional hazards, Monte Carlo)" = "weighted_logrank"
        )
      ),
      conditionalPanel(
        condition = design_is("logrank"),
        numericInput(ns("pE"), "pE (cumulative event probability, experimental group)",
                     value = 0.3707, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("pC"), "pC (cumulative event probability, control group)",
                     value = 0.4890, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("hr_logrank"), "Postulated hazard ratio (HR)", value = 0.7, min = 0.01, step = 0.05),
        numericInput(ns("ratio"), "Experimental:control allocation ratio", value = 1, min = 0.1, step = 0.5),
        numericInput(ns("alpha_logrank"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_logrank"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("cox_binary"),
        numericInput(ns("theta_b"), "Postulated hazard ratio (theta)", value = 2, min = 0.01, step = 0.1),
        numericInput(ns("p_b"), "Proportion with covariate of interest = 1 (p)",
                     value = 0.39, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("psi_b"), "Overall event probability (psi)",
                     value = 0.505, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("rho2_b"), "Squared correlation with adjustment covariate (rho-squared)",
                     value = 0.132^2, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("alpha_b"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_b"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("cox_continuous"),
        numericInput(ns("theta_c"), "Postulated hazard ratio per unit increase (theta)",
                     value = exp(1), min = 0.01, step = 0.1),
        numericInput(ns("sigma2_c"), "Variance of the covariate of interest (sigma-squared)",
                     value = 0.3126^2, min = 0.0001, step = 0.01),
        numericInput(ns("psi_c"), "Overall event probability (psi)",
                     value = 0.738, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("rho2_c"), "Squared multiple correlation with other covariates (rho-squared)",
                     value = 0.1837, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("alpha_c"), "Significance level (alpha)", value = 0.1, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_c"), "Desired power", value = 0.806, min = 0.5, max = 0.999, step = 0.001)
      ),
      conditionalPanel(
        condition = design_is("stratified"),
        numericInput(ns("timeUnit"), "Total study length (accrual + follow-up)", value = 1.25, min = 0.0001, step = 0.1),
        numericInput(ns("hr_strat"), "Postulated hazard ratio (HR)", value = 1 / 1.91, min = 0.01, step = 0.05),
        selectInput(ns("m_strata"), "Number of strata", choices = 2:6, selected = 2),
        uiOutput(ns("strata_ui")),
        numericInput(ns("alpha_strat"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_strat"), "Desired power", value = 0.9, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("noncompliance"),
        numericInput(ns("tref_nc"), "Reference time (tref)", value = 5, min = 0.01, step = 0.5),
        numericInput(ns("mc_nc"), "Control-arm event probability by tref (mc)",
                     value = 0.18, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("r_nc"), "Postulated percent reduction in mc (%)", value = 15, min = 0.1, max = 99, step = 1),
        numericInput(ns("accrual_nc"), "Accrual period length", value = 1.5, min = 0.01, step = 0.1),
        numericInput(ns("tmin_nc"), "Minimum follow-up time", value = 5, min = 0.01, step = 0.5),
        numericInput(ns("noncomp_c_nc"), "Control-arm drop-in (%)", value = 15, min = 0, max = 99, step = 1),
        numericInput(ns("noncomp_i_nc"), "Intervention-arm non-adherence (%)", value = 25, min = 0, max = 99, step = 1),
        numericInput(ns("alpha_nc"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_nc"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("weighted_logrank"),
        numericInput(ns("hazard0_wlr"), "Baseline (control-arm) hazard", value = 0.15, min = 0.0001, step = 0.01),
        numericInput(ns("hr_wlr"), "Treatment-arm hazard ratio during the effect period", value = 0.5, min = 0.01, step = 0.05),
        numericInput(ns("change_time_wlr"), "Time the hazard ratio switches on/off", value = 4, min = 0.01, step = 0.5),
        radioButtons(ns("effect_timing_wlr"), "Non-PH shape",
                     choices = c("Delayed effect (curves separate later)" = "delayed",
                                 "Early/fading effect (curves converge later)" = "early_fading")),
        numericInput(ns("accrual_wlr"), "Accrual period length", value = 12, min = 0.01, step = 1),
        numericInput(ns("tot_time_wlr"), "Total study time (final analysis)", value = 30, min = 0.01, step = 1),
        numericInput(ns("rho_wlr"), "Fleming-Harrington weight (rho); 0 = log-rank, 1 = Gehan-Wilcoxon-type",
                     value = 0, min = 0, step = 0.5),
        numericInput(ns("allocation1_wlr"), "Allocation proportion to treatment arm", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("alpha_wlr"), "Significance level (alpha)", value = 0.05, min = 0.001, max = 0.5, step = 0.01),
        numericInput(ns("power_wlr"), "Desired power", value = 0.8, min = 0.5, max = 0.999, step = 0.01),
        monte_carlo_calculate_ui(ns)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result"))
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(logrank_content$logrank$title),
      render_formula_block(logrank_content$logrank$formula_latex),
      shiny::markdown(logrank_content$logrank$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$logrank$worked_example),
      hr(),
      h4(logrank_content$cox_binary$title),
      render_formula_block(logrank_content$cox_binary$formula_latex),
      shiny::markdown(logrank_content$cox_binary$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$cox_binary$worked_example),
      hr(),
      h4(logrank_content$cox_continuous$title),
      render_formula_block(logrank_content$cox_continuous$formula_latex),
      shiny::markdown(logrank_content$cox_continuous$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$cox_continuous$worked_example),
      hr(),
      h4(logrank_content$stratified$title),
      render_formula_block(logrank_content$stratified$formula_latex),
      shiny::markdown(logrank_content$stratified$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$stratified$worked_example),
      hr(),
      h4(logrank_content$noncompliance$title),
      render_formula_block(logrank_content$noncompliance$formula_latex),
      shiny::markdown(logrank_content$noncompliance$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$noncompliance$worked_example),
      hr(),
      h4(logrank_content$weighted_logrank$title),
      render_formula_block(logrank_content$weighted_logrank$formula_latex),
      shiny::markdown(logrank_content$weighted_logrank$explanation),
      h5("Worked example"),
      shiny::markdown(logrank_content$weighted_logrank$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(logrank_content$logrank$title),
      p(strong("Citation: "), logrank_content$logrank$citation),
      p(strong("Implemented via: "), code(logrank_content$logrank$backend)),
      hr(),
      h4(logrank_content$cox_binary$title),
      p(strong("Citation: "), logrank_content$cox_binary$citation),
      p(strong("Implemented via: "), code(logrank_content$cox_binary$backend)),
      hr(),
      h4(logrank_content$cox_continuous$title),
      p(strong("Citation: "), logrank_content$cox_continuous$citation),
      p(strong("Implemented via: "), code(logrank_content$cox_continuous$backend)),
      hr(),
      h4(logrank_content$stratified$title),
      p(strong("Citation: "), logrank_content$stratified$citation),
      p(strong("Implemented via: "), code(logrank_content$stratified$backend)),
      hr(),
      h4(logrank_content$noncompliance$title),
      p(strong("Citation: "), logrank_content$noncompliance$citation),
      p(strong("Implemented via: "), code(logrank_content$noncompliance$backend)),
      hr(),
      h4(logrank_content$weighted_logrank$title),
      p(strong("Citation: "), logrank_content$weighted_logrank$citation),
      p(strong("Implemented via: "), code(logrank_content$weighted_logrank$backend))
    )
  )
}

mod_logrank_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$strata_ui <- renderUI({
      req(input$m_strata)
      m <- as.integer(input$m_strata)
      tagList(lapply(seq_len(m), function(i) {
        fluidRow(
          column(4, numericInput(session$ns(paste0("g_", i)), sprintf("Stratum %d: share of total n", i),
                                  value = round(1 / m, 3), min = 0.001, max = 0.999, step = 0.01)),
          column(4, numericInput(session$ns(paste0("p_", i)), sprintf("Stratum %d: proportion treated", i),
                                  value = 0.5, min = 0.001, max = 0.999, step = 0.01)),
          column(4, numericInput(session$ns(paste0("lambda0_", i)), sprintf("Stratum %d: baseline hazard", i),
                                  value = 1, min = 0.0001, step = 0.1))
        )
      }))
    })

    # weighted_logrank is Monte Carlo (ROADMAP F9/P1#7): once selected,
    # recompute only on Calculate, not on every keystroke -- see
    # monte_carlo_calculate_ui()'s comment in mod_shared_ui.R.
    SLOW_DESIGNS <- "weighted_logrank"

    result <- reactive({
      req(input$design)
      is_slow <- input$design %in% SLOW_DESIGNS
      if (is_slow) input$calculate

      compute <- function() {
      if (input$design == "logrank") {
        req(input$pE, input$pC, input$hr_logrank, input$ratio, input$alpha_logrank, input$power_logrank)
        tryCatch(
          list(ok = TRUE, value = calc_logrank(
            pE = input$pE, pC = input$pC, hr = input$hr_logrank, ratio = input$ratio,
            alpha = input$alpha_logrank, power = input$power_logrank
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "cox_binary") {
        req(input$power_b, input$theta_b, input$p_b, input$psi_b, input$rho2_b, input$alpha_b)
        tryCatch(
          list(ok = TRUE, value = calc_cox_binary(
            power = input$power_b, theta = input$theta_b, p = input$p_b,
            psi = input$psi_b, rho2 = input$rho2_b, alpha = input$alpha_b
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "cox_continuous") {
        req(input$power_c, input$theta_c, input$sigma2_c, input$psi_c, input$rho2_c, input$alpha_c)
        tryCatch(
          list(ok = TRUE, value = calc_cox_continuous(
            power = input$power_c, theta = input$theta_c, sigma2 = input$sigma2_c,
            psi = input$psi_c, rho2 = input$rho2_c, alpha = input$alpha_c
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "stratified") {
        req(input$m_strata, input$timeUnit, input$hr_strat, input$alpha_strat, input$power_strat)
        m <- as.integer(input$m_strata)
        g_vals <- lapply(seq_len(m), function(i) input[[paste0("g_", i)]])
        p_vals <- lapply(seq_len(m), function(i) input[[paste0("p_", i)]])
        lambda0_vals <- lapply(seq_len(m), function(i) input[[paste0("lambda0_", i)]])
        req(!any(vapply(g_vals, is.null, logical(1))),
            !any(vapply(p_vals, is.null, logical(1))),
            !any(vapply(lambda0_vals, is.null, logical(1))))

        tryCatch(
          list(ok = TRUE, value = calc_survival_stratified(
            power = input$power_strat, timeUnit = input$timeUnit,
            gVec = as.numeric(unlist(g_vals)), pVec = as.numeric(unlist(p_vals)),
            hr = input$hr_strat, lambda0Vec = as.numeric(unlist(lambda0_vals)),
            alpha = input$alpha_strat
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "noncompliance") {
        req(input$tref_nc, input$mc_nc, input$r_nc, input$accrual_nc, input$tmin_nc,
            input$noncomp_c_nc, input$noncomp_i_nc, input$alpha_nc, input$power_nc)
        tryCatch(
          list(ok = TRUE, value = calc_survival_noncompliance(
            tref = input$tref_nc, mc = input$mc_nc, pct_reduction = input$r_nc,
            accrual = input$accrual_nc, tmin = input$tmin_nc,
            noncomp_c = input$noncomp_c_nc, noncomp_i = input$noncomp_i_nc,
            alpha = input$alpha_nc, power = input$power_nc
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "weighted_logrank") {
        req(input$hazard0_wlr, input$hr_wlr, input$change_time_wlr, input$effect_timing_wlr,
            input$accrual_wlr, input$tot_time_wlr, input$rho_wlr, input$allocation1_wlr,
            input$alpha_wlr, input$power_wlr)
        tryCatch(
          list(ok = TRUE, value = calc_weighted_logrank(
            hazard0 = input$hazard0_wlr, hr = input$hr_wlr, change_time = input$change_time_wlr,
            effect_timing = input$effect_timing_wlr, accrual = input$accrual_wlr,
            tot_time = input$tot_time_wlr, rho = input$rho_wlr, allocation1 = input$allocation1_wlr,
            alpha = input$alpha_wlr, power = input$power_wlr
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
      if (input$design == "logrank") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Experimental group: %d, Control group: %d", v$n_exp, v$n_control))
        )
      } else if (input$design == "stratified") {
        tagList(
          p(strong("Total sample size: "), v$n_total)
        )
      } else if (input$design == "noncompliance") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Per arm: %d, achieved power: %.4f", v$n_per_group, v$achieved_power))
        )
      } else if (input$design == "weighted_logrank") {
        tagList(
          p(strong("Total sample size: "), v$n_total),
          p(sprintf("Per arm: %d treatment / %d control, achieved power: %.4f",
                     v$n1, v$n0, v$achieved_power))
        )
      } else {
        tagList(
          p(strong("Required total sample size: "), v$n)
        )
      }
    })
  })
}
