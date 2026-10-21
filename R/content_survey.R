# Metadata for the Survey Sample Selection and Survey Weights modules (ROADMAP Track B3, item 20): formula text,
# plain-language explanation, worked example and citation per design. Content is data, rendered generically by
# mod_survey_selection.R / mod_survey_weights.R.

.survey_citation <- paste(
  "Madow WG. On the theory of systematic sampling, II. Ann Math Stat 1949;20:333-354 (systematic selection with",
  "probability proportional to size; existence, journal, volume and pages confirmed by web search); Henderson RH, Sundaresan T.",
  "Cluster sampling to assess immunization coverage: a review of experience with a simplified sampling method. Bull World Health",
  "Organ 1982;60:253-260 (the 30 x 7 EPI design; confirmed); Bennett S, Woods T, Liyanage WM, Smith DL. A simplified general",
  "method for cluster-sample surveys of health in developing countries. World Health Stat Q 1991;44:98-106 (confirmed);",
  "Valliant R, Dever JA, Kreuter F. Practical Tools for Designing and Weighting Survey Samples. Springer; 2013 (certainty units,",
  "design and nonresponse weights; the book exists, its pages were not read here). The selection routines are checked by their",
  "defining properties and, for PPS, against sampling::UPsystematic() (Madow's method) for the same random start; none of the",
  "originals could be read."
)

survey_selection_content <- list(
  srs = list(
    title = "Simple random sample from a list of units",
    formula_latex = "$$\\pi_i=\\frac{n}{N},\\qquad w_i=\\frac{N}{n}$$",
    explanation = paste(
      "Enter the size of the list (the **sampling frame**) and the number to select, or paste the list of unit names. The app draws",
      "`n` units without replacement, so every unit has the same chance $n/N$ of being chosen, and shows each selected unit's",
      "**design weight** $N/n$ (how many frame units it stands for). The draw is reproducible from the **seed**: the same seed and",
      "inputs give the same sample, which you can keep in the study records.",
      "",
      "The frame should list every eligible unit once, and only once. Simple random sampling is the benchmark design; when units",
      "differ a lot in size, or you want the sample spread evenly over a list ordered by place or time, use the systematic or PPS design.",
      sep = "\\n"
    ),
    worked_example = "A frame of 500 households, 40 to select, seed 3: 40 distinct household numbers, each with inclusion probability 0.08 and design weight 12.5.",
    citation = .survey_citation,
    backend = "base R sample.int() with a pinned generator (Mersenne-Twister, rejection sampling); verified by property tests"
  ),
  systematic = list(
    title = "Systematic sample (every k-th unit from a random start)",
    formula_latex = "$$k=\\frac{N}{n},\\qquad r\\sim U(0,k],\\qquad \\text{select units }\\lceil r+(j-1)k\\rceil,\\ j=1,\\dots,n$$",
    explanation = paste(
      "The sampling interval is $k=N/n$ and does **not** have to be a whole number: with a random start $r$ in $(0,k]$ the",
      "units $\\lceil r+(j-1)k\\rceil$ are chosen, which always gives exactly $n$ units, each with probability $n/N$. It is quick to do in the",
      "field and spreads the sample evenly over a list that is ordered by place, date or record number.",
      "",
      "**Caution:** if the list has a repeating pattern that matches the interval (for example every 7th day), the sample can be",
      "biased; and variance estimation from a single systematic sample needs an assumption (the usual one is to treat it as",
      "simple random if the list order is unrelated to the outcome).",
      sep = "\\n"
    ),
    worked_example = "A list of 100 units, 12 to select: interval 8.33, units about 8 or 9 apart from a random start; with 100 and 10 the interval is exactly 10 and the units are exactly 10 apart.",
    citation = .survey_citation,
    backend = "closed form (random start, fractional interval); verified by property tests"
  ),
  pps = list(
    title = "Probability-proportional-to-size (PPS) systematic sample",
    formula_latex = paste0(
      "$$k=\\frac{X}{n},\\quad X=\\sum_i x_i,\\qquad r\\sim U(0,k],\\qquad \\text{unit } i \\text{ is chosen if } r+(j-1)k \\in \\Big(\\sum_{l<i}x_l,\\ \\sum_{l\\le i}x_l\\Big]$$",
      "$$\\pi_i=\\frac{n\\,x_i}{X},\\qquad w_i=\\frac1{\\pi_i},\\qquad \\sum_{i\\in s}x_iw_i=X$$"
    ),
    explanation = paste(
      "Enter the units with a **size** for each (population, households, beds, ...), one per line as `name, size`. Larger units get",
      "a proportionally larger chance: a unit of size $x_i$ is chosen with probability $\\pi_i=n x_i/X$. The method lays the units",
      "end to end on a line of length $X$ and places $n$ equally spaced points from a random start; the units hit are the sample. Use",
      "it for the first stage of a cluster survey, where each cluster should be chosen in proportion to its population.",
      "",
      "A unit at least as large as the interval $k$ would be hit more than once, so it is taken with **certainty** ($\\pi=1$) and set aside, and the",
      "interval is recomputed from the rest, repeating until no unit is that large. The order of the list matters (it acts as implicit",
      "stratification); tick *randomize order* for a random-order systematic sample instead. The table also gives each selected unit's design",
      "weight $1/\\pi_i$. A built-in check: the weighted sum of the selected sizes equals the frame total exactly.",
      sep = "\\n"
    ),
    worked_example = paste(
      "Ten villages with populations 1200, 300, 5000, 800, 950, 400, 2500, 60, 700 and 1500 (total 13,410), 4 to select, seed 1:",
      "the 5000-person village is a certainty unit; the other three are chosen from the remaining 8410 at interval 2803.3,",
      "each with inclusion probability n x / X (for the 2500 village 0.892).",
      sep = "\\n"
    ),
    citation = .survey_citation,
    backend = "closed form (Madow 1949); identical to sampling::UPsystematic() for the same random start, which it is tested against"
  ),
  epi = list(
    title = "WHO EPI cluster survey (30 x 7): choosing the clusters",
    formula_latex = "$$n_{\\text{clusters}}=30,\\quad m=7,\\quad n=30\\times 7=210,\\qquad \\pi_{\\text{cluster}}=\\frac{30\\,x_c}{X}$$",
    explanation = paste(
      "The classic cluster design of the Expanded Programme on Immunization: **30 clusters** (villages, blocks, enumeration areas) are",
      "chosen with probability proportional to size from a list with population sizes, then **7 subjects per cluster** (for example children",
      "aged 12-23 months), 210 in all. Because clusters are chosen in proportion to size and the same number is taken in each, the design",
      "is **self-weighting**. The app does the first stage with the PPS method above and shows the clusters; change the numbers for other",
      "designs (for example 40 x 10).",
      "",
      "**What this does not do:** choosing the households inside a cluster (a random walk from a random start, spinning a pen, a",
      "GPS-based draw or a household listing) is a field procedure and is not computed here. Cluster designs also lose precision",
      "to the **design effect**; plan the number of clusters and subjects with the Cluster / Design Effect calculator.",
      sep = "\\n"
    ),
    worked_example = "A list of 120 villages with populations, 30 clusters, 7 per cluster, seed 11: 30 selected villages, 210 subjects; the weighted sum of the selected populations reproduces the list total.",
    citation = .survey_citation,
    backend = "closed form (PPS systematic, Madow 1949); verified by property tests"
  )
)

survey_weights_content <- list(
  classes = list(
    title = "Design weights and nonresponse adjustment in weighting classes",
    formula_latex = paste0(
      "$$d_h=\\frac{N_h}{n_h},\\qquad RR_h=\\frac{r_h}{n_h},\\qquad w_h=\\frac{d_h}{RR_h}=\\frac{N_h}{r_h},\\qquad \\sum_h r_hw_h=\\sum_hN_h$$",
      "$$n_{\\text{eff}}=\\frac{\\left(\\sum w\\right)^2}{\\sum w^2},\\qquad \\text{deff}_w=\\frac{r}{n_{\\text{eff}}}=1+CV_w^2$$"
    ),
    explanation = paste(
      "Group the sample into **weighting classes** (for example age by sex, or region) and enter, for each class, the number of units in the",
      "population $N_h$, the number sampled $n_h$ and the number who responded $r_h$. A sampled unit stands for $d_h=N_h/n_h$ population units",
      "(its **design weight**); respondents also stand for the non-respondents of their class, so each respondent's **adjusted weight** is",
      "$d_h/RR_h = N_h/r_h$, and the adjusted weights add up to the population. This removes the bias from non-response only if, *within a class*,",
      "respondents resemble non-respondents -- choose classes that predict both response and the outcome.",
      "",
      "Unequal weights cost precision. **Kish's** approximation gives the design effect of the weighting, $1+CV_w^2$, and the **effective sample",
      "size** $n_{\\text{eff}}=r/\\text{deff}_w$: the number of equally weighted respondents that would give the same variance. Very large",
      "weights (small response in a large class) are a warning: merge classes or trim. A class with no respondents cannot be adjusted.",
      sep = "\\n"
    ),
    worked_example = paste(
      "Three classes with populations 500, 300, 200, samples 50, 50, 40 and respondents 40, 30, 35: design weights 10, 6, 5; response rates",
      "80%, 60%, 87.5%; adjusted weights 12.5, 10, 5.71; they add up to 1000. Weighted response rate 75.5%, Kish effective sample size 96.2 of",
      "105 respondents (design effect 1.09).",
      sep = "\\n"
    ),
    citation = paste(.survey_citation, "Kish L. Survey Sampling. New York: Wiley; 1965 (the design effect of unequal weights, 1 + CV^2; the formula was verified",
                     "numerically, the book was not read here)."),
    backend = "closed forms; identities and a Monte Carlo unbiasedness check in the unit tests"
  ),
  kish = list(
    title = "Effective sample size and design effect of a set of weights (Kish)",
    formula_latex = "$$n_{\\text{eff}}=\\frac{\\left(\\sum_i w_i\\right)^2}{\\sum_i w_i^2},\\qquad \\text{deff}_w=\\frac{n}{n_{\\text{eff}}}=1+CV_w^2$$",
    explanation = paste(
      "Paste the survey weights of your respondents (one number each, separated by spaces, commas or new lines). The app returns Kish's",
      "**effective sample size** and the **design effect due to weighting**: how much the variance of a mean grows because the weights",
      "differ. Equal weights give $n_{\\text{eff}}=n$ and a design effect of 1. This covers the effect of weighting only, not clustering or",
      "stratification; multiply by the cluster design effect separately.",
      sep = "\\n"
    ),
    worked_example = "Weights 1, 1, 2, 2: effective sample size 36/10 = 3.6 of 4, design effect 1.11.",
    citation = paste("Kish L. Survey Sampling. New York: Wiley; 1965 (formula verified numerically; the book was not read here);", .survey_citation),
    backend = "closed form; verified by identities (n sum w^2 / (sum w)^2 = 1 + CV^2)"
  )
)
