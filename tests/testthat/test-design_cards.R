# Design cards (R/design_cards.R; CHECKLIST FIND-21, decision F3): every statement either names a source that was checked or carries
# the "Suggestion only" mark; the figures the draft gave without a source stay marked; the two the sources contradicted stay corrected;
# every card is reachable from the guide and every design flag has a card.

all_sources_of <- function(card) unique(c(card$fallback$src, unlist(lapply(card$threats, `[[`, "src")), card$guideline, card$workflow_src))

test_that("every source a card cites is in the checked list, and every checked source is used", {
  used <- unique(unlist(lapply(design_cards, all_sources_of)))
  expect_setequal(used, names(.design_card_sources))
  for (k in names(.design_card_sources)) {
    s <- .design_card_sources[[k]]
    expect_match(s$pmid, "^[0-9]{7,8}$", info = k)
    expect_true(nzchar(s$cite) && nzchar(s$short) && s$read %in% c("record", "abstract", "full text"), info = k)
  }
})

test_that("every card is complete: a fallback, three threats with mitigations, a reporting guideline, a measure and a workflow", {
  for (k in names(design_cards)) {
    card <- design_cards[[k]]
    expect_true(nzchar(card$title) && nzchar(card$fallback$text) && nzchar(card$measure) && nzchar(card$workflow), info = k)
    expect_length(card$threats, 3)
    for (t in card$threats) expect_true(nzchar(t$threat) && nzchar(t$mitigation), info = k)
    expect_true(length(card$guideline) >= 1, info = k)
  }
})

test_that("every card is shown somewhere in the guide, and every design flag has a card", {
  terminal_cards <- unlist(lapply(design_nodes, function(n) n$card))
  flag_designs <- unique(unlist(lapply(design_nodes, function(n)
    if (!isTRUE(n$terminal)) vapply(n$options, function(o) if (is.null(o$set$design)) NA_character_ else o$set$design, ""))))
  flag_designs <- setdiff(stats::na.omit(flag_designs), "none")
  expect_true(all(c(terminal_cards, flag_designs) %in% names(design_cards)))
  expect_setequal(union(terminal_cards, flag_designs), names(design_cards))
})

test_that("the right card follows the path: the answer that decided the design, or the end point's own design", {
  key <- function(answers) {
    node_id <- "root"; flags <- list()
    for (label in answers) {
      opt <- Find(function(o) identical(o$label, label), design_nodes[[node_id]]$options)
      if (is.null(opt)) stop("no option '", label, "' at '", node_id, "'")
      if (!is.null(opt$set)) for (nm in names(opt$set)) flags[[nm]] <- opt$set[[nm]]
      node_id <- if (is.function(opt$next_id)) opt$next_id(flags) else opt$next_id
    }
    .design_card_key(design_nodes[[node_id]], flags)
  }
  cmp <- "Compare groups / test an association or hypothesis"
  assign <- "I (the investigator) assign it"
  expect_equal(key(c(cmp, assign, "Individual subjects", "Show one arm is better (superiority)")), "parallel_rct")
  expect_equal(key(c(cmp, assign, "Groups/clusters (villages, schools, PHCs, wards)", "Show one arm is better (superiority)")), "cluster_rct")
  expect_equal(key(c(cmp, assign, "Individual subjects", "Show it's not unacceptably worse (non-inferiority)")), "noninferiority")
  expect_null(key(c(cmp, assign, "Individual subjects", "Single-arm, response rate vs. a historical control (Phase II)")))   # no card
  expect_equal(key(c(cmp, assign, "Same subject receives both, in sequence (crossover)")), "crossover")
  obs <- c(cmp, "I only observe what happened naturally")
  expect_equal(key(c(obs, "Their exposure status (outcome measured/ascertained later)",
                     "Whether the disease/event occurred (a risk: relative risk)")), "cohort")
  expect_equal(key(c(obs, design_nodes$selection_basis$options[[11]]$label)), "mr")
  expect_equal(key(c("Estimate a parameter with precision (prevalence, mean, rate...)", "A proportion / prevalence")), "descriptive_cs")
  expect_equal(key(c("Plan a meta-analysis (number of studies, or trial sequential analysis)",
                     "How many studies a planned pairwise meta-analysis needs (power)")), "sr_meta")
})

test_that("the figures without a confirmed source are shown as suggestions; the ones the sources contradicted stay corrected", {
  statements <- unlist(lapply(design_cards, function(card)
    c(list(card$fallback), lapply(card$threats, function(t) list(text = paste(t$threat, t$mitigation), src = t$src)))), recursive = FALSE)
  for (num in .design_card_unsourced_numbers) {
    hits <- Filter(function(s) grepl(num, s$text, fixed = TRUE), statements)
    expect_gt(length(hits), 0)
    for (h in hits) expect_null(h$src, info = num)
  }
  txt <- paste(unlist(design_cards), collapse = " ")
  expect_false(grepl("8-12|8 to 12", txt))                                   # Bernal et al. 2017: no fixed minimum
  expect_match(design_cards$its$threats[[3]]$mitigation, "no fixed minimum")
  expect_match(design_cards$mr$threats[[2]]$mitigation, "misleading")        # Burgess & Thompson 2011
  expect_equal(design_cards$mr$threats[[2]]$src, "burgess2011")
})

test_that("a card renders with the mark's hover text, the sources it cites, and their links", {
  h <- as.character(.render_design_card("its"))
  expect_match(h, "Design card: Interrupted time series")
  expect_match(h, "Bernal et al. 2017")
  expect_match(h, "doi.org/10.1093/ije/dyw098", fixed = TRUE)
  h <- as.character(.render_design_card("crossover"))
  expect_match(h, 'title="Suggestion only -- no confirmed source"', fixed = TRUE)
  expect_match(h, 'aria-label="Suggestion only -- no confirmed source"', fixed = TRUE)
  expect_match(h, "Dwan K et al.", fixed = TRUE)
  expect_null(.render_design_card(NULL))
  expect_match(as.character(.render_design_terminal(design_nodes$term_its, list())), "Design card: Interrupted time series")
})
