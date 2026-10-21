# Infectious-disease teaching models (ROADMAP Track B5, item 20): herd immunity and vaccination, a deterministic
# SIR / SEIR epidemic with vaccination, and R0 from an observed growth rate or final size. These are textbook
# models for teaching and rough planning, not forecasts: homogeneous mixing, a closed population, no births or
# deaths, constant rates (exponentially distributed stage durations), and a vaccine that protects a fixed share
# of those vaccinated before the epidemic starts.
#
# Formulas (Kermack WO, McKendrick AG. A contribution to the mathematical theory of epidemics. Proc R Soc Lond A
# 1927;115:700-721; Anderson RM, May RM. Infectious Diseases of Humans. Oxford University Press; 1991; Hethcote HW.
# The mathematics of infectious diseases. SIAM Rev 2000;42:599-653; Fine P, Eames K, Heymann DL. "Herd immunity": a
# rough guide. Clin Infect Dis 2011;52:911-916; Wallinga J, Lipsitch M. How generation intervals shape the
# relationship between growth rates and reproductive numbers. Proc R Soc B 2007;274:599-604):
#   herd-immunity threshold            HIT = 1 - 1/R0
#   coverage needed with efficacy E    c = HIT / E   (a threshold above 1 cannot be reached by vaccination alone)
#   effective reproduction number      Re = R0 (1 - c E)
#   epidemic equations (fractions)     S' = -b S I, I' = b S I - g I, R' = g I; SEIR adds E' = b S I - s E, I' = s E - g I
#                                      with b = R0 g, g = 1 / infectious period, s = 1 / latent period
#   final size (SIR and SEIR alike)    s_inf = s0 exp(-R0 (1 - s_inf - v)),  v = c E immune at the start
#   peak infectious fraction (SIR)     i0 + s0 - (1 + ln(R0 s0)) / R0   when R0 s0 > 1
#   early growth rate                  SIR: r = g (R0 s0 - 1);  SEIR: (r + s)(r + g) = s g R0 s0, so
#                                      r = (-(s + g) + sqrt((s - g)^2 + 4 s g R0 s0)) / 2
#   R0 from a growth rate r            SIR: R0 = 1 + r / g;  SEIR: R0 = (1 + r / s)(1 + r / g)
#   R0 from a final size z (share of the whole population infected, fully susceptible before)  R0 = -ln(1 - z) / z;
#                                      with an immune share v: R0 = ln(s0 / s_inf) / (s0 - s_inf), s0 = 1 - v, s_inf = 1 - v - z
# The ODEs are stepped with a fixed-step fourth-order Runge-Kutta method in base R (no solver package at run time).
# Verification: the stepped solution equals deSolve::ode() at tight tolerance (oracle only), the closed forms above equal
# the stepped final size and peak, and R0 recovered from the stepped growth rate and final size equals the input R0.

.em_pos <- function(x, label, max = Inf) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x <= 0 || x > max) stop(sprintf("%s must be a single positive number%s.", label, if (is.finite(max)) sprintf(" (at most %g)", max) else ""))
}
.em_unit <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 0 || x > 1) stop(sprintf("%s must be a single number between 0 and 1.", label))
}

# Final size fraction s_inf (the share of the population still susceptible at the end): the unique root in (0, s0).
.em_final_susceptible <- function(r0, s0, v) {
  g <- function(s) s - s0 * exp(-r0 * (1 - s - v))
  stats::uniroot(g, c(0, s0), tol = 1e-14, extendInt = "no")$root
}

#' Herd-immunity threshold and the vaccination coverage needed
#' @param r0 Basic reproduction number. @param vaccine_efficacy Share of vaccinated people protected (0-1).
#' @param coverage Optional vaccination coverage (0-1) to evaluate.
calc_herd_immunity <- function(r0, vaccine_efficacy = 1, coverage = NULL) {
  .em_pos(r0, "R0", 50)
  .em_pos(vaccine_efficacy, "Vaccine efficacy"); .em_unit(vaccine_efficacy, "Vaccine efficacy")
  hit <- max(0, 1 - 1 / r0)
  needed <- hit / vaccine_efficacy
  out <- list(r0 = r0, vaccine_efficacy = vaccine_efficacy, herd_immunity_threshold = hit,
              coverage_needed = needed, attainable = as.numeric(needed <= 1),
              max_reduction_in_r0 = vaccine_efficacy)
  if (!is.null(coverage)) {
    .em_unit(coverage, "Coverage")
    v <- coverage * vaccine_efficacy
    out$coverage <- coverage; out$immune_share <- v
    out$effective_r0 <- r0 * (1 - v)
    out$above_threshold <- as.numeric(out$effective_r0 < 1)
    # final size when a negligible number of cases is introduced
    seed <- 1e-9
    out$final_attack_rate <- if (out$effective_r0 > 1) 1 - v - .em_final_susceptible(r0, 1 - v - seed, v) else 0
    out$final_attack_rate_no_vaccination <- 1 - .em_final_susceptible(r0, 1 - seed, 0)
  }
  out$inputs <- list(r0 = r0, vaccine_efficacy = vaccine_efficacy, coverage = if (is.null(coverage)) NA else coverage)
  new_ss_result(out)
}

#' Deterministic SIR / SEIR epidemic with vaccination before the start
#' @param r0 Basic reproduction number. @param infectious_period Mean infectious period (days).
#' @param latent_period Mean latent period (days); 0 gives an SIR model.
#' @param coverage,vaccine_efficacy Share vaccinated before the start and the share of those protected.
#' @param population Population size. @param initial_infected Infectious people at day 0.
#' @param days Days to simulate. @param steps_per_day Runge-Kutta steps per day.
calc_epidemic_sim <- function(r0, infectious_period = 7, latent_period = 0, coverage = 0, vaccine_efficacy = 1,
                              population = 100000, initial_infected = 10, days = 365, steps_per_day = 20) {
  .em_pos(r0, "R0", 50); .em_pos(infectious_period, "The infectious period", 365)
  if (!is.numeric(latent_period) || length(latent_period) != 1 || is.na(latent_period) || latent_period < 0 || latent_period > 365) stop("The latent period must be a single number from 0 to 365 days (0 gives an SIR model).")
  .em_unit(coverage, "Coverage"); .em_pos(vaccine_efficacy, "Vaccine efficacy"); .em_unit(vaccine_efficacy, "Vaccine efficacy")
  .em_pos(population, "The population", 1e10); .em_pos(initial_infected, "The initial number infectious", population)
  .em_pos(days, "The number of days", 1825)
  if (!is.numeric(steps_per_day) || length(steps_per_day) != 1 || is.na(steps_per_day) || steps_per_day < 1 || steps_per_day > 200 || steps_per_day != round(steps_per_day)) stop("Steps per day must be a whole number from 1 to 200.")
  days <- ceiling(days)
  v <- coverage * vaccine_efficacy
  i0 <- initial_infected / population
  s0 <- 1 - v - i0
  if (s0 <= 0) stop("The vaccinated share plus the initially infectious share leaves no one susceptible.")
  seir <- latent_period > 0
  gam <- 1 / infectious_period; sig <- if (seir) 1 / latent_period else NA_real_
  bet <- r0 * gam
  f <- function(y) {
    inf <- bet * y[1] * y[3]
    if (seir) c(-inf, inf - sig * y[2], sig * y[2] - gam * y[3], gam * y[3]) else c(-inf, 0, inf - gam * y[3], gam * y[3])
  }
  h <- 1 / steps_per_day
  y <- c(S = s0, E = 0, I = i0, R = v)
  out <- matrix(NA_real_, days + 1, 4); out[1, ] <- y
  for (d in seq_len(days)) {
    for (k in seq_len(steps_per_day)) {
      k1 <- f(y); k2 <- f(y + h / 2 * k1); k3 <- f(y + h / 2 * k2); k4 <- f(y + h * k3)
      y <- y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    }
    out[d + 1, ] <- y
  }
  series <- data.frame(day = 0:days, susceptible = out[, 1] * population, exposed = out[, 2] * population,
                       infectious = out[, 3] * population, removed = out[, 4] * population)
  series$cumulative_infected <- (1 - v - out[, 1]) * population
  series$new_infections <- c(NA_real_, -diff(out[, 1])) * population
  peak <- which.max(out[, 3])
  s_inf <- if (r0 * (1 - v) > 0) .em_final_susceptible(r0, s0, v) else s0
  growth <- if (seir) (-(sig + gam) + sqrt((sig - gam)^2 + 4 * sig * gam * r0 * s0)) / 2 else gam * (r0 * s0 - 1)
  peak_analytic <- if (!seir) (if (r0 * s0 > 1) i0 + s0 - (1 + log(r0 * s0)) / r0 else i0) else NA_real_
  base_s <- .em_final_susceptible(r0, 1 - i0, 0)
  fin <- list(
    model = NA_character_, r0 = r0, population = population,
    immune_at_start = v * population, effective_r0 = r0 * (1 - v),
    final_size_fraction = 1 - v - s_inf,
    final_size_cases = (1 - v - s_inf) * population,
    final_size_fraction_no_vaccination = 1 - base_s,
    infections_averted = ((1 - base_s) - (1 - v - s_inf)) * population,
    peak_infectious = out[peak, 3] * population, peak_infectious_fraction = out[peak, 3],
    peak_infectious_analytic = peak_analytic * population,
    peak_day = peak - 1, simulated_attack_fraction = 1 - v - out[days + 1, 1],
    epidemic_over = as.numeric((out[days + 1, 2] + out[days + 1, 3]) * population < 1),
    growth_rate = growth, doubling_time = if (growth > 0) log(2) / growth else NA_real_,
    generation_interval = if (seir) latent_period + infectious_period else infectious_period
  )
  fin$model <- if (seir) "SEIR" else "SIR"
  fin$inputs <- list(r0 = r0, infectious_period = infectious_period, latent_period = latent_period, coverage = coverage,
                     vaccine_efficacy = vaccine_efficacy, population = population, initial_infected = initial_infected,
                     days = days, steps_per_day = steps_per_day)
  res <- new_ss_result(fin)
  attr(res, "series") <- series
  res
}

#' R0 from an observed growth rate or a final attack fraction
#' @param method "growth" (needs growth_rate or doubling_time, and the infectious / latent periods) or "final_size".
#' @param growth_rate Exponential growth rate per day. @param doubling_time Days to double (alternative to growth_rate).
#' @param infectious_period,latent_period Mean periods in days (latent 0 gives the SIR form).
#' @param final_attack Share of the whole population infected over the whole epidemic.
#' @param immune_share Share immune before the epidemic (final-size method).
calc_r0_estimate <- function(method = c("growth", "final_size"), growth_rate = NULL, doubling_time = NULL,
                             infectious_period = 7, latent_period = 0, final_attack = NULL, immune_share = 0) {
  method <- match.arg(method)
  if (method == "growth") {
    if (is.null(growth_rate) == is.null(doubling_time)) stop("Give either a growth rate or a doubling time, not both.")
    r <- if (!is.null(growth_rate)) growth_rate else { .em_pos(doubling_time, "The doubling time"); log(2) / doubling_time }
    if (!is.numeric(r) || length(r) != 1 || is.na(r) || !is.finite(r)) stop("The growth rate must be a single number.")
    .em_pos(infectious_period, "The infectious period", 365)
    if (!is.numeric(latent_period) || length(latent_period) != 1 || is.na(latent_period) || latent_period < 0) stop("The latent period must be 0 or more days.")
    gam <- 1 / infectious_period
    r0 <- if (latent_period > 0) (1 + r * latent_period) * (1 + r / gam) else 1 + r / gam
    if (r0 < 0) stop("The growth rate is too negative for these periods (R0 would be negative).")
    out <- list(method = "growth", growth_rate = r, doubling_time = if (r > 0) log(2) / r else NA_real_, r0 = r0,
                model = if (latent_period > 0) "SEIR" else "SIR")
    out$inputs <- list(method = "growth", growth_rate = r, infectious_period = infectious_period, latent_period = latent_period)
  } else {
    .em_unit(immune_share, "The immune share")
    if (immune_share >= 1) stop("The immune share must be below 1.")
    z <- final_attack
    if (!is.numeric(z) || length(z) != 1 || is.na(z) || z <= 0 || z >= 1 - immune_share) stop("The final attack fraction must be above 0 and below the susceptible share at the start (1 - immune share).")
    s0 <- 1 - immune_share
    r0 <- log(s0 / (s0 - z)) / z
    out <- list(method = "final_size", final_attack = z, immune_share = immune_share, r0 = r0,
                herd_immunity_threshold = max(0, 1 - 1 / r0))
    out$inputs <- list(method = "final_size", final_attack = z, immune_share = immune_share)
  }
  new_ss_result(out)
}
