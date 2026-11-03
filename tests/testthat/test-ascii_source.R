# The package source is ASCII-only (CRAN groundwork, 30 Oct 2026): characters such as the information sign or Greek letters are
# written as \u escapes. Only in a repository checkout (R CMD check installs the package, where the R/ directory is not available).
test_that("every file in R/ is ASCII", {
  dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(dir), "no R/ directory (not a repository checkout)")
  bad <- Filter(function(f) any(readBin(f, "raw", file.info(f)$size) > as.raw(127)), list.files(dir, "[.]R$", full.names = TRUE))
  expect_equal(basename(bad), character())
})
