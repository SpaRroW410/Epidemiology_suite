# Metadata for the TOST Equivalence module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_tost.R (SDD 4.2: "content is data, not hardcoded UI").

tost_content <- list(
  means = list(
    title = "Equivalence of Two Means (Two One-Sided Tests, TOST)",
    formula_latex = paste0(
      "$$H_0: |\\mu_T - \\mu_R| \\ge \\Delta \\quad \\text{vs.} \\quad ",
      "H_1: -\\Delta < \\mu_T - \\mu_R < \\Delta$$",
      "$$n \\text{ solved iteratively so both one-sided tests reject at } \\alpha ",
      "\\text{ with the desired power (Owen's Q; Phillips 1990)}$$"
    ),
    explanation = paste(
      "Use this when your goal is to show two group means are",
      "*practically the same* -- e.g. a cheaper generic formulation, a",
      "simplified protocol, or a task-shifted delivery model -- rather",
      "than to detect a difference. This inverts the usual logic of a",
      "hypothesis test: here the null hypothesis is that the groups",
      "*differ* by at least the equivalence margin, and you're trying to",
      "reject that null in favor of equivalence.",
      "",
      "- **Expected difference** - the difference in means (test minus",
      "  reference) you actually expect; for a genuine equivalence claim",
      "  this is usually close to 0, and must be strictly smaller in",
      "  magnitude than the margin below.",
      "- **Equivalence margin** - the largest difference that would still",
      "  be considered clinically/practically equivalent (symmetric:",
      "  +/- this value).",
      "- **sd** - the common/pooled standard deviation.",
      "- **alpha** - the one-sided significance level for each of the two",
      "  tests (TOST runs two one-sided tests, not one two-sided test).",
      "- **power** - the desired probability of concluding equivalence,",
      "  given the assumed true difference.",
      "",
      "This uses the *original* (untransformed) scale, appropriate for a",
      "parallel-group design comparing raw units (e.g. exam scores, blood",
      "pressure). Pharmacokinetic bioequivalence studies conventionally",
      "use a log-transformed ratio (T/R) with a 0.80-1.25 margin and a",
      "crossover design instead -- the same backend package supports that",
      "framing too, but it isn't exposed by this calculator.",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose a simplified counseling protocol is expected to produce",
      "almost the same improvement as the standard, more intensive one",
      "(expected difference = 0.5 points on some scale), with a margin of",
      "+/-2 points considered practically equivalent, and a common SD of",
      "5. At a one-sided alpha of 0.05 and 80% power, this calculator",
      "returns n = 141 per group (282 total).",
      sep = "\n"
    ),
    citation = paste(
      "Phillips KF. Power of the two one-sided tests procedure in",
      "bioequivalence. J Pharmacokin Biopharm. 1990;18(2):137-144;",
      "Diletti D, Hauschke D, Steinijans VW. Sample size determination",
      "for bioequivalence assessment by means of confidence intervals.",
      "Int J Clin Pharmacol Ther Toxicol. 1991;29(1):1-8."
    ),
    backend = "PowerTOST::sampleN.TOST(logscale = FALSE, design = \"parallel\")"
  ),

  proportions = list(
    title = "Equivalence of Two Proportions (Two One-Sided Tests, TOST)",
    formula_latex = paste0(
      "$$H_0: |P_n - P_s| \\ge \\Delta \\quad \\text{vs.} \\quad ",
      "H_1: |P_n - P_s| < \\Delta$$"
    ),
    explanation = paste(
      "The proportions counterpart of \"Equivalence of Two Means\" above --",
      "use this to show two groups' proportions/response rates are",
      "*practically the same*, rather than to detect a difference.",
      "",
      "- **New / standard proportion** - the expected proportion of",
      "  successes in the new and standard groups; for a genuine",
      "  equivalence claim these are usually close.",
      "- **Equivalence margin** - the largest absolute difference that",
      "  would still be considered practically equivalent (symmetric:",
      "  +/- this value).",
      "- **alpha** - the one-sided significance level.",
      "- **power** - the desired probability of concluding equivalence.",
      "- **ratio** - the new-group size divided by the standard-group size",
      "  (1 = equal allocation).",
      sep = "\n"
    ),
    worked_example = paste(
      "Bennett, Dismukes, Duma et al. (1979), as reproduced in Machin,",
      "Campbell, Tan & Tan (2009, p. 113): a trial of shorter combination",
      "chemotherapy vs. conventional therapy for cryptococcal meningitis,",
      "where a difference of less than 20 percentage points in response",
      "rate (both expected at 50%) would indicate equivalence. At a",
      "one-sided alpha of 0.10 and 80% power, this calculator returns n =",
      "83 per group (166 total) -- exactly the textbook's own printed",
      "answer.",
      sep = "\n"
    ),
    citation = paste(
      "Bennett JE, Dismukes WE, Duma RJ, et al. A comparison of",
      "amphotericin B alone and combined with flucytosine in the treatment",
      "of cryptococcal meningitis. N Engl J Med. 1979;301:126-131;",
      "Machin D, Campbell MJ, Tan SB, Tan SH. Sample Size Tables for",
      "Clinical Studies. 3rd ed. Wiley-Blackwell; 2009, p. 113.",
      "(as implemented by epiR::epi.ssequb)."
    ),
    backend = "epiR::epi.ssequb(type = \"equivalence\")"
  )
)
