# Lan-DeMets alpha spending with any number of looks (TRIAL-29). gsDesign is the check (Suggests).

test_that("boundaries and inflation factors equal gsDesign for 2 to 5 looks, OF-type and Pocock-type", {
  skip_if_not_installed("gsDesign")
  cases <- list(list(t = 0.5, sp = "OF"), list(t = c(1/3, 2/3), sp = "OF"), list(t = c(0.25, 0.5, 0.75), sp = "OF"),
                list(t = c(0.3, 0.6), sp = "Pocock"), list(t = c(0.2, 0.4, 0.6, 0.8), sp = "Pocock"), list(t = c(0.4, 0.9), sp = "OF"))
  for (cs in cases) {
    res <- calc_lan_demets_k("continuous", timing = cs$t, spending = cs$sp, delta = 0.5, sd = 1)
    sfu <- if (cs$sp == "OF") gsDesign::sfLDOF else gsDesign::sfLDPocock
    g <- gsDesign::gsDesign(k = length(cs$t) + 1, test.type = 1, alpha = 0.025, beta = 0.2, sfu = sfu, timing = c(cs$t, 1))
    expect_equal(res$boundaries, g$upper$bound, tolerance = 1e-5, info = paste(cs$sp, length(cs$t)))
    expect_equal(res$inflation_factor, max(g$n.I), tolerance = 1e-6, info = paste(cs$sp, length(cs$t)))
  }
})

test_that("two looks reproduce calc_lan_demets_normal(), and the survival events equal gsDesign's", {
  old <- calc_lan_demets_normal(delta = 0.5, sd = 1, timing = 0.5)
  new <- calc_lan_demets_k("continuous", timing = 0.5, delta = 0.5, sd = 1)
  expect_equal(new$n_total, old$n_total)
  expect_equal(new$boundaries, c(old$boundary_interim, old$boundary_final), tolerance = 1e-4)
  skip_if_not_installed("gsDesign")
  s <- calc_lan_demets_k("survival", timing = c(0.25, 0.5, 0.75), spending = "Pocock", haz_ratio = 0.7)
  ev <- gsDesign::nEvents(hr = 0.7, ratio = 1, alpha = 0.025, beta = 0.2, sided = 1)
  expect_equal(s$n_fixed, ev, tolerance = 1e-8)
  g <- gsDesign::gsDesign(k = 4, test.type = 1, alpha = 0.025, beta = 0.2, sfu = gsDesign::sfLDPocock, n.fix = ev)
  expect_equal(s$n_events_total, ceiling(max(g$n.I)))
})

test_that("the binary design reaches its power and keeps the one-sided error in a simulation of the sequential test", {
  skip_on_cran()
  d <- calc_lan_demets_k("binary", timing = c(1/3, 2/3), pC = 0.3, pE = 0.45)
  expect_equal(d$n_total, 324); expect_equal(d$at_each_look, c(108, 216, 324))
  sim <- function(pE, reps) {
    set.seed(3); rej <- 0
    for (i in seq_len(reps)) {
      xc <- stats::rbinom(d$n_control, 1, 0.3); xe <- stats::rbinom(d$n_experimental, 1, pE)
      for (k in seq_along(d$timing)) {
        mc <- ceiling(d$timing[k] * d$n_control); me <- ceiling(d$timing[k] * d$n_experimental)
        a <- mean(xc[seq_len(mc)]); b <- mean(xe[seq_len(me)]); se <- sqrt(a * (1 - a) / mc + b * (1 - b) / me)
        if (se > 0 && (b - a) / se >= d$boundaries[k]) { rej <- rej + 1; break }
      }
    }
    rej / reps
  }
  expect_lt(abs(sim(0.45, 4000) - 0.8), 0.025)      # 20,000 studies gave 0.793 (simulation SE with 4,000: 0.006)
  expect_lt(abs(sim(0.30, 4000) - 0.025), 0.008)    # 20,000 studies gave 0.026 (simulation SE with 4,000: 0.0025)
})

test_that("inputs are checked", {
  expect_error(calc_lan_demets_k("continuous", timing = c(0.6, 0.3), delta = 1, sd = 1), "increasing")
  expect_error(calc_lan_demets_k("continuous", timing = 1, delta = 1, sd = 1), "between 0 and 1")
  expect_error(calc_lan_demets_k("binary", pC = 0.3, pE = 0.3), "differ")
  expect_error(calc_lan_demets_k("survival", haz_ratio = 1), "differ")
  expect_error(calc_lan_demets_k("continuous", delta = 0, sd = 1), "differ")
})
