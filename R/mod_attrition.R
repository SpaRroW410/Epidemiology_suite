# Study planning: Attrition and Non-response module (ROADMAP Track B2, item 14):
# Calculate / Formula-Help / Reference sub-tabs, design-radio contract as in mod_rate.R
# (docs/SDD.md #8). "stages": inflate for losses at one or several stages; "arms": per-arm
# inflation for different losses; "noncompliance": drop-out / drop-in dilution.

attrition_meta <- list(
  id = "attrition",
  nav_title = "Attrition and Non-response"
)

.attr_stage_defaults <- list(c("Non-response", 10), c("Loss to follow-up", 15), c("Unusable data", 20), c("Other", 0))
.attr_arm_defaults <- list(c("Arm 1", 100, 10), c("Arm 2", 100, 30), c("Arm 3", 100, 10), c("Arm 4", 100, 10))

mod_attrition_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  stage_rows <- lapply(seq_along(.attr_stage_defaults), function(i) {
    d <- .attr_stage_defaults[[i]]
    fluidRow(
      column(6, textInput(ns(paste0("stage_label", i)), NULL, value = d[1])),
      column(6, numericInput(ns(paste0("stage_loss", i)), NULL, value = as.numeric(d[2]), min = 0, max = 99, step = 1))
    )
  })
  arm_rows <- lapply(seq_along(.attr_arm_defaults), function(i) {
    d <- .attr_arm_defaults[[i]]
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_arms"), i),
      fluidRow(
        column(4, textInput(ns(paste0("arm_label", i)), NULL, value = d[1])),
        column(4, numericInput(ns(paste0("arm_n", i)), NULL, value = as.numeric(d[2]), min = 1, step = 1)),
        column(4, numericInput(ns(paste0("arm_loss", i)), NULL, value = as.numeric(d[3]), min = 0, max = 99, step = 1))
      )
    )
  })

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Turn the number you need to analyze (from any calculator under Plan: Sample Size) into the number to enrol."),
      radioButtons(
        ns("design"), "What do you want to allow for?",
        choices = c("Losses at one or several stages (non-response, loss to follow-up, ...)" = "stages",
                    "Different losses in each arm" = "arms",
                    "Drop-out and drop-in (non-compliance diluting the treatment contrast)" = "noncompliance"),
        selected = "stages"
      ),
      conditionalPanel(
        condition = design_is("stages"),
        numericInput(ns("n_required"), "Number that must be analyzable at the end", value = 200, min = 1, step = 1),
        fluidRow(column(6, strong("Stage (optional label)")), column(6, strong("Expected loss at this stage (%)"))),
        stage_rows,
        p(class = "text-muted small", "Leave a stage at 0% to ignore it.")
      ),
      conditionalPanel(
        condition = design_is("arms"),
        numericInput(ns("n_arms"), "Number of arms (2-4)", value = 2, min = 2, max = 4, step = 1),
        fluidRow(column(4, strong("Arm label")), column(4, strong("Number that must be analyzable")), column(4, strong("Expected loss (%)"))),
        arm_rows
      ),
      conditionalPanel(
        condition = design_is("noncompliance"),
        numericInput(ns("nc_n"), "Sample size per arm needed with full compliance", value = 100, min = 1, step = 1),
        numericInput(ns("nc_out"), "Drop-out in the treatment arm (% who stop treatment)", value = 10, min = 0, max = 99, step = 1),
        numericInput(ns("nc_in"), "Drop-in in the control arm (% who take up the treatment)", value = 5, min = 0, max = 99, step = 1)
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      h4(attrition_content$stages$title),
      render_formula_block(attrition_content$stages$formula_latex),
      shiny::markdown(attrition_content$stages$explanation),
      h5("Worked example"),
      shiny::markdown(attrition_content$stages$worked_example),
      hr(),
      h4(attrition_content$arms$title),
      render_formula_block(attrition_content$arms$formula_latex),
      shiny::markdown(attrition_content$arms$explanation),
      h5("Worked example"),
      shiny::markdown(attrition_content$arms$worked_example),
      hr(),
      h4(attrition_content$noncompliance$title),
      render_formula_block(attrition_content$noncompliance$formula_latex),
      shiny::markdown(attrition_content$noncompliance$explanation),
      h5("Worked example"),
      shiny::markdown(attrition_content$noncompliance$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(attrition_content$stages$title),
      p(strong("Basis: "), attrition_content$stages$citation),
      p(strong("Implemented via: "), code(attrition_content$stages$backend)),
      hr(),
      h4(attrition_content$noncompliance$title),
      p(strong("Basis: "), attrition_content$noncompliance$citation),
      p(strong("Implemented via: "), code(attrition_content$noncompliance$backend))
    )
  )
}

mod_attrition_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)
      tryCatch({
        value <- switch(input$design,
          stages = {
            req(input$n_required)
            lab <- vapply(1:4, function(i) { x <- input[[paste0("stage_label", i)]]; if (is.null(x) || !nzchar(trimws(x))) paste("Stage", i) else trimws(x) }, "")
            loss <- vapply(1:4, function(i) { x <- input[[paste0("stage_loss", i)]]; if (is.null(x)) NA_real_ else x }, 0) / 100
            req(!anyNA(loss))
            use <- loss > 0
            if (!any(use)) use[1] <- TRUE
            calc_attrition_stages(input$n_required, loss[use], lab[use])
          },
          arms = {
            req(input$n_arms)
            k <- as.integer(input$n_arms)
            if (is.na(k) || k < 2 || k > 4) stop("Give between 2 and 4 arms.")
            lab <- vapply(seq_len(k), function(i) { x <- input[[paste0("arm_label", i)]]; if (is.null(x) || !nzchar(trimws(x))) paste("Arm", i) else trimws(x) }, "")
            n <- vapply(seq_len(k), function(i) { x <- input[[paste0("arm_n", i)]]; if (is.null(x)) NA_real_ else x }, 0)
            loss <- vapply(seq_len(k), function(i) { x <- input[[paste0("arm_loss", i)]]; if (is.null(x)) NA_real_ else x }, 0) / 100
            req(!anyNA(n), !anyNA(loss))
            calc_attrition_arms(n, loss, lab)
          },
          noncompliance = {
            req(input$nc_n, !is.null(input$nc_out), !is.null(input$nc_in))
            calc_attrition_noncompliance(input$nc_n, input$nc_out / 100, input$nc_in / 100)
          })
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }
      v <- res$value
      pct <- function(x) sprintf("%.1f%%", 100 * x)
      if (res$design == "stages") {
        st <- attr(v, "stages")
        k <- v$n_stages
        rows <- lapply(seq_len(k), function(i) {
          tags$tr(tags$td(st[i]), tags$td(pct(v[[paste0("loss_", i)]])),
                  tags$td(sprintf("%.1f", v[[paste0("expected_after_stage_", i)]])))
        })
        tagList(
          h5(sprintf("Enrol %d participants", v$n_enrolled)),
          p(sprintf("To have %d analyzable after an overall loss of %s (retention %s), recruit %d -- %d more than needed. Adding the losses instead would give %d, which falls short.",
                    v$n_required, pct(v$overall_loss), pct(v$overall_retention), v$n_enrolled, v$extra_to_recruit, v$n_if_loss_added_instead)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Stage"), tags$th("Loss"), tags$th("Expected still in after this stage"))),
            tags$tbody(rows)
          ),
          h6("Protocol wording"),
          p(class = "border rounded p-2 bg-light small",
            sprintf("Analysis of %d participants is required. Allowing for an overall loss of %s (%s), %d participants will be enrolled.",
                    v$n_required, pct(v$overall_loss), paste(sprintf("%s %s", tolower(st), pct(unlist(lapply(seq_len(k), function(i) v[[paste0("loss_", i)]])))), collapse = ", "), v$n_enrolled))
        )
      } else if (res$design == "arms") {
        arms <- attr(v, "arms")
        k <- length(arms)
        rows <- lapply(seq_len(k), function(i) {
          tags$tr(tags$td(arms[i]), tags$td(v[[paste0("n_required_arm_", i)]]), tags$td(pct(v[[paste0("loss_arm_", i)]])),
                  tags$td(strong(v[[paste0("n_enrolled_arm_", i)]])))
        })
        tagList(
          h5(sprintf("Enrol %d participants in total", v$n_enrolled_total)),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(tags$th("Arm"), tags$th("Analyzable needed"), tags$th("Expected loss"), tags$th("Enrol"))),
            tags$tbody(rows)
          ),
          p(sprintf("%d more than the %d needed. Using the average loss for every arm would give %d in total and under-recruit the arm that loses more.",
                    v$extra_to_recruit, v$n_required_total, v$n_total_if_average_loss_used)),
          div(class = "text-muted", "Unequal losses can also bias the comparison; inflating the numbers does not remove that.")
        )
      } else {
        tagList(
          h5(sprintf("%d per arm", v$n_adjusted)),
          p(sprintf("Drop-out and drop-in shrink the expected difference to %s of the planned one, so the sample size grows by a factor of %.3f: from %d to %d per arm. Treating it as a simple loss of %s would give %d, which is too few.",
                    pct(v$dilution_factor), v$inflation_factor, v$n_required, v$n_adjusted, pct(1 - v$dilution_factor), v$n_if_simple_loss_used)),
          div(class = "text-muted", "Derived for the intention-to-treat comparison of means (variance unchanged); approximate for proportions.")
        )
      }
    })

    render_export_handlers(output, result, function() attrition_content[[input$design]])
  })
}
