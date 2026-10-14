test_that("calc_simon matches the classic textbook example exactly", {
  # pu = 0.20, pa = 0.40, alpha = beta = 0.10 -> Minimax: r1=3,n1=19,r=10,n=36;
  # Optimal: r1=3,n1=17,r=10,n=37 (as printed by clinfun::ph2simon itself).
  res <- calc_simon(pu = 0.2, pa = 0.4, alpha = 0.1, beta = 0.1)

  expect_equal(res$minimax$n, 36)
  expect_equal(res$minimax$n1, 19)
  expect_equal(res$minimax$r1, 3)
  expect_equal(res$minimax$r, 10)

  expect_equal(res$optimal$n, 37)
  expect_equal(res$optimal$n1, 17)
  expect_lt(res$optimal$EN, res$minimax$EN)
})

test_that("calc_simon rejects invalid inputs", {
  expect_error(calc_simon(pu = 0.4, pa = 0.2), "pa must be greater than pu")
  expect_error(calc_simon(pu = 0.2, pa = 0.2), "pa must be greater than pu")
  expect_error(calc_simon(pu = 0.2, pa = 0.4, nmax = 5), "between 10 and 1000")
})
