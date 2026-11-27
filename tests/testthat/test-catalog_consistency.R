# Cross-checks between the navbar (registry.R's module_registry()), the Home
# hub's calculator_catalog and the guided wizard (design_tree.R), so a new
# module or design option can't silently go missing from discovery again
# (docs/archive/ROADMAP.md finding F1/F2).

.registry <- module_registry()

.built <- Filter(function(e) isTRUE(e$built), calculator_catalog)
.titles <- vapply(.registry, `[[`, character(1), "title")
.ui_html <- lapply(setNames(.registry, vapply(.registry, `[[`, character(1), "id")),
                   function(m) as.character(m$ui(m$id)))

# Values of every radio button named `input_id` in a module's rendered UI.
.radio_values <- function(html, input_id) {
  hits <- regmatches(html, gregexpr(paste0('name="', input_id, '" value="[^"]*"'), html))[[1]]
  sub('.*value="([^"]*)"$', "\\1", hits)
}

test_that("every navbar module has at least one built catalog entry", {
  navs <- unique(vapply(.built, `[[`, character(1), "nav_target"))
  expect_equal(setdiff(.titles, navs), character(0))
})

test_that("every built catalog entry jumps to a real navbar module", {
  navs <- unique(vapply(.built, `[[`, character(1), "nav_target"))
  expect_equal(setdiff(navs, .titles), character(0))
})

test_that("every catalog design preset is a real radio choice in its module", {
  for (e in .built) {
    if (is.na(e$module_input_id)) next
    mid <- sub("-[^-]+$", "", e$module_input_id)
    m <- Find(function(m) identical(m$id, mid), .registry)
    expect_false(is.null(m), info = paste(e$key, "-> no module with id", mid))
    if (is.null(m)) next
    expect_equal(m$title, e$nav_target, info = e$key)
    expect_true(e$design_value %in% .radio_values(.ui_html[[mid]], e$module_input_id),
                info = paste0(e$key, ": '", e$design_value, "' is not a choice of ", e$module_input_id))
  }
})

test_that("every further preset (also_set) is a real radio choice in the entry's module", {
  n <- 0
  for (e in .built) for (id in names(e$also_set)) {
    n <- n + 1
    mid <- sub("-[^-]+$", "", e$module_input_id)
    expect_identical(sub("-[^-]+$", "", id), mid, info = paste(e$key, id))
    expect_true(e$also_set[[id]] %in% .radio_values(.ui_html[[mid]], id),
                info = paste0(e$key, ": '", e$also_set[[id]], "' is not a choice of ", id))
  }
  expect_gt(n, 0)
})

test_that("every design radio choice in a module has a catalog entry", {
  # Only "<module>-design" selectors: other preset inputs (e.g. the resource
  # equation's size/check "mode") switch between views of one calculation.
  preset_inputs <- unique(na.omit(vapply(.built, function(e) as.character(e$module_input_id), character(1))))
  preset_inputs <- grep("-design$", preset_inputs, value = TRUE)
  for (input_id in preset_inputs) {
    mid <- sub("-[^-]+$", "", input_id)
    for (v in .radio_values(.ui_html[[mid]], input_id)) {
      hit <- Filter(function(e) identical(e$module_input_id, input_id) && identical(e$design_value, v), .built)
      expect_true(length(hit) > 0, info = paste0(input_id, " choice '", v, "' has no catalog entry"))
    }
  }
})

test_that("modules with several catalog entries preset a design input", {
  for (m in .registry) {
    entries <- Filter(function(e) identical(e$nav_target, m$title), .built)
    if (length(entries) < 2) next
    expect_true(all(!is.na(vapply(entries, function(e) as.character(e$module_input_id), character(1)))),
                info = paste(m$id, "has several entries but at least one can't preset its design"))
  }
})

test_that("the guided wizard can reach every navbar module", {
  reached_keys <- design_reachable_keys()
  reached_navs <- unique(vapply(reached_keys, function(k) catalog_entry(k)$nav_target, character(1)))
  expect_equal(setdiff(.titles, reached_navs), character(0))
})

test_that("every module sits in exactly one group of exactly one workbench", {
  ids <- vapply(.registry, `[[`, character(1), "id")
  placed <- unlist(lapply(module_workbenches, function(wb) unlist(lapply(wb$groups, `[[`, "module_ids"))))
  expect_equal(sort(placed), sort(ids))               # none missing, none unknown
  expect_false(anyDuplicated(placed) > 0)             # none in two places
})

test_that("workbench ids, titles and navigation ids are unique and do not collide with module titles", {
  expect_false(anyDuplicated(vapply(module_workbenches, `[[`, character(1), "id")) > 0)
  wb_titles <- vapply(module_workbenches, `[[`, character(1), "title")
  expect_false(anyDuplicated(wb_titles) > 0)
  expect_false(anyDuplicated(vapply(module_workbenches, `[[`, character(1), "nav_id")) > 0)
  expect_equal(intersect(c("Home", "Find a calculator", wb_titles), .titles), character(0))
})

test_that("every built catalog entry's target module resolves to a workbench", {
  for (e in .built) {
    expect_false(is.null(module_workbench_of(e$nav_target)), info = e$key)
  }
  expect_null(module_workbench_of("No such module"))
})

test_that("the Plan sidebar has the groups agreed for the remap (docs/ui_remap_plan.md, 27 Nov 2026)", {
  plan <- Filter(function(wb) identical(wb$id, "plan"), module_workbenches)[[1]]
  titles <- vapply(plan$groups, `[[`, character(1), "title")
  expect_equal(titles, c("Effect Sizes", "Estimate: Surveys and Descriptive Studies", "Trials and Experiments",
                         "Observational Studies and Natural Experiments", "Survival", "Tests, Relationships and Models",
                         "Diagnosis, Agreement, Prediction and Measurement", "Other Designs and General Tools"))
  expect_equal(plan$groups[[1]]$module_ids, "effect_size")
  expect_true("attrition" %in% plan$groups[[8]]$module_ids)
  expect_equal(length(unlist(lapply(plan$groups, `[[`, "module_ids"))), 59)
})

test_that("Browse by study design uses the sidebar's group names, and every family and design is still listed (remap step 2)", {
  g <- study_design_family_groups()
  plan <- Filter(function(wb) identical(wb$id, "plan"), module_workbenches)[[1]]
  expect_true(all(names(g) %in% c(vapply(plan$groups, `[[`, character(1), "title"), "Analyze")))
  expect_setequal(unlist(g), seq_along(study_design_families))          # every family under exactly one heading
  expect_false(anyDuplicated(unlist(g)) > 0)
  ids <- vapply(study_design_families, `[[`, character(1), "id")
  expect_false(anyDuplicated(ids) > 0)
  expect_false("planning_tools" %in% ids)                                 # split into four on 27 Nov 2026
  fam <- function(id) study_design_families[[which(ids == id)]]
  expect_equal(study_design_family_group(fam("survey_field_tools")), "Estimate: Surveys and Descriptive Studies")
  expect_equal(study_design_family_group(fam("randomization_list")), "Trials and Experiments")
  expect_equal(study_design_family_group(fam("attrition")), "Other Designs and General Tools")
  expect_equal(study_design_family_group(fam("epidemic_models")), "Other Designs and General Tools")
  expect_equal(study_design_family_group(fam("proportions")), "Estimate: Surveys and Descriptive Studies")
  expect_equal(study_design_family_group(fam("analyze_counts")), "Analyze")
  expect_equal(module_group_title("stepped_wedge"), "Trials and Experiments")
  expect_equal(module_group_title("analyze_2x2"), "Analyze: From summary counts")
  expect_null(module_group_title("no_such_module"))
})

test_that("every calculator has a one-line description, shown on hover in the sidebar (remap step 3)", {
  ids <- vapply(module_registry(), `[[`, character(1), "id")
  expect_setequal(names(module_blurbs), ids)
  expect_true(all(nchar(module_blurbs) <= 60))
  expect_true(all(nzchar(module_blurbs)))
  expect_false(any(grepl("[^ -~]", module_blurbs)))                 # plain ASCII
  tg <- htmltools::renderTags(attr(epidemiologysuite_app(lazy = TRUE), "ui_tags")); html <- paste(tg$head, tg$html)
  # the description is set as the link's title attribute in the browser, so the link text stays exactly the calculator's title
  expect_match(html, '"Stepped-Wedge CRT": "Stepped-wedge cluster trial, continuous or binary"', fixed = TRUE)
  expect_match(html, 'data-value="Stepped-Wedge CRT"', fixed = TRUE)
  expect_false(grepl('<span title="Stepped-wedge', html, fixed = TRUE))
})

test_that("the sidebar filter box is part of the page and matches names and descriptions (remap step 4)", {
  html <- htmltools::renderTags(attr(epidemiologysuite_app(lazy = TRUE), "ui_tags"))
  page <- paste(html$head, html$html)
  expect_match(page, "Filter calculators (name or what it does)", fixed = TRUE)
  expect_match(page, "a.getAttribute('title')", fixed = TRUE)   # the description (hover text) is part of what is matched
  expect_match(page, "Also in ", fixed = TRUE)             # matches in the other workbench are listed
  expect_match(page, ".sidebar-filter { display: none; }", fixed = TRUE)   # hidden on phones (the drop-down is used there)
})
