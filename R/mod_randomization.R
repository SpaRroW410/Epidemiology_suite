# Study planning: Randomization List module (ROADMAP Track B2, item 14):
# Calculate / Formula-Help / Reference sub-tabs, design-radio contract as in mod_rate.R
# (docs/SDD.md #8). "block": permuted blocks; "simple": unrestricted; "stratified":
# permuted blocks within strata. The list is reproducible from the seed.

randomization_meta <- list(
  id = "randomization",
  nav_title = "Randomization List"
)

# "4, 6" / "4 6" / "4;6" -> c(4, 6); NULL for blank.
.rand_parse_numbers <- function(x) {
  x <- trimws(x)
  if (is.null(x) || !nzchar(x)) return(NULL)
  v <- suppressWarnings(as.numeric(strsplit(x, "[,;[:space:]]+")[[1]]))
  if (anyNA(v)) stop("Enter numbers separated by commas, for example 4, 6.")
  v
}
# "Site A, Site B" / one per line -> c("Site A", "Site B"); NULL for blank.
.rand_parse_labels <- function(x) {
  x <- trimws(x)
  if (is.null(x) || !nzchar(x)) return(NULL)
  v <- trimws(strsplit(x, "[,;\n]+")[[1]])
  v[nzchar(v)]
}

mod_randomization_ui <- function(id) {
  ns <- NS(id)
  design_is <- function(...) paste(sprintf("input['%s'] == '%s'", ns("design"), c(...)), collapse = " || ")

  tabsetPanel(
    tabPanel(
      "Calculate",
      br(),
      p(class = "text-muted",
        "Generate a reproducible allocation list. This tool does not plan the sample size; use the calculators under Plan: Sample Size",
        "first, and Attrition and Non-response to turn it into the number to enrol."),
      radioButtons(
        ns("design"), "Method",
        choices = c("Permuted blocks (balanced after every block)" = "block",
                    "Permuted blocks within strata (e.g. sites)" = "stratified",
                    "Simple randomization (independent assignments)" = "simple"),
        selected = "block"
      ),
      numericInput(ns("n"), "Number of participants (per stratum when stratified)", value = 24, min = 1, step = 1),
      textInput(ns("arms"), "Arm labels (separated by commas)", value = "Intervention, Control"),
      textInput(ns("ratio"), "Allocation ratio, one number per arm (blank = equal)", value = "1, 1"),
      conditionalPanel(
        condition = design_is("block", "stratified"),
        textInput(ns("block_sizes"), "Block size(s): multiples of the sum of the ratio; several sizes are picked at random", value = "4, 6")
      ),
      conditionalPanel(
        condition = design_is("stratified"),
        textInput(ns("strata"), "Stratum labels (separated by commas)", value = "Site A, Site B")
      ),
      fluidRow(
        column(6, numericInput(ns("seed"), "Seed (same seed and settings = same list)", value = 2026, step = 1)),
        column(6, br(), actionButton(ns("new_seed"), "New random seed", class = "btn-sm btn-outline-secondary"))
      ),
      hr(),
      h5("Result"),
      uiOutput(ns("result")),
      hr(),
      h5("Download and methods text"),
      downloadButton(ns("download_list"), "Download the full list (CSV)", class = "btn-sm btn-outline-secondary"),
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
      h4(randomization_content$block$title),
      render_formula_block(randomization_content$block$formula_latex),
      shiny::markdown(randomization_content$block$explanation),
      h5("Worked example"),
      shiny::markdown(randomization_content$block$worked_example),
      hr(),
      h4(randomization_content$stratified$title),
      render_formula_block(randomization_content$stratified$formula_latex),
      shiny::markdown(randomization_content$stratified$explanation),
      h5("Worked example"),
      shiny::markdown(randomization_content$stratified$worked_example),
      hr(),
      h4(randomization_content$simple$title),
      render_formula_block(randomization_content$simple$formula_latex),
      shiny::markdown(randomization_content$simple$explanation),
      h5("Worked example"),
      shiny::markdown(randomization_content$simple$worked_example)
    ),
    tabPanel(
      "Reference",
      br(),
      h4("Citations"),
      p(randomization_content$block$citation),
      hr(),
      p(strong("Implemented via: "), code(randomization_content$block$backend))
    )
  )
}

mod_randomization_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$new_seed, {
      updateNumericInput(session, "seed", value = sample.int(.Machine$integer.max, 1))
    })

    result <- reactive({
      req(input$design, input$n, input$seed)
      tryCatch({
        arms <- .rand_parse_labels(input$arms)
        if (is.null(arms)) stop("Give at least two arm labels.")
        ratio <- .rand_parse_numbers(input$ratio)
        if (is.null(ratio)) ratio <- rep(1, length(arms))
        method <- if (input$design == "simple") "simple" else "block"
        sizes <- if (method == "block") .rand_parse_numbers(input$block_sizes) else NULL
        strata <- if (input$design == "stratified") {
          s <- .rand_parse_labels(input$strata)
          if (is.null(s)) stop("Give at least one stratum label.")
          s
        } else NULL
        value <- calc_randomization_list(input$n, arms, ratio, method, sizes, strata, seed = input$seed)
        list(ok = TRUE, design = input$design, value = value)
      }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))
    })

    output$result <- renderUI({
      res <- result()
      if (!res$ok) {
        return(div(class = "text-danger", res$message))
      }
      v <- res$value
      a <- attr(v, "allocation")
      sm <- randomization_summary_table(v)
      show <- utils::head(a[, c("id", "stratum", "block", "block_size", "arm")], 20)
      cell <- function(x) if (is.na(x)) "" else as.character(x)
      tagList(
        p(sprintf("%d participants listed (%s; seed %s).", v$n_total,
                  if (v$method == "simple") "simple randomization" else paste("blocks of", v$block_sizes), v$seed)),
        h6("Counts by arm"),
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(lapply(names(sm), tags$th))),
          tags$tbody(lapply(seq_len(nrow(sm)), function(i) tags$tr(lapply(sm[i, ], function(x) tags$td(cell(x))))))
        ),
        if (v$method == "block" && !isTRUE(v$last_block_complete)) {
          div(class = "text-muted", "The last block is incomplete, so the counts can differ slightly from the ratio.")
        },
        if (v$method == "simple") {
          div(class = "text-muted", "With simple randomization the arm sizes can differ by chance; blocks keep them balanced.")
        },
        h6(sprintf("First %d assignments", nrow(show))),
        tags$table(
          class = "table table-sm",
          tags$thead(tags$tr(lapply(c("ID", "Stratum", "Block", "Block size", "Arm"), tags$th))),
          tags$tbody(lapply(seq_len(nrow(show)), function(i) {
            tags$tr(lapply(show[i, ], function(x) tags$td(cell(x))))
          }))
        )
      )
    })

    output$methods_text <- renderText({
      res <- result()
      req(res$ok)
      randomization_methods_text(res$value)
    })

    output$download_list <- downloadHandler(
      filename = function() "epidemiologicasuite_randomization_list.csv",
      content = function(file) {
        res <- result()
        req(res$ok)
        a <- attr(res$value, "allocation")
        utils::write.csv(a, file, row.names = FALSE, na = "")
      }
    )
  })
}
