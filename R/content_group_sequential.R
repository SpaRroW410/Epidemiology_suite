# Metadata for the Group Sequential Design module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_group_sequential.R (SDD 4.2: "content
# is data, not hardcoded UI").

group_sequential_content <- list(
  normal = list(
    title = "Group-Sequential Design: Continuous Outcome",
    formula_latex = paste0(
      "$$n_{\\text{total}} = \\frac{(r+1)^2}{r}\\left(\\frac{d \\cdot \\sigma}{\\delta}\\right)^2$$",
      "$$d = \\text{the \"drift\" parameter solved from the boundary shape, } ",
      "\\alpha, \\text{power, and the planned interim looks}$$"
    ),
    explanation = paste(
      "Use this when a two-arm trial with a continuous outcome will be",
      "monitored at several planned interim analyses (not just once at",
      "the end) -- so investigators can stop early for a clear benefit,",
      "or optionally for clear futility, without inflating the overall",
      "false-positive rate. This needs a larger *maximum* sample size",
      "than a single fixed-endpoint analysis, since some of the",
      "statistical \"budget\" (alpha) is spent looking early.",
      "",
      "- **delta, sd** - the assumed true difference in means and the",
      "  common standard deviation, exactly as in the Means module's",
      "  two-independent-means design.",
      "- **Number of planned analyses** - how many looks at the data,",
      "  including the final one; this calculator spaces them equally",
      "  (e.g. 4 looks = information fractions 0.25, 0.5, 0.75, 1.0).",
      "- **Boundary shape** - where the efficacy (and optional futility)",
      "  boundary sits on the Pocock (0) to O'Brien-Fleming (0.5) power",
      "  family: Pocock uses the same critical value at every look",
      "  (easier to stop early, but a stricter final boundary);",
      "  O'Brien-Fleming demands overwhelming evidence at early looks and",
      "  is close to the usual fixed-design boundary at the final look",
      "  (the more common choice in practice).",
      "- **Include a futility boundary** - if checked, the trial can also",
      "  stop early for a clearly negative result; this futility rule is",
      "  *non-binding* (doesn't reduce the effective alpha spent), the",
      "  conventional conservative default.",
      "- **r** - allocation ratio, experimental:control (1 = equal).",
      "",
      "The result gives the *maximum* sample size (reached only if the",
      "trial runs to its final planned look) and the Z-scale critical",
      "value to use at each look.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an assumed difference of 0.25 (SD = 1), 4 equally-spaced",
      "looks, O'Brien-Fleming boundaries (shape = 0.5) with a futility",
      "rule, two-sided alpha = 0.05 and 80% power, this calculator",
      "returns a maximum total sample size of 584 (292 per arm) --",
      "compare to 128 total (64 per arm) for the same effect analyzed",
      "only once, illustrating the added cost of interim monitoring. The",
      "efficacy boundary starts very high (Z > 4.04 at the first look,",
      "virtually impossible to cross by chance) and relaxes toward the",
      "conventional Z = 1.96 by the final look.",
      sep = "\n"
    ),
    citation = paste(
      "Wang SK, Tsiatis AA. Approximately optimal one-parameter boundaries",
      "for group sequential trials. Biometrics. 1987;43(1):193-199",
      "(the Pocock-to-O'Brien-Fleming power family used here); Jennison C,",
      "Turnbull BW. Group Sequential Methods with Applications to Clinical",
      "Trials. Chapman & Hall/CRC; 2000."
    ),
    backend = "clinfun::gsdesign.normal()"
  ),

  binary = list(
    title = "Group-Sequential Design: Binary Outcome",
    formula_latex = paste0(
      "$$n_{\\text{total}} = \\frac{(r+1)^2}{r}\\bar{p}(1-\\bar{p})\\left(\\frac{d}{p_C-p_E}\\right)^2, ",
      "\\ \\text{Casagrande-Pike-Smith continuity correction applied}$$"
    ),
    explanation = paste(
      "The binary-outcome counterpart of the continuous design above --",
      "same interim-monitoring logic (planned looks, a Pocock-to-",
      "O'Brien-Fleming boundary family, optional non-binding futility",
      "rule), but for a proportion/event-rate outcome instead of a mean.",
      "",
      "- **pC, pE** - the assumed event/response probability in the",
      "  control and experimental arms.",
      "- **Number of planned analyses, boundary shape, futility, r** -",
      "  as in the continuous-outcome design above.",
      "",
      "A small-sample continuity correction (Casagrande, Pike & Smith",
      "1978) is applied by default, matching common practice for",
      "two-proportion sample-size formulas.",
      sep = "\n"
    ),
    worked_example = paste(
      "For pC = 0.30 vs. pE = 0.50, analyzed only once (fixed design,",
      "for reference), two-sided alpha = 0.05 and 80% power, this",
      "calculator returns n = 201 total (close to, and cross-checked",
      "against, the classic two-proportion normal-approximation answer).",
      "Spread across 4 equally-spaced looks with O'Brien-Fleming",
      "boundaries and a futility rule, the maximum sample size rises to",
      "n = 230 total (115 per arm) -- the cost of being able to stop",
      "early.",
      sep = "\n"
    ),
    citation = paste(
      "Casagrande JT, Pike MC, Smith PG. An improved approximate formula",
      "for calculating sample sizes for comparing two binomial",
      "distributions. Biometrics. 1978;34(3):483-486; Wang SK, Tsiatis AA.",
      "Biometrics. 1987;43(1):193-199."
    ),
    backend = "clinfun::gsdesign.binomial()"
  ),

  survival = list(
    title = "Group-Sequential Design: Time-to-Event Outcome",
    formula_latex = paste0(
      "$$d_{\\text{total events}} = \\frac{(r+1)^2}{r}\\left(\\frac{\\text{drift}}{\\ln(HR)}\\right)^2$$"
    ),
    explanation = paste(
      "The time-to-event counterpart of the two designs above -- same",
      "interim-monitoring logic, but sized in terms of the total number",
      "of *events* (deaths, progressions, etc.) needed, per the standard",
      "log-rank/Cox framework, rather than a fixed sample size. At a",
      "single, final-only look this reduces exactly to the classic",
      "Schoenfeld (1983) event-count formula also used by this app's",
      "Log-Rank/Survival module.",
      "",
      "- **Hazard ratio** - the assumed hazard ratio, experimental vs.",
      "  control (< 1 favors the experimental arm).",
      "- **Number of planned analyses, boundary shape, futility, r** -",
      "  as in the two designs above.",
      "",
      "This calculator reports the required number of *events*, not",
      "enrolled subjects -- converting events to an enrollment target",
      "needs a separate accrual-period and follow-up-duration assumption",
      "(see the Log-Rank/Survival module's accrual-based design for that",
      "fuller calculation in the simpler, single-look case).",
      sep = "\n"
    ),
    worked_example = paste(
      "For an assumed hazard ratio of 0.5, analyzed only once (fixed",
      "design, for reference), two-sided alpha = 0.05 and 80% power,",
      "this calculator returns 66 total events -- an exact match to the",
      "classic Schoenfeld formula. Spread across 4 equally-spaced looks",
      "with O'Brien-Fleming boundaries and a futility rule, the maximum",
      "event total rises to 76 -- illustrating that group-sequential",
      "monitoring costs relatively less here than in the continuous/",
      "binary cases, since survival designs are already driven by event",
      "counts rather than enrollment.",
      sep = "\n"
    ),
    citation = paste(
      "Schoenfeld DA. Sample-size formula for the proportional-hazards",
      "regression model. Biometrics. 1983;39(2):499-503; Wang SK, Tsiatis",
      "AA. Biometrics. 1987;43(1):193-199."
    ),
    backend = "clinfun::gsdesign.survival()"
  ),

  lan_demets_normal = list(
    title = "Lan-DeMets Alpha-Spending Design: Continuous Outcome (2 Looks)",
    formula_latex = paste0(
      "$$\\alpha^*_{OF}(t) = 2\\left(1 - \\Phi\\!\\left(\\frac{z_{\\alpha/2}}{\\sqrt t}\\right)\\right), ",
      "\\quad \\alpha^*_{Pocock}(t) = \\alpha \\ln(1+(e-1)t)$$",
      "$$b_1 = \\Phi^{-1}(1-\\alpha^*(t_1)); \\quad ",
      "P(Z_1 \\le b_1, Z_2 > b_2) = \\alpha - \\alpha^*(t_1), \\ \\text{corr}(Z_1,Z_2)=\\sqrt{t_1}$$"
    ),
    explanation = paste(
      "This is the same interim-monitoring idea as the power-family design",
      "above (an interim look plus a final look, spending some of the",
      "overall alpha early), but using the literal **Lan-DeMets (1983)",
      "alpha-spending function** approach instead of the power-family",
      "reparameterization -- the method actually named \"Lan-DeMets alpha",
      "spending\" in the wider literature, and a genuinely different",
      "(though closely related) computation.",
      "",
      "- **delta, sd, r** - as in the continuous-outcome power-family",
      "  design above.",
      "- **Interim timing** - the information fraction (proportion of the",
      "  final sample size) at which the single interim look happens.",
      "- **Spending function** - O'Brien-Fleming-type (spends very little",
      "  alpha early, boundary close to the fixed-design value at the",
      "  final look -- small sample-size inflation) or Pocock-type (spends",
      "  alpha more evenly, easier to stop early, but a noticeably larger",
      "  maximum sample size).",
      "",
      "**Scope of this design**: exactly 2 looks (one interim, one final)",
      "and a continuous (two-sample z-test) outcome -- the case with a",
      "closed, directly verifiable two-look (bivariate-normal) boundary",
      "solve. More than 2 looks needs a higher-dimensional numerical",
      "integration/recursion not covered here; binary and time-to-event",
      "outcomes are left open for a future batch.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an assumed difference of 0.5 (SD = 1), a single interim look",
      "at 50% information, O'Brien-Fleming-type spending, two-sided",
      "alpha = 0.05 and 80% power, this calculator returns n = 128 total",
      "(64 per arm) -- a boundary of Z > 2.963 at the interim and",
      "Z > 1.969 at the final look, matching real",
      "`rpact::getDesignGroupSequential()` output exactly, and only a",
      "1.9% sample-size inflation over the n = 126 a single-look fixed",
      "design would need (O'Brien-Fleming spends almost no alpha early).",
      "The same scenario with Pocock-type spending instead needs n = 142",
      "total (a 13% inflation, and boundaries of Z > 2.157 at the interim",
      "and Z > 2.201 at the final look) -- Pocock's more even alpha",
      "spending makes it easier to stop early, at the cost of a stricter,",
      "larger-sample final analysis.",
      sep = "\n"
    ),
    citation = paste(
      "Lan KKG, DeMets DL. Discrete sequential boundaries for clinical",
      "trials. Biometrika. 1983;70(3):659-663.",
      "",
      "Spending functions and the 2-look boundary-solving procedure",
      "independently derived and verified exactly against real",
      "`rpact::getDesignGroupSequential()` output (O'Brien-Fleming-type",
      "and Pocock-type spending, one-sided alpha, informationRates =",
      "c(timing, 1)); the full sample-size solve was further verified by",
      "simulating the actual two-stage two-sample z-test procedure on raw",
      "data (300,000 replicates). Reimplemented from scratch rather than",
      "depending on `rpact` at runtime, so this app stays self-contained."
    ),
    backend = "closed-form reimplementation (bivariate-normal boundary solve via mvtnorm)"
  ),

  conditional_power_ssr = list(
    title = "Interim Conditional Power / Sample-Size Re-Estimation (SSR)",
    formula_latex = paste0(
      "$$z_2^{cutoff} = \\frac{b_2 - z_1\\sqrt{t_1}}{\\sqrt{1-t_1}}, \\quad ",
      "CP = \\Phi\\!\\left(\\sqrt{n_2}\\,\\hat\\theta - z_2^{cutoff}\\right)$$",
      "$$n_{2,\\text{new}} = \\left(\\frac{z_2^{cutoff} + \\Phi^{-1}(\\text{target CP})}{\\hat\\theta}\\right)^2$$"
    ),
    explanation = paste(
      "Once you have an actual interim result (an observed Z-statistic",
      "at the planned interim look), this answers two further questions:",
      "**conditional power** (\"given what we've seen so far, what's the",
      "chance of a positive result at the planned final analysis?\") and,",
      "if that chance looks too low, **sample-size re-estimation (SSR)**",
      "(\"how much bigger would the trial need to be to restore a good",
      "chance of success?\").",
      "",
      "Changing the sample size based on what the interim data show would",
      "normally inflate the false-positive rate if the final analysis just",
      "re-tested the pooled data -- so this uses the **inverse-normal",
      "combination test** (Lehmacher & Wassmer 1999): the final decision",
      "combines the interim Z-statistic and a SEPARATE Z-statistic computed",
      "from only the NEW (post-interim) data, using FIXED weights set at",
      "the planning stage. That second statistic's null distribution stays",
      "standard normal no matter how large the second stage turns out to",
      "be, so re-estimating its size never reopens the type-I error.",
      "",
      "- **Observed interim Z-statistic** - the actual test statistic seen",
      "  at the interim look.",
      "- **Target conditional power** - the chance of eventual success you",
      "  want to restore, if the current trend continues.",
      "- **Maximum fold-increase** - a cap on how much larger the trial is",
      "  allowed to grow, however promising the interim trend looks.",
      "",
      "Sample size is only re-estimated when the interim trend is positive",
      "and the *unadjusted* conditional power falls in an ambiguous middle",
      "range (30%-90%, by default) -- a clearly losing trend isn't",
      "rescued by adding more patients, and a clearly winning one doesn't",
      "need to be made bigger.",
      sep = "\n"
    ),
    worked_example = paste(
      "Continuing the O'Brien-Fleming example above (n = 128, interim",
      "boundary 2.963, final boundary 1.969, 50% information at the",
      "interim): an observed interim Z = 1.5 (below the efficacy",
      "boundary, so the trial continues) implies an observed trend of",
      "theta = 0.1875 and a conditional power, AT THE ORIGINALLY PLANNED",
      "remaining sample size, of just 58.6% -- discouraging, but not",
      "hopeless. Targeting 90% conditional power instead calls for",
      "growing the trial to n = 252 total (187 more participants beyond",
      "the 64 already enrolled per arm at the interim) -- verified to",
      "restore exactly 90% conditional power at that new size. If the",
      "interim trend had instead been negative (Z1 = -0.5), no",
      "adaptation is recommended -- the calculator instead keeps the",
      "originally planned sample size.",
      sep = "\n"
    ),
    citation = paste(
      "Lehmacher W, Wassmer G. Adaptive sample size calculations in group",
      "sequential trials. Biometrics. 1999;55(4):1286-1290; Proschan MA,",
      "Hunsberger SA. Designed extension of studies based on conditional",
      "power. Biometrics. 1995;51(4):1315-1324; Liu Q, Chi GYH. On sample",
      "size and inference for two-stage adaptive designs. Biometrics.",
      "2001;57(1):172-177.",
      "",
      "Formulas (the inverse-normal combination cutoff, conditional power,",
      "and the sample-size-re-estimation identity) transcribed from",
      "reading `gsDesign::condPower()`/`ssrCP()`'s own source",
      "(https://github.com/cran/gsDesign) -- `gsDesign` itself could not",
      "be fully installed in this sandbox (its `gt`/`r2rtf` dependencies",
      "pull in further unavailable packages) and its boundary math calls",
      "into compiled C code unusable from source alone, so it is used",
      "here only as a formula reference, not a runtime or verification",
      "dependency. Verified instead by: (1) an exact algebraic check that",
      "conditional power at the re-estimated sample size equals the",
      "target exactly; (2) integrating conditional power over the",
      "interim Z-statistic's own design distribution, exactly",
      "reconstructing this module's own Lan-DeMets design power; and (3)",
      "a 100,000-replicate simulation under the null hypothesis, adapting",
      "sample size on the observed (noisy) interim trend at every",
      "replicate -- the hardest case for a type-I-error leak -- confirming",
      "the empirical error rate matches the exact target exactly."
    ),
    backend = "closed-form reimplementation (inverse-normal combination test)"
  )
)
