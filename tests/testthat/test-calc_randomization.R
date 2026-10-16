alloc <- function(r) attr(r, "allocation")

test_that("permuted blocks: every complete block has exactly the allocation ratio", {
  for (cfg in list(list(c("A", "B"), c(1, 1), c(4, 6)), list(c("A", "B", "C"), c(2, 1, 1), c(4, 8)), list(c("X", "Y"), c(2, 1), 6))) {
    r <- calc_randomization_list(200, cfg[[1]], cfg[[2]], "block", cfg[[3]], seed = 11)
    a <- alloc(r)
    for (b in setdiff(unique(a$block), max(a$block))) {
      blk <- a[a$block == b, ]
      expect_equal(nrow(blk), blk$block_size[1])
      expect_equal(as.integer(table(blk$arm)), as.integer(cfg[[2]] * blk$block_size[1] / sum(cfg[[2]])))
    }
    expect_equal(nrow(a), 200)
    expect_true(all(a$block_size %in% cfg[[3]]))
  }
})

test_that("the list is a function of the seed only, and the user's random stream is untouched", {
  a1 <- alloc(calc_randomization_list(50, seed = 5)); a2 <- alloc(calc_randomization_list(50, seed = 5))
  expect_identical(a1, a2)
  expect_false(identical(a1$arm, alloc(calc_randomization_list(50, seed = 6))$arm))
  set.seed(99); x1 <- runif(3)
  set.seed(99); invisible(calc_randomization_list(50, seed = 5)); x2 <- runif(3)
  expect_identical(x1, x2)                                   # the call did not consume or reset the caller's stream
  rm(list = ".Random.seed", envir = globalenv()); invisible(calc_randomization_list(50, seed = 5))
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
  # a user with another RNG kind gets the same list
  old <- RNGkind(); suppressWarnings(RNGkind("Wichmann-Hill", "Box-Muller", "Rounding"))
  a3 <- alloc(calc_randomization_list(50, seed = 5)); suppressWarnings(RNGkind(old[1], old[2], old[3]))
  expect_identical(a1, a3)
})

test_that("regression values for fixed seeds (recorded from this code under R 4.3.3, so they guard against silent changes of the algorithm or of R's sampler; they are not independent references)", {
  r <- alloc(calc_randomization_list(12, c("A", "B"), c(1, 1), "block", 4, seed = 2026))
  expect_equal(as.character(r$arm), c("A", "B", "A", "B", "B", "A", "B", "A", "A", "B", "A", "B"))
  r <- alloc(calc_randomization_list(10, c("A", "B", "C"), c(2, 1, 1), "block", 4, strata = c("x", "y"), seed = 7))
  expect_equal(as.character(r$arm), c("B", "C", "A", "A", "B", "A", "C", "A", "B", "A", "A", "B", "C", "A", "B", "C", "A", "A", "B", "A"))
})

test_that("within a block every permutation is equally likely (chi-square on the 6 orderings of AABB)", {
  set.seed(1)
  perms <- vapply(1:6000, function(s) paste(as.character(alloc(calc_randomization_list(4, c("A", "B"), c(1, 1), "block", 4, seed = s))$arm), collapse = ""), "")
  tb <- table(perms)
  expect_equal(length(tb), 6)
  expect_gt(chisq.test(tb)$p.value, 0.001)
})

test_that("block sizes are drawn at random from the allowed sizes, about equally often", {
  r <- alloc(calc_randomization_list(20000, c("A", "B"), c(1, 1), "block", c(4, 6, 8), seed = 3))
  firsts <- r[!duplicated(r$block), "block_size"]
  expect_equal(as.numeric(prop.table(table(firsts))), rep(1/3, 3), tolerance = 0.06)
})

test_that("stratified lists are independent within strata and balanced in each", {
  r <- calc_randomization_list(20, c("A", "B"), c(1, 1), "block", 4, strata = c("Site 1", "Site 2", "Site 3"), seed = 8)
  a <- alloc(r)
  expect_equal(nrow(a), 60); expect_equal(r$n_lists, 3)
  for (s in unique(a$stratum)) expect_equal(as.integer(table(a$arm[a$stratum == s])), c(10L, 10L))   # 20 = 5 complete blocks of 4
  expect_false(identical(a$arm[a$stratum == "Site 1"], a$arm[a$stratum == "Site 2"]))
  expect_equal(r$max_departure_from_ratio, 0)
  expect_equal(unname(unlist(randomization_summary_table(r)[1, c("A", "B", "Total")])), c(10, 10, 20))
  expect_true(all(grepl("^S0[123]-", a$id)))
})

test_that("an incomplete last block shows up as a small departure from the ratio and is flagged", {
  r <- calc_randomization_list(10, c("A", "B"), c(1, 1), "block", 4, seed = 4)
  expect_false(r$last_block_complete)
  expect_lte(r$max_departure_from_ratio, 2)
  expect_true(calc_randomization_list(12, c("A", "B"), c(1, 1), "block", 4, seed = 4)$last_block_complete)
})

test_that("simple randomization follows the ratio in the long run and ignores the block settings", {
  r <- alloc(calc_randomization_list(30000, c("A", "B", "C"), c(2, 1, 1), "simple", seed = 9))
  expect_equal(as.numeric(prop.table(table(r$arm))), c(0.5, 0.25, 0.25), tolerance = 0.03)
  expect_true(all(is.na(r$block)))
  # chance imbalance is real in small trials -- that is the reason for blocks
  imb <- vapply(1:300, function(s) { x <- table(alloc(calc_randomization_list(20, c("A", "B"), method = "simple", seed = s))$arm); abs(diff(as.integer(x))) }, 1)
  expect_gt(mean(imb > 0), 0.5)
})

test_that("summary fields are consistent with the list, and the methods text states the facts used", {
  r <- calc_randomization_list(30, c("Drug", "Placebo"), c(2, 1), "block", c(3, 6), seed = 77)
  a <- alloc(r)
  expect_equal(c(r$n_arm_1, r$n_arm_2), as.integer(table(a$arm)))
  expect_equal(r$n_total, 30)
  txt <- randomization_methods_text(r)
  expect_match(txt, "30 participants"); expect_match(txt, "2:1"); expect_match(txt, "seed 77"); expect_match(txt, "3, 6")
  expect_match(txt, "\\[State who generated")        # a placeholder, not a claim about concealment
})

test_that("input is validated", {
  expect_error(calc_randomization_list(10, c("A", "B"), c(1, 1), "block", 3, seed = 1), "multiple of 2")
  expect_error(calc_randomization_list(10, c("A", "B"), c(2, 1), "block", 4, seed = 1), "multiple of 3")
  expect_error(calc_randomization_list(10, c("A", "A"), seed = 1), "distinct")
  expect_error(calc_randomization_list(10, "A", seed = 1), "between 2 and 8")
  expect_error(calc_randomization_list(10, c("A", "B"), c(1, 0), seed = 1), "allocation ratio")
  expect_error(calc_randomization_list(0, seed = 1), "whole number")
  expect_error(calc_randomization_list(10), "seed")
  expect_error(calc_randomization_list(10, seed = 1.5), "seed")
  expect_error(calc_randomization_list(10, strata = c("x", "x"), seed = 1), "distinct")
})
