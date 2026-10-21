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

# --- Linear algebra that still works where LAPACK is missing (browser / webR build) -----------------
# webR's R has no LAPACK, so solve() and chol() fail there with "LAPACK routines cannot be loaded".
# These try the normal function first and use a small base-R routine only on that specific failure, so
# the native app runs exactly the code it always ran. The matrices involved are tiny (visit times, a 2x2
# covariance), so a plain textbook algorithm is fast and accurate enough; tests compare it with solve() /
# chol() on random matrices.
.solve_gauss <- function(a, b = NULL) {
  a <- as.matrix(a)
  n <- nrow(a)
  if (ncol(a) != n) stop("'a' must be square")
  rhs <- if (is.null(b)) diag(n) else as.matrix(b)
  m <- cbind(a, rhs)
  for (i in seq_len(n)) {
    p <- which.max(abs(m[i:n, i])) + i - 1
    if (abs(m[p, i]) < 1e-14 * max(1, max(abs(a)))) stop("Lapack routine dgesv: system is exactly singular")
    if (p != i) m[c(i, p), ] <- m[c(p, i), ]
    m[i, ] <- m[i, ] / m[i, i]
    for (j in seq_len(n)[-i]) m[j, ] <- m[j, ] - m[j, i] * m[i, ]
  }
  out <- m[, (n + 1):ncol(m), drop = FALSE]
  if (!is.null(b) && is.null(dim(b))) as.vector(out) else out
}

.solve_safe <- function(a, b = NULL) {
  tryCatch(
    if (is.null(b)) solve(a) else solve(a, b),
    error = function(e) if (grepl("LAPACK", conditionMessage(e), fixed = TRUE)) .solve_gauss(a, b) else stop(e)
  )
}

# Upper-triangular Cholesky factor R with t(R) %*% R == a (what chol() returns).
.chol_base <- function(a) {
  n <- nrow(a)
  r <- matrix(0, n, n)
  for (j in seq_len(n)) {
    s <- a[j, j] - sum(r[seq_len(j - 1), j]^2)
    if (s <= 0) stop("the leading minor of order ", j, " is not positive")
    r[j, j] <- sqrt(s)
    if (j < n) for (k in (j + 1):n) r[j, k] <- (a[j, k] - sum(r[seq_len(j - 1), j] * r[seq_len(j - 1), k])) / r[j, j]
  }
  r
}

.chol_safe <- function(a) {
  tryCatch(chol(a), error = function(e) if (grepl("LAPACK", conditionMessage(e), fixed = TRUE)) .chol_base(a) else stop(e))
}

# A package that may not load everywhere (the browser build has no WebAssembly build of rootSolve, so
# `Exact` cannot load, and `PowerTOST` fails on its compiled `cubature`). Stops with a plain message
# instead of a package-loading error.
.require_pkg <- function(pkg, what) {
  ok <- tryCatch(suppressWarnings(requireNamespace(pkg, quietly = TRUE)), error = function(e) FALSE)
  if (!isTRUE(ok)) {
    stop(sprintf("%s needs the R package '%s', which cannot be loaded in this environment (this happens in the browser version of the app). The installed R package has every design; install it with: %s", what, pkg, .install_instructions), call. = FALSE)
  }
  invisible(TRUE)
}
