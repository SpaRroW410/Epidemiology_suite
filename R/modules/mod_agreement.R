# Agreement/Reliability module: Calculate / Formula-Help / Reference
# sub-tabs. Follows the same module contract as mod_proportion.R (docs/
# SDD.md #8), for the case where there is no gold standard to compare
# against -- see R/calc/calc_agreement.R and R/content/content_agreement.R.

agreement_meta <- list(
  id = "agreement",
  nav_title = "Agreement / Reliability"
)

mod_agreement_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "Cohen's kappa (categorical agreement)" = "kappa",
          "Intraclass correlation - ICC (continuous agreement)" = "icc",
          "Cronbach's alpha (scale internal consistency)" = "cronbach",
          "Bland-Altman limits of agreement" = "bland_altman",
          "Lin's concordance correlation coefficient (CCC)" = "ccc"
        ),
        selected = "kappa"
      ),
      conditionalPanel(
        condition = design_is("kappa"),
        numericInput(ns("kappa"), "Expected kappa", value = 0.6, min = -0.99, max = 0.99, step = 0.01),
        selectInput(ns("raters"), "Number of raters", choices = 2:6, selected = 2),
        selectInput(ns("n_category"), "Number of categories", choices = 2:5, selected = 2),
        # Dynamically rendered below: one proportion input per category,
        # since the number of inputs depends on n_category.
        uiOutput(ns("props_ui")),
        numericInput(ns("conf_width_kappa"), "Desired CI width", value = 0.2, min = 0.01, max = 1.99, step = 0.01),
        numericInput(ns("conf_level_kappa"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("icc"),
        numericInput(ns("rho"), "Expected ICC (rho)", value = 0.75, min = 0, max = 1, step = 0.01),
        numericInput(ns("k_icc"), "Number of raters/measurements per subject",
                     value = 2, min = 2, max = 20, step = 1),
        numericInput(ns("conf_width_icc"), "Desired CI width", value = 0.2, min = 0.01, max = 1.99, step = 0.01),
        numericInput(ns("conf_level_icc"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("cronbach"),
        numericInput(ns("k_cronbach"), "Number of items (k)", value = 5, min = 2, step = 1),
        numericInput(ns("calpha"), "Expected Cronbach's alpha", value = 0.7, min = 0.01, max = 0.99, step = 0.01),
        numericInput(ns("conf_width_cronbach"), "Desired CI width", value = 0.1, min = 0.001, max = 1, step = 0.01),
        numericInput(ns("conf_level_cronbach"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("bland_altman"),
        numericInput(ns("conf_width_ba"), "Desired CI width for the limit of agreement (SD-units)",
                     value = 1, min = 0.01, step = 0.1),
        numericInput(ns("conf_level_ba"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      conditionalPanel(
        condition = design_is("ccc"),
        numericInput(ns("rho_c"), "Expected CCC (rho_c)", value = 0.8, min = -0.99, max = 0.99, step = 0.01),
        numericInput(ns("rho_ccc"), "Expected underlying Pearson correlation (rho)",
                     value = 0.85, min = -0.99, max = 0.99, step = 0.01),
        numericInput(ns("u_ccc"), "Location-shift bias (u; 0 = no systematic bias)",
                     value = 0, step = 0.05),
        numericInput(ns("conf_width_ccc"), "Desired CI width", value = 0.2, min = 0.001, max = 1.99, step = 0.01),
        numericInput(ns("conf_level_ccc"), "Confidence level", value = 0.95, min = 0.5, max = 0.999, step = 0.01)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(agreement_content$kappa$title),
      render_formula_block(agreement_content$kappa$formula_latex),
      shiny::markdown(agreement_content$kappa$explanation),
      h5("Worked example"),
      shiny::markdown(agreement_content$kappa$worked_example),
      hr(),
      h4(agreement_content$icc$title),
      render_formula_block(agreement_content$icc$formula_latex),
      shiny::markdown(agreement_content$icc$explanation),
      h5("Worked example"),
      shiny::markdown(agreement_content$icc$worked_example),
      hr(),
      h4(agreement_content$cronbach$title),
      render_formula_block(agreement_content$cronbach$formula_latex),
      shiny::markdown(agreement_content$cronbach$explanation),
      h5("Worked example"),
      shiny::markdown(agreement_content$cronbach$worked_example),
      hr(),
      h4(agreement_content$bland_altman$title),
      render_formula_block(agreement_content$bland_altman$formula_latex),
      shiny::markdown(agreement_content$bland_altman$explanation),
      h5("Worked example"),
      shiny::markdown(agreement_content$bland_altman$worked_example),
      hr(),
      h4(agreement_content$ccc$title),
      render_formula_block(agreement_content$ccc$formula_latex),
      shiny::markdown(agreement_content$ccc$explanation),
      h5("Worked example"),
      shiny::markdown(agreement_content$ccc$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(agreement_content$kappa$title),
      p(strong("Citation: "), agreement_content$kappa$citation),
      p(strong("Implemented via: "), code(agreement_content$kappa$backend)),
      hr(),
      h4(agreement_content$icc$title),
      p(strong("Citation: "), agreement_content$icc$citation),
      p(strong("Implemented via: "), code(agreement_content$icc$backend)),
      hr(),
      h4(agreement_content$cronbach$title),
      p(strong("Citation: "), agreement_content$cronbach$citation),
      p(strong("Implemented via: "), code(agreement_content$cronbach$backend)),
      hr(),
      h4(agreement_content$bland_altman$title),
      p(strong("Citation: "), agreement_content$bland_altman$citation),
      p(strong("Implemented via: "), code(agreement_content$bland_altman$backend)),
      hr(),
      h4(agreement_content$ccc$title),
      p(strong("Citation: "), agreement_content$ccc$citation),
      p(strong("Implemented via: "), code(agreement_content$ccc$backend))
    )
  )
}

mod_agreement_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$props_ui <- renderUI({
      req(input$n_category)
      k <- as.integer(input$n_category)
      default <- round(1 / k, 2)
      # Built outside mod_agreement_ui(), so these inputs need session$ns()
      # (the module-scoped namespacer) rather than the ns() closure the
      # static UI function uses -- same namespace, different way to reach it.
      tagList(lapply(seq_len(k), function(i) {
        numericInput(session$ns(paste0("prop_", i)),
                     sprintf("Proportion in category %d", i),
                     value = default, min = 0.001, max = 0.999, step = 0.01)
      }))
    })

    result <- reactive({
      req(input$design)

      if (input$design == "kappa") {
        req(input$kappa, input$raters, input$n_category,
            input$conf_width_kappa, input$conf_level_kappa)
        k <- as.integer(input$n_category)
        prop_vals <- lapply(seq_len(k), function(i) input[[paste0("prop_", i)]])
        req(!any(vapply(prop_vals, is.null, logical(1))))
        props <- as.numeric(unlist(prop_vals))

        tryCatch(
          list(ok = TRUE, value = calc_kappa(
            kappa = input$kappa, n_category = k, raters = as.integer(input$raters),
            props = props, conf_width = input$conf_width_kappa,
            conf_level = input$conf_level_kappa
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "icc") {
        req(input$rho, input$k_icc, input$conf_width_icc, input$conf_level_icc)
        tryCatch(
          list(ok = TRUE, value = calc_icc(
            rho = input$rho, k = input$k_icc,
            conf_width = input$conf_width_icc, conf_level = input$conf_level_icc
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "cronbach") {
        req(input$k_cronbach, input$calpha, input$conf_width_cronbach, input$conf_level_cronbach)
        tryCatch(
          list(ok = TRUE, value = calc_agreement_cronbach(
            k = input$k_cronbach, calpha = input$calpha,
            conf_width = input$conf_width_cronbach, conf_level = input$conf_level_cronbach
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else if (input$design == "bland_altman") {
        req(input$conf_width_ba, input$conf_level_ba)
        tryCatch(
          list(ok = TRUE, value = calc_agreement_bland_altman(
            conf_width = input$conf_width_ba, conf_level = input$conf_level_ba
          )),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      } else {
        req(input$rho_c, input$rho_ccc, input$u_ccc, input$conf_width_ccc, input$conf_level_ccc)
        tryCatch(
          list(ok = TRUE, value = calc_agreement_ccc(
            rho_c = input$rho_c, rho = input$rho_ccc, u = input$u_ccc,
            conf_width = input$conf_width_ccc, conf_level = input$conf_level_ccc
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
      if (input$design == "kappa") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Expected CI at that n: kappa in [%.3f, %.3f]", v$lwr, v$upr))
        )
      } else if (input$design == "cronbach") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Expected CI at that n: alpha in [%.3f, %.3f]", v$lwr, v$upr))
        )
      } else if (input$design == "ccc") {
        tagList(
          p(strong("Required sample size: "), v$n),
          p(sprintf("Achieved CI width at that n: %.4f", v$achieved_width))
        )
      } else {
        p(strong("Required sample size: "), v$n)
      }
    })

    render_export_handlers(output, result, function() agreement_content[[input$design]])
  })
}
