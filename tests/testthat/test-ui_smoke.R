# Browser-driven UI smoke tests (ROADMAP P1 item 12, finding F6): the whole app
# is started once in headless Chrome via shinytest2 and every module is opened
# in turn. Unit tests call calc_*() directly and never see a module's own wiring
# (a broken content_fn, a renderUI error, a missing output), which is exactly
# what these catch. The per-design pass over every module's design radio is slow
# and runs only with S2R_SLOW_TESTS=true (the weekly CI run).

registry <- module_registry()

test_that("the app starts on the Home hub with no console errors", {
  skip_if_no_ui()
  app <- ui_driver()
  app$wait_for_idle(800, timeout = 120000)
  expect_equal(ui_output_errors(app), 0)
  expect_equal(app$get_js("document.querySelector('.navbar-brand, .navbar .navbar-title') !== null"), TRUE)
  expect_equal(app$get_value(input = "main_nav"), "Home")
  expect_equal(ui_console_errors(app), character())
})

test_that("a Home 'Browse calculators' button that shares its calculator with another family opens it", {
  skip_if_no_ui()
  app <- ui_driver()
  ids <- home_browse_button_ids()
  # A calculator listed under 2+ families of one lens: click the LAST such button
  # (the one a duplicated id would have shadowed).
  for (axis in c("design", "test")) {
    lens <- ids[startsWith(names(ids), paste0("jump_browse_", axis))]
    dup_keys <- unique(lens[duplicated(lens)])
    if (length(dup_keys)) break
  }
  expect_gt(length(dup_keys), 0)
  key <- dup_keys[[1]]
  entry <- catalog_entry(key)
  btn <- tail(names(lens)[lens == key], 1)
  app$set_inputs(home_browse_axis = axis, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 30000)
  expect_equal(app$get_js(sprintf("Array.from(document.querySelectorAll('[id]')).filter(function(e){return e.id === %s;}).length", ui_js_string(btn))), 1)
  app$run_js(sprintf("document.getElementById(%s).click()", ui_js_string(btn)))
  app$wait_for_idle(800, timeout = 30000)
  wb <- module_workbench_of(entry$nav_target)
  expect_equal(app$get_value(input = "main_nav"), wb$title)
  expect_equal(app$get_value(input = wb$nav_id), entry$nav_target)
  expect_equal(ui_output_errors(app), 0)
})

for (m in registry) {
  local({
    m <- m
    test_that(sprintf("UI: module '%s' opens and renders without output errors", m$id), {
      skip_if_no_ui()
      app <- ui_driver()
      ui_open_module(app, m$title)
      wb <- module_workbench_of(m$title)
      expect_equal(app$get_value(input = "main_nav"), wb$title)
      expect_equal(app$get_value(input = wb$nav_id), m$title)
      expect_true(ui_pane_visible(app, m$title))
      expect_equal(ui_output_errors(app), 0)
      txt <- ui_output_text(app, paste0(m$id, "-result"))
      if (!is.na(txt)) expect_gt(nchar(txt), 0)
    })
  })
}

test_that("Diagnostic Test Evaluation: single test shows CIs; combining 3 tests lists serial and parallel, with CIs once n is given", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Diagnostic Test Evaluation")
  single <- ui_output_text(app, "analyze_dx-result")
  expect_match(single, "Sensitivity")
  expect_match(single, "90.1% \\(87.7 to 92.1\\)")   # Scott et al. 2008 / epiR::epi.tests()
  expect_match(single, "Positive predictive value")

  app$set_inputs(`analyze_dx-design` = "combined")
  app$wait_for_idle(800, timeout = 60000)
  combined <- ui_output_text(app, "analyze_dx-result")
  expect_match(combined, "Parallel: positive if ANY of the 3 tests")
  expect_match(combined, "Serial: positive only if ALL 3 tests")
  expect_match(combined, "99.7%")   # parallel sensitivity of 90/80/85
  expect_match(combined, "61.2%")   # serial sensitivity
  expect_match(combined, "Enter the numbers of diseased and non-diseased")
  app$set_inputs(`analyze_dx-nd1` = 100, `analyze_dx-nd2` = 200, `analyze_dx-nd3` = 150,
                 `analyze_dx-nn1` = 300, `analyze_dx-nn2` = 250, `analyze_dx-nn3` = 200)
  app$wait_for_idle(800, timeout = 60000)
  with_ci <- ui_output_text(app, "analyze_dx-result")
  expect_match(with_ci, " to ")
  expect_false(grepl("Enter the numbers of diseased", with_ci))
  expect_equal(ui_output_errors(app), 0)
})

test_that("Confidence Intervals: proportion lists the methods; the mean design gives t and SD intervals", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Confidence Intervals")
  prop <- ui_output_text(app, "analyze_ci-result")
  expect_match(prop, "Wilson score")
  expect_match(prop, "0\\.1812")    # Wilson lower limit for 7/20 (= epiR::epi.conf())
  expect_match(prop, "Mid-P exact")
  app$set_inputs(`analyze_ci-design` = "mean")
  app$wait_for_idle(800, timeout = 60000)
  mean_txt <- ui_output_text(app, "analyze_ci-result")
  expect_match(mean_txt, "Mean \\(t interval\\)")
  expect_match(mean_txt, "9\\.253 to 10\\.75")
  expect_match(mean_txt, "Standard deviation")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Mantel-Haenszel: pooled estimates and tests render; fewer strata and the case-control design update them", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Stratified Analysis (Mantel-Haenszel)")
  txt <- ui_output_text(app, "analyze_mh-result")
  expect_match(txt, "3\\.80")                      # pooled OR for the default tables (= epiR / mantelhaen.test)
  expect_match(txt, "Risk difference")
  expect_match(txt, "Breslow-Day")
  expect_match(txt, "Stratum 3")
  app$set_inputs(`analyze_mh-n_strata` = 2)
  app$wait_for_idle(800, timeout = 60000)
  expect_false(grepl("Stratum 3", ui_output_text(app, "analyze_mh-result")))
  app$set_inputs(`analyze_mh-design` = "case_control")
  app$wait_for_idle(800, timeout = 60000)
  cc <- ui_output_text(app, "analyze_mh-result")
  expect_false(grepl("Risk difference", cc))
  expect_match(cc, "Odds ratio")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Rates and Rate Ratios: single rate lists the methods; comparing two groups gives the published rate ratio", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Rates and Rate Ratios")
  single <- ui_output_text(app, "analyze_rates-result")
  expect_match(single, "Exact \\(Garwood\\)")
  expect_match(single, "Mid-P exact")
  app$set_inputs(`analyze_rates-design` = "ratio")
  app$wait_for_idle(800, timeout = 60000)
  ratio <- ui_output_text(app, "analyze_rates-result")
  expect_match(ratio, "0\\.461")                  # Feychting et al. 1998: IRR 0.46
  expect_match(ratio, "Rate ratio -- exact")
  expect_match(ratio, "Population attributable fraction")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Paired, Agreement and Trend Tests: McNemar, kappa (3x3, weighted) and trend render their results", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Paired, Agreement and Trend Tests")
  mc <- ui_output_text(app, "analyze_tests-result")
  expect_match(mc, "McNemar chi-square")
  expect_match(mc, "2\\.882")                         # = stats::mcnemar.test(correct = FALSE)
  app$set_inputs(`analyze_tests-design` = "kappa")
  app$wait_for_idle(800, timeout = 60000)
  kp <- ui_output_text(app, "analyze_tests-result")
  expect_match(kp, "0\\.650")                         # unweighted kappa of the default 3x3 table (= DescTools)
  expect_match(kp, "Observed agreement")
  app$set_inputs(`analyze_tests-weights` = "quadratic")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "analyze_tests-result"), "0\\.747")
  app$set_inputs(`analyze_tests-design` = "trend")
  app$wait_for_idle(800, timeout = 60000)
  tr <- ui_output_text(app, "analyze_tests-result")
  expect_match(tr, "Chi-square for trend")
  expect_match(tr, "increasing")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Standardization and SMR: the published direct example, a two-group comparison, indirect and direct SMR", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Standardization and SMR")
  dr <- ui_output_text(app, "analyze_std-result")
  expect_match(dr, "Directly standardized rate")
  expect_match(dr, "264\\.7")                           # Thrusfield (2007) / epiR: 0.2647 per dog-year, per 1000
  app$set_inputs(`analyze_std-compare` = TRUE)
  app$wait_for_idle(800, timeout = 60000)
  two <- ui_output_text(app, "analyze_std-result")
  expect_match(two, "Group B")
  expect_match(two, "259\\.9")                          # Glasgow 0.2599 per dog-year
  expect_match(two, "Ratio")
  app$set_inputs(`analyze_std-design` = "indirect")
  app$wait_for_idle(800, timeout = 60000)
  ind <- ui_output_text(app, "analyze_std-result")
  expect_match(ind, "expected 52")                        # 550 x 0.025 + 450 x 0.085, as in epi.indirectadj()
  expect_match(ind, "1\\.115")
  app$set_inputs(`analyze_std-design` = "smr")
  app$wait_for_idle(800, timeout = 60000)
  smr <- ui_output_text(app, "analyze_std-result")
  expect_match(smr, "0\\.8470")                                          # exact lower limit, = poisson.test(58, 52)
  expect_match(smr, "Rothman-Greenland")                                   # the side-by-side comparison of interval methods
  expect_match(smr, "Vandenbroucke")
  expect_match(smr, "Byar approximation")
  expect_equal(ui_output_errors(app), 0)
})

test_that("no JavaScript or Shiny errors accumulated while opening every module", {
  skip_if_no_ui()
  expect_equal(ui_console_errors(ui_driver()), character())
})

# --- slow lane: every design of every module ---------------------------------

.ui_primary_radio <- function(app, id) {
  for (g in c("design", "outcome", "mode", "es_type")) {
    vals <- app$get_js(sprintf(
      "Array.from(document.querySelectorAll('input[type=radio]')).filter(function(e){return e.name === %s;}).map(function(e){return e.value;})",
      ui_js_string(paste0(id, "-", g))))
    if (length(vals)) return(list(group = g, values = unlist(vals)))
  }
  NULL
}

for (m in registry) {
  local({
    m <- m
    test_that(sprintf("UI (every design): module '%s' renders each design without output errors", m$id), {
      skip_if_not_slow()
      skip_if_no_ui()
      app <- ui_driver()
      ui_open_module(app, m$title)
      radio <- .ui_primary_radio(app, m$id)
      skip_if(is.null(radio), "module has no design selector")
      for (v in radio$values) {
        ui_choose_radio(app, paste0(m$id, "-", radio$group), v)
        app$wait_for_idle(800, timeout = 180000)
        expect_equal(ui_output_errors(app), 0, info = paste(m$id, v))
      }
    })
  })
}
