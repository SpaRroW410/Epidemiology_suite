# Text of the "When should I use absolute or relative precision?" panel shown in the five precision-based calculators
# (mod_shared_precision.R). Sources: Pourhoseingholi MA, Vahedi M, Rahimzadeh M. Sample size calculation in medical studies.
# Gastroenterol Hepatol Bed Bench 2013;6(1):14-17 (PMID 24834239, PMC4017493; read through PubMed Central). The 20% limit for a
# relative precision is a common rule of thumb for which no published source was checked; the text says so.

.precision_citation_pourhoseingholi <- paste(
  "Pourhoseingholi MA, Vahedi M, Rahimzadeh M. Sample size calculation in medical studies.",
  "Gastroenterol Hepatol Bed Bench. 2013;6(1):14-17. PMID 24834239; PMCID PMC4017493."
)

.precision_guidance_common <- paste(
  "**Absolute precision** (+/- d, in the units of the estimate) suits a result reported as \"30% +/- 5 percentage points\" and an",
  "estimate that is neither very small nor very large. **Relative precision** (+/- a fraction of the estimate, d = epsilon x",
  "estimate) suits a small or rare quantity, where a fixed d would be too crude, and a result reported as \"within 10% of the true",
  "value\". The line under the inputs shows your precision both ways.",
  "",
  "- **Relative precision above 20%** gives a wide interval and a warning. At most 20% is a common rule of thumb; no published",
  "  source for it was checked. 10%-20% is usual. **100% or more is refused**: the interval would reach 0.",
  sep = "\n"
)

.precision_guidance_proportion <- paste(
  "- **The absolute precision d must be smaller than p and than 1 - p**, otherwise the interval p +/- d passes 0 or 1; the",
  "  calculator refuses it.",
  "- **Small proportions.** Pourhoseingholi et al. (2013) note that some authors recommend d = 5% when the proportion is between",
  "  10% and 90%, that 5% is inappropriate below 10% (for a prevalence of 1% it is \"obviously crude\"), and that a conservative",
  "  choice is **one-fourth to one-fifth of p**: their Table 1 uses d = 0.01 for p = 0.05 (n = 1825), d = 0.04 for p = 0.2",
  "  (n = 384) and d = 0.1 for p = 0.6 (n = 92). The calculator warns when p is below 10% and d is above p/4; above 90% it applies",
  "  the same rule to 1 - p (the mirror is this app's, not the paper's).",
  "- p = 0.5 gives the largest n for an absolute precision, but not for a relative one (n = z^2 (1 - p) / (epsilon^2 p) grows as",
  "  p falls), so with relative precision use your best estimate of p, not 0.5.",
  sep = "\n"
)

.precision_guidance_nonresponse <- function(how) {
  paste(
    "",
    "**Non-response / loss to follow-up.** Enter the fraction you expect to lose (refusals, no answer, lost to follow-up, unusable",
    paste0("data). ", how, " If a fraction r is lost only 1 - r remain, so the inflation is n / (1 - r), **not** n x (1 + r): with"),
    "20% loss, 100 analyzable need 125 enrolled, not 120. Inflating restores the number, not the bias if those lost differ from",
    "those who stay. For several stages or different losses per arm, use the Attrition and Non-response calculator.",
    sep = "\n"
  )
}

precision_guidance_md <- function(kind = c("proportion", "mean", "cluster", "rate", "diagnostic")) {
  kind <- match.arg(kind)
  specific <- switch(kind,
    proportion = .precision_guidance_proportion,
    cluster = paste(.precision_guidance_proportion,
                    "- The precision is for the proportion in the whole population; the clustering only changes how many people that needs.",
                    sep = "\n"),
    diagnostic = paste(
      "- The precision applies to sensitivity and to specificity separately, each on the 0-1 scale (absolute) or as a fraction of",
      "  it (relative). **The absolute precision must be smaller than the value and than 1 minus the value** (a sensitivity of 0.95",
      "  with +/- 0.05 would reach 1); the calculator refuses it.",
      "- Sensitivity and specificity are often above 90%, where a fixed +/- 5% is crude; the calculator then warns when the",
      "  precision is above one-fourth of 1 minus the value (the small-proportion rule of Pourhoseingholi et al. 2013, applied by",
      "  this app to 1 - sensitivity and 1 - specificity).",
      sep = "\n"),
    mean = paste(
      "- For a mean, absolute precision is in the units of the measurement (mmHg, g/dL). Relative precision is natural when the",
      "  variable is a positive amount and the SD is roughly proportional to the mean.",
      "- An **absolute precision as large as the mean** gives an interval that includes 0, which is not useful for a positive",
      "  measurement; the calculator warns.",
      sep = "\n"),
    rate = paste(
      "- For a rate, the absolute precision is the **full width** of the confidence interval (as in presize::prec_rate), in the",
      "  units of the rate; a relative precision epsilon means a width of 2 x epsilon x rate. The width may not exceed 5 times the",
      "  rate (presize's guidance).",
      sep = "\n")
  )
  how <- switch(kind,
    proportion = "The calculator gives the number to analyze and the number to enrol.",
    mean = "The calculator gives the number to analyze and the number to enrol.",
    cluster = paste("The number of clusters stays the same; each cluster selects b / (1 - r) people so that b are analyzable,",
                    "and the total to select is the clusters times that."),
    rate = paste("For a rate, enter the fraction of the planned person-time you expect to lose (people who leave early",
                 "contribute only the time before they leave); the person-time to plan is the required person-time / (1 - r)."),
    diagnostic = "The calculator gives the number to analyze (with a reference-standard result) and the number to enrol."
  )
  paste(.precision_guidance_common, specific, .precision_guidance_nonresponse(how),
        "", paste("Source:", .precision_citation_pourhoseingholi), sep = "\n")
}
