# Cluster / Design Effect module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same design-radio pattern as mod_proportion.R
# (docs/SDD.md #8) -- two designs: inflating an externally-computed base n
# by the design effect (DEFF), or solving a full cluster survey (PSU + SSU
# counts) in one step for a proportion.

cluster_meta <- list(
  id = "cluster",
  nav_title = "Cluster / Design Effect"
)

mod_cluster_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "The design effect applies to any cluster design: a survey of villages, schools or wards, a cluster-randomised trial, or a",
        "quasi-experimental community trial."),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Design-effect inflation (given a computed base n)" = "deff",
          "Design-effect inflation (variable cluster size)" = "deff_variable",
          "Calculate the design effect from the variance between clusters" = "deff_calc",
          "Cluster survey precision (WHO EPI-style, proportion)" = "survey",
          "Two-stage PPS -- optimal cluster allocation (take b)" = "pps_optimal"
        ),
        selected = "deff"
      ),
      conditionalPanel(
        condition = design_is("deff"),
        numericInput(ns("n_base"), "Base sample size (simple random sampling)",
                     value = 200, min = 1, step = 1),
        radioButtons(ns("deff_route"), tagList("Design effect", info_tip("deff")),
                     choices = c("Work it out from the ICC and the cluster size" = "icc",
                                 "Enter the design effect itself (1.5 if not known)" = "deff")),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'icc'", ns("deff_route")),
          numericInput(ns("icc"), with_tip("Intraclass correlation coefficient (ICC / rho)", "icc"),
                       value = 0.05, min = 0, max = 0.999, step = 0.01),
          numericInput(ns("cluster_size"), "Average cluster size (subjects per cluster)",
                       value = 10, min = 1, step = 1)
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'deff'", ns("deff_route")),
          numericInput(ns("deff_direct"), "Design effect (DEFF)", value = 1.5, min = 0.1, step = 0.1),
          p(class = "text-muted small",
            "If the ICC and the variance between clusters are not known, the design effect is most commonly taken as 1.5 or 2.",
            "The design-effect calculator in this module works it out from the variance between clusters.")
        )
      ),
      conditionalPanel(
        condition = design_is("deff_calc"),
        radioButtons(ns("dc_from"), "What do you know?",
                     choices = c("The between-cluster and within-cluster variances" = "components",
                                 "The variance of the cluster means (or proportions)" = "means",
                                 "The variance of the estimate under the cluster design and under simple random sampling" = "design")),
        conditionalPanel(
          condition = sprintf("input['%s'] != 'design'", ns("dc_from")),
          numericInput(ns("dc_m"), "Average cluster size (subjects per cluster)", value = 10, min = 1, step = 1)),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'components'", ns("dc_from")),
          fluidRow(column(6, numericInput(ns("dc_vb"), "Variance between clusters", value = 2, min = 0, step = 0.1)),
                   column(6, numericInput(ns("dc_vw"), "Variance within clusters", value = 38, min = 0.0001, step = 0.1)))),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'means'", ns("dc_from")),
          numericInput(ns("dc_vmeans"), "Variance of the cluster means (or of the cluster proportions)", value = 0.0125, min = 0, step = 0.001),
          radioButtons(ns("dc_total_as"), "Overall spread of the outcome", inline = TRUE,
                       choices = c("Overall proportion (binary outcome)" = "p", "Total variance of individuals" = "var")),
          conditionalPanel(condition = sprintf("input['%s'] == 'p'", ns("dc_total_as")),
                           numericInput(ns("dc_p"), "Overall proportion", value = 0.3, min = 0.001, max = 0.999, step = 0.01)),
          conditionalPanel(condition = sprintf("input['%s'] == 'var'", ns("dc_total_as")),
                           numericInput(ns("dc_vtotal"), "Total variance of the outcome among individuals", value = 40, min = 0.0001, step = 0.1))),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'design'", ns("dc_from")),
          fluidRow(column(6, numericInput(ns("dc_vdesign"), "Variance of the estimate, cluster design", value = 0.0021, min = 0.000001, step = 0.0001)),
                   column(6, numericInput(ns("dc_vsrs"), "Variance of the estimate, simple random sampling (same total size)", value = 0.0014, min = 0.000001, step = 0.0001)))),
        numericInput(ns("dc_nbase"), "Base sample size to inflate (optional)", value = NA, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("deff_variable"),
        numericInput(ns("n_base_var"), "Base sample size (simple random sampling)",
                     value = 100, min = 1, step = 1),
        numericInput(ns("icc_var"), with_tip("Intraclass correlation coefficient (ICC / rho)", "icc"),
                     value = 0.05, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("cluster_size_var"), "Average cluster size (subjects per cluster)",
                     value = 20, min = 1, step = 1),
        numericInput(ns("cv_var"), "Coefficient of variation of cluster size (SD / mean)",
                     value = 0.5, min = 0, step = 0.05)
      ),
      conditionalPanel(
        condition = design_is("survey"),
        numericInput(ns("b_survey"), "Average individuals sampled per cluster (b)",
                     value = 75, min = 0.001, step = 1),
        numericInput(ns("b_sd_survey"), "SD of cluster size (optional; leave blank if constant)",
                     value = NA, min = 0),
        numericInput(ns("p_survey"), "p (expected proportion)",
                     value = 0.46, min = 0, max = 1, step = 0.01),
        numericInput(ns("epsilon_survey"), "Desired precision (epsilon)",
                     value = 0.10, min = 0.0001, step = 0.01),
        selectInput(ns("error_survey"), "Precision expressed as",
                    choices = c("Relative (fraction of p, e.g. 0.10 = +/- 10% of p)" = "relative",
                                "Absolute (same 0-1 scale as p, e.g. 0.05 = +/- 5 points)" = "absolute")),
        numericInput(ns("rho_survey"), with_tip("Intracluster correlation (rho)", "icc"),
                     value = 0.20, min = 0, max = 0.999, step = 0.01),
        numericInput(ns("N_psu_survey"),
                     "Total number of clusters in the population (optional; leave blank if unlimited)",
                     value = NA, min = 1),
        numericInput(ns("conf_level_survey"), "Confidence level",
                     value = 0.90, min = 0.5, max = 0.999, step = 0.01),
        nonresponse_input(ns("nonresponse_survey"),
                          "Expected non-response within clusters (fraction; 0 = none, 0.1 = 10%)"),
        uiOutput(ns("precision_equiv_survey")),
        precision_guidance_ui("cluster")
      ),
      conditionalPanel(
        condition = design_is("pps_optimal"),
        numericInput(ns("cost_psu_pps"), "Cost per PSU (cluster)", value = 750, min = 0.0001, step = 10),
        numericInput(ns("cost_element_pps"), "Cost per element (within a sampled cluster)",
                     value = 100, min = 0.0001, step = 10),
        numericInput(ns("delta_pps"), "Delta (intracluster homogeneity, ICC-like)",
                     value = 0.05, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("unit_relvar_pps"), "Unit relvariance (1 if unknown)", value = 1, min = 0.0001, step = 0.1),
        numericInput(ns("k_pps"), "k (variance-component ratio; 1 if unknown)", value = 1, min = 0.0001, step = 0.1),
        radioButtons(
          ns("mode_pps"), "Solve for",
          choices = c("Achieved CV, given a fixed total budget" = "budget",
                      "Required cost, given a target CV" = "precision"),
          selected = "budget"
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'budget'", ns("mode_pps")),
          numericInput(ns("total_budget_pps"), "Total variable-cost budget", value = 100000, min = 0.0001, step = 1000)
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'precision'", ns("mode_pps")),
          numericInput(ns("target_cv_pps"), "Target coefficient of variation (CV)", value = 0.05, min = 0.0001, max = 1, step = 0.01)
        )
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(cluster_content$deff$title),
      render_formula_block(cluster_content$deff$formula_latex),
      shiny::markdown(cluster_content$deff$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$deff$worked_example),
      hr(),
      h4(cluster_content$deff_calc$title),
      render_formula_block(cluster_content$deff_calc$formula_latex),
      shiny::markdown(cluster_content$deff_calc$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$deff_calc$worked_example),
      hr(),
      h4(cluster_content$deff_variable$title),
      render_formula_block(cluster_content$deff_variable$formula_latex),
      shiny::markdown(cluster_content$deff_variable$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$deff_variable$worked_example),
      hr(),
      h4(cluster_content$survey$title),
      render_formula_block(cluster_content$survey$formula_latex),
      shiny::markdown(cluster_content$survey$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$survey$worked_example),
      hr(),
      h4(cluster_content$pps_optimal$title),
      render_formula_block(cluster_content$pps_optimal$formula_latex),
      shiny::markdown(cluster_content$pps_optimal$explanation),
      h5("Worked example"),
      shiny::markdown(cluster_content$pps_optimal$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(cluster_content$deff$title),
      p(strong("Citation: "), cluster_content$deff$citation),
      p(strong("Implemented via: "), code(cluster_content$deff$backend)),
      hr(),
      h4(cluster_content$deff_calc$title),
      p(strong("Citation: "), cluster_content$deff_calc$citation),
      p(strong("Implemented via: "), code(cluster_content$deff_calc$backend)),
      hr(),
      h4(cluster_content$deff_variable$title),
      p(strong("Citation: "), cluster_content$deff_variable$citation),
      p(strong("Implemented via: "), code(cluster_content$deff_variable$backend)),
      hr(),
      h4(cluster_content$survey$title),
      p(strong("Citation: "), cluster_content$survey$citation),
      p(strong("Implemented via: "), code(cluster_content$survey$backend)),
      hr(),
      h4(cluster_content$pps_optimal$title),
      p(strong("Citation: "), cluster_content$pps_optimal$citation),
      p(strong("Implemented via: "), code(cluster_content$pps_optimal$backend))
    )
  )
}

mod_cluster_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$precision_equiv_survey <- renderUI({
      precision_equivalents_ui(precision_equivalents_text(input$p_survey, input$epsilon_survey, input$error_survey,
                                                          input$conf_level_survey, "proportion", "p"))
    })
    result <- reactive({
      req(input$design)

      if (input$design == "deff") {
        req(input$n_base)
        tryCatch(
          list(ok = TRUE, value = if (identical(input$deff_route, "deff")) {
            req(input$deff_direct)
            calc_cluster_deff(n_base = input$n_base, deff = input$deff_direct)
          } else {
            req(input$icc, input$cluster_size)
            calc_cluster_deff(n_base = input$n_base, icc = input$icc, cluster_size = input$cluster_size)
          }),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "deff_calc") {
        tryCatch({
          nb <- input$dc_nbase; if (is.null(nb) || is.na(nb)) nb <- NULL
          from <- if (is.null(input$dc_from)) "components" else input$dc_from
          list(ok = TRUE, value = switch(from,
            components = { req(input$dc_m, input$dc_vb, input$dc_vw)
                           calc_cluster_deff_variance(cluster_size = input$dc_m, var_between = input$dc_vb, var_within = input$dc_vw, n_base = nb) },
            means = { req(input$dc_m, input$dc_vmeans)
                      if (identical(input$dc_total_as, "var")) { req(input$dc_vtotal); calc_cluster_deff_variance(cluster_size = input$dc_m, var_means = input$dc_vmeans, var_total = input$dc_vtotal, n_base = nb) }
                      else { req(input$dc_p); calc_cluster_deff_variance(cluster_size = input$dc_m, var_means = input$dc_vmeans, p = input$dc_p, n_base = nb) } },
            design = { req(input$dc_vdesign, input$dc_vsrs)
                       calc_cluster_deff_variance(var_design = input$dc_vdesign, var_srs = input$dc_vsrs, n_base = nb) }))
        }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
      } else if (input$design == "deff_variable") {
        req(input$n_base_var, input$icc_var, input$cluster_size_var, input$cv_var)
        tryCatch(
          list(ok = TRUE, value = calc_cluster_deff_variable(
            n_base = input$n_base_var, icc = input$icc_var,
            cluster_size = input$cluster_size_var, cv = input$cv_var
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "survey") {
        req(input$b_survey, input$p_survey, input$epsilon_survey, input$error_survey,
            input$rho_survey, input$conf_level_survey)
        b_sd <- input$b_sd_survey
        if (is.null(b_sd) || is.na(b_sd)) b_sd <- NULL
        N_psu <- input$N_psu_survey
        if (is.null(N_psu) || is.na(N_psu)) N_psu <- NULL
        tryCatch(
          list(ok = TRUE, value = calc_cluster_survey_binary(
            b = input$b_survey, b_sd = b_sd, p = input$p_survey,
            epsilon = input$epsilon_survey, error = input$error_survey,
            rho = input$rho_survey, N_psu = N_psu, conf_level = input$conf_level_survey,
            nonresponse = .nonresponse_value(input$nonresponse_survey)
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$cost_psu_pps, input$cost_element_pps, input$delta_pps,
            input$unit_relvar_pps, input$k_pps, input$mode_pps)
        tryCatch(
          list(ok = TRUE, value = calc_cluster_pps_optimal_allocation(
            cost_psu = input$cost_psu_pps, cost_element = input$cost_element_pps,
            delta = input$delta_pps, unit_relvar = input$unit_relvar_pps, k = input$k_pps,
            mode = input$mode_pps,
            total_budget = if (input$mode_pps == "budget") input$total_budget_pps else NULL,
            target_cv = if (input$mode_pps == "precision") input$target_cv_pps else NULL
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
      if (input$design == "deff") {
        tagList(
          p(strong("Design effect (DEFF): "), sprintf("%.3f", v$deff), info_tip("deff")),
          p(strong("Cluster-adjusted (effective) sample size: "), v$n_effective)
        )
      } else if (input$design == "deff_calc") {
        tagList(
          p(strong("Design effect (DEFF): "), sprintf("%.3f", v$deff), info_tip("deff")),
          p("Intracluster correlation (ICC): ", if (is.na(v$icc)) "not defined (needs the cluster size)" else sprintf("%.4f", v$icc), info_tip("icc")),
          if (!is.null(v$n_effective)) p(strong("Cluster-adjusted sample size: "), v$n_effective),
          p(class = "text-muted small", "Based on: ", v$basis),
          lapply(v$notes, function(n) div(class = "text-warning", n))
        )
      } else if (input$design == "deff_variable") {
        tagList(
          p(strong("Design effect (DEFF, variable cluster size): "), sprintf("%.3f", v$deff)),
          p(strong("Cluster-adjusted (effective) sample size: "), v$n_effective)
        )
      } else if (input$design == "survey") {
        tagList(
          p(strong("Required number of clusters (PSUs): "), v$n_psu),
          p(strong("Required total individuals (SSUs, to analyze): "), v$n_ssu),
          if (!is.null(v$b_enrolled)) {
            p(strong(sprintf("To select, allowing for %s non-response: ", .prec_pct(v$inputs$nonresponse))),
              sprintf("%s per cluster, %s in total", v$b_enrolled, v$n_ssu_enrolled),
              span(class = "text-muted", sprintf(" (b / (1 - %s) = %s / %s, rounded up; the number of clusters is unchanged)",
                                                 format(v$inputs$nonresponse, trim = TRUE), format(v$inputs$b, trim = TRUE),
                                                 format(1 - v$inputs$nonresponse, trim = TRUE))))
          },
          p(sprintf("Design effect = %.3f", v$deff)),
          p(sprintf("Precision (%s): +/- %s on the 0-1 scale = +/- %s of p.", v$inputs$error,
                    .prec_fmt(v$d_absolute), .prec_pct(v$epsilon_relative))),
          precision_notes_ui(v$precision_notes)
        )
      } else {
        tagList(
          p(strong("Optimal take (elements per cluster): "), sprintf("%.1f", v$n_opt)),
          p(strong("Optimal number of clusters (PSUs): "), sprintf("%.1f", v$m_opt)),
          if (input$mode_pps == "budget") {
            p(sprintf("Achieved CV = %.4f (for a budget of %s)", v$cv, format(v$cost, big.mark = ",")))
          } else {
            p(sprintf("Required cost = %s (for a target CV of %.4f)", format(round(v$cost, 2), big.mark = ","), v$cv))
          }
        )
      }
    })

    render_export_handlers(output, result, function() cluster_content[[input$design]])

    # Precision curves (ROADMAP P1 item 10): a precision-based design has no
    # power, so its two curves are n against the key assumption and n against
    # the precision target.
    render_power_curves(output, function() {
      req(input$design)
      if (input$design == "deff_calc") {
        NULL
      } else if (input$design == "deff") {
        req(input$n_base, input$deff_route)
        if (identical(input$deff_route, "deff")) return(NULL)
        req(input$icc, input$cluster_size)
        list(
          calc_fn = calc_cluster_deff,
          args = list(n_base = input$n_base, icc = input$icc, cluster_size = input$cluster_size),
          effect = list(param = "icc", values = curve_range_within(0, 0.5),
                      label = "Intracluster correlation (ICC)",
                      title = "Required n vs. ICC"),
          power = list(param = "cluster_size", values = curve_range_multiplicative(input$cluster_size),
                      label = "Average cluster size",
                      title = "Required n vs. cluster size")
        )
      } else if (input$design == "deff_variable") {
        req(input$n_base_var, input$icc_var, input$cluster_size_var, input$cv_var)
        list(
          calc_fn = calc_cluster_deff_variable,
          args = list(n_base = input$n_base_var, icc = input$icc_var,
                       cluster_size = input$cluster_size_var, cv = input$cv_var),
          effect = list(param = "icc", values = curve_range_within(0, 0.5),
                      label = "Intracluster correlation (ICC)",
                      title = "Required n vs. ICC"),
          power = list(param = "cluster_size", values = curve_range_multiplicative(input$cluster_size_var),
                      label = "Average cluster size",
                      title = "Required n vs. cluster size")
        )
      } else if (input$design == "survey") {
        req(input$b_survey, input$p_survey, input$epsilon_survey, input$error_survey,
            input$rho_survey, input$conf_level_survey)
        b_sd <- input$b_sd_survey
        if (is.null(b_sd) || is.na(b_sd)) b_sd <- NULL
        N_psu <- input$N_psu_survey
        if (is.null(N_psu) || is.na(N_psu)) N_psu <- NULL
        list(
          calc_fn = calc_cluster_survey_binary,
          args = list(b = input$b_survey, b_sd = b_sd, p = input$p_survey, epsilon = input$epsilon_survey,
                       error = input$error_survey, rho = input$rho_survey, N_psu = N_psu,
                       conf_level = input$conf_level_survey),
          effect = list(param = "rho", values = curve_range_within(0, 0.5),
                      label = "Intracluster correlation (rho)",
                      title = "Required n vs. ICC"),
          power = list(param = "epsilon", values = curve_range_multiplicative(input$epsilon_survey, 0.25, 3),
                      label = "Desired precision (epsilon)",
                      title = "Required n vs. precision (epsilon)")
        )
      } else {
        NULL
      }
    })
  })
}
