# Fisher's and Boschloo's exact power written from the definitions (R/calc_closed_forms_exact.R) against Exact::power.exact.test(),
# which is a verification oracle only.

test_that("Fisher and Boschloo power equal Exact::power.exact.test() over a grid of designs", {
  skip_if_not_installed("Exact")
  grid <- expand.grid(n1 = c(4, 9, 17, 30), n2 = c(5, 12, 23), alt = c("two.sided", "less", "greater"),
                      alpha = c(0.05, 0.01), stringsAsFactors = FALSE)
  ps <- rbind(c(0.15, 0.6), c(0.5, 0.3), c(0.8, 0.85), c(0.05, 0.25))
  for (r in seq_len(nrow(grid))) {
    g <- grid[r, ]
    p <- ps[(r %% nrow(ps)) + 1, ]
    for (m in c("fisher", "boschloo")) {
      expect_equal(.exact_test_power(p[1], p[2], g$n1, g$n2, g$alt, g$alpha, m),
                   Exact::power.exact.test(p1 = p[1], p2 = p[2], n1 = g$n1, n2 = g$n2, alternative = g$alt, alpha = g$alpha,
                                           method = m)$power,
                   tolerance = 1e-12, info = paste(m, g$n1, g$n2, g$alt, g$alpha))
    }
  }
})

test_that("the rejection regions are those of the definitions", {
  # two-sided Fisher: a table is rejected exactly when stats::fisher.test() gives p <= alpha and the sample proportions differ
  n1 <- 9; n2 <- 12
  reg <- .fisher_reject_region(n1, n2, "two.sided", 0.05)
  for (x in 0:n1) for (y in 0:n2) {
    p <- stats::fisher.test(matrix(c(x, n1 - x, y, n2 - y), 2))$p.value
    expect_equal(reg[x + 1, y + 1], p <= 0.05 && x / n1 != y / n2, info = paste(x, y))
  }
  # a p-value equal to alpha (n1 = 4, n2 = 12, x = 2: p = 1/20): the table and its mirror are decided alike
  reg <- .fisher_reject_region(4, 12, "two.sided", 0.05)
  for (x in 0:4) for (y in 0:12) expect_equal(reg[x + 1, y + 1], reg[4 - x + 1, 12 - y + 1], info = paste(x, y))
  # Boschloo rejects every table Fisher rejects (it is uniformly at least as powerful), and its size stays at most alpha
  for (alt in c("two.sided", "less", "greater")) {
    f <- .fisher_reject_region(15, 15, alt, 0.05)
    b <- .boschloo_reject_region(15, 15, alt, 0.05)
    expect_true(all(b[f]), info = alt)
    size <- max(vapply(seq(0.01, 0.99, by = 0.01), function(pi) sum(outer(dbinom(0:15, 15, pi), dbinom(0:15, 15, pi))[b]), numeric(1)))
    expect_lte(size, 0.05 + 1e-9)
  }
})

test_that("the Fisher sample size reproduces the Exact package's documented example", {
  # p1 = 0.15, p2 = 0.60, two-sided 5%, 80% power (content_exact_tests.R)
  r <- calc_fisher_exact(p1 = 0.15, p2 = 0.60, alpha = 0.05, power = 0.8)
  expect_gte(r$achieved_power, 0.8)
  skip_if_not_installed("Exact")
  expect_equal(r$achieved_power, Exact::power.exact.test(p1 = 0.15, p2 = 0.60, n1 = r$n1, n2 = r$n2, method = "fisher")$power,
               tolerance = 1e-12)
})
