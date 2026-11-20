# Metadata for the Resource Equation module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_resource_equation.R (SDD 4.2: "content is data, not
# hardcoded UI").

resource_equation_content <- list(
  size = list(
    title = "Resource Equation Method -- Recommended Sample Size",
    formula_latex = "$$E = N - T, \\quad 10 \\le E \\le 20 \\text{ (Mead's rule of thumb)}$$",
    explanation = paste(
      "Use this for small, exploratory *animal* studies where a formal",
      "power calculation isn't feasible (e.g. no prior estimate of the",
      "effect size or its variability exists yet). Rather than targeting",
      "a specific power, the resource equation method sizes the study",
      "via the *error degrees of freedom* E of the planned ANOVA-style",
      "analysis: E = N (total experimental units) minus T (total number",
      "of treatment groups). Mead's rule of thumb: E between 10 and 20",
      "gives an adequate chance of detecting a real difference without",
      "committing more animals than needed -- E<10 risks being",
      "underpowered; E>20 gives little further benefit and wastes",
      "animals (an important ethical/3Rs consideration in animal",
      "research).",
      "",
      "- **Number of groups (T)** - the number of treatment/comparison",
      "  groups in the study.",
      "- **Target E** - the desired error degrees of freedom, typically",
      "  10 (minimum adequate) up to 20 (comfortable upper bound).",
      "",
      "This calculator solves N = T + E and divides evenly across groups",
      "for the recommended total and per-group sample size. A companion",
      "\"check adequacy\" mode does the reverse: given a chosen number of",
      "groups and animals per group, computes E and classifies it as too",
      "low, adequate, or more than needed.",
      sep = "\n"
    ),
    worked_example = paste(
      "Charan & Kantharia (2013)'s own worked example: a researcher",
      "studying a drug's effect on rats divides them into 5 groups",
      "(T=5) with 10 rats each (N=50). Checking adequacy: E = 50 - 5 =",
      "45 -- well above 20, meaning the study committed far more animals",
      "than the resource equation method calls for. This calculator's",
      "\"check adequacy\" mode reproduces E=45 exactly and flags it as",
      "\"more than needed\". Using the sizing mode instead with the same",
      "5 groups and a target E=10 (the minimum adequate value) gives a",
      "recommended N=15 (3 per group) -- a much smaller, still-adequate",
      "study.",
      sep = "\n"
    ),
    citation = paste(
      "Mead R. The Design of Experiments: Statistical Principles for",
      "Practical Applications. Cambridge University Press, 1988.",
      "Charan J, Kantharia ND. How to calculate sample size in animal",
      "studies? J Pharmacol Pharmacother. 2013;4(4):303-306."
    ),
    backend = "Direct arithmetic (E = N - T) -- no package needed"
  )
)
