# The pmsampsize-free criteria must reproduce pmsampsize 1.1.3 (the package is an oracle only), except for the one documented
# sign error in the continuous outcome's fourth criterion, which is checked against its own definition instead.
skip_if_not_installed("pmsampsize")

test_that("binary outcome (Cox-Snell R2 given) equals pmsampsize over a grid", {
  for (p in c(5, 24, 60)) for (prev in c(0.05, 0.174, 0.4)) for (r2 in c(0.05, 0.12, 0.288)) for (S in c(0.8, 0.9, 0.95)) {
    a <- tryCatch(.cf_pmsampsize_bin(p, prev, rsquared = r2, shrinkage = S), error = function(e) "error")
    b <- tryCatch(pmsampsize::pmsampsize(type = "b", parameters = p, prevalence = prev, csrsquared = r2, shrinkage = S), error = function(e) "error")
    info <- paste(p, prev, r2, S)
    if (identical(b, "error")) { expect_identical(a, "error", info = info); next }
    expect_equal(a$sample_size, b$sample_size, info = info)
    expect_equal(a$events, b$events, info = info); expect_equal(a$EPP, b$EPP, info = info)
    expect_equal(a$max_r2a, b$max_r2a, tolerance = 1e-12, info = info); expect_equal(a$nag_r2, b$nag_r2, tolerance = 1e-12, info = info)
  }
})

test_that("the Cox-Snell R2 from a C-statistic (own Newton fit of the package's simulation) equals the package's, and so does the sample size", {
  for (cs in c(0.65, 0.8, 0.9)) for (prev in c(0.1, 0.25)) {
    r2 <- .cf_cstat2rsq(cs, prev)
    expect_equal(r2, pmsampsize:::cstat2rsq(cs, prev)$R2.coxsnell, tolerance = 1e-9, info = paste(cs, prev))
    a <- .cf_pmsampsize_bin(24, prev, cstatistic = cs)
    b <- pmsampsize::pmsampsize(type = "b", parameters = 24, prevalence = prev, cstatistic = cs)
    expect_equal(a$sample_size, b$sample_size, info = paste(cs, prev)); expect_equal(a$rsquared, b$rsquared)
  }
  expect_error(.cf_pmsampsize_bin(24, 0.2), "exactly one")
})

test_that("time-to-event outcome equals pmsampsize over a grid", {
  for (p in c(10, 30)) for (rate in c(0.05, 0.065, 0.2)) for (tp in c(1, 2)) for (mf in c(1.5, 2.07)) for (r2 in c(0.051, 0.2)) {
    a <- .cf_pmsampsize_surv(p, rate, tp, mf, r2)
    b <- pmsampsize::pmsampsize(type = "s", parameters = p, rate = rate, timepoint = tp, meanfup = mf, csrsquared = r2)
    info <- paste(p, rate, tp, mf, r2)
    expect_equal(a$sample_size, b$sample_size, info = info); expect_equal(a$events, b$events, info = info)
    expect_equal(c(a$int_lci, a$int_uci, a$int_cuminc), c(b$int_lci, b$int_uci, b$int_cuminc), info = info)
    expect_equal(a$max_r2a, b$max_r2a, tolerance = 1e-12); expect_equal(a$EPP, b$EPP, info = info)
  }
})

test_that("continuous outcome equals pmsampsize whenever the intercept criterion does not bind", {
  for (p in c(5, 25, 60)) for (r2 in c(0.1, 0.2, 0.5)) for (S in c(0.85, 0.9)) for (cfg in list(c(1.9, 0.6), c(50, 12))) {
    a <- .cf_pmsampsize_cont(p, cfg[1], cfg[2], r2, S)
    b <- pmsampsize::pmsampsize(type = "c", parameters = p, intercept = cfg[1], sd = cfg[2], rsquared = r2, shrinkage = S)
    info <- paste(p, r2, S, paste(cfg, collapse = "/"))
    expect_equal(a$criteria[1:3], unname(b$results_table[1:3, 1]), info = info)
    if (b$sample_size == max(b$results_table[1:3, 1])) {      # criterion 4 did not raise n: the package is right
      expect_equal(a$sample_size, b$sample_size, info = info)
      expect_equal(c(a$int_lci, a$int_uci, a$SPP), c(b$int_lci, b$int_uci, b$SPP), info = info)
      expect_equal(a$final_shrinkage, b$final_shrinkage, info = info)
    }
  }
})

test_that("the intercept criterion, when it binds, is the smallest n that meets it (where pmsampsize 1.1.3 stops one step on)", {
  a <- .cf_pmsampsize_cont(parameters = 2, intercept = 1.9, sd = 0.6, rsquared = 0.2, mmoe = 1.02)
  upper <- function(n) 1.9 + sqrt(0.6^2 * (1 - 0.2) / n) * qt(0.975, n - 2 - 1)
  expect_lte(upper(a$sample_size) / 1.9, 1.02)
  expect_gt(upper(a$sample_size - 1) / 1.9, 1.02)                 # one fewer is not enough
  expect_gt(a$sample_size, 700)                                   # not the package's 237
  expect_lt(a$int_lci, a$int_uci)                                 # limits in order (the package returns them swapped)
  b <- pmsampsize::pmsampsize(type = "c", parameters = 2, intercept = 1.9, sd = 0.6, rsquared = 0.2, mmoe = 1.02)
  expect_equal(b$sample_size, 237)                                # documents the package behaviour this differs from
  expect_gt(b$int_lci, b$int_uci)
  # and a realistic binding case: a large sd relative to the mean
  c2 <- .cf_pmsampsize_cont(parameters = 8, intercept = 1, sd = 1, rsquared = 0.3)
  expect_lte((1 + sqrt(1 * 0.7 / c2$sample_size) * qt(0.975, c2$sample_size - 9)) / 1, 1.1)
  expect_equal(c2$sample_size, c2$criteria[4])
  expect_error(.cf_pmsampsize_cont(5, 0, 1, 0.2), "must not be 0")
})
