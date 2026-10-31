# Exact power of Fisher's exact test and of Boschloo's test for two independent proportions (ROADMAP Phase 6, dependency
# reduction: replaces the Exact package, whose import rootSolve has no WebAssembly build, so both designs could not run in the
# browser version). Written from the definitions of the tests, not from the package's code (Exact is GPL-2 only); the tests in
# tests/testthat/test-calc_closed_forms_exact.R compare the power with Exact::power.exact.test() over grids of inputs, and Exact is
# kept as a verification oracle only.
#
# The power of a test is the probability, under the true proportions, of the tables it rejects:
#   power = sum over tables (x of n1, y of n2) in the rejection region of dbinom(x, n1, p1) * dbinom(y, n2, p2).
# Fisher's test rejects a table when its conditional (hypergeometric) p-value is at most alpha. The two-sided p-value is the sum of
# the probabilities of the tables no more likely than the observed one, with the relative tolerance 1e-7 used by
# stats::fisher.test(). A table whose two sample proportions are equal is never rejected.
# Boschloo's test (Boschloo RD. Raised conditional level of significance for the 2x2-table when testing the equality of two
# probabilities. Statistica Neerlandica 1970;24:1-35) orders the tables by Fisher's p-value and rejects the most extreme ones as long
# as the largest probability of rejecting under the null hypothesis, over the common proportion pi, stays at most alpha. As in Exact
# (and its documentation's defaults): pi runs over 100 equally spaced values from 0.00001 to 0.99999, probabilities and p-values are
# compared after rounding to 12 significant digits, and tables whose Fisher p-value is already at most alpha are always rejected.

# Fisher p-values of every table: a (n1 + 1) x (n2 + 1) matrix, row x + 1 and column y + 1 for x successes of n1 and y of n2.
# "less": P(X <= x), "greater": P(X >= x), where X is the number of successes in group 1 given the total x + y.
.fisher_p_matrix <- function(n1, n2, alternative) {
  p <- matrix(NA_real_, n1 + 1, n2 + 1)
  for (k in 0:(n1 + n2)) {
    lo <- max(0, k - n2)
    hi <- min(k, n1)
    x <- lo:hi
    ld <- stats::dhyper(x, n1, n2, k, log = TRUE)
    d <- exp(ld - max(ld))
    d <- d / sum(d)
    pv <- switch(alternative,
      less = stats::phyper(x, n1, n2, k),
      greater = stats::phyper(x - 1, n1, n2, k, lower.tail = FALSE),
      two.sided = vapply(seq_along(x), function(i) sum(d[d <= d[i] * (1 + 1e-7)]), numeric(1))
    )
    p[cbind(x + 1, k - x + 1)] <- pv
  }
  p
}

# Which tables are on the side of the alternative: sample proportion of group 1 below group 2 ("less"), above ("greater"), or
# different ("two.sided"); compared after rounding to 10 digits, so equal proportions with different denominators count as equal.
.exact_direction <- function(n1, n2, alternative) {
  r1 <- round((0:n1) / n1, 10)
  r2 <- round((0:n2) / n2, 10)
  switch(alternative,
    less = outer(r1, r2, "<"),
    greater = outer(r1, r2, ">"),
    two.sided = outer(r1, r2, "!=")
  )
}

# Two-sided: a table and its mirror image (n1 - x, n2 - y) have the same p-value, so the decision is taken on the tables where
# group 1's proportion is lower and copied to their mirrors. This matters only when a p-value equals alpha exactly: the two
# floating-point values of the same p-value can then fall on either side of alpha (n1 = 4, n2 = 12, x = 2: p = 0.05), and the
# table and its mirror must not be decided differently. Exact decides the same way.
.fisher_reject_region <- function(n1, n2, alternative, alpha) {
  if (alternative != "two.sided") return(.exact_direction(n1, n2, alternative) & .fisher_p_matrix(n1, n2, alternative) <= alpha)
  lower <- .exact_direction(n1, n2, "less") & .fisher_p_matrix(n1, n2, "two.sided") <= alpha
  lower | lower[(n1 + 1):1, (n2 + 1):1]
}

.boschloo_reject_region <- function(n1, n2, alternative, alpha, np_numbers = 100) {
  stat <- signif(.fisher_p_matrix(n1, n2, alternative), 12)
  stat[is.na(stat)] <- 0
  pi_grid <- seq(1e-05, 0.99999, length.out = np_numbers)
  b1 <- outer(0:n1, pi_grid, function(x, p) stats::dbinom(x, n1, p))   # (n1 + 1) x grid
  b2 <- outer(0:n2, pi_grid, function(y, p) stats::dbinom(y, n2, p))
  ord <- order(stat)
  xs <- (row(stat)[ord]) - 1L
  ys <- (col(stat)[ord]) - 1L
  ts <- stat[ord]
  # walk through the tables from the most extreme, one block of equal statistic at a time, keeping the null rejection
  # probability at every pi; the largest statistic whose block keeps its maximum at most alpha is the critical value
  ends <- c(which(diff(ts) != 0), length(ts))
  starts <- c(1L, utils::head(ends, -1) + 1L)
  cum <- numeric(np_numbers)
  crit <- -Inf
  for (b in seq_along(ends)) {
    idx <- starts[b]:ends[b]
    cum <- cum + .colSums(b1[xs[idx] + 1, , drop = FALSE] * b2[ys[idx] + 1, , drop = FALSE], length(idx), np_numbers)
    if (max(signif(cum, 12)) <= alpha) crit <- ts[ends[b]] else break   # the size only grows with more tables
  }
  stat <= max(crit, alpha)
}

# Power of Fisher's ("fisher") or Boschloo's ("boschloo") test with n1 and n2 observations and true proportions p1 and p2.
.exact_test_power <- function(p1, p2, n1, n2, alternative = c("two.sided", "less", "greater"), alpha = 0.05,
                              method = c("fisher", "boschloo")) {
  alternative <- match.arg(alternative)
  method <- match.arg(method)
  region <- if (method == "fisher") .fisher_reject_region(n1, n2, alternative, alpha) else .boschloo_reject_region(n1, n2, alternative, alpha)
  prob <- outer(stats::dbinom(0:n1, n1, p1), stats::dbinom(0:n2, n2, p2))
  sum(prob[region])
}
