# Metadata for the Diagnostic Accuracy module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_diagnostic.R (SDD 4.2: "content is data, not hardcoded
# UI").
#
# All four designs, and every worked example below, follow Akoglu H. User's
# guide to sample size estimation in diagnostic accuracy studies. Turk J
# Emerg Med. 2022;22(4):177-185 (Table 2, Equations 1-5) -- the article this
# module was built from. Each worked example was independently recomputed
# from the formulas rather than copied, so a figure may differ by +/-1 from
# the article's own precomputed tables due to intermediate rounding there;
# where that happens it's noted explicitly.

diagnostic_content <- list(
  precision = list(
    title = "Sensitivity & Specificity -- Precision-Based (No Reference Value)",
    formula_latex = paste0(
      "$$n_{Sn} = \\frac{Z_{1-\\alpha/2}^2 \\, Sn(1-Sn)}{W_{Sn}^2 \\times P}$$",
      "$$n_{Sp} = \\frac{Z_{1-\\alpha/2}^2 \\, Sp(1-Sp)}{W_{Sp}^2 \\times (1-P)}$$",
      "$$N = \\max(n_{Sn},\\, n_{Sp})$$"
    ),
    explanation = paste(
      "Estimating a diagnostic test's sensitivity and specificity is",
      "different from a typical one- or two-sample study: only subjects",
      "who truly *have* the target condition contribute information to the",
      "sensitivity estimate, and only subjects who truly *do not* contribute",
      "to the specificity estimate. That means the prevalence of the",
      "condition in the sampled population determines how many *total*",
      "subjects are needed to get enough of each group -- ignoring",
      "prevalence and sizing the study as if it were a single proportion",
      "will under-power one of the two estimates.",
      "",
      "- **Sn** - the expected sensitivity of the test.",
      "- **Sp** - the expected specificity of the test.",
      "- **P** - the expected prevalence of the target condition in the",
      "  population you will sample from.",
      "- **W_Sn, W_Sp** - the desired precision (confidence interval",
      "  half-width) for sensitivity and specificity respectively, e.g.",
      "  0.05 for a result reported as \"sensitivity +/- 5 percentage",
      "  points\". These can be set equal, or looser/tighter for whichever",
      "  metric matters more to your study.",
      "- **Confidence level** - typically 0.95 (95%), giving Z = 1.96.",
      "",
      "n_Sn and n_Sp are each the *total* sample size (not just the",
      "diseased or healthy subgroup) needed to hit that metric's precision",
      "target at the given prevalence -- this design (Akoglu 2022's",
      "Equation 1, following Buderer 1996's insight of incorporating",
      "prevalence) folds prevalence into the denominator so both formulas",
      "already return a total N. Since a single study draws one sample",
      "serving both estimates, take N = the larger of the two.",
      "",
      "No hypothesis is being tested here (no reference value, no power",
      "target) -- if you instead want to test whether your test's Se/Sp",
      "differs from a known/reference value, use the *vs. known/reference",
      "value* design below.",
      "",
      "**Common pitfall:** low prevalence dramatically inflates the",
      "required total sample size for sensitivity (few diseased subjects",
      "per enrollee), and high prevalence does the same for specificity",
      "(few healthy subjects per enrollee) -- always compute both n_Sn and",
      "n_Sp and report the total needed for whichever binds, rather than",
      "sizing the study on sensitivity or specificity alone.",
      sep = "\n"
    ),
    worked_example = paste(
      "Akoglu (2022)'s own example: a new screening test is expected to",
      "have 90% sensitivity (Sn = 0.90) in a cohort with a known disease",
      "prevalence of 10% (P = 0.10). At 95% confidence (Z = 1.96) and a",
      "desired precision of +/-5 percentage points (W_Sn = 0.05), this",
      "calculator returns n_Sn = 1383, of which ~138 (10%) are expected to",
      "be diseased and ~1245 (90%) non-diseased.",
      sep = "\n"
    ),
    citation = paste(
      "Buderer NM. Statistical methodology: I. Incorporating the",
      "prevalence of disease into the sample size calculation for",
      "sensitivity and specificity. Acad Emerg Med. 1996;3(9):895-900.",
      "(original method, as Equation 1 + prevalence adjustment);",
      "Obuchowski NA. Sample size calculations in studies of test",
      "accuracy. Stat Methods Med Res. 1998;7(4):371-92. (summarized this",
      "and related formulas); Akoglu H. User's guide to sample size",
      "estimation in diagnostic accuracy studies. Turk J Emerg Med.",
      "2022;22(4):177-185. (Table 2, Equation 1 + 4a/4b; worked practical",
      "guide to this and related diagnostic-accuracy sample size methods)."
    ),
    backend = "Closed-form (Buderer's method); no external package required"
  ),

  vs_reference = list(
    title = "Sensitivity & Specificity vs. a Known/Reference Value",
    formula_latex = paste0(
      "$$n_{unadj} = \\frac{\\left[Z_\\alpha\\sqrt{P_0(1-P_0)} + Z_\\beta\\sqrt{P_1(1-P_1)}\\right]^2}{(P_1-P_0)^2}$$",
      "$$n_{Yates} = \\frac{n_{unadj}}{4}\\left(1+\\sqrt{1+\\frac{4}{n_{unadj}|P_1-P_0|}}\\right)^2$$",
      "$$n_{Sn} = \\frac{n_{Yates,Sn}}{P}, \\quad n_{Sp} = \\frac{n_{Yates,Sp}}{1-P}, \\quad N=\\max(n_{Sn}, n_{Sp})$$"
    ),
    explanation = paste(
      "This design tests whether a new (index) test's sensitivity and",
      "specificity are *statistically significantly different* from",
      "pre-specified reference/null values -- e.g. those of an existing",
      "test, or a minimum acceptable performance level -- rather than just",
      "estimating them to a precision target. Because it's a hypothesis",
      "test, it needs a power target, and Yates' continuity correction is",
      "applied (as it is to every proportion-comparison design in this",
      "module).",
      "",
      "- **Sn0/Sp0** - the reference/null sensitivity and specificity",
      "  you're testing against.",
      "- **Sn1/Sp1** - the sensitivity and specificity you expect the new",
      "  test to actually have.",
      "- **P** - the expected prevalence of the target condition.",
      "- **alpha, power** - as elsewhere; both sensitivity and specificity",
      "  are each sized for the same power target, computed independently",
      "  in their own subgroup (diseased for Sn, non-diseased for Sp).",
      "",
      "As with the precision-based design, N is the larger of the",
      "sensitivity- and specificity-implied totals.",
      sep = "\n"
    ),
    worked_example = paste(
      "Akoglu (2022)'s own example: for the diagnosis of acute",
      "appendicitis (prevalence 40%), contrast-enhanced CT is expected to",
      "have 95% sensitivity (Sn1) vs. 90% for non-contrast CT (Sn0), and",
      "85% specificity (Sp1) vs. 80% (Sp0). At alpha = 0.05, power = 90%,",
      "this calculator returns n_Sn ~ 850 and n_Sp ~ 1094, so N ~ 1094",
      "(specificity binds) -- consistent with the article's own",
      "pre-rounded table figures of 849 and 1093 respectively (the +/-1",
      "difference is from intermediate rounding in that table).",
      sep = "\n"
    ),
    citation = paste(
      "Akoglu H. User's guide to sample size estimation in diagnostic",
      "accuracy studies. Turk J Emerg Med. 2022;22(4):177-185. (Table 2,",
      "Equation 2 + 4a/4b, per Obuchowski NA, Stat Methods Med Res.",
      "1998;7(4):371-92); Yates' continuity correction per Beam CA.",
      "Strategies for improving power in diagnostic radiology research.",
      "AJR Am J Roentgenol. 1992;159:631-7."
    ),
    backend = "Closed-form (Akoglu 2022, Eq. 2 + Yates' correction); no external package required"
  ),

  two_indep = list(
    title = "Two Independent (Unpaired) Diagnostic Tests",
    formula_latex = paste0(
      "$$n_{unadj} = \\frac{\\left[Z_\\alpha\\sqrt{2\\bar P(1-\\bar P)} + Z_\\beta\\sqrt{P_1(1-P_1)+P_2(1-P_2)}\\right]^2}{(P_1-P_2)^2}$$",
      "$$n_{\\text{per group}} = \\frac{n_{unadj}}{4}\\left(1+\\sqrt{1+\\frac{4}{n_{unadj}|P_1-P_2|}}\\right)^2$$"
    ),
    explanation = paste(
      "Use this design to compare the *same* metric (sensitivity, or",
      "specificity) between two different diagnostic tests applied to two",
      "independent (unpaired/between-subjects) groups of subjects --",
      "e.g. two alternative diagnostic pathways, each tried on a",
      "different set of patients, per Casagrande & Pike's two-proportion",
      "formula with Yates' continuity correction.",
      "",
      "- **P1, P2** - the expected value of the metric (both sensitivity,",
      "  or both specificity -- not mixed) for test 1 and test 2.",
      "- **alpha, power** - as elsewhere. A one-sided alternative",
      "  (\"less\"/\"greater\") matches a directional hypothesis like \"the",
      "  new test's sensitivity is higher\"; both one-sided choices use the",
      "  same critical value here (only the two-sided/one-sided split",
      "  changes the arithmetic, not which side you name).",
      "",
      "This returns the number of subjects needed *in that subgroup*",
      "(diseased, if comparing sensitivity; non-diseased, if comparing",
      "specificity) per test arm. If your two arms are drawn from a mixed",
      "population rather than a pre-selected diseased/non-diseased group,",
      "gross this up by prevalence or (1-prevalence) yourself, the same",
      "way the single-test designs above do it.",
      sep = "\n"
    ),
    worked_example = paste(
      "Akoglu (2022)'s own example: comparing sensitivity between two",
      "diagnostic pathways, where a contender test has 70% sensitivity",
      "(P2) and the new pathway is hypothesized to reach at least 80%",
      "(P1 -- a 10 percentage-point difference). At a one-sided alpha of",
      "0.05 and power of 80%, this calculator returns n = 251 per",
      "pathway (502 total) -- consistent with the article's own",
      "pre-rounded figure of 250 per pathway (500 total).",
      sep = "\n"
    ),
    citation = paste(
      "Casagrande JT, Pike MC. An improved approximate formula for",
      "calculating sample sizes for comparing two binomial distributions.",
      "Biometrics. 1978;34(3):483-6; Beam CA. Strategies for improving",
      "power in diagnostic radiology research. AJR Am J Roentgenol.",
      "1992;159:631-7. (application to diagnostic accuracy, with Yates'",
      "correction); Akoglu H. User's guide to sample size estimation in",
      "diagnostic accuracy studies. Turk J Emerg Med. 2022;22(4):177-185.",
      "(Table 2, Equation 3a)."
    ),
    backend = "Closed-form (Casagrande-Pike + Yates' correction); no external package required"
  ),

  two_paired = list(
    title = "Two Paired Diagnostic Tests (Same Subjects)",
    formula_latex = paste0(
      "$$\\Psi_{min} = |P_1-P_2|, \\quad \\Psi_{max} = P_1(1-P_2)+P_2(1-P_1)$$",
      "$$n_{unadj}(\\Psi) = \\frac{\\left[Z_\\alpha\\sqrt{\\Psi} + Z_\\beta\\sqrt{\\Psi-(P_1-P_2)^2}\\right]^2}{(P_1-P_2)^2}$$",
      "$$n(\\Psi) = \\frac{n_{unadj}(\\Psi)}{4}\\left(1+\\sqrt{1+\\frac{4}{n_{unadj}(\\Psi)|P_1-P_2|}}\\right)^2$$"
    ),
    explanation = paste(
      "Use this design to compare the *same* metric (sensitivity, or",
      "specificity) between two different diagnostic tests applied to the",
      "*same* subjects (within-subjects/paired design) -- e.g. every",
      "patient gets both index tests plus the reference standard. This",
      "follows Connor (1987)'s McNemar-test-based method, with Yates'",
      "continuity correction.",
      "",
      "- **P1, P2** - the expected value of the metric (both sensitivity,",
      "  or both specificity) for test 1 and test 2.",
      "- **alpha, power** - as elsewhere.",
      "",
      "Unlike the other designs, this one doesn't return a single number:",
      "how often the two tests *disagree* with each other (the",
      "probability of disagreement, Psi) matters, and isn't fully",
      "determined by P1 and P2 alone. So the calculator reports a range:",
      "**Psi_min = |P1-P2|** (tests disagree by only the minimum amount",
      "consistent with P1/P2 -- the smallest, most optimistic sample",
      "size) and **Psi_max = P1(1-P2) + P2(1-P1)** (tests agree with each",
      "other purely by chance -- the largest, most conservative sample",
      "size). Pick a value in between based on how correlated you expect",
      "the two tests' results to be; when in doubt, the upper bound is",
      "the safe choice. Note that even at the most conservative end, a",
      "paired design typically needs far fewer subjects than the",
      "equivalent unpaired comparison.",
      sep = "\n"
    ),
    worked_example = paste(
      "Same scenario as the unpaired example, but now both diagnostic",
      "pathways are tried on every patient (P1 = 0.80, P2 = 0.70), at a",
      "one-sided alpha of 0.05 and power of 80%. This calculator returns",
      "a range of n = 79 (Psi_min) to n = 253 (Psi_max) -- consistent",
      "with the article's own pre-rounded range of 78 to 252. Even the",
      "conservative end (252-253) is roughly half the 500-502 subjects",
      "the unpaired version of this same comparison needed.",
      sep = "\n"
    ),
    citation = paste(
      "Connor RJ. Sample size for testing differences in proportions for",
      "the paired-sample design. Biometrics. 1987;43(1):207-11; Beam CA.",
      "Strategies for improving power in diagnostic radiology research.",
      "AJR Am J Roentgenol. 1992;159:631-7. (application to diagnostic",
      "accuracy, with Yates' correction); Akoglu H. User's guide to",
      "sample size estimation in diagnostic accuracy studies. Turk J",
      "Emerg Med. 2022;22(4):177-185. (Table 2, Equation 3b)."
    ),
    backend = "Closed-form (Connor's method + Yates' correction); no external package required"
  ),

  ppv_npv = list(
    title = "Predictive Values (PPV/NPV), Precision-Based",
    formula_latex = paste0(
      "$$PPV = \\frac{Sn \\times P}{Sn \\times P + (1-Sp)(1-P)}, \\quad ",
      "NPV = \\frac{Sp(1-P)}{(1-Sn)P + Sp(1-P)}$$",
      "$$n_{PPV} = \\frac{Z_{1-\\alpha/2}^2 \\, PPV(1-PPV)}{W_{PPV}^2 \\times P(\\text{test+})}, \\quad ",
      "n_{NPV} = \\frac{Z_{1-\\alpha/2}^2 \\, NPV(1-NPV)}{W_{NPV}^2 \\times P(\\text{test-})}$$"
    ),
    explanation = paste(
      "PPV (the probability a positive test result is a true positive) and",
      "NPV (the probability a negative result is a true negative) are",
      "themselves just proportions -- computed from sensitivity,",
      "specificity, and prevalence per Altman & Bland (1994) -- so their",
      "own precision-based sample size follows the same",
      "Z^2\\*p(1-p)/W^2 formula as any proportion. This calculator extends",
      "Buderer's prevalence-adjustment insight (already used by the",
      "sensitivity/specificity design above) to PPV and NPV: only subjects",
      "who *test positive* inform the PPV estimate, and only subjects who",
      "*test negative* inform the NPV estimate, so the total number needed",
      "to screen is the per-outcome count divided by the probability of",
      "that test outcome (not by disease prevalence directly).",
      "",
      "- **Sn, Sp, P** - same as the precision-based Se/Sp design above.",
      "- **W_PPV, W_NPV** - desired precision (CI half-width) for PPV and",
      "  NPV respectively.",
      "- **Confidence level** - typically 0.95.",
      "",
      "Take N = the larger of the two implied totals, same logic as the",
      "sensitivity/specificity design. Note PPV and NPV both depend",
      "heavily on prevalence (unlike Se/Sp themselves) -- a test with",
      "excellent Se/Sp can still have a low PPV in a low-prevalence",
      "population, which is exactly why this calculator asks for a",
      "separate precision target for each.",
      sep = "\n"
    ),
    worked_example = paste(
      "Worked from raw values: a test with 90% sensitivity and 85%",
      "specificity used in a population with 20% prevalence has PPV = 0.60",
      "and NPV = 0.9714. Wanting +/-5 percentage points of precision on",
      "both (95% confidence), this calculator returns n_PPV = 1230",
      "(binding) and n_NPV = 61 -- so N = 1230 subjects need to be",
      "screened, of whom about 30% (369) are expected to test positive.",
      sep = "\n"
    ),
    citation = paste(
      "Altman DG, Bland JM. Diagnostic tests 2: predictive values. BMJ.",
      "1994;309(6947):102. (PPV/NPV formulas from Se/Sp/prevalence);",
      "Buderer NM. Statistical methodology: I. Incorporating the",
      "prevalence of disease into the sample size calculation for",
      "sensitivity and specificity. Acad Emerg Med. 1996;3(9):895-900.",
      "(prevalence-adjustment logic, extended here to PPV/NPV)."
    ),
    backend = "Closed-form (Buderer-style prevalence adjustment applied to Altman & Bland's PPV/NPV formulas); no external package required"
  ),

  likelihood_ratio = list(
    title = "Likelihood Ratios (LR+/LR-), Precision-Based",
    formula_latex = paste0(
      "$$LR^+ = \\frac{Sn}{1-Sp}, \\quad LR^- = \\frac{1-Sn}{Sp}$$",
      "$$n \\text{ solved so the CI for the chosen LR has the desired width (Simel et al. 1991, Eq. 10)}$$"
    ),
    explanation = paste(
      "Likelihood ratios express how much a test result shifts the odds",
      "of disease -- LR+ for a positive result, LR- for a negative one --",
      "and, unlike predictive values, don't depend on prevalence (though",
      "the sample *size* to estimate them still does, since prevalence",
      "determines how many diseased vs. non-diseased subjects you'll",
      "enroll).",
      "",
      "- **Sn, Sp** - expected sensitivity and specificity.",
      "- **Prevalence** - expected prevalence of the target condition in",
      "  the population you will sample from.",
      "- **LR type** - positive (LR+, for interpreting a positive result)",
      "  or negative (LR-, for interpreting a negative result).",
      "- **Desired CI width** - the full width of the confidence interval",
      "  for the chosen LR -- note this is on the ratio scale (LRs are",
      "  analysed on the log scale internally but reported on the",
      "  original scale, so the interval is asymmetric around the point",
      "  estimate).",
      "",
      "This calculator returns the *total* sample size and its 1:1",
      "diseased/non-diseased split (implied by the prevalence and the",
      "chosen allocation) -- same precision-based logic as the other",
      "Diagnostic Accuracy designs.",
      sep = "\n"
    ),
    worked_example = paste(
      "Simel, Samsa & Matchar (1991), Problem 1: a new test has 80%",
      "sensitivity and 73% specificity (LR+ = 2.96), sampled with as many",
      "diseased as non-diseased subjects (prevalence = 0.5). Wanting a",
      "95% CI width of 2.2 for LR+, this calculator returns n = 173 (87",
      "diseased, 87 non-diseased) -- matching the article's own worked",
      "solution (~172-173) for this problem.",
      "",
      "Problem 2 (LR-): sensitivity 90%, specificity 50% (LR- = 0.2),",
      "prevalence 0.5. This calculator's own forward check (given n =",
      "160) reproduces a CI width of ~0.30, and n = 160 is exactly the",
      "article's own answer for this problem.",
      sep = "\n"
    ),
    citation = paste(
      "Simel DL, Samsa GP, Matchar DB. Likelihood ratios with confidence:",
      "Sample size estimation for diagnostic test studies. J Clin",
      "Epidemiol. 1991;44(8):763-770."
    ),
    backend = "closed form (equal to presize::prec_lr(); presize::prec_pos_lr() / prec_neg_lr() ignore the confidence level, here it is used)"
  ),

  odds_ratio = list(
    title = "Diagnostic Odds Ratio (DOR)",
    formula_latex = paste0(
      "$$DOR = \\frac{Sn/(1-Sn)}{(1-Sp)/Sp}$$",
      "$$n_{\\text{per group}} \\text{ solved as for two independent proportions, } ",
      "P_1=Sn, \\, P_2=1-Sp \\text{ (Casagrande-Pike + Yates' correction)}$$"
    ),
    explanation = paste(
      "The diagnostic odds ratio summarizes overall test discrimination",
      "in a single number: the odds of a positive result in diseased",
      "subjects, relative to the odds of a positive result in",
      "non-diseased subjects. A DOR of 1 means the test result carries no",
      "information about disease status; larger DORs mean better",
      "discrimination.",
      "",
      "- **Sn, Sp** - expected sensitivity and specificity.",
      "- **alpha, power, Alternative hypothesis** - as elsewhere.",
      "",
      "Testing whether the DOR differs from 1 (no discrimination) given",
      "an assumed sensitivity and specificity is mathematically identical",
      "to comparing the test-positive rate between two independent",
      "groups -- diseased subjects (P1 = Sn) and non-diseased subjects",
      "(P2 = 1-Sp) -- exactly the same comparison as the \"Two independent",
      "diagnostic tests\" design above, just applied to one test across",
      "the two disease-status groups instead of two tests within one",
      "group. This calculator reuses that same formula directly (no new",
      "math, no new verification risk), the same way the Exact Tests",
      "module's sign test reuses the binomial test.",
      sep = "\n"
    ),
    worked_example = paste(
      "A test with 80% sensitivity and 70% specificity has",
      "DOR = (0.8/0.2) / (0.3/0.7) = 9.33. Comparing the resulting",
      "test-positive rates (80% in diseased subjects vs. 30% in",
      "non-diseased subjects) at alpha = 0.05 (two-sided) and 80% power,",
      "this calculator returns n = 19 per group (38 total) -- inheriting",
      "the already-verified Two Independent Diagnostic Tests calculation",
      "above exactly, just relabeled.",
      sep = "\n"
    ),
    citation = paste(
      "Glas AS, Lijmer JG, Prins MH, Bonsel GJ, Bossuyt PM. The",
      "diagnostic odds ratio: a single indicator of test performance.",
      "J Clin Epidemiol. 2003;56(11):1129-1135. Sample size formula:",
      "Casagrande JT, Pike MC. Biometrics. 1978;34(3):483-6; Beam CA.",
      "AJR Am J Roentgenol. 1992;159:631-7 (Yates' correction)."
    ),
    backend = "Closed-form (reuses calc_diagnostic_two_indep(): Casagrande-Pike + Yates' correction)"
  )
)
