# Metadata for the Rule of Three module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_rule_of_three.R (SDD 4.2: "content is data, not
# hardcoded UI").

rule_of_three_content <- list(
  bound = list(
    title = "Upper Bound on an Unseen Event Rate (Rule of Three)",
    formula_latex = paste0(
      "$$\\text{exact: } U = 1 - \\alpha^{1/n} \\qquad ",
      "\\text{approx (}\\alpha=0.05\\text{): } U \\approx 3/n$$"
    ),
    explanation = paste(
      "If you observe *zero* events (e.g. adverse events) in n subjects,",
      "this calculator gives the upper confidence bound on the true event",
      "rate consistent with that observation -- \"absence of evidence isn't",
      "evidence of absence\", quantified. The exact bound solves",
      "P(zero events | true rate = U, n subjects) = alpha; for a 95% bound",
      "(alpha = 0.05) this is closely approximated by the well-known",
      "\"rule of three\": U ~ 3/n.",
      "",
      "- **n** - the number of subjects observed, with zero events seen.",
      "- **conf_level** - the confidence level for the bound, typically 0.95.",
      "",
      "This is a one-sided bound only (\"the true rate is unlikely to be",
      "higher than this\"), appropriate for safety monitoring where a study",
      "of modest size found no adverse events but can't rule out a",
      "meaningful underlying risk.",
      sep = "\n"
    ),
    worked_example = paste(
      "The classic illustration (Hanley & Lippman-Hand 1983): a trial",
      "enrolls n = 30 subjects and observes zero adverse events. This",
      "calculator returns an approximate upper 95% bound of 3/30 = 0.0999",
      "and an exact bound of 0.0950 -- i.e. a true adverse-event rate of up",
      "to about 10% cannot be ruled out, even though none were observed.",
      sep = "\n"
    ),
    citation = paste(
      "Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all",
      "right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745;",
      "Louis TA. Confidence intervals for a binomial parameter after",
      "observing no successes. Am Stat. 1981;35(3):154."
    ),
    backend = "closed-form (exact zero-events binomial bound + rule-of-three approximation)"
  ),

  n_required = list(
    title = "Sample Size to Detect at Least One Event",
    formula_latex = paste0(
      "$$n = \\left\\lceil \\frac{\\ln(\\alpha)}{\\ln(1-p)} \\right\\rceil \\qquad ",
      "\\text{approx (}\\alpha=0.05\\text{): } n \\approx 3/p$$"
    ),
    explanation = paste(
      "The complement of the bound above: given an assumed true event",
      "rate, how many subjects are needed for a target probability of",
      "observing *at least one* event -- useful for planning a",
      "surveillance or safety-monitoring sample so that a rare-but-",
      "important event isn't missed purely by bad luck.",
      "",
      "- **p** - the assumed true event rate (e.g. from a known background",
      "  incidence).",
      "- **conf_level** - the desired probability of observing at least one",
      "  event, typically 0.95.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an assumed true event rate of 1% (p = 0.01), this calculator",
      "returns an exact n = 299 (and an approximate n = 300, i.e. the",
      "\"3/p\" rule) to have a 95% chance of observing at least one event.",
      sep = "\n"
    ),
    citation = paste(
      "Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all",
      "right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745."
    ),
    backend = "closed-form (exact zero-events binomial bound + rule-of-three approximation)"
  ),

  detect_imperfect = list(
    title = "Detect at Least One Case, Imperfect Test (Finite Population)",
    formula_latex = paste0(
      "$$n_{\\text{hypergeometric}} \\text{ solved so that, at prevalence } d, ",
      "\\text{a test of sensitivity Se, specificity Sp detects} \\ge 1 \\text{ case with probability } \\ge \\text{conf.level}$$",
      "$$\\text{Series: } Se_{combined}=Se_1 Se_2,\\ Sp_{combined}=Sp_1+Sp_2-Sp_1 Sp_2 \\qquad ",
      "\\text{Parallel: } Se_{combined}=Se_1+Se_2-Se_1 Se_2,\\ Sp_{combined}=Sp_1 Sp_2$$"
    ),
    explanation = paste(
      "The more realistic, \"prove disease/defect freedom\" version of the",
      "sample-size design above: rather than assuming a perfect test and",
      "an effectively unlimited population, this accounts for a known,",
      "*finite* population size (a herd, a batch, a defined study area)",
      "and a diagnostic test with imperfect sensitivity and specificity --",
      "the standard veterinary/food-safety surveillance design (Cannon",
      "2001), equally applicable to any \"confirm the absence of a rare",
      "condition\" sampling problem.",
      "",
      "- **N** - the total population size (e.g. number of animals in a",
      "  herd, units in a batch, or individuals in a defined area).",
      "- **prev** - the prevalence you'd expect *if* the condition were",
      "  present (not the actual/unknown prevalence -- the point of the",
      "  study is to rule this out).",
      "- **Number of tests** - one, or two combined in series or",
      "  parallel.",
      "- **se, sp** (per test) - sensitivity and specificity; 1.00 for a",
      "  perfect (gold-standard) test recovers the simpler calculator",
      "  above.",
      "- **Series** (both tests must be positive to call a case positive)",
      "  raises combined specificity but lowers combined sensitivity;",
      "  **parallel** (either test positive suffices) does the reverse --",
      "  the classic sensitivity/specificity trade-off of combining",
      "  imperfect tests.",
      "- **conf_level** - the desired confidence that, if the condition",
      "  were present at the assumed prevalence, the sampling plan would",
      "  catch at least one case.",
      "",
      "The reported sample size uses the hypergeometric distribution",
      "(accounting for sampling without replacement from a finite",
      "population, per MacDiarmid 1988) -- always at least as large as,",
      "and typically close to, the simpler binomial/rule-of-three answer",
      "when N is large relative to n.",
      sep = "\n"
    ),
    worked_example = paste(
      "epiR's own documented examples (Cannon 2001; Dohoo, Martin & Stryhn",
      "2009): to confirm the absence of disease in a 1000-cow herd,",
      "expecting 5% prevalence if present, using a single test with 90%",
      "sensitivity and 100% specificity, this calculator returns n = 65",
      "cows to be 95% confident of detecting the disease if present. To",
      "document Mycoplasma absence in a 200-sow herd at a 20% threshold",
      "prevalence with a perfect test, it returns n = 15 sows. For a",
      "two-test example (N = 5000, prevalence 8%, test 1 90%/80%",
      "Se/Sp, test 2 95%/85% Se/Sp -- independently re-derived and",
      "cross-checked against the standard series/parallel combination",
      "formulas above): series interpretation gives combined",
      "Se/Sp = 0.855/0.970 and n = 44; parallel interpretation gives",
      "combined Se/Sp = 0.995/0.680 and n = 38 -- illustrating how",
      "parallel testing buys sensitivity (catching more true cases) at",
      "the cost of specificity (more false alarms), and vice versa for",
      "series testing.",
      sep = "\n"
    ),
    citation = paste(
      "Cannon RM. Sense and sensitivity -- designing surveys based on an",
      "imperfect test. Prev Vet Med. 2001;49(3-4):141-163. MacDiarmid S.",
      "Future options for brucellosis surveillance in New Zealand beef",
      "herds. N Z Vet J. 1988;36(1):39-42. Dohoo I, Martin W, Stryhn H.",
      "Veterinary Epidemiologic Research. 2nd ed. AVC Inc; 2009, p. 54."
    ),
    backend = "closed form (MacDiarmid 1988; Cannon 2001); identical to epiR 2.0.67 epi.ssdetect(), which it is tested against"
  )
)
