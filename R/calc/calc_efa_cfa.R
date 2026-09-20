#' EFA/CFA subjects-per-item rule-of-thumb sample size guidance
#'
#' There is no single accepted power formula for exploratory/confirmatory
#' factor analysis sample size in the way there is for a hypothesis test --
#' the field instead relies on published subjects-per-item (or
#' subjects-per-parameter) ratios, refined over decades of methodological
#' work. This is a genuine rule-of-thumb calculator (deterministic
#' arithmetic + a published lookup table), following the same honest
#' "guidance, not a solved formula" framing this app already uses for the
#' Pilot/Feasibility module (Julious 2005's 12-per-arm rule).
#'
#' Costello & Osborne (2005, Practical Assessment, Research & Evaluation
#' 10(7)) summarize the field's commonly-cited participant-to-item ratios:
#' 5:1 as an absolute minimum, 10:1 commonly recommended, and up to 20:1
#' for a more robust/stable solution. Comrey & Lee (1992, "A First Course
#' in Factor Analysis", 2nd ed.) separately propose absolute-N "adjective"
#' labels for the resulting total sample size, independent of item count:
#' 50=very poor, 100=poor, 200=fair, 300=good, 500=very good,
#' 1000=excellent.
#'
#' MacCallum, Widaman, Zhang & Hong (1999, Psychological Methods 4(1):
#' 84-99) is cited here as an explicit caveat, not folded into the
#' arithmetic: their finding is that required N depends heavily on
#' communality level and how overdetermined the factors are, so a fixed
#' ratio-only rule can be badly wrong in either direction for a specific
#' study -- these ratios are a starting point, not a substitute for
#' planning around the actual expected communalities when that
#' information is available.
#'
#' @param n_items Number of items (EFA) or free parameters (CFA/SEM) the
#'   scale/model has (whole number >= 1)
#' @return list(n_items, n_5to1, n_10to1, n_20to1, adjective_5to1,
#'   adjective_10to1, adjective_20to1, inputs)
calc_efa_cfa_sample_size <- function(n_items) {
  if (!is.numeric(n_items) || length(n_items) != 1 || is.na(n_items) ||
        n_items < 1 || n_items != round(n_items)) {
    stop("n_items must be a single whole number >= 1.")
  }

  n_5to1 <- 5 * n_items
  n_10to1 <- 10 * n_items
  n_20to1 <- 20 * n_items

  list(
    n_items = n_items,
    n_5to1 = n_5to1, n_10to1 = n_10to1, n_20to1 = n_20to1,
    adjective_5to1 = .comrey_lee_adjective(n_5to1),
    adjective_10to1 = .comrey_lee_adjective(n_10to1),
    adjective_20to1 = .comrey_lee_adjective(n_20to1),
    inputs = list(n_items = n_items)
  )
}

#' Comrey & Lee (1992) absolute-N adjective scale for factor analysis
#' sample size: 50=very poor, 100=poor, 200=fair, 300=good, 500=very
#' good, 1000+=excellent. Returns the highest threshold N meets or
#' exceeds.
.comrey_lee_adjective <- function(N) {
  if (N >= 1000) "excellent"
  else if (N >= 500) "very good"
  else if (N >= 300) "good"
  else if (N >= 200) "fair"
  else if (N >= 100) "poor"
  else if (N >= 50) "very poor"
  else "below the Comrey & Lee (1992) scale's minimum (very poor starts at N=50)"
}

#' Power for a CFA/SEM test of close fit via RMSEA (MacCallum, Browne &
#' Sugawara 1996)
#'
#' Unlike the rule-of-thumb calculator above, this is a genuine closed-
#' form hypothesis-test power calculation: testing a null RMSEA value
#' (e.g. "close fit", RMSEA0 = 0.05) against an alternative RMSEA value
#' (e.g. "poor fit", rmseaA = 0.08), using the noncentral chi-square
#' distribution implied by RMSEA's own definition. Reimplemented from
#' `semTools::findRMSEApower()`'s source (`semTools` installed via the
#' github.com/cran mirror as a verification oracle only -- not a runtime
#' dependency, per this project's vendoring policy) and verified
#' bit-for-bit against it.
#'
#' @param rmsea0 Null-hypothesis RMSEA value (>= 0)
#' @param rmseaA Alternative-hypothesis RMSEA value (>= 0, != rmsea0)
#' @param df Model degrees of freedom (whole number >= 1)
#' @param n Total sample size (> 1)
#' @param alpha Significance level (0,1)
#' @param group Number of groups in a multi-group model (whole number >= 1;
#'   1 for a single-group model)
#' @return Power (0,1)
calc_sem_rmsea_power <- function(rmsea0, rmseaA, df, n, alpha = 0.05, group = 1) {
  if (!is.numeric(rmsea0) || length(rmsea0) != 1 || is.na(rmsea0) || rmsea0 < 0) {
    stop("rmsea0 must be a single number >= 0.")
  }
  if (!is.numeric(rmseaA) || length(rmseaA) != 1 || is.na(rmseaA) || rmseaA < 0) {
    stop("rmseaA must be a single number >= 0.")
  }
  if (isTRUE(all.equal(rmsea0, rmseaA))) stop("rmsea0 and rmseaA must differ.")
  if (!is.numeric(df) || length(df) != 1 || is.na(df) || df < 1 || df != round(df)) {
    stop("df must be a single whole number >= 1.")
  }
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n <= 1) {
    stop("n must be a single number > 1.")
  }
  .validate_unit_interval(alpha, "alpha")
  if (!is.numeric(group) || length(group) != 1 || is.na(group) || group < 1 || group != round(group)) {
    stop("group must be a single whole number >= 1.")
  }

  ncp0 <- ((n - 1) * df * rmsea0^2) / group
  ncpa <- ((n - 1) * df * rmseaA^2) / group
  if (rmsea0 < rmseaA) {
    cval <- qchisq(alpha, df, ncp = ncp0, lower.tail = FALSE)
    pchisq(cval, df, ncp = ncpa, lower.tail = FALSE)
  } else {
    cval <- qchisq(1 - alpha, df, ncp = ncp0, lower.tail = FALSE)
    1 - pchisq(cval, df, ncp = ncpa, lower.tail = FALSE)
  }
}

#' Required sample size for a target CFA/SEM RMSEA test power
#'
#' Searches upward for the smallest total sample size reaching the
#' target power, mirroring `semTools::findRMSEAsamplesize()`'s own
#' search strategy (checked in blocks of 500 after an initial 5-500
#' scan) for an exact match to its behavior.
#'
#' @inheritParams calc_sem_rmsea_power
#' @param power Desired power (0,1)
#' @return list(n, achieved_power, inputs)
calc_sem_rmsea_samplesize <- function(rmsea0, rmseaA, df, power = 0.8, alpha = 0.05, group = 1) {
  .validate_unit_interval(power, "power")

  n_candidates <- 5:500
  pw <- sapply(n_candidates, function(n) calc_sem_rmsea_power(rmsea0, rmseaA, df, n, alpha, group))
  hit <- which(pw > power)[1]

  if (is.na(hit)) {
    n_candidates <- n_candidates + 500
    repeat {
      pw <- sapply(n_candidates, function(n) calc_sem_rmsea_power(rmsea0, rmseaA, df, n, alpha, group))
      hit <- which(pw > power)[1]
      if (!is.na(hit)) break
      n_candidates <- n_candidates + 500
      if (n_candidates[1] > 1e6) {
        stop("No feasible sample size found up to 1,000,000 -- the RMSEA difference is likely too small relative to df.")
      }
    }
  }

  n <- n_candidates[hit]
  list(
    n = n,
    achieved_power = calc_sem_rmsea_power(rmsea0, rmseaA, df, n, alpha, group),
    inputs = list(rmsea0 = rmsea0, rmseaA = rmseaA, df = df, power = power, alpha = alpha, group = group)
  )
}

#' IRT item calibration rule-of-thumb minimum sample size, by model type
#'
#' There is no closed-form power/sample-size formula for IRT item
#' calibration -- required N for adequate item-parameter recovery depends
#' on the specific model, item discrimination/difficulty distribution,
#' and test length, none of which reduce to a single hypothesis test. The
#' field instead relies on Monte Carlo parameter-recovery studies that
#' established minimum-N guidelines by model complexity, the same "genuine
#' rule-of-thumb, not a solved formula" framing this app already uses for
#' the EFA/CFA subjects-per-item ratios above and the Pilot/Feasibility
#' module's Julious (2005) 12-per-arm rule.
#'
#' - Rasch/1PL: Linacre (1994) -- roughly 50 well-targeted examinees is a
#'   conservative minimum for useful (if imprecise, ~1 logit) calibration;
#'   100-150 for +/-0.5 logit precision; 250+ for the tightest, most
#'   stable calibrations.
#' - 2PL: Hulin, Lissak & Drasgow (1982) -- a Monte Carlo parameter-
#'   recovery study (N = 200/500/1000/2000, tests of 15/30/60 items)
#'   concluding N >= 500 is needed for adequate 2PL item-parameter
#'   recovery.
#' - 3PL: the same Hulin, Lissak & Drasgow (1982) study -- the added
#'   guessing parameter needs substantially more data, N >= 1000.
#' - Polytomous (graded response/partial credit): Reise & Yu (1990) --
#'   N >= 500 needed for adequate discrimination-parameter recovery
#'   (correlation >= 0.85 between estimated and true values) in the
#'   graded response model.
#'
#' @param model Which IRT model is being calibrated: "rasch_1pl", "twopl",
#'   "threepl", or "polytomous"
#' @return list(model, n_minimum, n_precise, note, inputs)
calc_irt_calibration_guidance <- function(model = c("rasch_1pl", "twopl", "threepl", "polytomous")) {
  model <- match.arg(model)

  vals <- switch(model,
    rasch_1pl = list(
      n_minimum = 50, n_precise = 250,
      note = "50 well-targeted examinees is a conservative minimum for useful (~1 logit precision) calibration; 100-150 for +/-0.5 logit precision; 250+ for the tightest, most stable calibrations (Linacre 1994)."
    ),
    twopl = list(
      n_minimum = 500, n_precise = 1000,
      note = "N >= 500 for adequate 2PL item-parameter recovery, rising toward 1000+ for a more precisely-estimated discrimination parameter, especially with a shorter test (Hulin, Lissak & Drasgow 1982)."
    ),
    threepl = list(
      n_minimum = 1000, n_precise = 2000,
      note = "N >= 1000 for adequate 3PL item-parameter recovery -- the added guessing parameter needs substantially more data than the 2PL case; 2000+ for the most stable estimates (Hulin, Lissak & Drasgow 1982)."
    ),
    polytomous = list(
      n_minimum = 500, n_precise = 1000,
      note = "N >= 500 for adequate graded-response-model discrimination-parameter recovery (correlation >= 0.85 between estimated and true values); 1000+ for a longer polytomous scale or more response categories (Reise & Yu 1990)."
    )
  )

  list(
    model = model,
    n_minimum = vals$n_minimum,
    n_precise = vals$n_precise,
    note = vals$note,
    inputs = list(model = model)
  )
}
