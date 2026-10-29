# Eyes / Lesions per Patient module: Calculate / Formula-Help / Reference sub-tabs. Several measurements per patient (both eyes, lesions,
# patches, teeth, split-face / split-body). Three designs (treatment between patients, continuous or binary; treatment within patients,
# continuous), each solved either for the patients needed or for the units per patient needed when the number of patients is fixed.
# Follows the design-radio pattern of mod_proportion.R (docs/SDD.md #8).

patient_units_meta <- list(
  id = "patient_units",
  nav_title = "Eyes / Lesions per Patient"
)

mod_patient_units_ui <- function(id) {
  ns <- NS(id)

  design_is <- function(...) {
    values <- c(...)
    paste(sprintf("input['%s'] == '%s'", ns("design"), values), collapse = " || ")
  }
  solve_is <- function(value) sprintf("input['%s'] == '%s'", ns("solve"), value)
  both <- function(a, b) sprintf("(%s) && (%s)", a, b)

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      radioButtons(
        ns("design"), "Design",
        choices = c(
          "All of a patient's units get the same treatment -- compare two means" = "between_continuous",
          "All of a patient's units get the same treatment -- compare two proportions" = "between_binary",
          "Each patient gets both treatments (split-face, one eye per arm) -- compare two means" = "within_continuous"
        ),
        selected = "between_continuous"
      ),
      radioButtons(
        ns("solve"), "Find",
        choices = c("Patients needed (for a chosen number of units per patient)" = "patients",
                    "Units per patient needed (for a chosen number of patients)" = "units"),
        selected = "patients"
      ),
      conditionalPanel(
        condition = design_is("between_continuous", "within_continuous"),
        numericInput(ns("delta"), "Difference between treatments to detect (delta)", value = 0.5, step = 0.1),
        numericInput(ns("sd"), "Standard deviation of one unit's measurement (sd)", value = 1, min = 0.0001, step = 0.1)
      ),
      conditionalPanel(
        condition = design_is("between_binary"),
        numericInput(ns("p1"), "Proportion of units with the outcome, group 1 (p1)", value = 0.40, min = 0.001, max = 0.999, step = 0.01),
        numericInput(ns("p2"), "Proportion of units with the outcome, group 2 (p2)", value = 0.25, min = 0.001, max = 0.999, step = 0.01)
      ),
      numericInput(ns("icc"), "Correlation between two units of the same patient (rho; e.g. between-eye correlation)",
                   value = 0.3, min = 0, max = 0.999, step = 0.05),
      conditionalPanel(
        condition = both(design_is("between_continuous", "between_binary"), solve_is("patients")),
        numericInput(ns("m_between"), "Units per patient (average; 2 for both eyes)", value = 2, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = both(design_is("within_continuous"), solve_is("patients")),
        numericInput(ns("m_within"), "Units per treatment in each patient (1 = one eye per arm)", value = 1, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("between_continuous", "between_binary"),
        numericInput(ns("cv"), "Variation of the number of units per patient (CV = SD / mean; 0 if every patient has the same number)",
                     value = 0, min = 0, step = 0.05)
      ),
      conditionalPanel(
        condition = both(design_is("between_continuous", "between_binary"), solve_is("units")),
        numericInput(ns("k_between"), "Patients available per arm", value = 40, min = 2, step = 1)
      ),
      conditionalPanel(
        condition = both(design_is("within_continuous"), solve_is("units")),
        numericInput(ns("n_within"), "Patients available (each gets both treatments)", value = 20, min = 2, step = 1)
      ),
      numericInput(ns("alpha"), "Significance level (two-sided)", value = 0.05, min = 0.0001, max = 0.5, step = 0.01),
      numericInput(ns("power"), "Power", value = 0.8, min = 0.5, max = 0.999, step = 0.05),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns),
      power_curves_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(patient_units_content$between_continuous$title),
      render_formula_block(patient_units_content$between_continuous$formula_latex),
      shiny::markdown(patient_units_content$between_continuous$explanation),
      h5("Worked example"),
      shiny::markdown(patient_units_content$between_continuous$worked_example),
      hr(),
      h4(patient_units_content$between_binary$title),
      render_formula_block(patient_units_content$between_binary$formula_latex),
      shiny::markdown(patient_units_content$between_binary$explanation),
      h5("Worked example"),
      shiny::markdown(patient_units_content$between_binary$worked_example),
      hr(),
      h4(patient_units_content$within_continuous$title),
      render_formula_block(patient_units_content$within_continuous$formula_latex),
      shiny::markdown(patient_units_content$within_continuous$explanation),
      h5("Worked example"),
      shiny::markdown(patient_units_content$within_continuous$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(patient_units_content$between_continuous$title),
      p(strong("Citation: "), patient_units_content$between_continuous$citation),
      p(strong("Implemented via: "), code(patient_units_content$between_continuous$backend)),
      hr(),
      h4(patient_units_content$between_binary$title),
      p(strong("Citation: "), patient_units_content$between_binary$citation),
      p(strong("Implemented via: "), code(patient_units_content$between_binary$backend)),
      hr(),
      h4(patient_units_content$within_continuous$title),
      p(strong("Citation: "), patient_units_content$within_continuous$citation),
      p(strong("Implemented via: "), code(patient_units_content$within_continuous$backend))
    )
  )
}

mod_patient_units_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # the calc function and its arguments for the current design and "Find" choice (NULL while an input is empty)
    spec <- reactive({
      req(input$design, input$solve, input$icc, input$alpha, input$power)
      d <- input$design
      if (d == "between_continuous") req(input$delta, input$sd, input$cv) else if (d == "between_binary") req(input$p1, input$p2, input$cv) else req(input$delta, input$sd)
      if (input$solve == "patients") {
        if (d == "between_continuous") {
          req(input$m_between)
          list(fn = calc_patient_units_between_continuous, args = list(delta = input$delta, sd = input$sd, icc = input$icc,
               units_per_patient = input$m_between, cv = input$cv, alpha = input$alpha, power = input$power))
        } else if (d == "between_binary") {
          req(input$m_between)
          list(fn = calc_patient_units_between_binary, args = list(p1 = input$p1, p2 = input$p2, icc = input$icc,
               units_per_patient = input$m_between, cv = input$cv, alpha = input$alpha, power = input$power))
        } else {
          req(input$m_within)
          list(fn = calc_patient_units_within_continuous, args = list(delta = input$delta, sd = input$sd, icc = input$icc,
               units_per_arm = input$m_within, alpha = input$alpha, power = input$power))
        }
      } else {
        if (d == "within_continuous") {
          req(input$n_within)
          list(fn = calc_patient_units_needed, args = list(design = d, patients = input$n_within, delta = input$delta, sd = input$sd,
               icc = input$icc, alpha = input$alpha, power = input$power))
        } else {
          req(input$k_between)
          list(fn = calc_patient_units_needed, args = list(design = d, patients = input$k_between, delta = if (d == "between_continuous") input$delta,
               sd = if (d == "between_continuous") input$sd, p1 = if (d == "between_binary") input$p1, p2 = if (d == "between_binary") input$p2,
               icc = input$icc, cv = input$cv, alpha = input$alpha, power = input$power))
        }
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
      d <- input$design
      if (input$solve == "patients" && d != "within_continuous") {
        tagList(
          p(strong("Patients needed per arm: "), v$n_patients_per_arm, sprintf(" (%s in total, %s units in total)", v$n_patients_total, v$n_units_total)),
          p(sprintf("Design effect %.3f: each patient is worth %.2f independent units (not %s).", v$design_effect, v$effective_units_per_patient, format(input$m_between))),
          p(class = "text-muted", sprintf("If the units were wrongly counted as independent people, %s patients per arm would seem enough.",
                                          v$n_patients_per_arm_if_units_independent)),
          if (!is.na(v$n_patients_per_arm_floor))
            p(class = "text-muted", sprintf("Floor: with any number of units per patient, at least %s patients per arm are needed (rho = %s).",
                                            v$n_patients_per_arm_floor, format(input$icc)))
        )
      } else if (input$solve == "patients") {
        tagList(
          p(strong("Patients needed (each gets both treatments): "), v$n_patients, sprintf(" (%s units in total)", v$n_units_total)),
          p(sprintf("The difference between a patient's two treatment means has a standard deviation of %.3f.", v$sd_difference)),
          p(class = "text-muted", sprintf("Giving the two treatments to separate patients at the same correlation would need %s patients.",
                                          v$n_patients_if_treatments_in_separate_patients))
        )
      } else if (!isTRUE(v$achievable)) {
        div(class = "text-danger", "These patients cannot reach the power however many units each one contributes. ",
            if (!is.na(v$n_patients_per_arm_floor)) sprintf("At least %s patients per arm are needed at this correlation.", v$n_patients_per_arm_floor))
      } else {
        tagList(
          p(strong("Units needed per patient: "), v$n_units_per_patient, if (d == "within_continuous") " per treatment" else ""),
          p(sprintf("%s units in total.", v$n_units_total)),
          if (d != "within_continuous" && !is.na(v$n_patients_per_arm_floor))
            p(class = "text-muted", sprintf("Floor: below %s patients per arm no number of units per patient is enough.", v$n_patients_per_arm_floor))
        )
      }
    })

    render_export_handlers(output, result, function() patient_units_content[[input$design]])

    # Curves (patients solved for only): patients against the correlation, and patients against units per patient -- the second one
    # shows the floor that more units per patient cannot get below.
    render_power_curves(output, function() {
      s <- spec()
      if (input$solve != "patients") return(NULL)
      unit_param <- if (input$design == "within_continuous") "units_per_arm" else "units_per_patient"
      m <- s$args[[unit_param]]
      list(
        calc_fn = s$fn, args = s$args,
        effect = list(param = "icc", values = curve_range_within(0, 0.9),
                      label = "Correlation between units of a patient (rho)", title = "Required patients vs. correlation"),
        power = list(param = unit_param, values = seq(1, max(20, 3 * m), length.out = 40),
                     label = if (input$design == "within_continuous") "Units per treatment per patient" else "Units per patient",
                     title = "Required patients vs. units per patient")
      )
    })
  })
}
