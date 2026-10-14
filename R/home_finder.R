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

# Every "Browse calculators" jump button, as a named character vector: the
# button's HTML id -> the catalog key it opens. A calculator listed under several
# families of the SAME lens (e.g. one precision design under several test
# families) needs one distinct id per occurrence -- Shiny inputs must have unique
# ids -- so the id carries the lens and the family's position, not just the key.
# The UI (home_finder_server) and the click observers both derive ids from here.
.browse_button_id <- function(axis, family_index, key) {
  paste0("jump_browse_", axis, family_index, "_", key)
}

home_browse_button_ids <- function() {
  lenses <- list(design = study_design_families, test = test_families)
  ids <- character()
  for (axis in names(lenses)) {
    for (i in seq_along(lenses[[axis]])) {
      for (key in lenses[[axis]][[i]]$catalog_keys) {
        ids[.browse_button_id(axis, i, key)] <- key
      }
    }
  }
  ids
}

home_finder_server <- function(input, output, session) {
  output$home_browse_result <- renderUI({
    axis <- if (identical(input$home_browse_axis, "test")) "test" else "design"
    families <- if (axis == "test") test_families else study_design_families
    panels <- lapply(seq_along(families), function(i) {
      fam <- families[[i]]
      body <- if (length(fam$catalog_keys) == 0) {
        .coming_soon_note()
      } else {
        entries <- lapply(fam$catalog_keys, catalog_entry)
        tagList(
          p(class = "text-muted", fam$hint),
          lapply(entries, function(entry) {
            .render_catalog_entry(entry, id = .browse_button_id(axis, i, entry$key))
          })
        )
      }
      accordion_panel(fam$label, body)
    })
    do.call(accordion, c(list(id = "home_browse_accordion", open = FALSE), panels))
  })

  # One click-observer per jump button of a built calculator (see
  # home_browse_button_ids()). Only one lens's accordion is in the DOM at a
  # time (renderUI replaces the whole uiOutput on toggle), but a calculator can
  # still appear under several families of that lens, hence distinct ids.
  ids <- home_browse_button_ids()
  for (btn_id in names(ids)) {
    local({
      btn_id <- btn_id
      entry <- catalog_entry(ids[[btn_id]])
      if (!isTRUE(entry$built)) return(invisible(NULL))
      observeEvent(input[[btn_id]], {
        nav_select("main_nav", entry$nav_target, session = session)
        if (!is.na(entry$module_input_id)) {
          updateRadioButtons(session, entry$module_input_id, selected = entry$design_value)
        }
      }, ignoreInit = TRUE)
    })
  }
}

.render_catalog_entry <- function(entry, id) {
  answers_p <- if (!is.null(entry$answers) && !is.na(entry$answers)) {
    p(class = "text-muted small mb-1", entry$answers)
  }
  if (isTRUE(entry$built)) {
    div(class = "mb-3",
        answers_p,
        actionButton(id, entry$label, class = "btn-primary"))
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
