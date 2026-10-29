# Survey and field epidemiology tools (ROADMAP Track B3, item 20): sample selection and design weights.
# Base R only. Selections are reproducible from a seed in the same way as the randomization lists
# (.rand_with_seed(): pinned generator, caller's RNG stream restored).
#
# Selection methods
#   SRS         n units drawn without replacement from N: every unit has inclusion probability n / N.
#   systematic  interval k = N / n (need not be a whole number), random start r in (0, k], units
#               ceiling(r + (j - 1) k), j = 1..n. Exactly n units; inclusion probability n / N.
#               Every n-th unit of a list ordered by place or time spreads the sample over the frame.
#   PPS         probability proportional to size, systematic (Madow 1949): units listed with sizes x_i,
#               total X, interval k = X / n, random start r in (0, k]; unit i is selected when one of the
#               points r + (j - 1) k falls in its range of the cumulative sizes. Inclusion probability
#               n x_i / X. A unit with x_i >= k would be hit twice or more, so such "certainty" units
#               are taken with probability 1 and set aside, and the interval is recomputed from the
#               rest, repeatedly until none is left (the usual treatment, e.g. Valliant, Dever & Kreuter 2013).
#   EPI 30 x 7  the WHO Expanded Programme on Immunization cluster design (Henderson & Sundaresan 1982;
#               Bennett et al. 1991): first stage = PPS selection of 30 clusters (villages, blocks) from a
#               list with population sizes; second stage = a fixed number (7) of subjects per cluster,
#               which is a self-weighting design. The selection of households inside a cluster (random
#               walk, spin the pen, GPS) is a field procedure and is NOT computed here.
# Weights
#   design weight d = 1 / inclusion probability; nonresponse adjustment in weighting classes:
#   w = d n_h / r_h (sample n_h, respondents r_h in class h); Kish's approximate design effect of
#   unequal weights deff_w = n sum(w^2) / (sum w)^2 = 1 + CV(w)^2 and n_eff = n / deff_w (Kish 1965).
# Verification: sample selection is checked by its defining properties (exact sample size, inclusion
# probabilities, Horvitz-Thompson totals reproduce the frame total exactly for PPS) and, for PPS, against
# sampling::UPsystematic() (Madow's method) given the same random start; the weights by identities
# (adjusted weights sum to the class population sizes) and a Monte Carlo check of unbiasedness.

.survey_check_n <- function(n, upper, what) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1 || n != round(n)) stop(sprintf("The number of %s to select must be a whole number >= 1.", what))
  if (n > upper) stop(sprintf("Cannot select %d %s from a frame of %d.", as.integer(n), what, as.integer(upper)))
}
.survey_check_seed <- function(seed) {
  if (missing(seed) || !is.numeric(seed) || length(seed) != 1 || is.na(seed) || seed != round(seed) || abs(seed) > 2^31 - 1) {
    stop("Give a whole-number seed (it is what makes the selection reproducible).")
  }
}
.survey_labels <- function(labels, n) {
  if (is.null(labels)) return(as.character(seq_len(n)))
  if (length(labels) != n) stop("There must be one label per unit.")
  as.character(labels)
}
.survey_start <- function() 1 - stats::runif(1)       # uniform on (0, 1]

# PPS systematic selection given the random start u in (0, 1] (a fraction of one interval). Returns the
# 0/1 hit counts per unit; `x` must satisfy x < total / n for every unit (certainty units removed by the caller).
.survey_pps_hits <- function(x, n, u) {
  k <- sum(x) / n
  cum <- cumsum(x)
  points <- (u + seq_len(n) - 1) * k
  # unit index containing each point: first i with cum_i >= point (ties go to the earlier unit)
  idx <- findInterval(points, c(0, cum), left.open = TRUE)
  idx <- pmin(idx, length(x))
  tabulate(idx, nbins = length(x))
}

.survey_result <- function(fields, selection, inputs) {
  fields$inputs <- inputs
  res <- new_ss_result(fields)
  attr(res, "selection") <- selection
  res
}

#' Simple random sample of units from a frame
#' @param N Frame size.
#' @param n Number to select.
#' @param seed Whole-number seed.
#' @param labels Optional unit labels (length N).
#' @return A named list of class `ss_result` (printed by `print()`) with the components `method`, `frame_size`, `n_selected`, `sampling_fraction`, `design_weight`, `seed` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_survey_select_srs(500, 40, seed = 3, labels = paste0("U", 1:500))
#' @export
calc_survey_select_srs <- function(N, n, seed, labels = NULL) {
  if (!is.numeric(N) || length(N) != 1 || is.na(N) || N < 2 || N != round(N)) stop("The frame size must be a whole number >= 2.")
  .survey_check_n(n, N, "units")
  .survey_check_seed(seed)
  lab <- .survey_labels(labels, N)
  pick <- .rand_with_seed(seed, sort(sample.int(N, n)))
  sel <- data.frame(position = pick, unit = lab[pick], inclusion_probability = n / N, design_weight = N / n, stringsAsFactors = FALSE)
  .survey_result(list(method = "srs", frame_size = N, n_selected = n, sampling_fraction = n / N, design_weight = N / n, seed = seed),
                 sel, list(N = N, n = n, seed = seed))
}

#' Systematic sample (random start, fractional interval allowed)
#' @param N Size of the list (number of units, a whole number of at least 2).
#' @param n Number of units to select.
#' @param seed Whole-number seed, so that the same seed and settings give the same sample.
#' @param labels Optional unit labels, one per unit of the list.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `method`, `frame_size`, `n_selected`, `interval`, `random_start`, `sampling_fraction`, `design_weight`, `seed` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_survey_select_systematic(100, 10, seed = 5)
#' @export
calc_survey_select_systematic <- function(N, n, seed, labels = NULL) {
  if (!is.numeric(N) || length(N) != 1 || is.na(N) || N < 2 || N != round(N)) stop("The frame size must be a whole number >= 2.")
  .survey_check_n(n, N, "units")
  .survey_check_seed(seed)
  lab <- .survey_labels(labels, N)
  k <- N / n
  r <- .rand_with_seed(seed, k * .survey_start())
  pick <- ceiling(round(r + (seq_len(n) - 1) * k, 9))
  pick <- pmin(pick, N)
  sel <- data.frame(position = pick, unit = lab[pick], inclusion_probability = n / N, design_weight = N / n, stringsAsFactors = FALSE)
  .survey_result(list(method = "systematic", frame_size = N, n_selected = n, interval = k, random_start = r,
                      sampling_fraction = n / N, design_weight = N / n, seed = seed),
                 sel, list(N = N, n = n, seed = seed))
}

#' PPS systematic selection (Madow) with certainty units
#' @param sizes Positive sizes (e.g. populations), one per unit, in frame order.
#' @param n Number of units to select.
#' @param randomize_order Shuffle the list before selecting (random-order systematic PPS).
#' @param seed Whole-number seed, so that the same seed and settings give the same sample.
#' @param labels Optional unit labels, one per unit.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `method`, `frame_size`, `total_size`, `n_selected`, `n_certainty`, `interval`, `random_start`, `ht_total_size`, `seed` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_survey_select_pps(c(100, 60, 10, 10, 10, 10), 3, seed = 1)
#' @export
calc_survey_select_pps <- function(sizes, n, seed, labels = NULL, randomize_order = FALSE) {
  if (!is.numeric(sizes) || length(sizes) < 2 || anyNA(sizes) || any(!is.finite(sizes)) || any(sizes <= 0)) {
    stop("Give at least two units, each with a positive size.")
  }
  N <- length(sizes)
  .survey_check_n(n, N, "units")
  .survey_check_seed(seed)
  lab <- .survey_labels(labels, N)

  # certainty units: size >= interval of what is left; iterate (removing one raises no other unit's rank, but
  # lowers the remaining total, so the interval can fall and expose more)
  cert <- rep(FALSE, N)
  repeat {
    n_rem <- n - sum(cert)
    if (n_rem <= 0) break
    k <- sum(sizes[!cert]) / n_rem
    newc <- !cert & sizes >= k
    if (!any(newc)) break
    cert <- cert | newc
  }
  n_cert <- sum(cert)
  if (n_cert > n) stop("More units than the sample size are large enough to be taken with certainty; increase the number to select.")
  n_rem <- n - n_cert
  rest <- which(!cert)
  hits <- numeric(N)
  hits[cert] <- 1
  u <- NA_real_
  k <- NA_real_
  if (n_rem > 0) {
    u <- .rand_with_seed(seed, {
      start <- .survey_start()
      if (isTRUE(randomize_order)) rest <- rest[sample.int(length(rest))]
      start
    })
    h <- .survey_pps_hits(sizes[rest], n_rem, u)
    hits[rest] <- h
    k <- sum(sizes[rest]) / n_rem
  }
  pi_i <- rep(1, N)
  pi_i[!cert] <- if (n_rem > 0) n_rem * sizes[!cert] / sum(sizes[!cert]) else 0
  # cumulative size range of each non-certainty unit, in the order used for the systematic pass
  cum_to <- rep(NA_real_, N)
  cum_to[rest] <- cumsum(sizes[rest])
  cum_from <- cum_to - sizes
  sel_idx <- which(hits > 0)
  if (any(hits > 1)) stop("Internal error: a unit was selected twice.")
  sel <- data.frame(position = sel_idx, unit = lab[sel_idx], size = sizes[sel_idx], certainty = cert[sel_idx],
                    inclusion_probability = pi_i[sel_idx], design_weight = 1 / pi_i[sel_idx], stringsAsFactors = FALSE)
  full <- data.frame(position = seq_len(N), unit = lab, size = sizes, certainty = cert, selected = hits > 0,
                     cumulative_from = cum_from, cumulative_to = cum_to,
                     inclusion_probability = pi_i, design_weight = ifelse(pi_i > 0, 1 / pi_i, NA_real_),
                     stringsAsFactors = FALSE)
  res <- .survey_result(list(method = "pps", frame_size = N, total_size = sum(sizes), n_selected = nrow(sel),
                             n_certainty = n_cert, interval = k, random_start = if (is.na(u)) NA_real_ else u * k,
                             ht_total_size = sum(sel$size * sel$design_weight), seed = seed),
                        sel, list(n_units = N, n = n, randomize_order = randomize_order, seed = seed))
  attr(res, "frame") <- full
  res
}

#' WHO EPI cluster survey: PPS selection of clusters and the per-cluster take
#' @param n_clusters Clusters to select (30 in the EPI design).
#' @param per_cluster Subjects per cluster (7).
#' @param sizes Positive sizes (for example village populations), one per cluster in the list.
#' @param seed Whole-number seed, so that the same seed and settings give the same sample.
#' @param labels Optional cluster labels, one per cluster in the list.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `method`, `frame_size`, `total_size`, `n_selected`, `n_certainty`, `interval`, `random_start`, `ht_total_size`, `seed`, `clusters`, `per_cluster`, `total_sample` and `inputs`, the arguments the result was calculated from.
#' @examples
#' set.seed(3)
#' villages <- round(runif(120, 200, 3000))   # populations of 120 villages
#' calc_survey_epi_clusters(villages, n_clusters = 30, per_cluster = 7, seed = 11, labels = paste("Village", 1:120))
#' @export
calc_survey_epi_clusters <- function(sizes, n_clusters = 30, per_cluster = 7, seed, labels = NULL) {
  if (!is.numeric(per_cluster) || length(per_cluster) != 1 || is.na(per_cluster) || per_cluster < 1 || per_cluster != round(per_cluster)) {
    stop("The number of subjects per cluster must be a whole number >= 1.")
  }
  r <- calc_survey_select_pps(sizes, n_clusters, seed, labels)
  r$clusters <- r$n_selected
  r$per_cluster <- per_cluster
  r$total_sample <- r$n_selected * per_cluster
  r$method <- "epi"
  r$inputs$per_cluster <- per_cluster
  r$inputs$n_clusters <- n_clusters
  r
}

# Wording for a methods section; states what was done, not who held the list.
survey_selection_methods_text <- function(result) {
  m <- result$method
  how <- switch(m,
    srs = sprintf("a simple random sample of %d of %d units", result$n_selected, result$frame_size),
    systematic = sprintf("a systematic sample of %d of %d units (sampling interval %s, random start %s)", result$n_selected,
                         result$frame_size, format(round(result$interval, 3)), format(round(result$random_start, 3))),
    pps = sprintf("a probability-proportional-to-size systematic sample of %d of %d units (Madow 1949; interval %s, random start %s%s)",
                  result$n_selected, result$frame_size, format(round(result$interval, 1)), format(round(result$random_start, 1)),
                  if (result$n_certainty > 0) sprintf("; %d units taken with certainty", result$n_certainty) else ""),
    epi = sprintf("a two-stage cluster sample: %d clusters selected with probability proportional to size (systematic, interval %s, random start %s) and %d subjects per cluster (%d in total)",
                  result$clusters, format(round(result$interval, 1)), format(round(result$random_start, 1)), result$per_cluster, result$total_sample))
  sprintf("The sample was drawn by computer as %s, reproducible from the seed %s (R %s, Mersenne-Twister generator; epidemiologicasuite). [Describe how the frame was built, how it was ordered, and how subjects inside each selected unit are chosen.]",
          how, result$seed, paste0(R.version$major, ".", R.version$minor))
}

# --- design weights and nonresponse adjustment --------------------------------------------------------

#' Design weights, nonresponse adjustment in weighting classes, and Kish's effective sample size
#'
#' @param population Population (frame) count in each weighting class N_h.
#' @param sampled Number sampled in each class n_h.
#' @param responded Number of respondents in each class r_h (at least 1).
#' @param labels Optional class labels.
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n_classes`, `population_total`, `sampled_total`, `respondents_total`, `unweighted_response_rate`, `weighted_response_rate`, `sum_of_adjusted_weights`, `cv_weights`, `design_effect_weighting`, `effective_sample_size`, `min_weight`, `max_weight`, `adjusted_weight_1`, `response_rate_1`, `adjusted_weight_2`, `response_rate_2`, `adjusted_weight_3`, `response_rate_3` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_survey_weights(c(500, 300, 200), c(50, 50, 40), c(40, 30, 35))
#' @export
calc_survey_weights <- function(population, sampled, responded, labels = NULL) {
  k <- length(population)
  if (k < 1 || k > 20 || length(sampled) != k || length(responded) != k) stop("Give the population, sampled and responded counts for each class (1 to 20 classes).")
  for (nm in c("population", "sampled", "responded")) {
    v <- get(nm)
    if (!is.numeric(v) || anyNA(v) || any(v != round(v)) || any(v < 0)) stop(sprintf("%s must be whole numbers, 0 or more.", nm))
  }
  if (any(sampled < 1) || any(population < sampled)) stop("In every class the number sampled must be at least 1 and no more than the population.")
  if (any(responded > sampled)) stop("In every class the number of respondents cannot exceed the number sampled.")
  if (any(responded < 1)) stop("A class with no respondents cannot be adjusted: merge it with a similar class first.")
  lab <- if (is.null(labels)) paste("Class", seq_len(k)) else as.character(labels)
  base <- population / sampled                   # design weight of a sampled unit (equal-probability sampling within the class)
  rr <- responded / sampled
  w <- base / rr                                 # = population / responded
  r_tot <- sum(responded)
  n_eff <- sum(responded * w)^2 / sum(responded * w^2)
  tb <- data.frame(class = lab, population = population, sampled = sampled, responded = responded,
                   sampling_fraction = sampled / population, design_weight = base, response_rate = rr,
                   adjusted_weight = w, stringsAsFactors = FALSE)
  out <- list(
    n_classes = k, population_total = sum(population), sampled_total = sum(sampled), respondents_total = r_tot,
    unweighted_response_rate = r_tot / sum(sampled),
    weighted_response_rate = sum(base * responded) / sum(base * sampled),
    sum_of_adjusted_weights = sum(responded * w),
    cv_weights = sqrt(sum(responded * (w - sum(responded * w) / r_tot)^2) / r_tot) / (sum(responded * w) / r_tot),
    design_effect_weighting = r_tot / n_eff, effective_sample_size = n_eff,
    min_weight = min(w), max_weight = max(w)
  )
  for (i in seq_len(k)) {
    out[[paste0("adjusted_weight_", i)]] <- w[i]
    out[[paste0("response_rate_", i)]] <- rr[i]
  }
  out$inputs <- list(population = paste(population, collapse = ", "), sampled = paste(sampled, collapse = ", "),
                     responded = paste(responded, collapse = ", "))
  res <- new_ss_result(out)
  attr(res, "classes") <- tb
  res
}

#' Kish's effective sample size and design effect of unequal weights, from a list of weights
#' @param weights Survey weights, one per respondent (at least two, all positive).
#' @return A named list of class `ss_result` (printed by `print()`) with the components `n`, `effective_sample_size`, `design_effect_weighting`, `cv_weights`, `one_plus_cv_squared`, `min_weight`, `max_weight`, `max_to_min_ratio` and `inputs`, the arguments the result was calculated from.
#' @examples
#' calc_survey_effective_n(c(1, 1, 2, 2))
#' @export
calc_survey_effective_n <- function(weights) {
  if (!is.numeric(weights) || length(weights) < 2 || anyNA(weights) || any(!is.finite(weights)) || any(weights <= 0)) {
    stop("Give at least two positive weights.")
  }
  n <- length(weights)
  m <- mean(weights)
  cv <- sqrt(sum((weights - m)^2) / n) / m          # population-style CV, as in Kish's 1 + CV^2
  n_eff <- sum(weights)^2 / sum(weights^2)
  new_ss_result(list(
    n = n, effective_sample_size = n_eff, design_effect_weighting = n / n_eff, cv_weights = cv,
    one_plus_cv_squared = 1 + cv^2, min_weight = min(weights), max_weight = max(weights),
    max_to_min_ratio = max(weights) / min(weights),
    inputs = list(n = n)
  ))
}
