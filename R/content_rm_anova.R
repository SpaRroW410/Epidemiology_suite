# Metadata for the RM-ANOVA / Mixed ANOVA module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_rm_anova.R (SDD 4.2: "content is
# data, not hardcoded UI").

rm_anova_content <- list(
  between = list(
    title = "Repeated-Measures ANOVA -- Between-Subjects Effect",
    formula_latex = paste0(
      "$$df_1 = n_g - 1, \\quad df_2 = n - n_g, \\quad \\lambda = f^2 \\, n \\, \\epsilon$$",
      "$$\\text{Power} = P\\!\\left(F_{df_1, df_2, \\lambda} > F_{1-\\alpha; df_1, df_2}\\right)$$"
    ),
    explanation = paste(
      "Tests whether the between-subjects grouping factor (e.g. treatment",
      "arm) has an overall effect, averaged across the repeated",
      "measurements, in a repeated-measures or mixed (split-plot)",
      "ANOVA design.",
      "",
      "- **ng** - number of between-subjects groups (>= 2).",
      "- **nm** - number of repeated measurements/occasions (not used by",
      "  this particular effect, but requested for consistency with the",
      "  Within-Subjects and Interaction designs, since all three share",
      "  one design).",
      "- **f** - Cohen's f effect size (Cohen 1988): small = 0.10,",
      "  medium = 0.25, large = 0.40.",
      "- **nscor (epsilon)** - a nonsphericity correction coefficient in",
      "  (0, 1]; 1 = sphericity assumption fully met (Cohen's original",
      "  case). Lower values (down to 1/(nm-1)) inflate the required",
      "  sample size to compensate for violated sphericity.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "WebPower::wp.rmanova()'s own documented example: with 3 groups",
      "(ng = 3), 4 repeated measurements (nm = 4), effect size f = 0.36,",
      "and a nonsphericity correction of 0.7, a sample of n = 110 gives",
      "80.29% power -- this calculator solves the same equation for the",
      "sample size needed to reach 80% power and returns n = 110.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Lawrence Erlbaum Associates; 1988. Reference implementation:",
      "Zhang Z, Yuan K-H. WebPower: Basic and Advanced Statistical Power",
      "Analysis. R package."
    ),
    backend = "closed-form (Cohen 1988; WebPower::wp.rmanova() algorithm, type = 0)"
  ),

  within = list(
    title = "Repeated-Measures ANOVA -- Within-Subjects Effect",
    formula_latex = paste0(
      "$$df_1 = (n_m - 1)\\epsilon, \\quad df_2 = (n - n_g)\\,df_1, ",
      "\\quad \\lambda = f^2 \\, n \\, \\epsilon$$",
      "$$\\text{Power} = P\\!\\left(F_{df_1, df_2, \\lambda} > F_{1-\\alpha; df_1, df_2}\\right)$$"
    ),
    explanation = paste(
      "Tests whether the repeated-measurement factor itself (e.g. change",
      "across time points) has an effect, averaged across the",
      "between-subjects groups.",
      "",
      "- **ng** - number of between-subjects groups (>= 1; a single-group",
      "  purely-repeated-measures design is fine here).",
      "- **nm** - number of repeated measurements/occasions (>= 2).",
      "- **f** - Cohen's f effect size for the within-subjects effect.",
      "- **nscor (epsilon)** - nonsphericity correction, as above.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "With 2 groups (ng = 2), 3 repeated measurements (nm = 3), effect",
      "size f = 0.25, and a nonsphericity correction of 0.8, this",
      "calculator returns n = 182 to reach 80% power for the",
      "within-subjects effect (cross-verified by directly running",
      "WebPower::wp.rmanova()'s own extracted algorithm with the same",
      "inputs, since this specific design combination isn't in that",
      "package's own published examples).",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Lawrence Erlbaum Associates; 1988. Reference implementation:",
      "Zhang Z, Yuan K-H. WebPower: Basic and Advanced Statistical Power",
      "Analysis. R package."
    ),
    backend = "closed-form (Cohen 1988; WebPower::wp.rmanova() algorithm, type = 1)"
  ),

  interaction = list(
    title = "Repeated-Measures / Mixed ANOVA -- Group x Time Interaction",
    formula_latex = paste0(
      "$$df_1 = (n_g - 1)(n_m - 1)\\epsilon, \\quad df_2 = (n - n_g)(n_m - 1)\\epsilon, ",
      "\\quad \\lambda = f^2 \\, n \\, \\epsilon$$",
      "$$\\text{Power} = P\\!\\left(F_{df_1, df_2, \\lambda} > F_{1-\\alpha; df_1, df_2}\\right)$$"
    ),
    explanation = paste(
      "Tests whether the effect of the repeated-measurement factor",
      "differs across the between-subjects groups (e.g. whether one",
      "treatment arm changes over time differently from another) -- the",
      "classic \"mixed (split-plot) ANOVA\" interaction test.",
      "",
      "- **ng** - number of between-subjects groups (>= 2).",
      "- **nm** - number of repeated measurements/occasions (>= 2).",
      "- **f** - Cohen's f effect size for the interaction.",
      "- **nscor (epsilon)** - nonsphericity correction, as above.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "With 3 groups (ng = 3), 3 repeated measurements (nm = 3), effect",
      "size f = 0.25, and a nonsphericity correction of 0.8, this",
      "calculator returns n = 226 to reach 80% power for the",
      "group-by-time interaction (again cross-verified by directly",
      "running WebPower::wp.rmanova()'s own extracted algorithm with the",
      "same inputs).",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Lawrence Erlbaum Associates; 1988. Reference implementation:",
      "Zhang Z, Yuan K-H. WebPower: Basic and Advanced Statistical Power",
      "Analysis. R package."
    ),
    backend = "closed-form (Cohen 1988; WebPower::wp.rmanova() algorithm, type = 2)"
  )
)
