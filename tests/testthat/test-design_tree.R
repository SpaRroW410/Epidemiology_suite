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
                 "Independent"))
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
                 "Independent"))
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
                 "Time-to-event (e.g. survival, time to recurrence)"))
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

test_that("qualitative branch is a guidance terminal with no catalog_key", {
  res <- .walk(c("Explore experiences or meanings (qualitative)"))
  expect_true(isTRUE(res$node$terminal))
  expect_true(isTRUE(res$node$guidance))
  expect_null(res$node$catalog_key)
})
