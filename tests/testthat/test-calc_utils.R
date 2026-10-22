
test_that("the LAPACK-free fallbacks equal solve() and chol() on random matrices", {
  set.seed(5)
  for (n in c(1, 2, 3, 5, 8)) {
    a <- crossprod(matrix(rnorm(n * n), n)) + diag(n)           # symmetric positive definite
    b <- matrix(rnorm(n * 2), n); bv <- rnorm(n)
    expect_equal(.solve_gauss(a), solve(a), tolerance = 1e-9)
    expect_equal(.solve_gauss(a, b), solve(a, b), tolerance = 1e-9)
    expect_equal(.solve_gauss(a, bv), solve(a, bv), tolerance = 1e-9)
    expect_equal(.chol_base(a), chol(a), tolerance = 1e-10)
    expect_equal(.solve_safe(a), solve(a))                       # the normal path is used when LAPACK works
    expect_equal(.chol_safe(a), chol(a))
  }
  g <- matrix(rnorm(25), 5)                                      # a general (not symmetric) matrix needs pivoting
  expect_equal(.solve_gauss(g), solve(g), tolerance = 1e-8)
  expect_error(.solve_gauss(matrix(c(1, 2, 2, 4), 2)), "singular")
  expect_error(.chol_base(matrix(c(1, 2, 2, 1), 2)), "not positive")
})

test_that("the fallback is used only for the specific LAPACK failure, and other errors pass through", {
  local_mocked_bindings(solve = function(...) stop("LAPACK routines cannot be loaded"), .package = "base")
  expect_equal(.solve_safe(matrix(c(2, 0, 0, 4), 2)), matrix(c(0.5, 0, 0, 0.25), 2), tolerance = 1e-12)
  local_mocked_bindings(solve = function(...) stop("something else"), .package = "base")
  expect_error(.solve_safe(diag(2)), "something else")
})

test_that(".require_pkg stops with a plain message for a package that cannot load, and passes for one that can", {
  expect_true(.require_pkg("stats", "x"))
  expect_error(.require_pkg("notARealPackageName", "The thing"), "The thing needs the R package 'notARealPackageName'")
})
