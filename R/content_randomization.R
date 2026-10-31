# Metadata for the Randomization List module (ROADMAP Track B2, item 14): formula text,
# plain-language explanation, worked example and citation per design. Content is data,
# rendered generically by mod_randomization.R.

.rand_citation <- paste(
  "Altman DG, Bland JM. How to randomise. BMJ 1999;319:703-704; Schulz KF, Grimes DA. Generation of allocation sequences in",
  "randomised trials: chance, not choice. Lancet 2002;359:515-519; Schulz KF, Grimes DA. Allocation concealment in randomised",
  "trials: defending against deciphering. Lancet 2002;359:614-618; Matts JP, Lachin JM. Properties of permuted-block",
  "randomization in clinical trials. Control Clin Trials 1988;9:327-344. Existence, journal, volume and pages of all four were",
  "confirmed by web search; the papers themselves could not be read here. The generator is checked by its defining properties",
  "(exact balance in complete blocks, equally likely permutations, reproducibility from the seed), not against a package."
)

.rand_concealment <- paste(
  "**Allocation concealment** is separate from sequence generation. A good sequence is useless if recruiters can see or guess",
  "the next assignment. Keep the list with a person or system independent of recruitment, release one assignment at a time",
  "only after the participant is enrolled, and do not disclose block sizes in the protocol that recruiters read. With a",
  "fixed small block size in an unmasked trial the last assignments of each block can be guessed (Matts & Lachin 1988),",
  "which is why several block sizes chosen at random are usually preferred. The seed reproduces the entire list, so treat it",
  "as confidential too. Reporting guidelines ask you to state how the sequence was generated, what restriction (blocks,",
  "strata) was used and how it was concealed.",
  sep = "\n"
)

randomization_content <- list(
  block = list(
    title = "Permuted-block randomization (reproducible list)",
    formula_latex = paste0(
      "$$\\text{block size } b = c\\cdot\\sum_j r_j,\\qquad \\text{each arm } j \\text{ appears } c\\,r_j \\text{ times per block},\\qquad ",
      "P(\\text{any ordering of a block})=\\frac{\\prod_j (c\\,r_j)!}{b!}$$"
    ),
    explanation = paste(
      "Enter the number of participants, the arm labels, the allocation ratio (for example 2:1) and one or more **block sizes**",
      "(each a multiple of the sum of the ratio, e.g. 4 and 6 for 1:1). The list is built from consecutive blocks; each block is a",
      "random ordering of the arm labels in the allocation ratio, so the arms are balanced after every complete block. When",
      "several block sizes are given, one is chosen at random for each block. The **last block is cut** at the number of",
      "participants, so the final counts can differ from the ratio by less than one block.",
      "",
      "The list is a function of the **seed**: the same seed, method and block sizes give exactly the same list (on R 3.6 or later),",
      "and your own random-number stream is not disturbed. Download the list as CSV and keep the seed in the study records.",
      "",
      .rand_concealment,
      sep = "\n"
    ),
    worked_example = paste(
      "23 participants, arms A and B (1:1), block sizes 4 and 6, seed 1: the list is built from blocks such as BBAA | ... and the",
      "final counts are 12 and 11 (the last block is incomplete). Re-entering the same inputs reproduces the same list.",
      sep = "\n"
    ),
    citation = .rand_citation,
    backend = "base R sample() with a pinned generator (Mersenne-Twister, rejection sampling); verified by property tests"
  ),
  simple = list(
    title = "Simple (unrestricted) randomization",
    formula_latex = "$$P(\\text{arm } j)=\\frac{r_j}{\\sum_k r_k},\\ \\text{independently for each participant}$$",
    explanation = paste(
      "Each participant is assigned independently, with probabilities proportional to the allocation ratio -- the computer",
      "equivalent of a coin toss or die roll. It is completely unpredictable and unbiased, but **arm sizes can differ by chance**,",
      "noticeably in small trials (for 20 participants and two arms the arms are unequal more often than not). Blocks or",
      "strata are usually added for that reason; simple randomization is mostly used for large trials.",
      "",
      .rand_concealment,
      sep = "\n"
    ),
    worked_example = "20 participants, arms A and B (1:1), seed 1: the two arms are unequal in size in most seeds; the app shows the counts it got.",
    citation = .rand_citation,
    backend = "base R sample.int() with a pinned generator (Mersenne-Twister, rejection sampling)"
  ),
  stratified = list(
    title = "Stratified permuted-block randomization",
    formula_latex = "$$\\text{an independent permuted-block list for each stratum } s=1,\\dots,S$$",
    explanation = paste(
      "Enter stratum labels (for example sites, or sex-by-age groups) and the number of participants **per stratum**. Each stratum gets",
      "its own independent permuted-block list, so the arms are balanced within every stratum, not just overall. Stratify only on a",
      "few strong prognostic factors: with many strata and few participants in each, the incomplete last block of every stratum",
      "leaves the trial unbalanced. Each participant gets an ID that includes the stratum, and the recruiter picks the next unused",
      "ID in the participant's stratum.",
      "",
      .rand_concealment,
      sep = "\n"
    ),
    worked_example = "3 sites, 20 participants per site, arms A and B (1:1), block size 4, seed 8: every site has exactly 10 and 10 (20 is five complete blocks).",
    citation = .rand_citation,
    backend = "base R sample() per stratum with a pinned generator (Mersenne-Twister, rejection sampling); verified by property tests"
  )
)
