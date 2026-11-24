# FIND-13: the guide keeps the objectives of a study: save one, answer the questions again for the next

test_that("the objectives list shows each saved design and is empty when nothing is saved", {
  expect_null(.render_objectives(list()))
  h <- as.character(.render_objectives(list(list(design = "Cross-sectional survey", key = "proportion_single_precision"),
                                            list(design = "Cohort", key = NULL))))
  expect_match(h, "Objectives of your study so far", fixed = TRUE)
  expect_match(h, "design_wizard_objective_go_1", fixed = TRUE)
  expect_false(grepl("design_wizard_objective_go_2", h, fixed = TRUE))    # no calculator to go to for an unbuilt design
  expect_match(h, "design_wizard_objective_rm_2", fixed = TRUE)
})

test_that("a design end point offers to save the objective and plan another", {
  h <- as.character(.render_design_terminal(design_nodes$term_stepped_wedge, list()))
  expect_match(h, "design_wizard_objective_add", fixed = TRUE)
})

test_that("saving an objective keeps it and returns the guide to the first question", {
  html <- function(x) paste(as.character(if (is.null(x$html)) x else x$html), collapse = "")
  shiny::testServer(function(input, output, session) design_wizard_server(input, output, session), {
    session$setInputs(design_wizard_parse = 0)     # the first value of an input is its initial value; later ones are clicks
    session$setInputs(design_wizard_freetext = "Estimate the prevalence of hypertension")
    session$setInputs(design_wizard_parse = 1)
    expect_match(html(output$design_wizard_body), "design_wizard_objective_add", fixed = TRUE)   # at an end point
    session$setInputs(design_wizard_objective_add = 0)
    session$setInputs(design_wizard_objective_add = 1)
    expect_match(html(output$design_wizard_objectives), "Objectives of your study so far", fixed = TRUE)
    expect_match(html(output$design_wizard_body), "design_wizard_choice", fixed = TRUE)           # the first question again
    session$setInputs(design_wizard_restart = 0)
    session$setInputs(design_wizard_restart = 1)                                                 # start over keeps the list
    expect_match(html(output$design_wizard_objectives), "design_wizard_objective_rm_1", fixed = TRUE)
    session$setInputs(design_wizard_objective_rm_1 = 0)
    session$setInputs(design_wizard_objective_rm_1 = 1)
    expect_false(grepl("Objectives of your study", html(output$design_wizard_objectives), fixed = TRUE))
  })
})
