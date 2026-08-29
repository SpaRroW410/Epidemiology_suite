# Metadata for the Cluster / Design Effect module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_cluster.R (SDD 4.2: "content is data,
# not hardcoded UI").

cluster_content <- list(
  deff = list(
    title = "Cluster / Multistage Sampling -- Design Effect (DEFF)",
    formula_latex = paste0(
      "$$DEFF = 1 + (m-1)\\rho$$",
      "$$n_{effective} = n_{base} \\times DEFF$$"
    ),
    explanation = paste(
      "Use this whenever subjects are sampled in **clusters** (villages,",
      "schools, health facilities, households) rather than as a simple",
      "random sample of individuals -- e.g. a two-stage cluster survey.",
      "Subjects within the same cluster tend to be more similar to each",
      "other than to subjects in a different cluster, which reduces the",
      "effective information per subject relative to a true simple random",
      "sample of the same size.",
      "",
      "- **n_base** - the sample size already computed under a simple-",
      "  random-sampling assumption (e.g. from the Proportions or Means",
      "  module's precision- or power-based calculators), for the same",
      "  outcome, precision, and power you actually need.",
      "- **rho (ICC)** - the intraclass correlation coefficient: the",
      "  proportion of total variance in the outcome that is *between*",
      "  clusters rather than within them. 0 means clusters are no more",
      "  alike internally than the population at large (no penalty); values",
      "  are typically small (0.01-0.20) for most health outcomes but can",
      "  be larger for strongly clustered behaviors.",
      "- **m** - the average number of subjects sampled per cluster.",
      "",
      "The design effect (DEFF) says how many times larger the cluster",
      "sample needs to be, compared to a simple random sample, to achieve",
      "the same precision/power. Multiplying by DEFF (rather than deriving",
      "a wholly separate cluster-sampling formula) is the standard,",
      "widely-used shortcut (Kish 1965) -- an approximation that ignores",
      "variation in cluster size, which is adequate for planning purposes.",
      sep = "\n"
    ),
    worked_example = paste(
      "Killip, Mahfoud & Pearce (2004), the paper's own illustration of",
      "the design-effect formula: an ICC of 0.05 and an average cluster",
      "size of 10 subjects gives DEFF = 1 + (10-1)(0.05) = 1.45. Applied to",
      "a simple-random-sample base requirement of n = 200 (e.g. from a",
      "single-proportion precision calculation), the cluster-adjusted",
      "sample size is 200 x 1.45 = 290 subjects.",
      sep = "\n"
    ),
    citation = paste(
      "Kish L. Survey Sampling. New York: John Wiley & Sons; 1965;",
      "Killip S, Mahfoud Z, Pearce K. What is an intracluster correlation",
      "coefficient? Crucial concepts for primary care researchers. Ann Fam",
      "Med. 2004;2(3):204-208."
    ),
    backend = "closed-form (Kish 1965)"
  ),

  survey = list(
    title = "Cluster Survey Precision (WHO EPI-Style)",
    formula_latex = paste0(
      "$$n_{ssu} = \\frac{z^2 \\, p(1-p) \\, D}{\\epsilon_a^2}, \\quad ",
      "D = 1 + (b-1)\\rho, \\quad n_{psu} = n_{ssu}/b$$"
    ),
    explanation = paste(
      "Solves the full two-stage (or one-stage) cluster survey design in",
      "one step -- both the number of clusters (primary sampling units,",
      "PSUs) and the total number of individuals (secondary sampling",
      "units, SSUs) needed to estimate a population proportion to a",
      "target precision -- rather than requiring you to compute a simple-",
      "random-sample n first and inflate it separately (the \"Design",
      "Effect\" calculator above). This is the closed-form basis behind",
      "WHO's classic EPI 30-cluster immunization-coverage survey",
      "methodology, generalized to any number of clusters and precision",
      "target.",
      "",
      "- **b** - the average number of individuals sampled or examined",
      "  per cluster.",
      "- **SD of cluster size** - optional; leave blank if every cluster",
      "  contributes the same number of individuals, or supply a",
      "  standard deviation if cluster sizes vary (this inflates the",
      "  design effect further, since more variable clusters need more",
      "  clusters sampled for the same precision).",
      "- **p** - the expected proportion (prevalence) being estimated.",
      "- **epsilon** - the desired precision (margin of error), either",
      "  relative (a fraction of p, e.g. 0.10 = \"within 10% of p\") or",
      "  absolute (on the same 0-1 scale as p, e.g. 0.05 = \"within 5",
      "  percentage points\").",
      "- **rho (ICC)** - the intracluster correlation coefficient, as in",
      "  the Design Effect calculator above.",
      "- **Total clusters (N, optional)** - the total number of clusters",
      "  in the source population, if known and not effectively",
      "  unlimited, for a finite-population correction.",
      "",
      "**A package quirk worth knowing:** epiR provides two same-",
      "sounding functions here, `epi.ssclus1estb()` (\"one-stage\", every",
      "individual in a sampled cluster is enumerated) and",
      "`epi.ssclus2estb()` (\"two-stage\", a subsample of b individuals is",
      "drawn from each cluster) -- on inspection of both functions' own",
      "source code, they are byte-for-byte identical. This calculator",
      "therefore covers both cases; read `b` as \"individuals examined per",
      "cluster\" either way.",
      sep = "\n"
    ),
    worked_example = paste(
      "epiR's own documented examples (Levy & Lemeshow 1999; Machin,",
      "Campbell, Tan & Tan 2018): an aid project wants to know what",
      "proportion of households are still using a donated cook stove,",
      "expecting a pilot-study prevalence of p = 0.46, with b = 75",
      "households visited per village and an intracluster correlation of",
      "rho = 0.20. At 90% confidence and a relative precision of 10%,",
      "this calculator returns 67 villages (clusters) to sample. If",
      "village size actually varies (mean 75, SD 35 households), that",
      "rises to 81 villages; if the total number of villages in the",
      "province is known to be only 220 (a finite-population correction),",
      "it falls back to 60 villages -- all three matching epiR's own",
      "worked answers exactly. A second, WHO-style example (b = 20 per",
      "cluster, p = 0.20, an absolute precision of +/-0.05, rho = 0.02, 95%",
      "confidence) returns 17 clusters and 340 individuals total.",
      sep = "\n"
    ),
    citation = paste(
      "Levy PS, Lemeshow S. Sampling of Populations: Methods and",
      "Applications. Wiley Series in Probability and Statistics; 1999,",
      "p. 258. Machin D, Campbell MJ, Tan SB, Tan SH. Sample Sizes for",
      "Clinical, Laboratory and Epidemiological Studies. 4th ed. Wiley",
      "Blackwell; 2018, pp. 195-214. Henderson RH, Sundaresan T. Cluster",
      "sampling to assess immunization coverage: a review of experience",
      "with a simplified sampling method. Bull World Health Organ.",
      "1982;60(2):253-260."
    ),
    backend = "epiR::epi.ssclus2estb()"
  )
)
