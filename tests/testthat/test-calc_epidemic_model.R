# Parameter values are illustrative (textbook-style), not estimates for any disease.
test_that("herd-immunity threshold, coverage needed and effective R0 follow the closed forms", {
  h <- calc_herd_immunity(12, 0.95, 0.9)
  expect_equal(h$herd_immunity_threshold, 1 - 1 / 12)
  expect_equal(h$coverage_needed, (1 - 1 / 12) / 0.95)
  expect_equal(h$attainable, 1)
  expect_equal(h$effective_r0, 12 * (1 - 0.9 * 0.95))
  expect_equal(h$above_threshold, 0)                      # 12 * 0.145 = 1.74: still above 1
  expect_equal(calc_herd_immunity(12, 1, 0.92)$above_threshold, 1)
  # a vaccine with low efficacy cannot reach the threshold even at 100% coverage
  w <- calc_herd_immunity(5, 0.7)
  expect_equal(w$attainable, 0); expect_gt(w$coverage_needed, 1)
  expect_equal(calc_herd_immunity(0.8)$herd_immunity_threshold, 0)
  # exactly at the needed coverage Re = 1
  expect_equal(calc_herd_immunity(4, 0.9, (1 - 1 / 4) / 0.9)$effective_r0, 1)
  expect_error(calc_herd_immunity(-1), "positive"); expect_error(calc_herd_immunity(3, 1.2), "between 0 and 1")
  expect_error(calc_herd_immunity(3, 0.9, 1.5), "between 0 and 1")
})

test_that("final size of the herd-immunity function satisfies the final-size equation, and vaccination shrinks it", {
  h <- calc_herd_immunity(2.5, 0.9, 0.3)
  v <- 0.3 * 0.9; z <- h$final_attack_rate
  sinf <- 1 - v - z
  expect_equal(sinf, (1 - v) * exp(-2.5 * (1 - sinf - v)), tolerance = 1e-6)
  expect_lt(z, h$final_attack_rate_no_vaccination)
  # the classic value: R0 = 2 infects 79.7% of a fully susceptible population (z = 1 - exp(-R0 z))
  expect_equal(calc_herd_immunity(2, 1, 0)$final_attack_rate_no_vaccination, 0.7968121, tolerance = 1e-6)
  expect_equal(calc_herd_immunity(3, 1, 0.7)$final_attack_rate, 0)       # Re = 0.9: nothing takes off
})

test_that("SIR run: stepped final size and peak equal the closed forms; compartments are conserved", {
  r <- calc_epidemic_sim(2.5, infectious_period = 7, population = 1e5, initial_infected = 10, days = 400)
  s <- attr(r, "series")
  expect_equal(s$susceptible + s$exposed + s$infectious + s$removed, rep(1e5, nrow(s)), tolerance = 1e-9)
  expect_equal(r$simulated_attack_fraction, r$final_size_fraction, tolerance = 1e-6)
  expect_equal(r$peak_infectious, r$peak_infectious_analytic, tolerance = 2e-3)   # peak on a daily grid
  expect_equal(r$epidemic_over, 1)
  s0 <- 1 - 1e-4; sinf <- 1 - r$final_size_fraction
  expect_equal(sinf, s0 * exp(-2.5 * (1 - sinf)), tolerance = 1e-8)             # i0 counted in the removed share
  expect_equal(r$growth_rate, (2.5 * (1 - 1e-4) - 1) / 7)
})

test_that("SEIR has the same final size as SIR, a later and lower peak, and its own growth rate", {
  a <- calc_epidemic_sim(3, 5, 0, population = 1e5, initial_infected = 20, days = 500)
  b <- calc_epidemic_sim(3, 5, 4, population = 1e5, initial_infected = 20, days = 500)
  expect_equal(b$model, "SEIR")
  expect_equal(b$final_size_fraction, a$final_size_fraction)
  expect_equal(b$simulated_attack_fraction, a$simulated_attack_fraction, tolerance = 1e-6)
  expect_gt(b$peak_day, a$peak_day); expect_lt(b$peak_infectious, a$peak_infectious)
  expect_lt(b$growth_rate, a$growth_rate)
  s0 <- 1 - 20 / 1e5; sg <- 1 / 4; g <- 1 / 5
  expect_equal(b$growth_rate, (-(sg + g) + sqrt((sg - g)^2 + 4 * sg * g * 3 * s0)) / 2)
  # the growth rate is the root of (r + sigma)(r + gamma) = sigma gamma R0 s0
  expect_equal((b$growth_rate + sg) * (b$growth_rate + g), sg * g * 3 * s0, tolerance = 1e-12)
})

test_that("the stepped solution equals deSolve::ode at tight tolerance (SIR and SEIR)", {
  skip_if_not_installed("deSolve")
  chk <- function(r0, ip, lp, cov, ve) {
    r <- calc_epidemic_sim(r0, ip, lp, cov, ve, population = 1e5, initial_infected = 15, days = 200)
    s <- attr(r, "series")
    v <- cov * ve; g <- 1 / ip; sg <- if (lp > 0) 1 / lp else 1; b <- r0 * g
    f <- function(t, y, p) {
      inf <- b * y[1] * y[3]
      if (lp > 0) list(c(-inf, inf - sg * y[2], sg * y[2] - g * y[3], g * y[3])) else list(c(-inf, 0, inf - g * y[3], g * y[3]))
    }
    o <- deSolve::ode(c(1 - v - 15 / 1e5, 0, 15 / 1e5, v), 0:200, f, NULL, method = "lsoda", rtol = 1e-11, atol = 1e-13)
    expect_equal(s$susceptible, o[, 2] * 1e5, tolerance = 1e-5)
    expect_equal(s$infectious, o[, 4] * 1e5, tolerance = 1e-5)
    expect_equal(s$removed, o[, 5] * 1e5, tolerance = 1e-5)
  }
  chk(2.5, 7, 0, 0, 1)
  chk(4, 5, 3, 0.4, 0.9)
})

test_that("vaccination: no epidemic above the threshold, fewer infections below it, herd protection of the unvaccinated", {
  none <- calc_epidemic_sim(3, 6, 2, coverage = 0, population = 1e5)
  part <- calc_epidemic_sim(3, 6, 2, coverage = 0.5, vaccine_efficacy = 0.9, population = 1e5)
  full <- calc_epidemic_sim(3, 6, 2, coverage = 0.8, vaccine_efficacy = 0.9, population = 1e5)   # 0.72 > 1 - 1/3
  expect_lt(part$final_size_cases, none$final_size_cases)
  expect_equal(part$infections_averted, none$final_size_cases - part$final_size_cases, tolerance = 1e-6)
  expect_lt(full$final_size_fraction, 0.001)                                  # only the seed's own chains
  expect_lt(full$effective_r0, 1)
  # unvaccinated and unprotected people are less infected than if nobody were vaccinated (indirect effect)
  unprotected_share_infected <- part$final_size_cases / (1e5 * (1 - 0.5 * 0.9))
  expect_lt(unprotected_share_infected, none$final_size_fraction)
})

test_that("R0 recovered from the stepped run's growth rate and final size equals the input", {
  r <- calc_epidemic_sim(2.2, 8, 0, population = 1e6, initial_infected = 1, days = 600)
  expect_equal(calc_r0_estimate("final_size", final_attack = r$final_size_fraction)$r0, 2.2, tolerance = 1e-4)
  expect_equal(calc_r0_estimate("growth", growth_rate = (2.2 * (1 - 1e-6) - 1) / 8, infectious_period = 8)$r0, 2.2, tolerance = 1e-5)
  # measured early slope of log(infectious) in the SEIR run gives back the SEIR growth rate and R0
  b <- calc_epidemic_sim(2.2, 8, 3, population = 1e8, initial_infected = 1, days = 80, steps_per_day = 40)
  s <- attr(b, "series"); w <- 55:75
  slope <- unname(coef(lm(log(s$infectious[w]) ~ s$day[w]))[2])
  expect_equal(slope, b$growth_rate, tolerance = 5e-3)
  expect_equal(calc_r0_estimate("growth", growth_rate = slope, infectious_period = 8, latent_period = 3)$r0, 2.2, tolerance = 0.02)
  # with prior immunity, final-size R0 still recovers the input
  v <- calc_epidemic_sim(3, 5, 0, coverage = 0.4, vaccine_efficacy = 1, population = 1e6, initial_infected = 1, days = 500)
  expect_equal(calc_r0_estimate("final_size", final_attack = v$final_size_fraction, immune_share = 0.4)$r0, 3, tolerance = 1e-3)
})

test_that("R0 estimators: doubling time, textbook value, guards", {
  d <- calc_r0_estimate("growth", doubling_time = 3, infectious_period = 5)
  expect_equal(d$growth_rate, log(2) / 3); expect_equal(d$r0, 1 + log(2) / 3 * 5)
  expect_equal(calc_r0_estimate("final_size", final_attack = 0.8)$r0, -log(0.2) / 0.8)
  expect_error(calc_r0_estimate("growth"), "either")
  expect_error(calc_r0_estimate("growth", growth_rate = 0.1, doubling_time = 3), "either")
  expect_error(calc_r0_estimate("final_size", final_attack = 1), "above 0")
  expect_error(calc_r0_estimate("final_size", final_attack = 0.7, immune_share = 0.4), "above 0")
  expect_error(calc_epidemic_sim(2, 7, population = 100, initial_infected = 100, coverage = 0.5), "no one susceptible")
  expect_error(calc_epidemic_sim(2, 0), "positive")
  expect_error(calc_epidemic_sim(2, 7, days = 5000), "at most")
})
