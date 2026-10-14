# Metadata for the Stratified Sampling module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_stratified.R (SDD 4.2: "content is data, not
# hardcoded UI").

stratified_content <- list(
  stratified = list(
    title = "Stratified Sampling -- Total Sample Size and Allocation",
    formula_latex = paste0(
      "$$n = \\frac{\\sum_h w_h^2 \\dfrac{N}{N_h-1} S_h^2}",
      "{e^2/z^2 + \\sum_h w_h^2 \\dfrac{S_h^2}{N_h-1}} ",
      "\\quad\\text{(proportional allocation, } w_h = N_h/N\\text{)}$$",
      "$$n_h^{prop} = n \\times \\frac{N_h}{N}, ",
      "\\qquad n_h^{opt} = n \\times \\frac{N_h S_h}{\\sum_h N_h S_h} ",
      "\\quad\\text{(optimal/Neyman allocation)}$$"
    ),
    explanation = paste(
      "Use this when a population is divided into distinct **strata**",
      "(e.g. urban/rural, age groups, hospital departments) and you plan",
      "to sample independently *within* each stratum -- rather than",
      "treating the whole population as one simple random sample -- to",
      "estimate an overall mean or total to a target precision.",
      "",
      "- **Nh** - the population size of each stratum.",
      "- **Sh** - the standard deviation of the outcome within each",
      "  stratum (from prior data, a pilot, or an educated guess).",
      "- **e** - the desired absolute precision (margin of error) for the",
      "  overall (population-weighted) estimate.",
      "- **conf_level** - the confidence level, e.g. 0.95.",
      "- **Allocation** - *proportional* assigns each stratum a share of",
      "  the total sample proportional to its population size (simple,",
      "  self-weighting). *Optimal (Neyman)* additionally accounts for",
      "  each stratum's variability, assigning more of the sample to",
      "  strata that are both larger AND more variable -- this minimizes",
      "  the variance of the overall estimate for a given total n, but",
      "  needs a reasonable prior estimate of each Sh.",
      "",
      "The calculator returns both the total sample size needed and how",
      "many subjects to sample from each individual stratum.",
      sep = "\n"
    ),
    worked_example = paste(
      "A national survey population is split into 3 strata (Nh =",
      "100,000, 300,000, and 600,000) with stratum SDs Sh = 1, 2, and 3",
      "respectively, targeting a precision of e = 0.1 at 95% confidence.",
      "Under proportional allocation this calculator returns a total",
      "n = 2,568; under optimal (Neyman) allocation, n = 2,395 -- fewer",
      "subjects overall, because Neyman allocation concentrates sampling",
      "effort on the larger, more variable strata. (This example -- and",
      "the allocation formulas -- reproduce `samplingbook::stratasize()`",
      "and `stratasamp()`'s own documented examples exactly.)",
      sep = "\n"
    ),
    citation = paste(
      "Cochran WG. Sampling Techniques. 3rd ed. New York: John Wiley &",
      "Sons; 1977; Kauermann G, Kuechenhoff H. Stichproben: Methoden und",
      "praktische Umsetzung mit R. Berlin: Springer; 2011."
    ),
    backend = "closed-form (Cochran 1977; Kauermann & Kuechenhoff 2011)"
  )
)
