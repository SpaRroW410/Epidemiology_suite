# Writes docs/PENDING.md from docs/CHECKLIST.md: the open items (`- [ ]`) only, under the same section headings, with the items
# marked [owner] also listed together at the top. CHECKLIST.md is the only place where status is kept; this file is never edited by hand.
#
#   Rscript tools/docs/build_pending.R          (from the repository root)
#
# tests/testthat/test-docs_pending.R fails when docs/PENDING.md differs from what this script would write. Base R only.

# The items of a checklist: one row per item (section, subsection, open or not, the item's lines). An item starts with "- [ ]" or
# "- [x]"; the indented lines that follow belong to it.
checklist_items <- function(lines) {
  items <- list(); sec <- ""; sub <- ""; cur <- NULL
  close_item <- function() if (!is.null(cur)) items[[length(items) + 1]] <<- cur
  for (ln in lines) {
    if (grepl("^## ", ln)) { close_item(); cur <- NULL; sec <- sub("^## ", "", ln); sub <- ""; next }
    if (grepl("^### ", ln)) { close_item(); cur <- NULL; sub <- sub("^### ", "", ln); next }
    if (grepl("^- \\[[ x]\\] ", ln)) {
      close_item()
      cur <- list(section = sec, subsection = sub, open = grepl("^- \\[ \\] ", ln), lines = ln)
      next
    }
    if (!is.null(cur) && grepl("^  \\S", ln)) { cur$lines <- c(cur$lines, ln); next }
    close_item(); cur <- NULL
  }
  close_item()
  items
}

# The item's text on one line, without the check box (for the owner list and for searching).
item_text <- function(it) trimws(gsub("\\s+", " ", sub("^- \\[[ x]\\] ", "", paste(it$lines, collapse = " "))))

pending_lines <- function(checklist_lines) {
  items <- checklist_items(checklist_lines)
  open <- Filter(function(it) it$open, items)
  n_done <- sum(!vapply(items, function(it) it$open, logical(1)))
  owner <- Filter(function(it) grepl("[owner]", item_text(it), fixed = TRUE), open)
  out <- c("# Pending",
           "",
           "> Generated from `docs/CHECKLIST.md` by `tools/docs/build_pending.R`; do not edit by hand. Tick an item in the checklist when",
           "> it is done and run the script again (a test fails while this file is out of date).",
           "",
           sprintf("**%d open** of %d items (%d done).", length(open), length(items), n_done),
           "")
  if (length(owner)) {
    out <- c(out, "## Waiting for the owner", "")
    for (it in owner) {
      txt <- item_text(it)
      id <- sub("^\\*\\*([A-Z]+-[0-9]+)\\*\\*.*$", "\\1", txt)
      rest <- trimws(gsub("\\*\\*\\[owner\\]\\*\\*", "", sub("^\\*\\*[A-Z]+-[0-9]+\\*\\* ", "", txt)))
      out <- c(out, sprintf("- **%s** %s", id, rest))
    }
    out <- c(out, "")
  }
  sec <- NULL; sub <- NULL
  for (it in open) {
    if (!identical(it$section, sec)) {
      sec <- it$section; sub <- ""
      n <- sum(vapply(open, function(o) identical(o$section, sec), logical(1)))
      out <- c(out, sprintf("## %s -- %d open", sec, n), "")
    }
    if (!identical(it$subsection, sub)) {
      sub <- it$subsection
      if (nzchar(sub)) out <- c(out, paste0("### ", sub), "")
    }
    out <- c(out, it$lines)
  }
  # a blank line before every heading that follows an item; no blank lines at the end
  res <- character()
  for (ln in out) {
    if (grepl("^#{2,3} ", ln) && length(res) && nzchar(res[length(res)])) res <- c(res, "")
    res <- c(res, ln)
  }
  res[seq_len(max(which(nzchar(res))))]
}

build_pending <- function(root = ".") {
  lines <- readLines(file.path(root, "docs", "CHECKLIST.md"), warn = FALSE, encoding = "UTF-8")
  writeLines(pending_lines(lines), file.path(root, "docs", "PENDING.md"), useBytes = TRUE)
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  build_pending(".")
  cat("Wrote docs/PENDING.md\n")
}
