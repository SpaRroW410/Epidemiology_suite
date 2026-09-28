# Monte Carlo tests (seconds to minutes each) are skipped by default so the
# everyday run stays fast; CI runs them weekly. Run them locally with
#   S2R_SLOW_TESTS=true Rscript -e 'testthat::test_dir("tests/testthat")'
skip_if_not_slow <- function() {
  if (!identical(tolower(Sys.getenv("S2R_SLOW_TESTS")), "true")) {
    testthat::skip("slow Monte Carlo test (set S2R_SLOW_TESTS=true to run)")
  }
}
