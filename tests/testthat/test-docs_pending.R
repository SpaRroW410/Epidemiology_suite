# docs/CHECKLIST.md is the one place where the project's status is kept; docs/PENDING.md is generated from it by
# tools/docs/build_pending.R. These tests keep the two in step and the checklist's IDs usable.

.docs_root <- file.path("..", "..")
.has_docs <- function() file.exists(file.path(.docs_root, "docs", "CHECKLIST.md")) &&
  file.exists(file.path(.docs_root, "tools", "docs", "build_pending.R"))

test_that("docs/PENDING.md is what tools/docs/build_pending.R writes from docs/CHECKLIST.md", {
  skip_if_not(.has_docs(), "docs/ are not part of the installed package")
  env <- new.env()
  sys.source(file.path(.docs_root, "tools", "docs", "build_pending.R"), envir = env)
  checklist <- readLines(file.path(.docs_root, "docs", "CHECKLIST.md"), warn = FALSE, encoding = "UTF-8")
  pending <- readLines(file.path(.docs_root, "docs", "PENDING.md"), warn = FALSE, encoding = "UTF-8")
  expect_identical(pending, env$pending_lines(checklist),
                   info = "docs/PENDING.md is out of date: run Rscript tools/docs/build_pending.R")
})

test_that("every checklist item has a unique, well-formed ID", {
  skip_if_not(.has_docs(), "docs/ are not part of the installed package")
  env <- new.env()
  sys.source(file.path(.docs_root, "tools", "docs", "build_pending.R"), envir = env)
  items <- env$checklist_items(readLines(file.path(.docs_root, "docs", "CHECKLIST.md"), warn = FALSE, encoding = "UTF-8"))
  texts <- vapply(items, env$item_text, character(1))
  ids <- sub("^\\*\\*([A-Z]+-[0-9]{2,})\\*\\*.*$", "\\1", texts)
  expect_true(all(grepl("^[A-Z]+-[0-9]{2,}$", ids)), info = paste(texts[!grepl("^[A-Z]+-[0-9]{2,}$", ids)], collapse = "\n"))
  expect_false(anyDuplicated(ids) > 0, info = paste(ids[duplicated(ids)], collapse = ", "))
  expect_gt(length(items), 300)
})

test_that("checklist IDs cited by the app (\"docs/PENDING.md, XXX-NN\") are open items of the checklist", {
  skip_if_not(.has_docs(), "docs/ are not part of the installed package")
  env <- new.env()
  sys.source(file.path(.docs_root, "tools", "docs", "build_pending.R"), envir = env)
  items <- env$checklist_items(readLines(file.path(.docs_root, "docs", "CHECKLIST.md"), warn = FALSE, encoding = "UTF-8"))
  open_ids <- sub("^\\*\\*([A-Z]+-[0-9]+)\\*\\*.*$", "\\1", vapply(Filter(function(it) it$open, items), env$item_text, character(1)))
  src <- unlist(lapply(list.files(file.path(.docs_root, "R"), "\\.R$", full.names = TRUE), readLines, warn = FALSE))
  cited <- unlist(regmatches(src, gregexpr("PENDING\\.md, [A-Z]+-[0-9]+", src)))
  cited <- sub("^PENDING\\.md, ", "", cited)
  expect_gt(length(cited), 0)
  expect_true(all(cited %in% open_ids), info = paste(setdiff(cited, open_ids), collapse = ", "))
})
