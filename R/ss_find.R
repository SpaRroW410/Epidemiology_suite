# Finding a calculator from the R console (or an RStudio / Positron addin) without opening the app first.
# Searches the same catalog as the Home page's search box (home_catalog.R): one row per built design.

#' Find a sample size calculator
#'
#' Searches every built design by words in its name, in the question it answers and in the name of the calculator it lives in.
#' A word in the name counts most; results are ranked by how many of your words match.
#'
#' @param query A few words, e.g. `"two means"`, `"kappa"`, `"eyes per patient"`. Empty (the default) lists everything.
#' @param n The most rows to return (default 10; use `Inf` for all).
#' @return A data frame with one row per design: `key` (what [run_app()] takes), `design` (its name), `calculator` (the
#'   calculator in the app that holds it) and `answers` (the question it answers).
#' @examples
#' ss_find("eyes per patient")
#' ss_find("kappa", n = 3)
#' @export
ss_find <- function(query = "", n = 10) {
  if (!is.character(query) || length(query) != 1 || is.na(query)) stop("query must be a single string.")
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1) stop("n must be a single number >= 1.")
  tab <- .home_search_table()
  words <- unique(strsplit(tolower(trimws(query)), "[^[:alnum:]]+")[[1]])
  words <- words[nzchar(words)]
  hit <- function(field, w) grepl(w, tolower(field), fixed = TRUE)
  score <- if (length(words)) {
    Reduce(`+`, lapply(words, function(w) 3 * hit(tab$label, w) + 2 * hit(tab$module, w) + 1 * hit(tab$answers, w)))
  } else rep(1, nrow(tab))
  # a design must match every word somewhere
  if (length(words)) {
    all_words <- Reduce(`&`, lapply(words, function(w) hit(tab$label, w) | hit(tab$module, w) | hit(tab$answers, w)))
    score[!all_words] <- 0
  }
  # on equal matches a sample-size calculator comes before an analysis tool (the app is mostly used to plan)
  in_plan <- vapply(tab$module, function(m) identical(module_workbench_of(m)$id, "plan"), logical(1))
  score <- score + ifelse(score > 0 & in_plan, 0.5, 0)
  keep <- which(score > 0)
  keep <- keep[order(-score[keep], seq_along(keep))]
  keep <- utils::head(keep, if (is.finite(n)) n else length(keep))
  out <- data.frame(key = tab$key[keep], design = tab$label[keep], calculator = tab$module[keep],
                    answers = gsub("\\s+", " ", tab$answers[keep]), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

# A design key, or words that identify one: returns the key (the best match), or stops with a clear message.
.resolve_calculator <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x) || !nzchar(x)) stop("calculator must be a design key or a few words describing one; see ss_find().")
  keys <- .home_search_table()$key
  if (x %in% keys) return(x)
  hits <- ss_find(x, n = 1)
  if (!nrow(hits)) stop("No calculator matches '", x, "'. Try ss_find() with other words.")
  message("Opening: ", hits$design[1], " (", hits$calculator[1], ")")
  hits$key[1]
}

#' RStudio / Positron addin: find a calculator and open it
#'
#' A small search window (the same search as [ss_find()]); choosing a result starts the app on that calculator.
#' It appears under *Addins* as "Find a sample size calculator".
#' @return Called for its side effect (starts the app); returns `NULL` if the window is cancelled.
#' @export
ss_find_addin <- function() {
  tab <- .home_search_table()
  ui <- shiny::fluidPage(
    shiny::h4("Find a sample size calculator"),
    shiny::selectizeInput("pick", label = "Search by words in the name or the question",
                          choices = stats::setNames(tab$key, tab$label), selected = character(0), width = "100%",
                          options = list(placeholder = "e.g. two means, kappa, eyes per patient")),
    shiny::actionButton("open", "Open the app on it", class = "btn-primary"),
    shiny::actionButton("cancel", "Cancel")
  )
  server <- function(input, output, session) {
    shiny::observeEvent(input$open, if (nzchar(input$pick)) shiny::stopApp(input$pick))
    shiny::observeEvent(input$cancel, shiny::stopApp(NULL))
  }
  key <- shiny::runGadget(ui, server, viewer = shiny::dialogViewer("Find a sample size calculator", width = 600, height = 260))
  if (is.null(key)) return(invisible(NULL))
  run_app(calculator = key)
}
