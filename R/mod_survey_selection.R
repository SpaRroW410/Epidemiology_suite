# Survey Sample Selection module (ROADMAP Track B3, item 20): Calculate / Formula-Help / Reference sub-tabs,
# design-radio contract as in mod_rate.R (docs/SDD.md #8). "srs", "systematic", "pps", "epi".

survey_selection_meta <- list(
  id = "survey_selection",
  nav_title = "Survey Sample Selection"
)

# Lines of "name, size", "name<TAB>size", "name;size" or a bare size per line.
.survey_parse_units <- function(text) {
  lines <- trimws(strsplit(paste0(text, ""), "\n")[[1]])
  lines <- lines[nzchar(lines)]
  if (length(lines) == 0) stop("Enter the units, one per line.")
  parts <- strsplit(lines, "[,;\t]+")
  size_txt <- vapply(parts, function(p) trimws(p[length(p)]), "")
  sizes <- suppressWarnings(as.numeric(size_txt))
  if (anyNA(sizes)) stop("Every line needs a size as its last item, for example: Village A, 1200")
  labels <- vapply(seq_along(parts), function(i) if (length(parts[[i]]) > 1) trimws(paste(parts[[i]][-length(parts[[i]])], collapse = ", ")) else as.character(i), "")
  list(labels = labels, sizes = sizes)
}

.survey_example_units <- paste(c("Village 1, 1200", "Village 2, 300", "Village 3, 5000", "Village 4, 800", "Village 5, 950", "Village 6, 400",
                                 "Village 7, 2500", "Village 8, 60", "Village 9, 700", "Village 10, 1500", "Village 11, 880", "Village 12, 1750"), collapse = "\n")

mod_survey_selection_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(...) paste(sprintf("input['%s'] == '%s'", ns("design"), c(...)), collapse = " || ")
  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Draw the units for a survey from a list you already have. This tool selects the units; for how many to select, use the calculators",
        "under Plan: Sample Size (Proportions, Cluster / Design Effect, Stratified Sampling)."),
      radioButtons(
        ns("design"), "Method",
        choices = c("Simple random sample" = "srs",
                    "Systematic sample (every k-th unit)" = "systematic",
                    "PPS systematic (probability proportional to size; e.g. clusters)" = "pps",
                    "WHO EPI cluster survey (30 clusters x 7 subjects)" = "epi"),
        selected = "pps"
      ),
      conditionalPanel(
        condition = design_is("srs", "systematic"),
        numericInput(ns("N"), "Size of the list (number of units)", value = 500, min = 2, step = 1),
        numericInput(ns("n"), "Number of units to select", value = 40, min = 1, step = 1)
      ),
      conditionalPanel(
        condition = design_is("pps", "epi"),
        textAreaInput(ns("units"), "Units and sizes: one per line as  name, size  (a bare size also works)", value = .survey_example_units,
                      rows = 8, width = "100%"),
        conditionalPanel(
          condition = design_is("pps"),
          numericInput(ns("n_pps"), "Number of units to select", value = 4, min = 1, step = 1),
          checkboxInput(ns("randomize"), "Put the list in random order first", value = FALSE)
        ),
        conditionalPanel(
          condition = design_is("epi"),
          numericInput(ns("n_clusters"), "Number of clusters", value = 30, min = 1, step = 1),
          numericInput(ns("per_cluster"), "Subjects per cluster", value = 7, min = 1, step = 1)
        )
      ),
      fluidRow(
        column(6, numericInput(ns("seed"), "Seed (same seed and settings = same sample)", value = 2026, step = 1)),
        column(6, br(), actionButton(ns("new_seed"), "New random seed", class = "btn-sm btn-outline-secondary"))
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      hr(),
      h5("Download and methods text"),
      downloadButton(ns("download_list"), "Download the selected units (CSV)", class = "btn-sm btn-outline-secondary"),
      p(class = "text-muted small mt-2", "Wording for the methods section (edit the bracketed part):"),
      verbatimTextOutput(ns("methods_text")),
      tags$button(
        "Copy text", type = "button", class = "btn btn-sm btn-outline-secondary mb-2",
        onclick = sprintf("navigator.clipboard.writeText(document.getElementById('%s').innerText)", ns("methods_text"))
      )
    ),
    tabPanel(
      "Formula / Help",
      br(),
      lapply(c("srs", "systematic", "pps", "epi"), function(d) {
        x <- survey_selection_content[[d]]
        tagList(h4(x$title), render_formula_block(x$formula_latex), shiny::markdown(x$explanation),
                h5("Worked example"), shiny::markdown(x$worked_example), hr())
      })
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(survey_selection_content$pps$citation),
      hr(),
      p(strong("Implemented via: "), code(survey_selection_content$pps$backend))
    )
  )
}

mod_survey_selection_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$new_seed, {
      updateNumericInput(session, "seed", value = sample.int(.Machine$integer.max, 1))
    })

    result <- reactive({
      req(input$design, input$seed)
      tryCatch({
        value <- switch(input$design,
          srs = { req(input$N, input$n); calc_survey_select_srs(input$N, input$n, input$seed) },
          systematic = { req(input$N, input$n); calc_survey_select_systematic(input$N, input$n, input$seed) },
          pps = {
            req(input$n_pps); u <- .survey_parse_units(input$units)
            calc_survey_select_pps(u$sizes, input$n_pps, input$seed, u$labels, isTRUE(input$randomize))
          },
          epi = {
            req(input$n_clusters, input$per_cluster); u <- .survey_parse_units(input$units)
            calc_survey_epi_clusters(u$sizes, input$n_clusters, input$per_cluster, input$seed, u$labels)
          })
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) return(div(class = "text-danger", res$message))
      v <- res$value
      s <- attr(v, "selection")
      show <- utils::head(s, 60)
      fmt <- function(x) if (is.numeric(x)) formatC(x, digits = 4, format = "fg") else as.character(x)
      cols <- intersect(c("position", "unit", "size", "certainty", "inclusion_probability", "design_weight"), names(show))
      head_txt <- switch(res$design,
        srs = sprintf("%d of %d units selected at random (probability %s each, design weight %s).", v$n_selected, v$frame_size, fmt(v$n_selected / v$frame_size), fmt(v$design_weight)),
        systematic = sprintf("%d of %d units selected: interval %s, random start %s.", v$n_selected, v$frame_size, fmt(v$interval), fmt(v$random_start)),
        pps = sprintf("%d of %d units selected: interval %s, random start %s%s.", v$n_selected, v$frame_size, fmt(v$interval), fmt(v$random_start),
                      if (v$n_certainty > 0) sprintf("; %d taken with certainty", v$n_certainty) else ""),
        epi = sprintf("%d clusters selected (interval %s, random start %s) with %d subjects per cluster: %d subjects in total.", v$clusters, fmt(v$interval), fmt(v$random_start), v$per_cluster, v$total_sample))
      tagList(
        p(head_txt),
        if (res$design %in% c("pps", "epi")) p(class = "text-muted small", sprintf("Check: the design-weighted sum of the selected sizes is %s, the list total %s.", fmt(v$ht_total_size), fmt(v$total_size))),
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(lapply(cols, function(cn) tags$th(gsub("_", " ", cn))))),
          tags$tbody(lapply(seq_len(nrow(show)), function(i) tags$tr(lapply(cols, function(cn) tags$td(fmt(show[[cn]][i]))))))
        ),
        if (nrow(s) > 60) p(class = "text-muted small", sprintf("Showing the first 60 of %d; download the CSV for all of them.", nrow(s)))
      )
    })

    output$methods_text <- renderText({ res <- result(); req(res$ok); survey_selection_methods_text(res$value) })

    output$download_list <- downloadHandler(
      filename = function() "epidemiologicasuite_survey_selection.csv",
      content = function(file) { res <- result(); req(res$ok); utils::write.csv(attr(res$value, "selection"), file, row.names = FALSE, na = "") }
    )
  })
}
