# Metadata for the Trial Sequential Analysis module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_tsa.R (SDD 4.2: "content is data, not
# hardcoded UI").

tsa_content <- list(
  rr = list(
    title = "Required Information Size -- Risk Ratio (RR)",
    formula_latex = paste0(
      "$$p_I = p_C \\times RR, \\quad \\bar p = \\frac{p_C + p_I}{2}, ",
      "\\quad V = \\bar p (1 - \\bar p)$$",
      "$$N_F = \\left\\lceil 2 (z_{1-\\alpha/side} + z_{1-\\beta})^2 ",
      "\\frac{2V}{(p_C - p_I)^2} \\right\\rceil$$"
    ),
    backend = "closed-form reimplementation (Wetterslev fixed-effect RIS)"
  ),
  or = list(
    title = "Required Information Size -- Odds Ratio (OR)",
    formula_latex = paste0(
      "$$p_I = \\text{logit}^{-1}\\big(\\text{logit}(p_C) + \\ln(OR)\\big), ",
      "\\quad \\bar p = \\frac{p_C + p_I}{2}, \\quad V = \\bar p (1 - \\bar p)$$",
      "$$N_F = \\left\\lceil 2 (z_{1-\\alpha/side} + z_{1-\\beta})^2 ",
      "\\frac{2V}{(p_C - p_I)^2} \\right\\rceil$$"
    ),
    backend = "closed-form reimplementation (Wetterslev fixed-effect RIS)"
  ),
  rd = list(
    title = "Required Information Size -- Risk Difference (RD)",
    formula_latex = paste0(
      "$$V = p_C(1-p_C) + p_1(1-p_1)$$",
      "$$N_F = \\left\\lceil 2 (z_{1-\\alpha/side} + z_{1-\\beta})^2 ",
      "\\frac{2V}{mc^2} \\right\\rceil$$"
    ),
    backend = "closed-form reimplementation (Wetterslev fixed-effect RIS)"
  ),
  md = list(
    title = "Required Information Size -- Mean Difference (MD)",
    formula_latex = paste0(
      "$$V = \\sigma_{mc}^2$$",
      "$$N_F = \\left\\lceil 2 (z_{1-\\alpha/side} + z_{1-\\beta})^2 ",
      "\\frac{2V}{mc^2} \\right\\rceil$$"
    ),
    backend = "closed-form reimplementation (Wetterslev fixed-effect RIS)"
  ),
  shared = list(
    explanation = paste(
      "**Trial Sequential Analysis (TSA)** applies the same logic as a",
      "single trial's sample-size calculation to a *meta-analysis* of",
      "trials: just as an underpowered single trial risks a false",
      "conclusion, an underpowered (too little cumulative data) or",
      "repeatedly-peeked-at (too many looks without adjustment)",
      "meta-analysis risks the same. The **Required/Optimal Information",
      "Size (RIS/OIS)** computed here is the cumulative total sample size",
      "(summed across all trials in the meta-analysis) needed for a",
      "fixed-effect meta-analysis to have the specified power to detect",
      "the anticipated effect -- the meta-analytic analogue of a single",
      "trial's required n, and the threshold TSA software (e.g. the CTU",
      "Copenhagen TSA program, or the RTSA R package) uses to build",
      "alpha-spending monitoring boundaries for cumulative",
      "meta-analyses that are updated as new trials appear.",
      "",
      "- **Outcome type** - risk ratio, odds ratio, risk difference, or",
      "  mean difference, matching how the anticipated effect is",
      "  expressed.",
      "- **mc (minimal/anticipated clinically relevant effect)** - the",
      "  effect size the meta-analysis should be powered to detect: a",
      "  ratio for RR/OR (e.g. 0.8), or an absolute difference for",
      "  RD/MD.",
      "- **pC (control-arm event probability)** - required for RR, OR,",
      "  and RD.",
      "- **p1 (intervention-arm event probability)** - required for RD",
      "  only (RR and OR derive the intervention-arm probability from",
      "  pC and mc instead).",
      "- **sd_mc (standard deviation of the effect)** - required for MD",
      "  only.",
      "- **alpha, beta (power = 1 - beta), side** - as elsewhere; `side`",
      "  is 1 or 2 or a one- or two-sided test.",
      "",
      "This calculator computes the **fixed-effect** RIS only -- the",
      "baseline threshold assuming no between-trial heterogeneity.",
      "Real TSA software also offers heterogeneity-adjusted",
      "(random-effects, diversity- or inconsistency-adjusted) variants",
      "that inflate this number once trials with observed heterogeneity",
      "exist; those require an already-conducted meta-analysis's",
      "heterogeneity estimate as an input and are out of scope for this",
      "prospective planning calculator.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an anticipated risk ratio of 0.8 with a 12% control-arm event",
      "rate (two-sided, alpha = 0.05, 90% power), this calculator returns",
      "a required information size of 7,030 participants -- exactly",
      "matching the RTSA R package's own `ris()` function",
      "(`ris(outcome = \"RR\", mc = 0.8, pC = 0.12, alpha = 0.05,",
      "beta = 0.1, side = 2)`), which is the reference implementation",
      "this calculator's formula was independently verified against",
      "across all four outcome types (16/16 exact matches under varied",
      "alpha, beta, and side).",
      sep = "\n"
    ),
    citation = paste(
      "Wetterslev J, Thorlund K, Brok J, Gluud C. Trial sequential",
      "analysis may establish when firm evidence is reached in",
      "cumulative meta-analysis. J Clin Epidemiol. 2008;61(1):64-75.",
      "",
      "Formula independently derived by reading the source of the RTSA",
      "R package's `ris()` function (Imberg H, Wetterslev J, et al.,",
      "https://github.com/cran/RTSA) and verified numerically against",
      "real `RTSA::ris()` calls (16/16 exact matches across RR, OR, RD,",
      "and MD outcome types with varied alpha/beta/side). Reimplemented",
      "from scratch rather than depending on RTSA at runtime, so this",
      "app stays self-contained."
    )
  )
)
