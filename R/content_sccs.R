# Metadata for the Self-Controlled Case Series (SCCS) module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_sccs.R (SDD 4.2: "content is data, not
# hardcoded UI").

sccs_content <- list(
  samplesize = list(
    title = "Self-Controlled Case Series (SCCS)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}+Z_{power}\\sqrt{B}\\right)^2}{A}$$",
      "$$A = 2\\sum_j v_j\\left[\\pi_j\\log(\\rho) - \\log(r_j\\rho+1-r_j)\\right], \\qquad ",
      "B = \\frac{[\\log(\\rho)]^2}{A}\\sum_j v_j\\pi_j(1-\\pi_j)$$"
    ),
    explanation = paste(
      "Use this for a **self-controlled case series (SCCS)** study --",
      "cases only (no separate control group) are followed over an",
      "observation period, and each case's own event-free time serves as",
      "their control: the rate of events during a defined \"risk period\"",
      "(e.g. shortly after a vaccine or drug exposure) is compared to the",
      "rate during the rest of their own observation time. Only cases who",
      "experience the event of interest are needed -- no unaffected",
      "controls -- which makes SCCS efficient for studying transient,",
      "vaccine/drug-associated risks.",
      "",
      "- **eexpo** - the design value of the exposure-associated relative",
      "  incidence you want to be able to detect (> 1 for increased risk",
      "  during the risk period; < 1 for decreased risk).",
      "- **risk** - the length of the risk period (e.g. days after",
      "  exposure); must be shorter than the shortest age group (or the",
      "  whole observation period, if no age groups are used).",
      "- **astart, aend** - the age (or calendar-time) bounds of the",
      "  observation period, same units as risk.",
      "- **p** - the proportion of the case population expected to be",
      "  exposed (default 1, i.e. no age effects and everyone exposed); if",
      "  age effects are included, one entry per age group, summing to at",
      "  most 1.",
      "- **eage, agegrp** (optional) - age-group relative-incidence",
      "  parameters and their cut points, for when the baseline event",
      "  rate itself varies by age (the first age group is the reference).",
      "- **alpha, power** - as elsewhere (two-sided test).",
      sep = "\n"
    ),
    worked_example = paste(
      "Musonda, Farrington & Whitaker (2006)'s own worked examples,",
      "reproduced by the `SCCS` package's documentation: eexpo = 2.5,",
      "risk = 21, astart = 366, aend = 730, alpha = 0.05, 80% power.",
      "With no age effects and all cases exposed (p = 1), this calculator",
      "returns n = 110; with 75% of cases exposed (p = 0.75), n = 143;",
      "and with age effects included (p = c(0.50, 0.35, 0.1, 0.05),",
      "eage = c(1.2, 1.6, 2.0), agegrp = c(457, 548, 639)), n = 132 --",
      "all three matching the package's own documented examples exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Musonda P, Farrington CP, Whitaker HJ. Sample sizes for",
      "self-controlled case series studies. Stat Med. 2006;25(15):",
      "2618-2631."
    ),
    backend = "closed-form (Musonda, Farrington & Whitaker 2006)"
  )
)
