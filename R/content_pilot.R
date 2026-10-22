# Metadata for the Pilot / Feasibility module: guidance text, worked
# example, and citation. Content is data, rendered generically by
# mod_pilot.R (SDD 4.2: "content is data, not hardcoded UI").
#
# Unlike every other content_*.R file, this module is guidance, not a
# formula -- there is no accepted "solve for n" method for pilot studies.

pilot_content <- list(
  rule_of_thumb = list(
    title = "Pilot / Feasibility Study Sample Size",
    formula_latex = paste0(
      "$$n \\approx 12 \\text{ per arm (Julious 2005, rule of thumb)}$$",
      "$$\\text{CI multiplier for } \\sigma: \\quad ",
      "\\left[\\sqrt{\\frac{n-1}{\\chi^2_{1-\\alpha/2,\\,n-1}}},\\ ",
      "\\sqrt{\\frac{n-1}{\\chi^2_{\\alpha/2,\\,n-1}}}\\right] \\times s$$"
    ),
    explanation = paste(
      "Pilot and feasibility studies aren't sized with a hypothesis-test",
      "formula -- there is no effect size to detect, because the point of",
      "a pilot is to check the study is *feasible* and to estimate",
      "parameters (recruitment rate, variance, adherence) for the main",
      "trial, not to test a hypothesis. Treat any number below as a",
      "starting point, not a target to defend statistically.",
      "",
      "**The 12-per-arm rule of thumb (Julious 2005).** Julious reviewed",
      "several independent lines of reasoning -- feasibility, precision of",
      "the mean and variance estimates that will feed the main trial's own",
      "sample size calculation, and regulatory conventions -- and found",
      "they converge on roughly 12 subjects per arm as a reasonable",
      "default when nothing else is known. It is a compromise, not an",
      "optimum: smaller pilots give a poorly-precise variance estimate;",
      "much larger ones start to consume the resources the main trial",
      "needs.",
      "",
      "**Precision tool.** The calculator below shows *why* the number 12",
      "is only a compromise: it computes the confidence interval width",
      "for the true SD, implied by a pilot of a given size, expressed as a",
      "multiple of whatever SD you observe. A small pilot's SD estimate",
      "can easily be half, or nearly double, the true value.",
      "",
      "**Beyond the flat rule.** More detailed stepped approaches exist,",
      "relating pilot size to the standardized effect size planned for",
      "the main trial (Whitehead et al. 2016; Lancaster et al. 2004) --",
      "not implemented here; treat the 12-per-arm figure and the",
      "precision tool as a starting point, and consult those sources for",
      "a size tailored to your specific main-trial design.",
      sep = "\n"
    ),
    worked_example = paste(
      "At n = 12 per arm, a 95% confidence interval for the true standard",
      "deviation ranges from about 0.71x to 1.70x whatever SD you observe",
      "in the pilot -- illustrating that a pilot this size only loosely",
      "informs the variance estimate you'll plug into the main trial's",
      "sample size calculation.",
      sep = "\n"
    ),
    citation = paste(
      "Julious SA. Sample size of 12 per group rule of thumb for a pilot",
      "study. Pharm Stat. 2005;4(4):287-291; Whitehead AL, Julious SA,",
      "Cooper CL, Campbell MJ. Estimating the sample size for a pilot",
      "randomised trial to minimise the overall trial sample size for the",
      "external pilot and main trial for a continuous outcome variable.",
      "Stat Methods Med Res. 2016;25(3):1057-1073; Lancaster GA, Dodd S,",
      "Williamson PR. Design and analysis of pilot studies: recommendations",
      "for good practice. J Eval Clin Pract. 2004;10(2):307-312."
    ),
    backend = "Closed-form (Julious 2005 rule; chi-squared CI for a normal variance); no external package required"
  )
)
