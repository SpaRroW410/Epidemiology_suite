source(file.path("..", "..", "R", "home", "home_catalog.R"))
source(file.path("..", "..", "R", "home", "design_tree.R"))

# Resolve a possibly-dynamic field (string, or function(flags) -> string/NULL)
# against every flag combination the tree can actually produce, so tests
# exercise both the "continuous" and "binary" outcome paths.
.flag_combos <- list(
  list(outcome = "continuous", cluster = FALSE),
  list(outcome = "binary", cluster = FALSE),
  list(outcome = "continuous", cluster = TRUE),
  list(outcome = "binary", cluster = TRUE)
)

.resolve <- function(field, flags) if (is.function(field)) field(flags) else field

test_that("every next_id (static or dynamic) points at a real node", {
  for (node in design_nodes) {
    if (isTRUE(node$terminal)) next
    for (opt in node$options) {
      for (flags in .flag_combos) {
        nid <- .resolve(opt$next_id, flags)
        expect_true(!is.null(nid) && nid %in% names(design_nodes),
                    info = paste0("node '", node$id, "' option '", opt$label, "' -> missing node '", nid, "'"))
      }
    }
  }
})

test_that("every terminal is either a built catalog entry, an explicit not-built note, or guidance", {
  terminals <- Filter(function(n) isTRUE(n$terminal), design_nodes)
  for (node in terminals) {
    for (flags in .flag_combos) {
      key <- .resolve(node$catalog_key, flags)
      if (!is.null(key)) {
        entry <- catalog_entry(key)
        expect_false(is.null(entry), info = paste0("terminal '", node$id, "' catalog_key '", key, "' not in calculator_catalog"))
        expect_true(isTRUE(entry$built), info = paste0("terminal '", node$id, "' points at an unbuilt catalog entry '", key, "'"))
      } else {
        expect_true(isTRUE(node$guidance) || !is.null(node$would_use),
                    info = paste0("terminal '", node$id, "' has no catalog_key, isn't guidance, and has no would_use note"))
      }
    }
  }
})

test_that("no node id collides with itself as its own next_id (no accidental infinite loop)", {
  for (node in design_nodes) {
    if (isTRUE(node$terminal)) next
    for (opt in node$options) {
      for (flags in .flag_combos) {
        nid <- .resolve(opt$next_id, flags)
        expect_false(identical(nid, node$id), info = paste0("node '", node$id, "' loops back to itself"))
      }
    }
  }
})

# --- Spot-check full paths end-to-end, mirroring how the wizard server walks
#     the tree (state$node_id starts at "root", flags accumulate from `set`).

.walk <- function(answer_labels) {
  node_id <- "root"
  flags <- list()
  for (label in answer_labels) {
    node <- design_nodes[[node_id]]
    opt <- Find(function(o) identical(o$label, label), node$options)
    if (is.null(opt)) stop("no option '", label, "' at node '", node_id, "'")
    if (!is.null(opt$set)) for (nm in names(opt$set)) flags[[nm]] <- opt$set[[nm]]
    node_id <- if (is.function(opt$next_id)) opt$next_id(flags) else opt$next_id
  }
  list(node = design_nodes[[node_id]], flags = flags)
}

test_that("estimation -> single proportion precision routes correctly", {
  res <- .walk(c("Estimate a parameter with precision (prevalence, mean, rate...)",
                 "A proportion / prevalence"))
  expect_true(isTRUE(res$node$terminal))
  expect_equal(res$node$catalog_key, "proportion_single_precision")
  expect_true(isTRUE(catalog_entry(res$node$catalog_key)$built))
})

test_that("RCT superiority, individual allocation, 2 independent continuous groups -> two independent means", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I (the investigator) assign it",
                 "Individual subjects",
                 "Show one arm is better (superiority)",
                 "Continuous (e.g. BP, Hb, BMI, a score)",
                 "2 groups",
                 "Independent",
                 "No -- equal group sizes and similar variances (t-test)"))
  expect_true(isTRUE(res$node$terminal))
  key <- res$node$catalog_key(res$flags)
  expect_equal(key, "means_two_indep")
})

test_that("RCT superiority, cluster allocation, 2 independent binary groups -> two proportions, cluster flag set", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I (the investigator) assign it",
                 "Groups/clusters (villages, schools, PHCs, wards)",
                 "Show one arm is better (superiority)",
                 "Binary (e.g. cured/not, positive/negative)",
                 "2 groups",
                 "Independent",
                 "Standard large-sample test (z / chi-square)"))
  expect_true(isTRUE(res$node$terminal))
  expect_true(isTRUE(res$flags$cluster))
  key <- res$node$catalog_key(res$flags)
  expect_equal(key, "proportion_two_indep")
})

test_that("observational, selected on outcome, unmatched -> unmatched case-control", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I only observe what happened naturally",
                 "Their outcome/disease status (exposure ascertained backwards)",
                 "No -- unmatched"))
  expect_true(isTRUE(res$node$terminal))
  expect_equal(res$node$catalog_key, "case_control_unmatched")
})

test_that("observational, selected on outcome, individually matched -> matched case-control", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I only observe what happened naturally",
                 "Their outcome/disease status (exposure ascertained backwards)",
                 "Yes -- individually matched 1:1 or 1:m"))
  expect_equal(res$node$catalog_key, "case_control_matched")
})

test_that("observational, each case is own control -> case-crossover, reuses matched case-control catalog entry", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I only observe what happened naturally",
                 "Each case is their own control, compared across different time windows (case-crossover)"))
  expect_true(isTRUE(res$node$terminal))
  expect_equal(res$node$catalog_key, "case_crossover")
  entry <- catalog_entry(res$node$catalog_key)
  expect_true(isTRUE(entry$built))
  expect_equal(entry$module_input_id, "case_control-design")
  expect_equal(entry$design_value, "matched")
})

test_that("observational, selected on exposure -> cohort/RR", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I only observe what happened naturally",
                 "Their exposure status (outcome measured/ascertained later)"))
  expect_equal(res$node$catalog_key, "cohort_rr")
})

test_that("comparison, time-to-event outcome -> log-rank", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I (the investigator) assign it",
                 "Individual subjects",
                 "Show one arm is better (superiority)",
                 "Time-to-event (e.g. survival, time to recurrence)",
                 "Log-rank test (two survival curves)"))
  expect_equal(res$node$catalog_key, "logrank")
})

test_that("single-arm Phase II -> Simon two-stage", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I (the investigator) assign it",
                 "Individual subjects",
                 "Single-arm, response rate vs. a historical control (Phase II)"))
  expect_equal(res$node$catalog_key, "simon_two_stage")
})

test_that("equivalence, continuous outcome -> TOST means; proportion outcome -> TOST proportions", {
  res_cont <- .walk(c("Compare groups / test an association or hypothesis",
                       "I (the investigator) assign it",
                       "Individual subjects",
                       "Show both arms are practically equivalent (equivalence)",
                       "Continuous (means)"))
  expect_equal(res_cont$node$catalog_key, "tost_means")

  res_prop <- .walk(c("Compare groups / test an association or hypothesis",
                       "I (the investigator) assign it",
                       "Individual subjects",
                       "Show both arms are practically equivalent (equivalence)",
                       "Proportion"))
  expect_true(isTRUE(res_prop$node$terminal))
  expect_equal(res_prop$node$catalog_key, "tost_proportions")
  expect_true(isTRUE(catalog_entry(res_prop$node$catalog_key)$built))
})

test_that("non-inferiority, continuous outcome -> means; proportion outcome -> proportions", {
  res_cont <- .walk(c("Compare groups / test an association or hypothesis",
                       "I (the investigator) assign it",
                       "Individual subjects",
                       "Show it's not unacceptably worse (non-inferiority)",
                       "Continuous (means)"))
  expect_equal(res_cont$node$catalog_key, "noninferiority_means")

  res_prop <- .walk(c("Compare groups / test an association or hypothesis",
                       "I (the investigator) assign it",
                       "Individual subjects",
                       "Show it's not unacceptably worse (non-inferiority)",
                       "Proportion"))
  expect_equal(res_prop$node$catalog_key, "noninferiority_proportions")
  expect_true(isTRUE(catalog_entry(res_prop$node$catalog_key)$built))
})

test_that("estimation -> single mean precision and incidence rate precision now route to built modules", {
  res_mean <- .walk(c("Estimate a parameter with precision (prevalence, mean, rate...)",
                      "A mean"))
  expect_equal(res_mean$node$catalog_key, "means_single_precision")
  expect_true(isTRUE(catalog_entry(res_mean$node$catalog_key)$built))

  res_rate <- .walk(c("Estimate a parameter with precision (prevalence, mean, rate...)",
                      "An incidence rate"))
  expect_equal(res_rate$node$catalog_key, "incidence_rate_precision")
  expect_true(isTRUE(catalog_entry(res_rate$node$catalog_key)$built))
})

test_that("qualitative branch is a guidance terminal pointing at the guidance module", {
  res <- .walk(c("Explore experiences or meanings (qualitative)"))
  expect_true(isTRUE(res$node$terminal))
  expect_true(isTRUE(res$node$guidance))
  expect_equal(res$node$catalog_key, "qualitative_guidance")
})

test_that("diagnostic -> PPV/NPV now routes to a built module", {
  res <- .walk(c("Assess the accuracy of a diagnostic test",
                 "Predictive values (PPV/NPV)"))
  expect_equal(res$node$catalog_key, "diagnostic_ppv_npv")
  expect_true(isTRUE(catalog_entry(res$node$catalog_key)$built))
})

test_that("comparison, count/rate outcome -> comparison of two incidence rates, now built", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I (the investigator) assign it",
                 "Individual subjects",
                 "Show one arm is better (superiority)",
                 "Count / rate (e.g. episodes per person-time)",
                 "Two groups' incidence rates (Poisson)"))
  expect_equal(res$node$catalog_key, "rate_comparison")
  expect_true(isTRUE(catalog_entry(res$node$catalog_key)$built))
})

test_that("paired binary outcome -> McNemar (paired proportions), now built", {
  res <- .walk(c("Compare groups / test an association or hypothesis",
                 "I (the investigator) assign it",
                 "Individual subjects",
                 "Show one arm is better (superiority)",
                 "Binary (e.g. cured/not, positive/negative)",
                 "2 groups",
                 "Paired / dependent (before-after, matched pairs)"))
  expect_equal(res$node$catalog_key, "proportion_two_dep")
  expect_equal(catalog_entry(res$node$catalog_key)$design_value, "mcnemar")
})

test_that("3+ groups branches by question and outcome type", {
  base <- c("Compare groups / test an association or hypothesis",
            "I (the investigator) assign it",
            "Individual subjects",
            "Show one arm is better (superiority)")
  trend_cont <- .walk(c(base, "Continuous (e.g. BP, Hb, BMI, a score)", "3 or more groups",
                        "Is there a trend across ordered groups? (dose-response)"))
  expect_equal(trend_cont$node$catalog_key(trend_cont$flags), "means_planned_contrast")
  trend_bin <- .walk(c(base, "Binary (e.g. cured/not, positive/negative)", "3 or more groups",
                       "Is there a trend across ordered groups? (dose-response)"))
  expect_equal(trend_bin$node$catalog_key(trend_bin$flags), "chisq_cochran_armitage")
  ctrl <- .walk(c(base, "Continuous (e.g. BP, Hb, BMI, a score)", "3 or more groups",
                  "Does each group differ from one common control?"))
  expect_equal(ctrl$node$catalog_key(ctrl$flags), "multiplicity_dunnett")
})

test_that("prediction branch routes development and validation to the Prediction Model module", {
  res <- .walk(c("Build or validate a prediction/prognostic model",
                 "Develop a model -- binary outcome (logistic)"))
  expect_equal(res$node$catalog_key, "prediction_binary")
  paused <- .walk(c("Build or validate a prediction/prognostic model",
                    "Externally validate an existing model -- time-to-event outcome"))
  expect_null(paused$node$catalog_key)
  expect_match(paused$node$would_use, "paused")
})

test_that("browse-by-test branch reaches a family's calculators", {
  res <- .walk(c("I already know which statistical test I'll use -- browse by test family",
                 "Nonparametric Tests",
                 catalog_entry("kruskal_wallis")$label))
  expect_true(isTRUE(res$node$terminal))
  expect_equal(res$node$catalog_key, "kruskal_wallis")
})

test_that("every built catalog entry is reachable from the wizard root", {
  built <- vapply(Filter(function(e) isTRUE(e$built), calculator_catalog), `[[`, character(1), "key")
  expect_equal(setdiff(built, design_reachable_keys()), character(0))
})

test_that("every node is reachable from root (no orphaned questions or terminals)", {
  reached <- attr(design_reachable_keys(), "nodes_reached")
  expect_equal(setdiff(names(design_nodes), reached), character(0))
})

test_that("every not-built terminal is tracked in docs/ROADMAP.md", {
  roadmap <- paste(readLines(file.path("..", "..", "docs", "ROADMAP.md"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  # One distinctive ROADMAP phrase per open terminal; update both together.
  tracked <- c(term_n_of_1 = "N-of-1", term_auc_unpaired = "Unpaired AUCs", term_mrmc = "MRMC",
               term_deming = "Deming / Passing-Bablok", term_pred_extval_tte = "time-to-event (Riley et al. 2022)",
               term_pred_updating = "Model updating", term_nma = "Network meta-analysis",
               term_dose_finding = "Dose-finding", term_platform = "Platform / basket",
               term_surv_one_sample = "One-sample survival", term_psm = "Propensity-score",
               term_time_varying = "Time-varying exposure", term_gwas = "GWAS",
               term_gxe = "environment interaction")
  open_terms <- names(Filter(function(n) isTRUE(n$terminal) && is.null(n$catalog_key) && !isTRUE(n$guidance), design_nodes))
  expect_setequal(open_terms, names(tracked))
  for (id in names(tracked)) {
    expect_true(grepl(tracked[[id]], roadmap, fixed = TRUE), info = paste(id, "->", tracked[[id]]))
  }
})
