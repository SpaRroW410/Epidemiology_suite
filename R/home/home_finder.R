# Home hub's calculator browser: a single toggle between two ways of scanning
# every built calculator at once -- by study design (study_design_families) or
# by statistical test family (test_families), both backed by the catalog in
# home_catalog.R. Both toggle states render the SAME underlying catalog
# entries; toggling never duplicates a calculator, it only changes which
# grouping lens is shown.
#
# This is plain UI-building + server logic, not a Shiny module (no NS()/
# moduleServer()) -- it's a one-per-app singleton, and it needs to jump the
# top-level navbar and update another module's input, which is simplest done
# from the root session (see README's "non-idiomatic patterns" section).

home_finder_body <- function() {
  tagList(
    radioButtons(
      "home_browse_axis", NULL,
      choices = c("By study design" = "design", "By test family" = "test"),
      inline = TRUE
    ),
    uiOutput("home_browse_result")
  )
}

home_finder_server <- function(input, output, session) {
  output$home_browse_result <- renderUI({
    families <- if (identical(input$home_browse_axis, "test")) test_families else study_design_families
    panels <- lapply(families, function(fam) {
      body <- if (length(fam$catalog_keys) == 0) {
        .coming_soon_note()
      } else {
        entries <- lapply(fam$catalog_keys, catalog_entry)
        tagList(
          p(class = "text-muted", fam$hint),
          lapply(entries, .render_catalog_entry, prefix = "browse")
        )
      }
      accordion_panel(fam$label, body)
    })
    do.call(accordion, c(list(id = "home_browse_accordion", open = FALSE), panels))
  })

  # One click-observer per built catalog entry. Both toggle states render
  # buttons via the same "browse" prefix, so a calculator that appears under
  # both study_design_families and test_families shares one observer -- no
  # duplicate ids, since only one of the two accordions is ever in the DOM at
  # a time (renderUI replaces the whole uiOutput on toggle).
  lapply(calculator_catalog, function(entry) {
    if (!isTRUE(entry$built)) return(invisible(NULL))
    btn_id <- paste0("jump_browse_", entry$key)
    observeEvent(input[[btn_id]], {
      nav_select("main_nav", entry$nav_target, session = session)
      if (!is.na(entry$module_input_id)) {
        updateRadioButtons(session, entry$module_input_id, selected = entry$design_value)
      }
    }, ignoreInit = TRUE)
  })
}

.render_catalog_entry <- function(entry, prefix) {
  answers_p <- if (!is.null(entry$answers) && !is.na(entry$answers)) {
    p(class = "text-muted small mb-1", entry$answers)
  }
  if (isTRUE(entry$built)) {
    div(class = "mb-3",
        answers_p,
        actionButton(paste0("jump_", prefix, "_", entry$key), entry$label,
                     class = "btn-primary"))
  } else {
    div(class = "mb-3",
        answers_p,
        div(class = "text-muted", paste(entry$label, "-- coming soon")))
  }
}

.coming_soon_note <- function() {
  div(class = "text-muted",
      "Not yet implemented in the app -- see ", code("docs/SDD.md"),
      " for the roadmap.")
}
