# Difference-in-differences with repeated measures (R/calc_did.R; CHECKLIST OBS-13). Hu & Hoover 2018, equation 6.

test_that("the standard error is the source's equation 6, and the power that of a two-sample t-test on each unit's change", {
  r <- calc_did(delta = 0.5, sd = 2, rho = 0.4, n_pre = 2, n_post = 3, ratio = 2, n_intervention = 25)
  expect_equal(c(r$n_intervention, r$n_comparison, r$n_total), c(25, 50, 75))
  se <- 2 * sqrt((1 / 25 + 1 / 50) * (1 / 2 + 1 / 3) * (1 - 0.4))
  expect_equal(r$se, se)
  expect_equal(r$df, 73)
  tc <- qt(0.975, 73); ncp <- 0.5 / se
  expect_equal(r$achieved_power, pt(tc, 73, ncp, lower.tail = FALSE) + pt(-tc, 73, ncp))
})

test_that("with equal groups it equals power.t.test() on the units' changes", {
  for (cfg in list(c(0.5, 1, 0.55, 1, 3, 38), c(0.4, 1, 0.3, 3, 3, 40), c(2, 8, 0.6, 2, 4, 60))) {
    sd_change <- cfg[2] * sqrt((1 - cfg[3]) * (1 / cfg[4] + 1 / cfg[5]))
    ref <- stats::power.t.test(n = cfg[6], delta = cfg[1], sd = sd_change, sig.level = 0.05, strict = TRUE)$power
    expect_equal(calc_did(cfg[1], cfg[2], cfg[3], cfg[4], cfg[5], n_intervention = cfg[6])$achieved_power, ref, tolerance = 1e-6)
  }
  n_ref <- ceiling(stats::power.t.test(delta = 0.5, sd = sqrt(0.45 * (1 + 1 / 3)), power = 0.8, sig.level = 0.05)$n)
  expect_equal(calc_did(0.5, 1, 0.55, 1, 3)$n_intervention, n_ref)
})

test_that("the simulated power agrees with equation 6, not with the source's printed equation 7 (a factor 2 too small)", {
  # 20 000 simulated studies per setting, 17 Nov 2026 (two-sample t-test on each unit's post-minus-pre mean):
  #   19 per group, b = 1, k = 3, rho = 0.55, delta = 0.5: 0.492;  38 per group: 0.791;
  #   21 per group, b = k = 2, rho = 0.75, delta = 0.5: 0.884;      40 per group, b = k = 3, rho = 0.3, delta = 0.4: 0.732
  sim <- rbind(c(19, 1, 3, 0.55, 0.5, 0.492), c(38, 1, 3, 0.55, 0.5, 0.791), c(21, 2, 2, 0.75, 0.5, 0.884), c(40, 3, 3, 0.3, 0.4, 0.732))
  for (i in seq_len(nrow(sim))) {
    p <- calc_did(sim[i, 5], 1, sim[i, 4], sim[i, 2], sim[i, 3], n_intervention = sim[i, 1])$achieved_power
    expect_lt(abs(p - sim[i, 6]), 0.012, label = paste("setting", i))
  }
  # the source's worked example prints 19 per group for 80% power; that many give under 50%
  expect_lt(calc_did(0.5, 1, 0.55, 1, 3, n_intervention = 19)$achieved_power, 0.5)
  expect_equal(calc_did(0.5, 1, 0.55, 1, 3)$n_intervention, 39)
})

test_that("more correlation, more time points and a balanced split of them need fewer units", {
  n <- function(...) do.call(calc_did, utils::modifyList(list(delta = 0.5, sd = 1, rho = 0.5, n_pre = 1, n_post = 3), list(...)))$n_intervention
  expect_lt(n(rho = 0.8), n())
  expect_lt(n(n_pre = 2, n_post = 2), n())                      # same four time points, balanced
  expect_equal(n(n_pre = 3, n_post = 1), n())                   # symmetric in b and k
  expect_lt(n(n_pre = 3, n_post = 3), n(n_pre = 2, n_post = 2))
  expect_equal(n(delta = -0.5), n())
  r <- calc_did(0.5, 1, 0.5, 1, 3, ratio = 3)
  expect_equal(r$n_comparison, 3 * r$n_intervention)
  expect_gte(r$achieved_power, 0.8)
  expect_lt(calc_did(0.5, 1, 0.5, 1, 3, ratio = 3, n_intervention = r$n_intervention - 1)$achieved_power, 0.8)
})

test_that("the documented worked example is what the function returns", {
  a <- calc_did(0.5, 1, 0.55, 1, 3)
  expect_equal(c(a$n_intervention, a$n_total), c(39, 78))
  expect_equal(round(c(a$se, a$achieved_power), 3), c(0.175, 0.804))
  expect_equal(calc_did(0.5, 1, 0.55, 2, 2)$n_intervention, 30)
  expect_equal(round(calc_did(0.5, 1, 0.55, 2, 2, n_intervention = 30)$achieved_power, 3), 0.810)
})

test_that("invalid inputs are rejected", {
  expect_error(calc_did(0, 1, 0.5), "differ from 0")
  expect_error(calc_did(0.5, 0, 0.5), "sd")
  expect_error(calc_did(0.5, 1, 1), "rho")
  expect_error(calc_did(0.5, 1, -0.1), "rho")
  expect_error(calc_did(0.5, 1, 0.5, n_pre = 0), "n_pre")
  expect_error(calc_did(0.5, 1, 0.5, n_post = 1.5), "n_post")
  expect_error(calc_did(0.5, 1, 0.5, ratio = 0), "ratio")
  expect_error(calc_did(0.5, 1, 0.5, n_intervention = 1), "n_intervention")
})
