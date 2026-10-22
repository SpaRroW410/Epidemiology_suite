# Counts are simulated, not surveillance data.
.sv_series <- function() { set.seed(11); c(rpois(30, 5), rpois(8, 12)) }

test_that("EARS C1 equals the direct (x - mean) / sd of the previous 7 values", {
  x <- .sv_series()
  r <- calc_surveillance_ears(x, "C1")
  s <- attr(r, "series")
  expect_true(all(is.na(s$statistic[1:7])) && !anyNA(s$statistic[8:38]))
  for (t in c(8, 20, 38)) expect_equal(s$statistic[t], (x[t] - mean(x[(t - 7):(t - 1)])) / sd(x[(t - 7):(t - 1)]))
  expect_equal(s$alarm, !is.na(s$statistic) & s$statistic > 3)
  expect_equal(r$n_monitored, 31); expect_equal(r$n_alarms, sum(s$alarm))
})

test_that("EARS C2 skips the two most recent values (guard band) and C3 adds the last three C2 excesses", {
  x <- .sv_series()
  s2 <- attr(calc_surveillance_ears(x, "C2"), "series")
  t <- 25
  b <- x[(t - 9):(t - 3)]
  expect_equal(s2$statistic[t], (x[t] - mean(b)) / sd(b))
  expect_equal(which(!is.na(s2$statistic))[1], 10)
  s3 <- attr(calc_surveillance_ears(x, "C3"), "series")
  expect_equal(which(!is.na(s3$statistic))[1], 12)
  expect_equal(s3$statistic[30], sum(pmax(0, s2$statistic[28:30] - 1)))
  expect_equal(s3$threshold[1], 2)
})

test_that("EARS C1 and C2 agree with surveillance::earsC when the thresholds are the same", {
  skip_if_not_installed("surveillance")
  x <- .sv_series()
  sts <- methods::new("sts", observed = matrix(x, ncol = 1), epoch = seq_along(x), freq = 7)
  alpha3 <- 1 - pnorm(3)                          # earsC thresholds at qnorm(1 - alpha); EARS uses 3
  for (m in c("C1", "C2")) {
    first <- if (m == "C1") 8 else 10
    o <- surveillance::earsC(sts, control = list(range = first:38, method = m, baseline = 7, alpha = alpha3))
    r <- attr(calc_surveillance_ears(x, m), "series")
    expect_equal(which(r$alarm), first - 1 + which(as.vector(surveillance::alarms(o))))
    base_mean_sd <- vapply(first:38, function(t) { b <- x[(t - 7 - if (m == "C2") 2 else 0):(t - 1 - if (m == "C2") 2 else 0)]; mean(b) + 3 * sd(b) }, 0)
    expect_equal(as.vector(surveillance::upperbound(o)), base_mean_sd, tolerance = 1e-8)
  }
})

test_that("EARS handles flat baselines, thresholds and too-short series", {
  flat <- c(rep(4, 10), 9)
  r <- calc_surveillance_ears(flat, "C1")
  expect_equal(r$n_undefined, 4)                   # t = 8..11 have a zero-sd baseline
  expect_equal(r$n_alarms, 0)
  r2 <- calc_surveillance_ears(flat, "C1", min_sd = 1)
  expect_equal(attr(r2, "series")$statistic[11], 5)
  expect_true(attr(r2, "series")$alarm[11])
  expect_equal(calc_surveillance_ears(rep(5, 30), "C3")$n_alarms, 0)
  expect_error(calc_surveillance_ears(1:7, "C1"), "at least")
  expect_error(calc_surveillance_ears(c(1, -1, 2, 3, 4, 5, 6, 7, 8), "C1"), "0 or more")
  expect_error(calc_surveillance_ears(1:20, "C1", baseline = 2), "at least 3")
  expect_error(calc_surveillance_ears(c(1:19, NA), "C1"), "numbers")
})

test_that("normal CUSUM equals the recursion by hand, restarts after a signal and ignores the baseline", {
  x <- .sv_series()
  r <- calc_surveillance_cusum(x, "normal", baseline = 14, k = 0.5, h = 4)
  s <- attr(r, "series")
  mu <- mean(x[1:14]); sg <- sd(x[1:14])
  expect_equal(r$baseline_mean, mu); expect_equal(r$baseline_sd, sg)
  expect_true(all(is.na(s$statistic[1:14])))
  c_prev <- 0; ref <- rep(NA_real_, 38); al <- rep(FALSE, 38)
  for (t in 15:38) { ref[t] <- max(0, c_prev + (x[t] - mu) / sg - 0.5); if (ref[t] > 4) { al[t] <- TRUE; c_prev <- 0 } else c_prev <- ref[t] }
  expect_equal(s$statistic, ref); expect_equal(s$alarm, al)
  expect_gt(r$n_alarms, 0)
  nr <- calc_surveillance_cusum(x, "normal", reset = FALSE)
  s2 <- attr(nr, "series")
  expect_equal(s2$statistic[which(s2$alarm)[1] + 1] >= s2$statistic[which(s2$alarm)[1]] - 0.5 - 1e-9, TRUE)
})

test_that("Poisson CUSUM uses Lucas's reference value k = (l1 - l0) / ln(l1 / l0)", {
  x <- .sv_series()
  r <- calc_surveillance_cusum(x, "poisson", baseline = 20, h = 6, shift_ratio = 2)
  l0 <- mean(x[1:20])
  expect_equal(r$reference_value, l0 * (2 - 1) / log(2))
  s <- attr(r, "series")
  c_prev <- 0; ref <- rep(NA_real_, 38)
  for (t in 21:38) { ref[t] <- max(0, c_prev + x[t] - r$reference_value); if (ref[t] > 6) c_prev <- 0 else c_prev <- ref[t] }
  expect_equal(s$statistic, ref)
  # a sustained doubling is picked up quickly, a constant series is not
  expect_lte(r$first_alarm - 30, 6)
  expect_equal(calc_surveillance_cusum(rep(5, 40), "poisson")$n_alarms, 0)
  expect_error(calc_surveillance_cusum(rep(0, 40), "poisson"), "no cases")
  expect_error(calc_surveillance_cusum(x, "poisson", shift_ratio = 1), "exceed 1")
  expect_error(calc_surveillance_cusum(x, "normal", h = -1), "positive")
})

test_that("CUSUM run lengths agree with spc::xcusum.arl (simulated, slow lane)", {
  skip_if_not_slow()
  skip_if_not_installed("spc")
  mk <- function(shift, h, reps, n, seed) {
    set.seed(seed)
    base <- 100 + 10 * as.numeric(scale(rep(c(-1, 1), 7)))
    rl <- vapply(seq_len(reps), function(i) {
      x <- c(base, rnorm(n, 100 + 10 * shift, 10))
      r <- calc_surveillance_cusum(x, "normal", baseline = 14, k = 0.5, h = h, min_sd = 0)
      r$first_alarm - 14
    }, 0)
    mean(rl, na.rm = TRUE)
  }
  # in control, one-sided k = 0.5: h = 4 -> about 336; shifted by one sd -> about 8.4
  expect_equal(mk(1, 4, 800, 200, 1), spc::xcusum.arl(0.5, 4, 1, sided = "one"), tolerance = 0.08)
  expect_equal(mk(0.5, 4, 800, 400, 2), spc::xcusum.arl(0.5, 4, 0.5, sided = "one"), tolerance = 0.08)
  expect_equal(mk(0, 4, 700, 3500, 3), spc::xcusum.arl(0.5, 4, 0, sided = "one"), tolerance = 0.10)
})

test_that("false-signal rate of C1 and C2 on stable normal counts equals the t-distribution value (slow lane)", {
  skip_if_not_slow()
  set.seed(1); a <- 0; m <- 0; a2 <- 0
  for (i in 1:30) {
    x <- rnorm(5000, 100, 10)
    r <- calc_surveillance_ears(x, "C1"); a <- a + r$n_alarms; m <- m + r$n_monitored
    a2 <- a2 + calc_surveillance_ears(x, "C2")$n_alarms
  }
  # (x - mean) / s with x independent of the 7 baseline values is sqrt(1 + 1/7) times a t variable on 6 df
  p <- pt(3 / sqrt(1 + 1 / 7), 6, lower.tail = FALSE)
  expect_equal(a / m, p, tolerance = 0.05)
  expect_equal(a2 / m, p, tolerance = 0.05)
})
