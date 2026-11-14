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
      "crossover design instead -- see the \"Bioequivalence crossover\"",
      "design below, using the same backend package.",
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
    backend = "PowerTOST::sampleN.TOST(logscale = FALSE, design = \"parallel\") logic, transcribed (calc_closed_forms_tost.R; equal to the package over grids, which is a test oracle only)"
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
    backend = "closed form (Chow, Shao & Wang 2008); identical to epiR::epi.ssequb(type = \"equivalence\"), which it is tested against"
  ),

  bioequivalence = list(
    title = "Pharmacokinetic Bioequivalence Crossover (Log-Scale Ratio)",
    formula_latex = paste0(
      "$$H_0: \\theta \\notin (\\theta_1, \\theta_2) \\quad \\text{vs.} \\quad ",
      "H_1: \\theta_1 < \\theta < \\theta_2, \\quad \\theta = \\mu_T/\\mu_R$$",
      "$$n \\text{ solved iteratively so both one-sided tests reject at } \\alpha ",
      "\\text{ with the desired power (Owen's Q; Phillips 1990)}$$"
    ),
    explanation = paste(
      "The classic pharmacokinetic bioequivalence design: comparing a",
      "test and reference formulation's exposure (e.g. AUC or Cmax) via",
      "their *ratio* on a log scale, rather than a raw difference --",
      "PowerTOST's more common use case, with intra-subject variability",
      "expressed as a coefficient of variation (CV) from a crossover",
      "design instead of a between-subjects standard deviation.",
      "",
      "- **CV (intra-subject)** - the expected within-subject coefficient",
      "  of variation on the log scale (e.g. 0.3 for 30%).",
      "- **theta0** - the assumed true test/reference ratio (e.g. 0.95 =",
      "  test averages 95% of reference); must fall strictly within the",
      "  bioequivalence limits below.",
      "- **theta1, theta2** - the bioequivalence limits (regulatory",
      "  default 0.80-1.25, i.e. 80%-125%).",
      "- **alpha, power** - as elsewhere (alpha is one-sided, per TOST).",
      "- **Design** - \"2x2\" (classical 2x2x2 crossover, one measurement",
      "  of each formulation per subject); \"2x2x4\" (full replicate, each",
      "  formulation measured twice, needed for reference-scaled average",
      "  bioequivalence / RSABE and average bioequivalence with expanding",
      "  limits / ABEL approaches for highly variable drugs); \"2x3x3\"",
      "  (partial replicate, reference measured twice, test once).",
      "",
      "Replicate designs need substantially fewer subjects than the",
      "classical 2x2 crossover for the same CV and power, since each",
      "subject contributes more within-subject information.",
      sep = "\n"
    ),
    worked_example = paste(
      "PowerTOST's own documented example: CV = 30%, assumed ratio",
      "theta0 = 0.95, standard 80-125% limits, alpha = 0.05 (one-sided),",
      "80% power. For the classical 2x2 crossover, this calculator",
      "returns n = 40 (achieved power 0.8158), matching the package's",
      "own worked answer exactly. For the same CV and power, the 2x2x4",
      "full-replicate design needs only n = 20, and the 2x3x3",
      "partial-replicate design needs n = 30 -- illustrating how much a",
      "replicate design can reduce sample size for the same precision.",
      sep = "\n"
    ),
    citation = paste(
      "Phillips KF. Power of the two one-sided tests procedure in",
      "bioequivalence. J Pharmacokin Biopharm. 1990;18(2):137-144;",
      "Diletti D, Hauschke D, Steinijans VW. Sample size determination",
      "for bioequivalence assessment by means of confidence intervals.",
      "Int J Clin Pharmacol Ther Toxicol. 1991;29(1):1-8."
    ),
    backend = "PowerTOST::sampleN.TOST(logscale = TRUE, design = \"2x2\"/\"2x2x4\"/\"2x3x3\") logic, transcribed (calc_closed_forms_tost.R; equal to the package over grids)"
  ),

  assurance = list(
    title = "Bioequivalence Crossover, Expected Power (Assurance)",
    formula_latex = paste0(
      "$$\\text{Expected power} = E_{CV}\\!\\left[\\Pr(\\text{reject } H_0 \\mid CV)\\right], ",
      "\\quad CV \\text{ uncertain given a prior study of } m \\text{ subjects}$$"
    ),
    explanation = paste(
      "The \"Pharmacokinetic Bioequivalence Crossover\" design above treats",
      "the assumed CV as known/fixed -- but in practice it is only an",
      "ESTIMATE from a smaller prior or pilot study, so the usual power",
      "calculation is conditional on that estimate happening to be exactly",
      "right. This design instead computes the sample size needed for the",
      "EXPECTED power (also called \"assurance\" or the \"probability of",
      "trial success\"), averaging over the sampling uncertainty in the CV",
      "estimate itself, given how many subjects it was based on.",
      "",
      "- **CV (intra-subject)** - the point estimate of the intra-subject",
      "  coefficient of variation from the prior/pilot study.",
      "- **Prior study size (m)** - how many subjects that prior study",
      "  had; a CV estimated from a small pilot is itself quite uncertain,",
      "  so smaller m inflates the required sample size more.",
      "- **theta0, theta1, theta2, alpha, power, Design** - as in the",
      "  fixed-CV bioequivalence design above (power here is the desired",
      "  EXPECTED power).",
      "",
      "Because assurance is bounded above by the \"probability of technical",
      "success\" (which can be well below 1 when the prior study was very",
      "small), this design will always need at least as many subjects as",
      "the fixed-CV design above for the same target power -- and can fail",
      "to find a feasible n at all if the prior study was too small to",
      "pin down the CV with any confidence.",
      sep = "\n"
    ),
    worked_example = paste(
      "PowerTOST's own documented example: CV = 30% estimated from a",
      "prior 2x2 crossover study with m = 30 subjects, default 80-125%",
      "limits, theta0 = 0.95, alpha = 0.05 (one-sided), 80% target expected",
      "power. This calculator returns n = 42, with an achieved expected",
      "power of 0.8063 -- matching the package's own worked answer",
      "exactly. Compare this to the fixed-CV design above with the",
      "identical CV/theta0/limits, which needs only n = 40 (achieved power",
      "0.8158): accounting for the CV's own sampling uncertainty costs 2",
      "extra subjects here.",
      sep = "\n"
    ),
    citation = paste(
      "Julious SA, Owen RJ. Sample size calculations for clinical studies",
      "allowing for uncertainty in variance. Pharm Stat. 2006;5:29-37;",
      "O'Hagan A, Stevens JW, Campbell MJ. Assurance in clinical trial",
      "design. Pharm Stat. 2005;4:187-201; Grieve AP. Confidence",
      "intervals and sample sizes. Biometrics. 1991;47:1597-1603."
    ),
    backend = "PowerTOST::expsampleN.TOST(prior.type = \"CV\") logic, transcribed (calc_closed_forms_tost.R; equal to the package over grids)"
  )
)
