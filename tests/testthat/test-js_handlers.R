# Shiny.addCustomMessageHandler() throws "handler must be a function that takes one argument." (a page error at load) when the
# handler declares no parameter. The Docker smoke test caught one such handler that no local browser test did, because the error
# fires during page load; this checks every handler written in R/ statically.

test_that("every Shiny custom message handler takes exactly one argument", {
  files <- list.files(test_path("..", "..", "R"), pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0, "R/ sources not available (installed package)")
  bad <- character()
  for (f in files) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    m <- gregexpr("addCustomMessageHandler\\(\\s*['\"][A-Za-z_]+['\"]\\s*,\\s*function\\s*\\(([^)]*)\\)", txt, perl = TRUE)
    hits <- regmatches(txt, m)[[1]]
    for (h in hits) {
      args <- trimws(sub(".*function\\s*\\(([^)]*)\\)$", "\\1", h, perl = TRUE))
      if (length(strsplit(args, ",")[[1]]) != 1 || !nzchar(args)) bad <- c(bad, paste0(basename(f), ": ", h))
    }
  }
  expect_equal(bad, character())
})
