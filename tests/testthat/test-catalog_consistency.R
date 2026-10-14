# Cross-checks between the navbar (registry.R's module_registry()), the Home
# hub's calculator_catalog and the guided wizard (design_tree.R), so a new
# module or design option can't silently go missing from discovery again
# (docs/ROADMAP.md finding F1/F2).

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
