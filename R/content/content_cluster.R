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
  )
)
