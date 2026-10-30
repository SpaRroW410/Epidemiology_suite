# Study planning: reproducible randomization lists (ROADMAP Track B2, item 14). Base R only.
#
# Methods
#   simple   each participant is assigned independently with probability proportional to the
#            allocation ratio (a coin toss / die roll). Unbiased and unpredictable, but the arm sizes
#            can differ by chance, markedly in small trials (Altman & Bland, BMJ 1999;319:703-704).
#   block    permuted blocks: the list is built from consecutive blocks, each a random permutation of
#            the arm labels repeated in the allocation ratio (block size = a multiple of the sum of
#            the ratio), so the arms are balanced after every complete block. Block sizes may be fixed
#            or drawn at random from several allowed sizes, which makes the next assignment harder to
#            guess in unmasked trials (Matts & Lachin, Control Clin Trials 1988;9:327-344).
#   stratified  an independent permuted-block list for each stratum (e.g. each site, or each
#            sex x age band), so balance holds within every stratum.
# The last block of a list is cut at the requested size, so it may be incomplete and the final
# counts may differ from the ratio by less than one block.
#
# Reproducibility: the list is a deterministic function of the seed. The generator is pinned
# (Mersenne-Twister, "Rejection" sampling, the R >= 3.6 default) inside the call and the user's
# own random-number stream is restored afterwards, so calling this function never disturbs
# other code and the same seed gives the same list on any R >= 3.6. Keep the seed, the method
# and the block sizes with the trial master file; the seed alone does NOT conceal the sequence
# -- keep the list away from the people who recruit (allocation concealment).
#
# There is no package oracle for "the correct list": the unit tests check the defining
# properties instead (exact balance in complete blocks, every permutation of a block equally
# likely, reproducibility, the global stream untouched, long-run arm frequencies).

.rand_with_seed <- function(seed, expr) {
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = globalenv(), inherits = FALSE) else NULL
  on.exit({
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  suppressWarnings(set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection"))
  force(expr)
}

.rand_block_list <- function(n, arms, ratio, block_sizes) {
  unit <- sum(ratio)
  out <- character(0); blk <- integer(0); bsz <- integer(0)
  b <- 0L
  while (length(out) < n) {
    b <- b + 1L
    size <- block_sizes[sample.int(length(block_sizes), 1L)]
    perm <- sample(rep(arms, times = ratio * (size / unit)))
    out <- c(out, perm); blk <- c(blk, rep(b, size)); bsz <- c(bsz, rep(size, size))
  }
  keep <- seq_len(n)
  list(arm = out[keep], block = blk[keep], block_size = bsz[keep])
}

#' Generate a randomization list
#'
#' @param n Number of participants (per stratum when `strata` is given).
#' @param arms Arm labels (2 to 8, distinct, non-empty).
#' @param ratio Positive whole-number allocation ratio, one per arm (e.g. c(2, 1)).
#' @param method "simple" or "block" (permuted blocks; with `strata`, one independent list per stratum).
#' @param block_sizes Allowed block sizes (multiples of sum(ratio)); one is picked at random for each block.
#' @param strata Optional stratum labels (1 to 40).
#' @param seed Whole-number seed that makes the list reproducible.
#' @return An `ss_result` of flat summary fields; the list itself is in `attr(result, "allocation")`.
#' @examples
#' calc_randomization_list(50, seed = 5)
#' @export
calc_randomization_list <- function(n, arms = c("Intervention", "Control"), ratio = rep(1, length(arms)),
                                    method = c("block", "simple"), block_sizes = NULL, strata = NULL, seed) {
  method <- match.arg(method)
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1 || n != round(n)) stop("The number of participants must be a whole number >= 1.")
  if (n > 100000) stop("At most 100,000 participants per list.")
  if (!is.character(arms) || length(arms) < 2 || length(arms) > 8) stop("Give between 2 and 8 arm labels.")
  arms <- trimws(arms)
  if (any(!nzchar(arms)) || anyDuplicated(arms)) stop("Arm labels must be non-empty and distinct.")
  if (!is.numeric(ratio) || length(ratio) != length(arms) || any(is.na(ratio)) || any(ratio < 1) || any(ratio != round(ratio))) {
    stop("The allocation ratio needs one whole number >= 1 for each arm.")
  }
  if (missing(seed) || !is.numeric(seed) || length(seed) != 1 || is.na(seed) || seed != round(seed) || abs(seed) > 2^31 - 1) {
    stop("Give a whole-number seed (it is what makes the list reproducible).")
  }
  if (!is.null(strata)) {
    strata <- trimws(strata)
    if (length(strata) < 1 || length(strata) > 40 || any(!nzchar(strata)) || anyDuplicated(strata)) {
      stop("Give 1 to 40 distinct, non-empty stratum labels.")
    }
  }
  unit <- sum(ratio)
  if (method == "block") {
    if (is.null(block_sizes)) block_sizes <- unit * 2
    if (!is.numeric(block_sizes) || length(block_sizes) < 1 || any(is.na(block_sizes)) ||
        any(block_sizes != round(block_sizes)) || any(block_sizes %% unit != 0) || any(block_sizes < unit)) {
      stop(sprintf("Every block size must be a multiple of %d (the sum of the allocation ratio).", unit))
    }
    block_sizes <- sort(unique(block_sizes))
  }
  groups <- if (is.null(strata)) NA_character_ else strata

  built <- .rand_with_seed(seed, {
    lapply(groups, function(g) {
      if (method == "simple") {
        arm <- arms[sample.int(length(arms), n, replace = TRUE, prob = ratio / unit)]
        list(arm = arm, block = rep(NA_integer_, n), block_size = rep(NA_integer_, n))
      } else {
        .rand_block_list(n, arms, ratio, block_sizes)
      }
    })
  })
  alloc <- do.call(rbind, lapply(seq_along(groups), function(i) {
    b <- built[[i]]
    data.frame(
      stratum = if (is.null(strata)) "All" else groups[i], sequence = seq_len(n),
      id = if (is.null(strata)) sprintf("%04d", seq_len(n)) else sprintf("S%02d-%03d", i, seq_len(n)),
      block = b$block, block_size = b$block_size, arm = b$arm, stringsAsFactors = FALSE)
  }))
  alloc$arm <- factor(alloc$arm, levels = arms)
  rownames(alloc) <- NULL

  counts <- as.integer(table(alloc$arm))
  # largest departure of any arm in any stratum from its expected count
  dev <- max(vapply(groups, function(g) {
    a <- if (is.na(g)) alloc$arm else alloc$arm[alloc$stratum == g]  # g is NA when there are no strata
    max(abs(as.integer(table(a)) - n * ratio / unit))
  }, numeric(1)))
  nblocks <- if (method == "block") sum(vapply(built, function(b) length(unique(b$block)), integer(1))) else NA_integer_
  last_complete <- if (method == "block") all(vapply(built, function(b) {
    nb <- max(b$block); sum(b$block == nb) == b$block_size[length(b$block_size)]
  }, logical(1))) else NA
  out <- list(
    n_total = nrow(alloc), n_per_list = n, n_lists = length(groups), method = method, seed = seed,
    block_sizes = if (method == "block") paste(block_sizes, collapse = ", ") else "none (simple randomization)",
    n_blocks = nblocks, last_block_complete = last_complete,
    max_departure_from_ratio = dev,
    r_version = paste0(R.version$major, ".", R.version$minor)
  )
  for (i in seq_along(arms)) {
    out[[paste0("arm_", i)]] <- arms[i]
    out[[paste0("ratio_arm_", i)]] <- ratio[i]
    out[[paste0("n_arm_", i)]] <- counts[i]
  }
  out$inputs <- list(n = n, arms = paste(arms, collapse = " | "), ratio = paste(ratio, collapse = ":"),
                     method = method, strata = if (is.null(strata)) "none" else paste(strata, collapse = " | "),
                     seed = seed)
  res <- new_ss_result(out)
  attr(res, "allocation") <- alloc
  res
}

# Counts of each arm per stratum (or overall), for display.
randomization_summary_table <- function(result) {
  a <- attr(result, "allocation")
  tb <- as.data.frame.matrix(table(factor(a$stratum, levels = unique(a$stratum)), a$arm))
  tb <- cbind(Stratum = rownames(tb), tb, Total = rowSums(tb))
  rownames(tb) <- NULL
  tb
}

# A paragraph for the methods section / trial master file. Generic wording; it states only what
# the tool did (it does not claim concealment, blinding or who generated the list).
randomization_methods_text <- function(result) {
  inp <- result$inputs
  ratio_txt <- if (length(unique(strsplit(inp$ratio, ":", fixed = TRUE)[[1]])) == 1) "equal allocation" else paste0("an allocation ratio of ", inp$ratio)
  arms <- strsplit(inp$arms, " | ", fixed = TRUE)[[1]]
  how <- if (result$method == "simple") {
    "simple (unrestricted) randomization"
  } else if (result$n_lists > 1) {
    sprintf("permuted-block randomization within strata (%s), with block sizes %s chosen at random for each block", gsub(" \\| ", ", ", inp$strata), result$block_sizes)
  } else {
    sprintf("permuted-block randomization with block sizes %s%s", result$block_sizes,
            if (grepl(",", result$block_sizes)) " chosen at random for each block" else "")
  }
  sprintf(paste0("A randomization list for %d participants%s (arms: %s; %s) was generated by computer using %s. The list is reproducible from",
                 " the seed %s (R %s, Mersenne-Twister generator, rejection sampling; epidemiologysuite). [State who generated the list, where the seed, method",
                 " and block sizes are recorded, and how assignments are concealed from those who recruit and assign participants.]"),
          result$n_total, if (result$n_lists > 1) sprintf(" in %d strata of %d each", result$n_lists, result$n_per_list) else "",
          paste(arms, collapse = ", "), ratio_txt, how, result$seed, result$r_version)
}
