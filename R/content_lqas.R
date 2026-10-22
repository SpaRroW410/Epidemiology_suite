# Metadata for the LQAS module: formula text, plain-language explanation,
# worked example, and citation. Content is data, rendered generically by
# mod_lqas.R (SDD 4.2: "content is data, not hardcoded UI").

lqas_content <- list(
  standard = list(
    title = "Lot Quality Assurance Sampling (LQAS)",
    formula_latex = paste0(
      "$$\\text{find smallest } n, d \\text{ s.t. } ",
      "P(X<d \\mid p=p_u) \\le \\alpha \\text{ and } ",
      "P(X\\ge d \\mid p=p_l) \\le \\beta, \\quad X\\sim\\text{Binomial}(n,p)$$"
    ),
    explanation = paste(
      "Use this for a rapid classification survey of a small area, health",
      "facility catchment, or program \"lot\" -- rather than estimating a",
      "proportion precisely (see the standard Proportion module), LQAS",
      "instead classifies the area as *high-performing* or",
      "*low-performing* against two pre-specified thresholds, using the",
      "smallest sample that controls both kinds of misclassification",
      "risk. This is the standard tool for rapid program monitoring",
      "(vaccination coverage, treatment access, water/sanitation access)",
      "in public health and humanitarian settings.",
      "",
      "- **p_upper** - the indicator proportion that defines an",
      "  *acceptable/high-performing* area (e.g. 80% vaccination coverage).",
      "- **p_lower** - the indicator proportion that defines an",
      "  *unacceptable/low-performing* area (e.g. 50% coverage). Must be",
      "  below p_upper -- the gap between the two drives the required n:",
      "  a narrow gap needs a much larger sample.",
      "- **alpha (producer's risk)** - the maximum acceptable probability",
      "  of wrongly classifying a truly high-performing area (at p_upper)",
      "  as low-performing.",
      "- **beta (consumer's risk)** - the maximum acceptable probability",
      "  of wrongly classifying a truly low-performing area (at p_lower)",
      "  as high-performing.",
      "",
      "The decision rule: sample n individuals; if X (the number showing",
      "the favorable outcome) is >= the returned decision value d, classify",
      "the area as high-performing; otherwise, low-performing. Both n and",
      "d are chosen together -- the smallest n for which some d satisfies",
      "both risk constraints simultaneously.",
      sep = "\n"
    ),
    worked_example = paste(
      "The widely-used LQAS \"n=19\" rule, as commonly applied to",
      "vaccination/treatment coverage surveys with a 30-percentage-point",
      "gap between thresholds: p_upper=0.80 (acceptable coverage),",
      "p_lower=0.50 (unacceptable coverage), targeting alpha=beta=0.10.",
      "This calculator returns n=19, d=13 -- classify the area as",
      "high-performing if 13 or more of the 19 sampled individuals show",
      "the favorable outcome. The achieved risks (alpha=6.8%, beta=8.4%,",
      "total ~15%) match the figures reported for this exact rule in the",
      "LQAS field literature (\"total error below 20%\"), including an",
      "independent mirror-image check of the same n=19/d rule reported",
      "for a malaria-treatment-access survey framed the opposite direction",
      "(counting *untreated* cases, d=6, giving the identical alpha=6.8%,",
      "beta=8.4% by binomial symmetry).",
      sep = "\n"
    ),
    citation = paste(
      "Robertson SE, Valadez JJ. Global review of health care surveys",
      "using lot quality assurance sampling (LQAS), 1984-2004.",
      "Soc Sci Med. 2006;63(6):1648-1660.",
      "Valadez JJ. Assessing Child Survival Programs in Developing",
      "Countries: Testing Lot Quality Assurance Sampling. Harvard",
      "University Press, 1991."
    ),
    backend = "Direct binomial operating-characteristic search (base R pbinom()) -- no package needed"
  )
)
