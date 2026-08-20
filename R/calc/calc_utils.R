# Shared input-validation helpers used across calc_*.R files. Kept here
# rather than duplicated per file, since global.R sources every file in
# R/calc/ into one shared environment -- duplicate names would silently
# shadow each other.

.validate_number <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x)) {
    stop(sprintf("%s must be a single number.", label))
  }
}

.validate_positive <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
    stop(sprintf("%s must be a single positive number.", label))
  }
}

.validate_unit_interval <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0 || x >= 1) {
    stop(sprintf("%s must be a single number strictly between 0 and 1.", label))
  }
}

.validate_population <- function(N, label = "N") {
  if (!is.numeric(N) || length(N) != 1 || is.na(N) || N < 1) {
    stop(sprintf(
      "%s must be a single number >= 1 (or left blank for an effectively infinite population).",
      label
    ))
  }
}
