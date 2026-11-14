# Metadata for the Attrition and Non-response module (ROADMAP Track B2, item 14): formula
# text, plain-language explanation, worked example and citation per design. Content is data,
# rendered generically by mod_attrition.R.

.attrition_citation_loss <- paste(
  "The inflation n / (1 - d) and the product over stages are identities of the retention argument (the fraction of those",
  "enrolled who are analyzable is 1 - d), so there is no package to compare with; the unit tests recompute the expected",
  "number of analyzable participants instead. Adding the loss (n x (1 + d)) is a common error and is shown for contrast."
)

attrition_content <- list(
  stages = list(
    title = "Inflating the sample size for attrition and non-response",
    formula_latex = paste0(
      "$$n_{\\text{enrol}}=\\left\\lceil \\frac{n_{\\text{required}}}{\\prod_i (1-d_i)}\\right\\rceil\\quad\\text{(not } n_{\\text{required}}(1+d)\\text{)}$$"
    ),
    explanation = paste(
      "Enter the number you need to **analyze** (from any sample-size calculator) and the fraction you expect to lose at each",
      "stage -- for example non-response or refusal, loss to follow-up, and unusable data. If a fraction $d$ is lost, only",
      "$1-d$ of those enrolled remain, so you must enrol $n/(1-d)$, which is **more** than $n(1+d)$: with 20% loss, 100",
      "analyzable participants need **125** enrolled, not 120. Independent stages multiply their retentions. The table shows how many",
      "are expected to remain after each stage.",
      "",
      "Use realistic losses (from pilot data or similar studies). Inflating restores the *number* but cannot remove the *bias* if",
      "those lost differ from those who stay, and losses that differ between arms need the per-arm version.",
      sep = "\n"
    ),
    worked_example = paste(
      "200 analyzable participants needed; 10% non-response, 15% loss to follow-up and 20% unusable data: retention 0.9 x 0.85 x 0.8 =",
      "0.612, so enrol 200 / 0.612 = 326.8, i.e. **327**; adding the losses instead (200 x 1.45) would give 290.",
      sep = "\n"
    ),
    citation = .attrition_citation_loss,
    backend = "closed form (retention product); verified by recomputing the expected analyzable number"
  ),
  arms = list(
    title = "Inflating each arm for different losses",
    formula_latex = "$$n_{\\text{enrol},j}=\\left\\lceil \\frac{n_{\\text{required},j}}{1-d_j}\\right\\rceil,\\qquad n_{\\text{enrol}}=\\sum_j n_{\\text{enrol},j}$$",
    explanation = paste(
      "When the expected loss differs between arms (for example more drop-out on an unpleasant treatment), inflate each arm by its",
      "own loss. Using the average loss for everyone under-recruits the arm that loses more and over-recruits the other. Enter",
      "the analyzable number and expected loss for each arm (2 to 6 arms).",
      "",
      "Differential loss also threatens the comparison itself (the remaining participants may no longer be comparable), which",
      "no sample size can repair; plan to limit and examine it.",
      sep = "\n"
    ),
    worked_example = "100 analyzable per arm; 10% loss in arm 1 and 30% in arm 2: enrol 112 and 143 (total 255); using the average 20% loss for both would give 250 in total.",
    citation = .attrition_citation_loss,
    backend = "closed form per arm; verified by recomputing the expected analyzable numbers"
  ),
  noncompliance = list(
    title = "Inflating for drop-out and drop-in (dilution of the treatment contrast)",
    formula_latex = "$$n_{\\text{adj}}=\\left\\lceil \\frac{n}{(1-R_E-R_C)^{2}}\\right\\rceil$$",
    explanation = paste(
      "In an intention-to-treat comparison, participants who stop the treatment (**drop-out**, fraction $R_E$ of the treatment arm)",
      "or who take it up although allocated to control (**drop-in**, fraction $R_C$ of the control arm) dilute the contrast: the",
      "expected difference shrinks to $(1-R_E-R_C)$ of the planned one. Because the sample size is proportional to the",
      "inverse of the *squared* difference, it grows by $1/(1-R_E-R_C)^2$.",
      "",
      "**This relation was derived for this tool** from that proportionality (the variance is assumed not to change) and checked by",
      "simulation for a difference in means; the form is the one usually attributed to Lachin (Control Clin Trials 1981;2:93-113,",
      "whose equations were not read here). For proportions it is approximate: the more exact route is to recompute the sample",
      "size from the diluted proportions. It applies to the intention-to-treat analysis; a per-protocol analysis has other",
      "problems (selection) that no sample size fixes.",
      sep = "\n"
    ),
    worked_example = "100 per arm needed with full compliance; 10% drop-out and 5% drop-in: dilution 0.85, enrol 100 / 0.85^2 = 138.4, i.e. **139** per arm (a simple 1/(1 - 0.15) inflation would give 118).",
    citation = paste(
      "Derived here from n proportional to 1/(difference)^2 and verified by simulation (unit tests). Associated reference, existence",
      "confirmed by web search but equations not read: Lachin JM. Introduction to sample size determination and power analysis for",
      "clinical trials. Control Clin Trials 1981;2:93-113."
    ),
    backend = "closed form (derived); verified by a power simulation"
  )
)
