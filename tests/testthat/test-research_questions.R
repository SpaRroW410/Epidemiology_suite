# The guide's free-text reader on research questions phrased by topic (R/design_free_text.R, R/design_wizard.R; ROADMAP "Expanding the
# guide's free-text reader"). These are typical community-medicine and public-health questions written for this test (4 Nov 2026), not
# the owner's list of real thesis titles, which is still to come (to_do_later.md C2).

rq <- function(text) walk_free_text(text)

test_that("descriptive topic questions (KAP, awareness, utilization, pattern) reach a survey estimate", {
  cases <- list(
    list("Knowledge, attitude and practice regarding contraception among married women", "term_prop_precision", pop = FALSE),
    list("KAP study on biomedical waste management among nurses", "term_prop_precision", pop = FALSE),
    list("Awareness of cervical cancer screening among women in a city", "term_prop_precision", pop = TRUE),
    list("Utilization of maternal health services in a rural block", "term_prop_precision", pop = TRUE),
    list("Pattern of self-medication among medical students", "term_prop_precision", pop = FALSE),
    list("Prevalence of anaemia among adolescent girls in a district", "term_prop_precision", pop = TRUE)
  )
  for (cs in cases) {
    r <- rq(cs[[1]])
    expect_equal(r$node_id, cs[[2]], info = cs[[1]])
    expect_equal(isTRUE(r$flags$population), cs$pop, info = paste("population:", cs[[1]]))
    expect_null(r$flags$ambiguous)
  }
})

test_that("determinants questions are not routed to one design: the guide is told to offer the candidates (algorithm doc, section 0.3)", {
  qs <- c("determinants of smoking in youth", "Sexual and reproductive determinants in youth of a city",
          "Factors associated with tobacco use among college students", "Risk factors of hypertension among adults in an urban slum",
          "Predictors of exclusive breastfeeding among mothers in a district", "Correlates of depression among the elderly in rural Bhopal",
          "Determinants of haemoglobin levels among pregnant women", "risk factors for diabetes among adults")
  for (q in qs) {
    r <- rq(q)
    expect_equal(r$node_id, "root", info = q)
    expect_length(r$trace, 0)
    expect_equal(r$flags$ambiguous, "determinants", info = q)
    expect_true(isTRUE(r$flags$determinants))
  }
  expect_true(isTRUE(rq("Correlates of depression among the elderly in rural Bhopal")$flags$population))   # not sent to correlation
})

test_that("each of the four candidate routes leads where its label says", {
  expect_equal(.walk_answers(.rq_routes$survey$answers)$node_id, "term_prop_precision")
  expect_equal(.walk_answers(c(1, 2))$node_id, "term_mean_precision")
  expect_equal(.walk_answers(.rq_routes$case_control$answers)$node_id, "cc_exposure_type")
  expect_equal(.walk_answers(.rq_routes$cohort$answers)$node_id, "cohort_outcome")
  expect_equal(.walk_answers(.rq_routes$prediction$answers)$node_id, "pred_type")
  w <- .walk_answers(.rq_routes$survey$answers, list(determinants = TRUE, population = TRUE))
  expect_true(isTRUE(w$flags$determinants)); expect_length(w$trace, 2)
  html <- as.character(.render_rq_choices())
  for (r in names(.rq_routes)) expect_match(html, sprintf('id="design_wizard_rq_%s"', r), fixed = TRUE)
})

test_that("an explicit design word still wins over the topic phrasing", {
  expect_equal(rq("Risk factors for hypertension: a case-control study")$node_id, "cc_exposure_type")
  expect_false(rq("Effect of yoga on blood pressure: a randomised trial")$node_id %in% c("root", "term_prop_precision", "term_mean_precision"))
  expect_false(rq("Factors associated with mortality in a cohort of patients followed up for two years")$node_id %in% c("root", "term_prop_precision"))
  expect_equal(rq("Correlation between BMI and blood pressure")$node_id, "corr_type")
  expect_equal(rq("Develop a prediction model for the risk of diabetes")$trace[[1]]$answer, design_nodes$root$options[[3]]$label)
})

test_that("after choosing the survey, the last step points to the association and to the design effect", {
  w <- .walk_answers(.rq_routes$survey$answers, list(determinants = TRUE, population = TRUE))
  html <- as.character(.render_design_terminal(design_nodes[[w$node_id]], w$flags))
  expect_match(html, "determinants or risk factors", fixed = TRUE)
  expect_match(html, "design_wizard_jump_assoc_two", fixed = TRUE)
  expect_match(html, "Multiple logistic regression", fixed = TRUE)
  expect_match(html, "design_wizard_jump_pop_deff", fixed = TRUE)
  m <- .walk_answers(c(1, 2), list(determinants = TRUE))
  hm <- as.character(.render_design_terminal(design_nodes[[m$node_id]], m$flags))
  expect_match(hm, "Two independent means", fixed = TRUE)
  expect_false(grepl("design_wizard_jump_pop_deff", hm, fixed = TRUE))
  k <- rq("Knowledge, attitude and practice regarding contraception among married women")
  expect_false(grepl("determinants or risk factors", as.character(.render_design_terminal(design_nodes[[k$node_id]], k$flags)), fixed = TRUE))
  for (key in c(.rq_assoc_keys("proportion_single_precision"), .rq_assoc_keys("means_single_precision"), "cluster_deff"))
    expect_true(isTRUE(catalog_entry(key)$built), info = key)
})

test_that("the guide shows the four designs for a determinants question and continues from the one chosen", {
  shiny::testServer(function(input, output, session) design_wizard_server(input, output, session), {
    session$setInputs(design_wizard_freetext = "Determinants of haemoglobin levels among pregnant women")
    session$setInputs(design_wizard_parse = 1)
    expect_match(as.character(output$design_wizard_trace$html), "Choose the one you plan")
    session$setInputs(design_wizard_rq_survey = 1)
    expect_match(as.character(output$design_wizard_body$html), "Single mean")            # "levels": a mean
    expect_false(grepl("Choose the one you plan", as.character(output$design_wizard_trace$html)))
    session$setInputs(design_wizard_restart = 1)
    session$setInputs(design_wizard_freetext = "determinants of smoking in youth")
    session$setInputs(design_wizard_parse = 2)
    session$setInputs(design_wizard_rq_case_control = 1)
    expect_match(as.character(output$design_wizard_trace$html), "Their outcome/disease status")
  })
})

test_that("in the app, the owner's question offers the designs, and the survey route ends with the association buttons (browser test)", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_select_tab(app, "main_nav", "Home")
  app$run_js("document.getElementById('home_go_wizard').click()")
  app$wait_for_js("(function(){var e=document.getElementById('design_wizard_freetext'); return !!e && e.getBoundingClientRect().width > 0;})()", timeout = 30000)
  app$set_inputs(design_wizard_freetext = "determinants of smoking in youth")
  app$click("design_wizard_parse"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_trace"), "Choose the one you plan")
  app$click("design_wizard_rq_survey"); app$wait_for_idle(800, timeout = 30000)
  body <- ui_output_text(app, "design_wizard_body")
  expect_match(body, "Single proportion, precision-based")
  expect_match(body, "determinants or risk factors")
  app$click("design_wizard_jump_assoc_reg")
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Plan: Sample Size'", timeout = 60000)
  app$wait_for_js("Shiny.shinyapp.$inputValues['logistic-design'] !== undefined", timeout = 60000)
  expect_equal(ui_output_errors(app), 0)
})

test_that("dose-response and categorical exposures have their own routes (cohort and case-control)", {
  ch <- function(node, i) design_nodes[[node]]$options[[i]]$next_id
  expect_equal(ch("cohort_outcome", 6), "term_cohort_trend")
  expect_equal(ch("cohort_outcome", 7), "term_logit_cont")
  expect_equal(ch("cc_exposure_type", 3), "term_chisq_independence_direct")
  expect_equal(ch("cc_exposure_type", 4), "term_cc_trend")
  expect_equal(design_nodes$term_cohort_trend$catalog_key, "chisq_cochran_armitage")
  expect_match(design_nodes$term_cc_trend$note, "approximate")
  # and the free-text reader finds them
  expect_equal(walk_free_text("Cohort study of the dose-response between pack-years of smoking and lung disease")$node_id, "term_cohort_trend")
  expect_equal(walk_free_text("Case-control study of smoking status (never, former, current) and tuberculosis")$node_id, "term_cc_trend")
  expect_equal(walk_free_text("Case-control study with three or more categories of exposure (occupation) and asthma")$node_id, "term_chisq_independence_direct")
})
