# Survey Weights and Non-response module (ROADMAP Track B3, item 20): Calculate / Formula-Help / Reference sub-tabs,
# design-radio contract as in mod_rate.R (docs/SDD.md #8). "classes": design weights and nonresponse adjustment in
# weighting classes; "kish": effective sample size of a pasted list of weights.

survey_weights_meta <- list(
  id = "survey_weights",
  nav_title = "Survey Weights and Non-response"
)

.sw_max_classes <- 8
.sw_defaults <- list(c(500, 50, 40), c(300, 50, 30), c(200, 40, 35), c(100, 20, 15), c(100, 20, 15), c(100, 20, 15), c(100, 20, 15), c(100, 20, 15))

mod_survey_weights_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(value) sprintf("input['%s'] == '%s'", ns("design"), value)
  rows <- lapply(seq_len(.sw_max_classes), function(i) {
    v <- .sw_defaults[[i]]
    conditionalPanel(
      condition = sprintf("input['%s'] >= %d", ns("n_classes"), i),
      fluidRow(
        column(3, textInput(ns(paste0("label", i)), NULL, value = "", placeholder = sprintf("Class %d", i))),
        column(3, numericInput(ns(paste0("pop", i)), NULL, value = v[1], min = 1, step = 1)),
        column(3, numericInput(ns(paste0("smp", i)), NULL, value = v[2], min = 1, step = 1)),
        column(3, numericInput(ns(paste0("rsp", i)), NULL, value = v[3], min = 0, step = 1))
      )
    )
  })
  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted", "Weights for survey estimates, from counts you already have. This tool does not plan the sample; use the calculators under Plan: Sample Size."),
      radioButtons(
        ns("design"), "What do you want to do?",
        choices = c("Design weights and nonresponse adjustment by weighting class" = "classes",
                    "Effective sample size and design effect of a list of weights (Kish)" = "kish"),
        selected = "classes"
      ),
      conditionalPanel(
        condition = design_is("classes"),
        numericInput(ns("n_classes"), "Number of weighting classes (1-8)", value = 3, min = 1, max = .sw_max_classes, step = 1),
        fluidRow(column(3, strong("Class label (optional)")), column(3, strong("Population N")), column(3, strong("Sampled n")), column(3, strong("Responded r"))),
        rows
      ),
      conditionalPanel(
        condition = design_is("kish"),
        textAreaInput(ns("weights"), "Weights (one per respondent; spaces, commas or new lines)", value = "1 1 2 2", rows = 5, width = "100%")
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      export_controls_ui(ns)
    ),
    tabPanel(
      "Formula / Help",
      br(),
      lapply(c("classes", "kish"), function(d) {
        x <- survey_weights_content[[d]]
        tagList(h4(x$title), render_formula_block(x$formula_latex), shiny::markdown(x$explanation),
                h5("Worked example"), shiny::markdown(x$worked_example), hr())
      })
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(survey_weights_content$classes$citation),
      hr(),
      p(strong("Implemented via: "), code(survey_weights_content$classes$backend))
    )
  )
}

mod_survey_weights_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      req(input$design)
      tryCatch({
        value <- if (input$design == "classes") {
          req(input$n_classes)
          k <- as.integer(input$n_classes)
          if (is.na(k) || k < 1 || k > .sw_max_classes) stop("Give between 1 and 8 classes.")
          cell <- function(prefix) vapply(seq_len(k), function(i) { v <- input[[paste0(prefix, i)]]; if (is.null(v)) NA_real_ else v }, 0)
          pop <- cell("pop"); smp <- cell("smp"); rsp <- cell("rsp")
          req(!anyNA(pop), !anyNA(smp), !anyNA(rsp))
          labs <- vapply(seq_len(k), function(i) { v <- input[[paste0("label", i)]]; if (is.null(v) || !nzchar(trimws(v))) paste("Class", i) else trimws(v) }, "")
          calc_survey_weights(pop, smp, rsp, labs)
        } else {
          w <- suppressWarnings(as.numeric(strsplit(trimws(input$weights), "[,;[:space:]]+")[[1]]))
          if (anyNA(w)) stop("Enter numbers separated by spaces, commas or new lines.")
          calc_survey_effective_n(w)
        }
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      g <- function(x, d = 4) formatC(x, digits = d, format = "fg", flag = "#")
      pct <- function(x) sprintf("%.1f%%", 100 * x)
      if (res$design == "classes") {
        tb <- attr(v, "classes")
        tagList(
          p(sprintf("%s respondents of %s sampled (%s); weighted response rate %s.", format(v$respondents_total, big.mark = ","),
                    format(v$sampled_total, big.mark = ","), pct(v$unweighted_response_rate), pct(v$weighted_response_rate))),
          tags$table(
            class = "table table-sm",
            tags$thead(tags$tr(lapply(c("Class", "N", "n", "r", "Design weight", "Response rate", "Adjusted weight"), tags$th))),
            tags$tbody(lapply(seq_len(nrow(tb)), function(i) tags$tr(
              tags$td(tb$class[i]), tags$td(tb$population[i]), tags$td(tb$sampled[i]), tags$td(tb$responded[i]),
              tags$td(g(tb$design_weight[i])), tags$td(pct(tb$response_rate[i])), tags$td(strong(g(tb$adjusted_weight[i]))))))
          ),
          p(sprintf("The adjusted weights add up to %s (the population). Kish effective sample size %s of %d respondents; design effect of the weighting %s (CV of the weights %s).",
                    format(round(v$sum_of_adjusted_weights, 2), big.mark = ","), g(v$effective_sample_size), v$respondents_total, g(v$design_effect_weighting), g(v$cv_weights, 3))),
          if (v$max_weight / v$min_weight > 5) div(class = "text-warning", sprintf("The largest weight is %s times the smallest: consider merging classes or trimming.", g(v$max_weight / v$min_weight, 3))),
          div(class = "text-muted", "Nonresponse adjustment removes bias only if, within a class, respondents resemble non-respondents.")
        )
      } else {
        tagList(
          h5(sprintf("Effective sample size %s of %d", g(v$effective_sample_size), v$n)),
          p(sprintf("Design effect of the weighting %s (= 1 + CV^2 = 1 + %s^2); largest / smallest weight %s.", g(v$design_effect_weighting), g(v$cv_weights, 3), g(v$max_to_min_ratio, 3))),
          div(class = "text-muted", "This covers the effect of unequal weights only, not clustering or stratification.")
        )
      }
    })

    render_export_handlers(output, result, function() survey_weights_content[[input$design]])
  })
}
