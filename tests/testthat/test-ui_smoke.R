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
  ui_select_tab(app, "main_nav", "Home")
  app$run_js("document.getElementById('home_go_browse').click()")   # "Browse all calculators": the Find a calculator tab
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Find a calculator' && Shiny.shinyapp.$inputValues['home_helper'] === 'Browse all calculators'", timeout = 30000)
  app$wait_for_js("!!document.getElementById('home_browse_axis')", timeout = 30000)
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

test_that("Variance Tests and Multiplicity Adjustment keep the alternative hypothesis in a folded Advanced options panel", {
  skip_if_no_ui()
  app <- ui_driver()
  for (m in list(list(title = "Variance Tests", id = "variance"), list(title = "Multiplicity Adjustment", id = "multiplicity"))) {
    ui_open_module(app, m$title)
    sel <- sprintf("#%s-adv_acc", m$id)
    expect_true(app$get_js(sprintf("document.querySelector(%s) !== null", ui_js_string(sel))), info = m$title)
    # the select sits inside the panel, which is closed, and it still has a value the calculation reads
    expect_true(app$get_js(sprintf("document.querySelector(%s) !== null",
                                   ui_js_string(paste(sel, sprintf("#%s-alternative", m$id))))), info = m$title)
    expect_false(app$get_js(sprintf("document.querySelector(%s).classList.contains('show')",
                                    ui_js_string(paste(sel, ".accordion-collapse")))), info = m$title)
    expect_equal(app$get_value(input = paste0(m$id, "-alternative")), "two.sided", info = m$title)
    expect_gt(nchar(ui_output_text(app, paste0(m$id, "-result"))), 0)
  }
})

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

test_that("Compare Two Groups: proportions list the interval methods side by side; means give Welch and pooled", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Compare Two Groups")
  pr <- ui_output_text(app, "analyze_compare-result")
  expect_match(pr, "Miettinen-Nurminen score")
  expect_match(pr, "Newcombe hybrid score")
  expect_match(pr, "Koopman score")
  expect_match(pr, "0\\.0528 to 0\\.338")           # Miettinen-Nurminen for 56/70 vs 48/80 (= DescTools::BinomDiffCI)
  app$set_inputs(`analyze_compare-design` = "means")
  app$wait_for_idle(800, timeout = 60000)
  me <- ui_output_text(app, "analyze_compare-result")
  expect_match(me, "Welch")
  expect_match(me, "Student, pooled variance")
  expect_match(me, "Hedges")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Rates: stratified design gives the Mantel-Haenszel rate ratio next to the crude one", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Rates and Rate Ratios")
  app$set_inputs(`analyze_rates-design` = "stratified")
  app$wait_for_idle(800, timeout = 60000)
  st <- ui_output_text(app, "analyze_rates-result")
  expect_match(st, "Mantel-Haenszel adjusted")
  expect_match(st, "2\\.16")                           # MH rate ratio 2.16 (= epiR::epi.2by2 cohort.time)
  expect_match(st, "1\\.30 to 3\\.60")
  expect_match(st, "Breslow-Day type")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Vaccine Efficacy: the three data types show their intervals side by side", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Vaccine Efficacy")
  rk <- ui_output_text(app, "analyze_vaccine-result")
  expect_match(rk, "Vaccine efficacy = 95\\.0%")
  expect_match(rk, "Koopman score")
  expect_match(rk, "90\\.0% to 97\\.5%")
  app$set_inputs(`analyze_vaccine-design` = "rate")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "analyze_vaccine-result"), "89\\.4% to 97\\.8%")
  app$set_inputs(`analyze_vaccine-design` = "odds")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "analyze_vaccine-result"), "Vaccine efficacy = 75\\.0%")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Attrition and Non-response: 200 analyzable with 10/15/20% losses needs 327; arms and dilution designs work", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Attrition and Non-response")
  st <- ui_output_text(app, "attrition-result")
  expect_match(st, "Enrol 327 participants")
  expect_match(st, "Adding the losses instead would give 290")
  app$set_inputs(`attrition-design` = "arms")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "attrition-result"), "Enrol 255 participants in total")
  app$set_inputs(`attrition-design` = "noncompliance")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "attrition-result"), "139 per arm")
  expect_equal(ui_output_errors(app), 0)
})

test_that("precision calculators: relative precision, the hard stop, the 20% warning and non-response inflation", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Proportions")
  expect_match(ui_output_text(app, "proportion-result"), "Required sample size \\(to analyze\\): 385")
  expect_match(ui_output_text(app, "proportion-precision_equiv"), "relative \\+/- 10% of p")
  app$set_inputs(`proportion-p_precision` = 0.03)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "proportion-result"), "would reach below 0")
  app$set_inputs(`proportion-p_precision` = 0.2, `proportion-error_precision` = "relative", `proportion-eps_precision` = 0.1,
                 `proportion-nonresponse_precision` = 0.1)
  app$wait_for_idle(800, timeout = 60000)
  st <- ui_output_text(app, "proportion-result")
  expect_match(st, ": 1537")
  expect_match(st, "non-response / loss to follow-up: 1708")
  app$set_inputs(`proportion-eps_precision` = 0.3)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "proportion-result"), "above 20%")

  ui_open_module(app, "Incidence Rate")
  app$set_inputs(`rate-error_rate` = "relative", `rate-epsilon_rate` = 0.2, `rate-nonresponse_rate` = 0.1)
  app$wait_for_idle(800, timeout = 60000)
  st <- ui_output_text(app, "rate-result")
  expect_match(st, "Required number of events: 97")
  expect_match(st, "43.11")

  ui_open_module(app, "Diagnostic Accuracy")
  app$set_inputs(`diagnostic-sens` = 0.95)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "diagnostic-result"), "1 - sensitivity")
  app$set_inputs(`diagnostic-sens` = 0.9, `diagnostic-nonresponse_precision` = 0.1)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "diagnostic-result"), "non-response / loss to follow-up")
  expect_equal(ui_output_errors(app), 0)
})

test_that("effect inputs: case-control p1 and phi from a pairs table, log-rank HR from pE and pC, a rate ratio from two rates, mean and SD from a median and IQR", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Case-Control")
  app$set_inputs(`case_control-effect_as` = "p1", `case_control-p1_cases` = 0.4615385)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "case_control-result"), "Total sample size: 282")    # the same as OR = 2 with p0 = 0.3
  expect_match(ui_output_text(app, "case_control-effect_equiv"), "odds ratio of 2")
  app$set_inputs(`case_control-design` = "matched")
  app$wait_for_idle(800, timeout = 60000)
  ui_choose_radio(app, "case_control-phi_as", "table")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "case_control-phi_table_result"), "phi = 0.328 from 100 pairs")
  expect_match(ui_output_text(app, "case_control-result"), "phi 0.328")

  ui_open_module(app, "Log-Rank / Survival")
  ui_choose_radio(app, "logrank-hr_as_logrank", "implied")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "logrank-result"), "Hazard ratio used: 0.690 \\(from pE and pC\\)")

  ui_open_module(app, "Incidence Rate")
  app$set_inputs(`rate-design` = "comparison")
  app$wait_for_idle(800, timeout = 60000)
  before <- ui_output_text(app, "rate-result")
  app$set_inputs(`rate-ratio_as_comp` = "rate", `rate-rate_exp` = 2.798 * 0.8938)
  app$wait_for_idle(800, timeout = 60000)
  expect_equal(ui_output_text(app, "rate-result"), before)

  ui_open_module(app, "Means")
  app$run_js("document.querySelectorAll('details').forEach(function(d){d.open = true})")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "means-iqr_result"), "Estimated mean 45.67, SD 12.15")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Effect Size: the converters give the published values, tips open on hover and tap, and the Glossary lists the terms", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Effect Size")
  expect_match(ui_output_text(app, "effect_size-result"), "Cohen's d: 0.322")
  ui_choose_radio(app, "effect_size-design", "proportions")
  app$wait_for_idle(800, timeout = 60000)
  st <- ui_output_text(app, "effect_size-result")
  expect_match(st, "Odds ratio: 2.000")
  expect_match(st, "Risk \\(prevalence\\) ratio: 1.905")       # OpenEpi's cohort form for p0 = 5%, OR = 2
  expect_match(st, "Risk difference: 0.045")
  ui_choose_radio(app, "effect_size-design", "matched_pairs")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "effect_size-result"), "phi: 0.328")
  # an information tip opens its popover on keyboard focus and closes again
  app$run_js("document.querySelector('#effect_size-result .info-tip').focus()")
  app$wait_for_js("document.querySelectorAll('.popover.show').length === 1", timeout = 10000)
  expect_match(app$get_js("document.querySelector('.popover.show').innerText"), "correlation between two yes/no variables")
  app$run_js("document.activeElement.blur()")
  app$wait_for_js("document.querySelectorAll('.popover.show').length === 0", timeout = 10000)
  # the Glossary page lists every term and filters
  ui_select_tab(app, "main_nav", "Find a calculator")
  app$run_js("document.querySelector('#home_helper a[data-value=\"Glossary\"]').click()")
  app$wait_for_js("document.querySelectorAll('.glossary-item').length > 25", timeout = 30000)
  app$set_inputs(glossary_filter = "phi")
  app$run_js("var e=document.getElementById('glossary_filter'); e.value='phi'; e.dispatchEvent(new Event('input', {bubbles: true}))")
  app$wait_for_js("Array.from(document.querySelectorAll('.glossary-item')).filter(function(e){return e.style.display !== 'none'}).length < 6", timeout = 10000)
  expect_equal(ui_output_errors(app), 0)
})

test_that("OpenEpi-style inputs: means (difference, variances), cohort (odds ratio), Cohen's f from means", {
  skip_if_no_ui()
  app <- ui_driver()
  # OpenEpi's mean-difference form: the difference and the variances; its example inputs give 152 per group
  ui_open_module(app, "Means")
  ui_choose_radio(app, "means-design", "welch")
  app$wait_for_idle(800, timeout = 60000)
  ui_choose_radio(app, "means-effect_as_welch", "diff")
  ui_choose_radio(app, "means-spread_as_welch", "var")
  app$set_inputs(`means-diff_welch` = 5.42, `means-var1_welch` = 15.34^2, `means-var2_welch` = 18.23^2, `means-ratio_welch` = 1, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "means-result"), "n1 = 152, n2 = 152")
  expect_match(ui_output_text(app, "means-effect_equiv_welch"), "Difference 5.42")
  ui_choose_radio(app, "means-design", "two_sample")
  ui_choose_radio(app, "means-effect_as_two", "d")
  app$set_inputs(`means-d_two` = 0.5, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "means-result"), "Required sample size per group: 64")

  # cohort: the odds ratio instead of the exposed group's risk (OpenEpi: 5% unexposed, OR 2 -> 9.52%, RR 1.90, RD 4.52)
  ui_open_module(app, "Cohort / RR")
  app$set_inputs(`cohort-p0` = 0.05, wait_ = FALSE)
  ui_choose_radio(app, "cohort-cohort_given", "OR")
  app$set_inputs(`cohort-cohort_OR` = 2, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "cohort-cohort_equiv"), "proportion 0.09524, odds ratio 2, risk ratio 1.905, risk difference 0.0452")
  expect_match(ui_output_text(app, "cohort-result"), "Total sample size: 1032")
  expect_match(ui_output_text(app, "cohort-result"), "odds ratio 2.000")

  # Cohen's f from group means and SD, in Kruskal-Wallis
  ui_open_module(app, "Nonparametric Tests")
  ui_choose_radio(app, "nonparametric-design", "kruskal_wallis")
  app$wait_for_idle(800, timeout = 60000)
  ui_choose_radio(app, "nonparametric-f_kw_as", "means")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "nonparametric-f_kw_equiv"), "Cohen's f = 0.342")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Calculate this / Use this value: a number goes from the converter back into the calculator", {
  skip_if_no_ui()
  app <- ui_driver()
  es_wb <- module_workbench_of("Effect Size")
  # Cohen's f in Kruskal-Wallis, from eta-squared
  ui_open_module(app, "Nonparametric Tests")
  ui_choose_radio(app, "nonparametric-design", "kruskal_wallis")
  app$wait_for_idle(800, timeout = 60000)
  app$click("nonparametric-es_f_kw")
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_value(input = "main_nav"), es_wb$title)
  expect_equal(app$get_value(input = "effect_size-design"), "anova_f")
  expect_match(ui_output_text(app, "effect_size-link_panel"), "Opened from Nonparametric Tests")
  ui_choose_radio(app, "effect_size-f_from", "eta2")
  app$set_inputs(`effect_size-f_eta2` = 0.06, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "effect_size-link_panel"), "Use Cohen's f = 0.2526 in Nonparametric Tests")
  app$click("effect_size-use_value")
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_value(input = module_workbench_of("Nonparametric Tests")$nav_id), "Nonparametric Tests")
  expect_equal(app$get_value(input = "nonparametric-f_kw_as"), "f")
  expect_equal(app$get_value(input = "nonparametric-f_kw"), 0.2526)
  # the panel is gone once the value is used
  expect_false(nzchar(ui_output_text(app, "effect_size-link_panel")))

  # the hazard ratio in the log-rank calculator, from median survival (18 and 12 months -> 0.6667)
  ui_open_module(app, "Log-Rank / Survival")
  app$click("logrank-es_hr_logrank")
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_value(input = "effect_size-design"), "hazard_ratio")
  app$click("effect_size-use_value")
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_value(input = "logrank-hr_logrank"), 0.6667)

  # a result that does not give the number offers no button; going back leaves the input as it was
  ui_open_module(app, "Means")
  ui_choose_radio(app, "means-design", "two_means")
  app$wait_for_idle(800, timeout = 60000)
  ui_choose_radio(app, "means-effect_as_two", "d")
  app$set_inputs(`means-d_two` = 0.5, wait_ = FALSE)
  app$click("means-es_d_two")
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_value(input = "effect_size-design"), "from_t")
  ui_choose_radio(app, "effect_size-design", "chisq_w")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "effect_size-link_panel"), "does not give Cohen's d")
  expect_equal(app$get_js("document.querySelector('#effect_size-use_value') === null"), TRUE)
  app$click("effect_size-back_without")
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_value(input = module_workbench_of("Means")$nav_id), "Means")
  expect_equal(app$get_value(input = "means-d_two"), 0.5)
  expect_equal(ui_output_errors(app), 0)
})

test_that("Cluster / Design Effect: the design effect from variances, and entered directly (1.5)", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Cluster / Design Effect")
  expect_match(ui_output_text(app, "cluster-result"), "Design effect \\(DEFF\\).*: 1.450")
  ui_choose_radio(app, "cluster-deff_route", "deff")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "cluster-result"), "1.500")
  expect_match(ui_output_text(app, "cluster-result"), "sample size: 300")
  ui_choose_radio(app, "cluster-design", "deff_calc")
  app$wait_for_idle(800, timeout = 60000)
  st <- ui_output_text(app, "cluster-result")
  expect_match(st, ": 1.450"); expect_match(st, "ICC.*: 0.0500"); expect_match(st, "variance components")
  ui_choose_radio(app, "cluster-dc_from", "means")
  app$set_inputs(`cluster-dc_m` = 20, `cluster-dc_vmeans` = 0.0125, `cluster-dc_p` = 0.3, wait_ = FALSE)
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "cluster-result"), ": 1.190")
  ui_choose_radio(app, "cluster-dc_from", "design")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "cluster-result"), ": 1.500")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Randomization List: the same seed gives the same list; blocks balance; stratified lists per site", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Randomization List")
  r1 <- ui_output_text(app, "randomization-result")
  expect_match(r1, "24 participants listed")
  expect_match(r1, "11\\D+13\\D+24")                    # seed 2026, blocks of 4 or 6: 11 vs 13 (last block incomplete)
  m1 <- ui_output_text(app, "randomization-methods_text")
  expect_match(m1, "seed 2026")
  app$set_inputs(`randomization-seed` = 5)
  app$wait_for_idle(800, timeout = 60000)
  app$set_inputs(`randomization-seed` = 2026)
  app$wait_for_idle(800, timeout = 60000)
  expect_equal(ui_output_text(app, "randomization-result"), r1)       # back to seed 2026 -> identical list
  app$set_inputs(`randomization-design` = "stratified")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "randomization-result"), "Site B")
  app$set_inputs(`randomization-design` = "simple")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "randomization-result"), "simple randomization")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Survey Sample Selection: PPS shows a certainty unit and the exact check; EPI gives 30 clusters and 210 subjects", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Survey Sample Selection")
  r <- ui_output_text(app, "survey_selection-result")
  expect_match(r, "4 of 12 units selected")
  expect_match(r, "taken with certainty")
  expect_match(r, "Check: the design-weighted sum of the selected sizes is")
  app$set_inputs(`survey_selection-design` = "epi")
  app$wait_for_idle(800, timeout = 60000)
  expect_equal(ui_output_errors(app), 0)
  app$set_inputs(`survey_selection-design` = "srs")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "survey_selection-result"), "40 of 500 units selected")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Survey Weights and Non-response: the worked example gives weighted response rate 75.5% and effective n 96.2", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Survey Weights and Non-response")
  r <- ui_output_text(app, "survey_weights-result")
  expect_match(r, "weighted response rate 75\\.5%")
  expect_match(r, "96\\.2")
  app$set_inputs(`survey_weights-design` = "kish")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "survey_weights-result"), "Effective sample size 3\\.600 of 4")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Outbreak Measures: attack rate, the food-specific table, and case fatality with its bias note", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Outbreak Measures")
  expect_match(ui_output_text(app, "analyze_outbreak-result"), "Attack rate 25\\.0% \\(30 of 120\\)")
  app$set_inputs(`analyze_outbreak-design` = "exposure")
  app$wait_for_idle(800, timeout = 60000)
  r <- ui_output_text(app, "analyze_outbreak-result")
  expect_match(r, "Salad"); expect_match(r, "Highest risk ratio: Salad \\(6\\.00\\)")
  app$set_inputs(`analyze_outbreak-design` = "cfr")
  app$wait_for_idle(800, timeout = 60000)
  r <- ui_output_text(app, "analyze_outbreak-result")
  expect_match(r, "Case fatality 7\\.5% \\(6 deaths among 80 cases\\)")
  expect_match(r, "15\\.0%")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Aberration Detection: EARS C2 and CUSUM signal on the example series and draw a plot", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Aberration Detection")
  expect_match(ui_output_text(app, "analyze_surveillance-result"), "C2: 4 signals in 29 monitored observations")
  app$set_inputs(`analyze_surveillance-design` = "cusum")
  app$wait_for_idle(800, timeout = 60000)
  r <- ui_output_text(app, "analyze_surveillance-result")
  expect_match(r, "CUSUM \\(normal\\): 4 signals in 24 monitored observations")
  expect_match(r, "first is observation 32")
  expect_equal(ui_output_errors(app), 0)
})

test_that("Epidemic Models and Herd Immunity: threshold, SIR run with the textbook final size, and R0 from the doubling time", {
  skip_if_no_ui()
  app <- ui_driver()
  ui_open_module(app, "Epidemic Models and Herd Immunity")
  r <- ui_output_text(app, "epidemic_model-result")
  expect_match(r, "Herd-immunity threshold 91\\.7%"); expect_match(r, "Re = 1\\.74")
  app$set_inputs(`epidemic_model-design` = "sim", `epidemic_model-r0` = 2.5, `epidemic_model-coverage` = 0, `epidemic_model-efficacy` = 1)
  app$wait_for_idle(1500, timeout = 90000)
  r <- ui_output_text(app, "epidemic_model-result")
  expect_match(r, "SIR epidemic: 89\\.3% of the population infected")
  expect_match(r, "on day 45")
  app$set_inputs(`epidemic_model-design` = "r0")
  app$wait_for_idle(800, timeout = 60000)
  expect_match(ui_output_text(app, "epidemic_model-result"), "R0 = 2\\.16 \\(SIR form\\)")
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

# --- lazy loading of the calculators (start-up time) -------------------------

test_that("start-up builds only the core calculators; lazy = FALSE builds all (static check)", {
  count_placeholders <- function(app) {
    html <- htmltools::renderTags(attr(app, "ui_tags"))$html
    lengths(regmatches(html, gregexpr('id="lazy_', html)))
  }
  n_lazy <- count_placeholders(epidemiologysuite_app(lazy = TRUE))
  expect_equal(n_lazy, length(module_registry()) - length(lazy_core_modules))
  expect_equal(count_placeholders(epidemiologysuite_app(lazy = FALSE)), 0)
  expect_true(all(lazy_core_modules %in% vapply(module_registry(), `[[`, character(1), "id")))
  # the module every workbench opens on (its first, or the one it names) is a core module, so none opens on a placeholder
  firsts <- vapply(module_workbenches, function(wb) if (!is.null(wb$open_on)) wb$open_on else wb$groups[[1]]$module_ids[1], "")
  expect_true(all(firsts %in% lazy_core_modules))
})

test_that("a Home jump to a calculator that is not loaded yet loads it and then sets its design", {
  skip_if_no_ui()
  app <- ui_fresh_driver(name = "lazy_jump")
  withr::defer(app$stop())
  expect_true(app$get_js("!!document.querySelector('#lazy_survey_selection > .lazy-note')"))   # not loaded at start
  ids <- home_browse_button_ids()
  btn <- names(ids)[ids == "survey_select_epi"][1]
  app$run_js(sprintf("Shiny.setInputValue(%s, 1, {priority: 'event'})", ui_js_string(btn)))   # what the Home button sends
  app$wait_for_js("Shiny.shinyapp.$inputValues['survey_selection-design'] === 'epi'", timeout = 60000)
  expect_false(app$get_js("!!document.querySelector('#lazy_survey_selection > .lazy-note')"))
  app$wait_for_idle(800, timeout = 60000)
  expect_equal(ui_output_errors(app), 0)
})

test_that("background loading fills in every calculator with the indicator beside the lists, without errors", {
  skip_if_no_ui()
  old <- Sys.getenv("EPIDEMIOLOGYSUITE_BACKGROUND_LOAD"); on.exit(Sys.setenv(EPIDEMIOLOGYSUITE_BACKGROUND_LOAD = old), add = TRUE)
  app <- ui_fresh_driver(background_load = TRUE, name = "lazy_bg")
  withr::defer(app$stop())
  # the indicator beside the calculator lists: faint entries for what is still to come, and a bar with the count
  expect_true(app$get_js("document.querySelectorAll('ul.nav-stacked a.lazy-pending').length") > 0)
  expect_true(app$get_js("document.querySelectorAll('.lazy-box').length") == 2)       # one per workbench
  expect_true(app$get_js("document.querySelectorAll('.lazy-note').length") > 0)
  app$wait_for_js("document.querySelectorAll('.lazy-note').length === 0", timeout = 240000)
  app$wait_for_idle(1500, timeout = 120000)
  expect_equal(app$get_js("document.querySelectorAll('ul.nav-stacked a.lazy-pending').length"), 0)   # nothing left to come
  expect_equal(app$get_js("document.querySelectorAll('.lazy-box:not(.lazy-complete)').length"), 0)   # and the bar has finished
  expect_equal(ui_output_errors(app), 0)
  ui_open_module(app, "Epidemic Models and Herd Immunity")
  # a calculator loaded in the background renders once its tab is shown; on a slow machine that is after "idle" first reads true
  app$wait_for_js("(function(){var e=document.getElementById('epidemic_model-result'); return !!e && e.innerText.trim().length > 0;})()", timeout = 60000)
  expect_match(ui_output_text(app, "epidemic_model-result"), "Herd-immunity threshold 91\\.7%")
})

# --- Home wizard (guided questions + free-text box) --------------------------

.wizard_open <- function(app) {
  ui_select_tab(app, "main_nav", "Home")
  app$run_js("document.getElementById('home_go_wizard').click()")   # "Start the guide": the Find a calculator tab, guided questions
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Find a calculator' && Shiny.shinyapp.$inputValues['home_helper'] === 'Guided questions'", timeout = 30000)
  app$wait_for_js("(function(){var e=document.getElementById('design_wizard_freetext'); return !!e && e.getBoundingClientRect().width > 0;})()", timeout = 30000)
  app$wait_for_idle(500, timeout = 30000)
}

test_that("the wizard's question box is full width and tall enough to read, and the Home card is not a small scroll window", {
  skip_if_no_ui()
  app <- ui_driver()
  .wizard_open(app)
  box <- app$get_js("(function(){var r=document.getElementById('design_wizard_freetext').getBoundingClientRect(); return [r.width, r.height];})()")
  expect_gt(box[[1]], 400); expect_gt(box[[2]], 70)
  # no card body on the Home page scrolls inside a window smaller than its content
  expect_equal(app$get_js("Array.from(document.querySelectorAll('.card-body')).filter(function(e){return e.clientHeight > 0 && e.scrollHeight > e.clientHeight + 4;}).length"), 0)
})

test_that("wizard: a cohort with a measured outcome reaches the means calculators, Back steps back, free text pre-fills", {
  skip_if_no_ui()
  app <- ui_driver()
  .wizard_open(app)
  app$set_inputs(design_wizard_freetext = "Cohort study, difference in mean blood pressure between exposed and unexposed")
  app$click("design_wizard_parse")
  app$wait_for_idle(800, timeout = 30000)
  txt <- ui_output_text(app, "design_wizard_trace")
  expect_match(txt, "auto-suggested")
  expect_match(txt, "Their exposure status")
  expect_match(txt, "A measurement compared between exposed and unexposed")
  expect_match(ui_output_text(app, "design_wizard_body"), "Anything unusual about the two groups")
  # click through to the calculator
  ui_wait_bound(app, "design_wizard_choice"); app$set_inputs(design_wizard_choice = "1"); app$click("design_wizard_next"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Two independent groups")
  expect_match(ui_output_text(app, "design_wizard_body"), "Go to: Means")
  # Back returns to the previous question
  app$click("design_wizard_back"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Anything unusual about the two groups")
  app$click("design_wizard_restart"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "primary purpose of your study")
  expect_equal(ui_output_errors(app), 0)
})

test_that("wizard: the case-control question offers a measured exposure, and its Go to button opens the means calculator", {
  skip_if_no_ui()
  app <- ui_driver()
  .wizard_open(app)
  if (app$get_js("!!document.getElementById('design_wizard_restart')")) { app$click("design_wizard_restart"); app$wait_for_idle(500, timeout = 30000) }
  app$set_inputs(design_wizard_freetext = "Case-control study comparing mean serum lead level between cases and controls, unmatched")
  app$click("design_wizard_parse"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Anything unusual about the two groups")
  ui_wait_bound(app, "design_wizard_choice"); app$set_inputs(design_wizard_choice = "1"); app$click("design_wizard_next"); app$wait_for_idle(800, timeout = 30000)
  expect_match(ui_output_text(app, "design_wizard_body"), "Go to: Means")
  app$click("design_wizard_jump")
  app$wait_for_js("Shiny.shinyapp.$inputValues['main_nav'] === 'Plan: Sample Size'", timeout = 60000)
  app$wait_for_js("Shiny.shinyapp.$inputValues['means-design'] !== undefined", timeout = 60000)
  expect_equal(ui_output_errors(app), 0)
})
