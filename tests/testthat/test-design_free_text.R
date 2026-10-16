.terminal_key <- function(res) {
  node <- design_nodes[[res$node_id]]
  if (!isTRUE(node$terminal)) return(NULL)
  if (is.function(node$catalog_key)) node$catalog_key(res$flags) else node$catalog_key
}

test_that("estimation phrasing resolves to single-proportion precision", {
  res <- walk_free_text("To estimate the prevalence of anaemia among adolescent girls in a block")
  expect_true(res$reached_terminal)
  expect_equal(.terminal_key(res), "proportion_single_precision")
  expect_true(isTRUE(catalog_entry(.terminal_key(res))$built))
})

test_that("estimation phrasing for a mean resolves to single-mean precision", {
  res <- walk_free_text("We want to estimate the mean haemoglobin level among pregnant women")
  expect_true(res$reached_terminal)
  expect_equal(.terminal_key(res), "means_single_precision")
})

test_that("matched case-control phrasing resolves to matched case-control", {
  res <- walk_free_text("We compared cases and controls, individually matched 1:1, for exposure to pesticide")
  expect_true(res$reached_terminal)
  expect_equal(.terminal_key(res), "case_control_matched")
})

test_that("unmatched case-control phrasing resolves to unmatched case-control", {
  res <- walk_free_text("This is an unmatched case-control study of cases and controls and their exposure to smoking")
  expect_true(res$reached_terminal)
  expect_equal(.terminal_key(res), "case_control_unmatched")
})

test_that("cohort phrasing resolves to cohort/RR", {
  res <- walk_free_text("Followed up a cohort of exposed and unexposed workers for incidence of lung disease")
  expect_true(res$reached_terminal)
  expect_equal(.terminal_key(res), "cohort_rr")
})

test_that("qualitative phrasing resolves to the guidance terminal (no numeric N)", {
  res <- walk_free_text("This qualitative study used in-depth interviews and thematic analysis")
  expect_true(res$reached_terminal)
  node <- design_nodes[[res$node_id]]
  expect_true(isTRUE(node$guidance))
})

test_that("prediction-model phrasing stops at the development/validation sub-question", {
  res <- walk_free_text("We aim to develop and validate a prognostic risk score")
  expect_false(res$reached_terminal)
  expect_equal(res$node_id, "pred_type")
  expect_length(res$trace, 1)
})

test_that("a comparator mentioned alongside an estimation-sounding word still routes to comparison", {
  res <- walk_free_text("A cross-sectional study comparing the proportion of hypertension between two groups")
  expect_false(res$reached_terminal)
  # first trace step must be the "compare" branch (option 2), not "estimate" (option 1)
  expect_match(res$trace[[1]]$answer, "^Compare groups")
})

test_that("diagnostic-accuracy phrasing stops at the diagnostic sub-question (no rule authored yet)", {
  res <- walk_free_text("We assessed the sensitivity and specificity of a new test against a gold standard")
  expect_false(res$reached_terminal)
  expect_equal(res$node_id, "diag_type")
})

test_that("RCT phrasing advances through allocation but stops at the unmodelled exp_unit branch", {
  res <- walk_free_text("This is a randomised controlled trial comparing time to recurrence")
  expect_false(res$reached_terminal)
  expect_equal(res$node_id, "exp_unit")
  expect_length(res$trace, 2)
})

test_that("unrecognizable text degrades honestly to root with an empty trace", {
  res <- walk_free_text("asdf qwer zxcv")
  expect_equal(res$node_id, "root")
  expect_length(res$trace, 0)
  expect_false(res$reached_terminal)
})

test_that("empty or NULL text degrades to root without erroring", {
  expect_equal(walk_free_text("")$node_id, "root")
  expect_equal(walk_free_text("   ")$node_id, "root")
  expect_equal(walk_free_text(NULL)$node_id, "root")
})

test_that("a deliberately ambiguous phrase ('risk factors for') is never auto-routed", {
  # The algorithm doc explicitly flags this phrasing as low-confidence/ambiguous
  # (cohort vs. case-control vs. prediction model) and says it "must ask" --
  # confirm no rule exists that would silently pick a branch for it.
  res <- walk_free_text("risk factors for diabetes among adults")
  expect_equal(res$node_id, "root")
  expect_length(res$trace, 0)
})

test_that("every option_index referenced by a free-text rule exists at that node", {
  for (node_id in names(free_text_rules)) {
    node <- design_nodes[[node_id]]
    expect_false(is.null(node), info = paste("rule authored for missing node", node_id))
    for (rule in free_text_rules[[node_id]]) {
      expect_true(rule$option_index >= 1 && rule$option_index <= length(node$options),
                  info = paste0("node '", node_id, "' rule references out-of-range option_index ", rule$option_index))
    }
  }
})

test_that("analysis phrasing reaches the Analyze branch, and planning phrasing is not hijacked", {
  r <- walk_free_text("I want to analyze the counts I have: a 2x2 table with an odds ratio")
  expect_equal(r$trace[[1]]$answer, design_nodes$root$options[[10]]$label)
  expect_equal(r$node_id, "analyze_design")           # 2x2 -> asks how subjects were sampled; no rule there
  r <- walk_free_text("Mantel-Haenszel analysis of stratified tables")
  expect_equal(r$node_id, "analyze_mh_design")
  r <- walk_free_text("analyze the counts: standardized mortality ratio (SMR) for a cohort")
  expect_equal(r$node_id, "analyze_std_type")
  r <- walk_free_text("analyze the counts I already have for vaccine efficacy")
  expect_equal(r$node_id, "analyze_vaccine_type")
  r <- walk_free_text("from the summary counts, rate ratio per person-years")
  expect_equal(r$node_id, "analyze_rate_type")
  # planning texts that merely mention analysis-sounding words keep their old route
  expect_equal(walk_free_text("sample size for a vaccine efficacy trial, randomized")$trace[[1]]$answer, design_nodes$root$options[[2]]$label)
  expect_equal(walk_free_text("estimate sensitivity and specificity against a gold standard")$trace[[1]]$answer, design_nodes$root$options[[4]]$label)
})
