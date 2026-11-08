# PubMed search builder (R/pubmed_search.R; CHECKLIST FIND-22, FIND-23; decision F4): published filters copied exactly and
# labelled, simple filters labelled as not validated, every MeSH heading checked against NLM, and a query that PubMed can parse.

mesh_checked <- function() utils::read.csv(system.file("extdata", "mesh_checked.csv", package = "epidemiologysuite"),
                                          stringsAsFactors = FALSE, colClasses = "character")

test_that("every MeSH heading, publication type and subheading the builder prints is in the list checked against NLM", {
  checked <- mesh_checked()
  expect_true(all(c("printed", "kind", "ui", "nlm_label", "mesh_year", "checked_on") %in% names(checked)))
  expect_true(all(as.integer(checked$mesh_year) >= 2026))
  expect_match(checked$ui, "^[DQ][0-9]{6,9}$")
  # the name NLM gives is the printed one (case aside; Clinical Queries prints "risk taking" for "Risk-Taking")
  expect_equal(.mesh_norm(checked$printed), .mesh_norm(checked$nlm_label))
  printed <- .pubmed_all_mesh_atoms()
  expect_gt(nrow(printed), 30)
  key <- function(d) paste(d$kind, d$printed)
  missing <- setdiff(key(printed), key(checked))
  expect_equal(missing, character(0), info = "run Rscript tools/find/check_mesh.R")
  expect_setequal(checked$kind[checked$kind == "qualifier"], "qualifier")
})

test_that("the draft's headings that do not exist are not printed, and Network Meta-Analysis is a publication type", {
  all_q <- paste(c(vapply(.pubmed_filters, `[[`, "", "query"), vapply(.pubmed_designs, `[[`, "", "terms")), collapse = " ")
  for (bad in c("Cluster Randomized Controlled Trials", "Ecological Studies", "Factorial Design", "Equivalence Trials"))
    expect_false(grepl(bad, all_q, fixed = TRUE), info = bad)
  expect_match(all_q, "\"Network Meta-Analysis\"[pt]", fixed = TRUE)
  expect_false(grepl("\"Network Meta-Analysis\"[Mesh]", all_q, fixed = TRUE))
  expect_match(all_q, "\"Equivalence Trial\"[pt]", fixed = TRUE)
})

test_that("the Cochrane strategies are Boxes 3.a and 3.b of the Handbook supplement, line by line", {
  lines_of <- function(q) {
    inner <- sub("^\\((.*)\\) NOT \\(animals \\[mh\\] NOT humans \\[mh\\]\\)$", "\\1", q)
    expect_false(identical(inner, q))
    strsplit(inner, " OR ", fixed = TRUE)[[1]]
  }
  expect_equal(lines_of(.pubmed_filters$cochrane_sens$query),
               c("randomized controlled trial [pt]", "controlled clinical trial [pt]", "randomized [tiab]", "placebo [tiab]",
                 "drug therapy [sh]", "randomly [tiab]", "trial [tiab]", "groups [tiab]"))
  expect_equal(lines_of(.pubmed_filters$cochrane_prec$query),
               c("randomized controlled trial [pt]", "controlled clinical trial [pt]", "randomized [tiab]", "placebo [tiab]",
                 "clinical trials as topic [mesh:noexp]", "randomly [tiab]", "trial [ti]"))
  expect_match(.pubmed_filters$cq_therapy_narrow$query, "randomized controlled trial[Publication Type]", fixed = TRUE)
  for (f in .pubmed_filters) {
    expect_true(f$status %in% c("validated", "pubmed"))
    expect_true(f$source %in% names(.pubmed_sources))
  }
  for (k in grep("^cq_", names(.pubmed_filters), value = TRUE))
    expect_match(.pubmed_filters[[k]]$label, "sensitivity [0-9]+%, specificity [0-9]+%")
})

test_that("every design card has search terms, every filter it offers exists, and every choice gives a well-formed query", {
  expect_setequal(names(.pubmed_designs), names(design_cards))
  balanced <- function(q) {
    ch <- strsplit(q, "")[[1]]
    depth <- cumsum((ch == "(") - (ch == ")"))
    all(depth >= 0) && depth[length(depth)] == 0 && sum(ch == "\"") %% 2 == 0
  }
  for (d in names(.pubmed_designs)) {
    expect_true(all(.pubmed_designs[[d]]$filters %in% names(.pubmed_filters)), info = d)
    choices <- .pubmed_filter_choices(d)
    expect_equal(unname(tail(choices, 2)), c("terms", "none"), info = d)
    for (ch in choices) {
      q <- pubmed_build_query("asthma", design = d, choice = ch)
      expect_true(balanced(q), info = paste(d, ch))
      expect_match(q, "^\\(asthma\\[tiab\\]\\)", info = paste(d, ch))
      if (ch == "none") expect_equal(q, "(asthma[tiab])")
    }
  }
  # a validated filter is never changed by adding design terms unless the user picks that choice, and then it is said
  expect_equal(.pubmed_filter_query("crossover", "cochrane_sens"), paste0("(", .pubmed_filters$cochrane_sens$query, ")"))
  expect_match(.pubmed_filter_query("crossover", "cochrane_sens+terms"), "AND (\"Cross-Over Studies\"[Mesh]", fixed = TRUE)
  expect_null(.pubmed_filter_query("cohort", "cochrane_sens"))   # not offered for this design
  expect_equal(.pubmed_filter_query("sr_narrative", "pubmed_sr"), "systematic[sb]")
})

test_that("the user's words become title/abstract terms, synonyms are ORed, concepts ANDed, MeSH headings added as typed", {
  q <- pubmed_build_query(c("type 2 diabetes, T2DM", "yoga; physical activity", ""), c("Diabetes Mellitus, Type 2", "", ""))
  expect_equal(sub(" AND .*", "", q), "(\"type 2 diabetes\"[tiab] OR T2DM[tiab] OR \"Diabetes Mellitus, Type 2\"[Mesh])")
  expect_match(q, ") AND (yoga[tiab] OR \"physical activity\"[tiab])", fixed = TRUE)
  expect_equal(pubmed_build_query(c("asthma OR wheez*", "")), "(asthma[tiab] OR wheez*[tiab])")
  expect_equal(pubmed_build_query("\"Asthma\"[Mesh], inhaler*[tiab]"), "(\"Asthma\"[Mesh] OR inhaler*[tiab])")   # kept as tagged
  expect_equal(pubmed_build_query("asthma (child)"), "(\"asthma child\"[tiab])")                                  # stray brackets dropped
  expect_equal(pubmed_build_query("", "Asthma\nHypersensitivity; Yoga"),
               "(\"Asthma\"[Mesh] OR \"Hypersensitivity\"[Mesh] OR \"Yoga\"[Mesh])")   # a heading's own comma is kept
  expect_null(pubmed_build_query(c("", "  ")))
  expect_null(pubmed_build_query(character(0)))
  expect_equal(pubmed_url("a[tiab] AND b"), "https://pubmed.ncbi.nlm.nih.gov/?term=a%5Btiab%5D%20AND%20b")
})

test_that("the builder renders at an end point, and the result says what kind of filter it is", {
  h <- as.character(.render_pubmed_builder("crossover"))
  expect_match(h, "Search PubMed for studies like this")
  expect_match(h, "Cochrane highly sensitive strategy", fixed = TRUE)
  expect_match(h, "Design terms only (simple filter, not validated)", fixed = TRUE)
  expect_null(.render_pubmed_builder(NULL))
  q <- pubmed_build_query("asthma", design = "crossover", choice = "cochrane_sens")
  r <- as.character(.render_pubmed_result("crossover", "cochrane_sens", q))
  expect_match(r, "A published, validated filter, copied as printed.", fixed = TRUE)
  expect_match(r, "Cochrane Handbook 6.5", fixed = TRUE)
  expect_match(r, "pubmed.ncbi.nlm.nih.gov/?term=", fixed = TRUE)
  r <- as.character(.render_pubmed_result("crossover", "cochrane_sens+terms", q))
  expect_match(r, "not part of the validated filter", fixed = TRUE)
  expect_match(as.character(.render_pubmed_result("its", "terms", "x")), "A simple filter, not validated", fixed = TRUE)
  expect_match(as.character(.render_pubmed_result("sr_meta", "pubmed_sr", "x")), "Built into PubMed", fixed = TRUE)
  expect_match(as.character(.render_pubmed_result("its", "terms", NULL)), "Enter at least one word")
  expect_match(as.character(.render_design_terminal(design_nodes$term_its, list())), "Search PubMed for studies like this")
})
