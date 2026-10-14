# Shared input-validation helpers used across calc_*.R files. Kept here
# rather than duplicated per file, since every file in R/ lives in
# one shared package namespace -- duplicate names would silently
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

# Shared exponential-search-then-bisection root finder for Monte Carlo
# sample-size calculators (e.g. calc_ks_two_sample(), which has no closed
# form and must search over n by directly simulating the actual test).
# `empirical_power` takes a single candidate n1 and returns simulated
# power at that n; the search brackets the target power by doubling n
# from `n_lo`/`n_hi`, then bisects to the smallest n1 clearing it.
.mc_search_n1 <- function(empirical_power, target_power, n_lo = 5, n_hi = 10, n_max = 20000) {
  while (empirical_power(n_hi) < target_power) {
    n_lo <- n_hi
    n_hi <- n_hi * 2
    if (n_hi > n_max) {
      stop(sprintf(
        "No feasible sample size found up to %d per group (effect size likely too small).",
        n_max
      ))
    }
  }

  for (i in 1:12) {
    mid <- round((n_lo + n_hi) / 2)
    if (mid == n_lo || mid == n_hi) break
    if (empirical_power(mid) >= target_power) {
      n_hi <- mid
    } else {
      n_lo <- mid
    }
  }

  n_hi
}
