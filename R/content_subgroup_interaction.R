# Metadata for the Subgroup / Interaction Testing module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_subgroup_interaction.R (SDD 4.2:
# "content is data, not hardcoded UI").

subgroup_interaction_content <- list(
  standard = list(
    title = "Subgroup / Interaction Testing -- the \"4x Rule\"",
    formula_latex = paste0(
      "$$N_{\\text{interaction}} = N_{\\text{main effect}} \\times ",
      "\\frac{4}{r^2}, \\quad r = \\frac{\\delta_{\\text{interaction}}}{\\delta_{\\text{main effect}}}$$"
    ),
    explanation = paste(
      "Testing whether a treatment effect *differs* between two",
      "subgroups (a treatment-by-subgroup interaction) needs a much",
      "larger sample than testing the treatment effect itself. This is",
      "a well-known but often-overlooked pitfall: a trial with 80% power",
      "for its main effect can have as little as ~29% power to detect",
      "an interaction of the same magnitude (Brookes et al. 2004).",
      "",
      "This is a general multiplier, applicable on top of ANY already-",
      "computed two-group comparison in this app (means, proportions,",
      "survival, etc.) -- not a new statistical test in its own right.",
      "",
      "- **Main-effect total sample size** - the total N (both arms",
      "  combined) you've already computed elsewhere in this app for the",
      "  main treatment effect.",
      "- **Effect ratio** - how large the interaction you want to detect",
      "  is, relative to the main effect's magnitude. 1.0 means an",
      "  interaction the SAME size as the main effect (Brookes et al.'s",
      "  headline scenario, needing 4x the sample size); 0.5 means an",
      "  interaction HALF the main effect's size (needing 16x); smaller",
      "  ratios need dramatically more, with no upper limit as the ratio",
      "  shrinks.",
      "",
      "The 4/r-squared multiplier can be derived directly: the",
      "interaction test statistic is a difference of two independent",
      "group-differences, so its variance is exactly double a single",
      "group-difference's variance; solving each design (main effect vs.",
      "interaction) for its own required N at the same alpha/power gives",
      "exactly this ratio.",
      sep = "\n"
    ),
    worked_example = paste(
      "Brookes et al. (2004)'s own headline finding: a trial sized for",
      "80% power to detect a main effect had only ~29% power to detect",
      "an interaction of the SAME magnitude using that same sample size",
      "-- i.e. detecting that interaction at 80% power instead would need",
      "about 4x the original sample size. This calculator reproduces",
      "that exactly: main-effect total N=100, effect ratio=1.0 -> 400",
      "needed for the interaction test (multiplier=4.0). The paper also",
      "reports that for an interaction HALF the main effect's magnitude,",
      "the inflation factor rises to 16 -- also reproduced exactly here:",
      "main-effect total N=100, effect ratio=0.5 -> 1,600 needed",
      "(multiplier=16.0). Both figures were additionally verified",
      "independently in this app's own development by directly deriving",
      "the required-N formula from first principles (z-based power",
      "calculations for a main-effect vs. a difference-of-differences",
      "test) rather than only trusting the paper's summary numbers.",
      sep = "\n"
    ),
    citation = paste(
      "Brookes ST, Whitely E, Egger M, Davey Smith G, Mulheran PA,",
      "Peters TJ. Subgroup analyses in randomized trials: risks of",
      "subgroup-specific analyses; power and sample size for the",
      "interaction test. J Clin Epidemiol. 2004;57(3):229-236."
    ),
    backend = "Direct arithmetic multiplier (4/effect_ratio^2), independently re-derived from first principles -- no package needed"
  )
)
