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
