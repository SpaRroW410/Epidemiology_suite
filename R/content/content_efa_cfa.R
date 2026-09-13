# Metadata for the EFA/CFA Subjects-Per-Item Guidance module. Content is
# data, rendered generically by mod_efa_cfa.R (SDD 4.2: "content is data,
# not hardcoded UI").
#
# Like the Pilot/Feasibility module, this is a rule-of-thumb calculator,
# not a solved hypothesis-test formula -- there is no single accepted
# power formula for factor-analysis sample size.

efa_cfa_content <- list(
  rule_of_thumb = list(
    title = "EFA/CFA Subjects-Per-Item Sample Size",
    formula_latex = paste0(
      "$$N_{5:1} = 5 \\times k, \\quad N_{10:1} = 10 \\times k, ",
      "\\quad N_{20:1} = 20 \\times k$$",
      "$$k = \\text{number of items (EFA) or free parameters (CFA/SEM)}$$"
    ),
    explanation = paste(
      "There is no accepted power formula for exploratory or confirmatory",
      "factor analysis sample size the way there is for a hypothesis",
      "test -- the field instead relies on published participant-to-item",
      "(or participant-to-parameter) ratios, refined over decades of",
      "methodological work. Treat any number below as a starting point,",
      "not a target to defend statistically.",
      "",
      "**Costello & Osborne (2005) ratios.** Reviewing common practice",
      "and simulation evidence, they summarize: 5:1 as an absolute",
      "minimum, 10:1 commonly recommended, and up to 20:1 for a more",
      "robust and stable factor solution.",
      "",
      "**Comrey & Lee (1992) absolute-N scale.** Independently of item",
      "count, they propose adjective labels for the resulting total N:",
      "50 = very poor, 100 = poor, 200 = fair, 300 = good, 500 = very",
      "good, 1000+ = excellent. The calculator below reports which label",
      "each of the three ratio-based N's falls into.",
      "",
      "**The important caveat (MacCallum, Widaman, Zhang & Hong 1999).**",
      "A fixed ratio-only rule can be badly wrong in either direction: the",
      "authors show required N depends heavily on the COMMUNALITY level",
      "(how strongly items load on their factors) and on how",
      "OVERDETERMINED the factors are (how many items mark each factor).",
      "Low communality can need a much larger N than any of these ratios",
      "suggest, regardless of item count; high communality with several",
      "items per factor can need less. Use these ratios as a starting",
      "point when nothing else is known, not a substitute for planning",
      "around your study's actual expected communalities when that",
      "information is available.",
      sep = "\n"
    ),
    worked_example = paste(
      "A 20-item scale: 5:1 -> N=100 (\"poor\" on the Comrey & Lee scale);",
      "10:1 -> N=200 (\"fair\"); 20:1 -> N=400 (\"good\"). A shorter 6-item",
      "scale needs far fewer participants by these ratios (N=30/60/120),",
      "but MacCallum et al.'s caveat matters most exactly in these smaller",
      "cases: a 6-item scale with low communalities can still need a much",
      "larger N than 120 to recover a stable factor structure.",
      sep = "\n"
    ),
    citation = paste(
      "Costello AB, Osborne JW. Best practices in exploratory factor",
      "analysis: four recommendations for getting the most from your",
      "analysis. Pract Assess Res Eval. 2005;10(7). Comrey AL, Lee HB. A",
      "First Course in Factor Analysis. 2nd ed. Erlbaum, 1992. MacCallum",
      "RC, Widaman KF, Zhang S, Hong S. Sample size in factor analysis.",
      "Psychol Methods. 1999;4(1):84-99."
    ),
    backend = "Closed-form rule-of-thumb ratios (Costello & Osborne 2005; Comrey & Lee 1992 adjective lookup); no external package required"
  )
)
