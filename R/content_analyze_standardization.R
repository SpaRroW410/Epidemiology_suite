# Metadata for the Analyze: Standardization module (ROADMAP Track B1): formula text,
# plain-language explanation, worked example and citation per design. Content is
# data, rendered generically by mod_analyze_standardization.R.

.analyze_std_citation_direct <- paste(
  "Fay MP, Feuer EJ. Confidence intervals for directly standardized rates: a method based on the gamma",
  "distribution. Stat Med 1997;16:791-801; Dobson AJ, Kuulasmaa K, Eberle E, Scherer J. Confidence intervals for",
  "weighted sums of Poisson parameters. Stat Med 1991;10:457-462; Haneuse S, Rothman KJ. Stratification and",
  "standardization. In: Lash TL, et al. Modern Epidemiology, 4th ed. 2021; Thrusfield M. Veterinary Epidemiology.",
  "Blackwell; 2007, pp. 63-64 (worked example, as cited in the epiR help page). The comparison of two standardized",
  "rates uses a delta-method standard error derived here and checked by simulation.",
  "Cross-checked against epiR::epi.directadj()."
)

analyze_std_content <- list(
  direct = list(
    title = "Direct standardization: age-standardized rates and their comparison",
    formula_latex = paste0(
      "$$DSR=\\sum_i w_i\\,\\frac{d_i}{T_i},\\qquad w_i=\\frac{\\text{standard}_i}{\\sum_j \\text{standard}_j},\\qquad ",
      "v=\\sum_i w_i^2\\,\\frac{d_i}{T_i^2}$$",
      "$$\\text{Fay-Feuer 95\\% CI: }\\ \\left[\\,G^{-1}\\!\\left(\\tfrac\\alpha2;\\tfrac{DSR^2}{v},\\tfrac{v}{DSR}\\right),\\ ",
      "G^{-1}\\!\\left(1-\\tfrac\\alpha2;\\tfrac{(DSR+w_m)^2}{v+w_m^2},\\tfrac{v+w_m^2}{DSR+w_m}\\right)\\right],\\ w_m=\\max_i\\frac{w_i}{T_i}$$",
      "$$\\ln\\frac{DSR_A}{DSR_B}\\ \\text{has}\\ \\operatorname{SE}=\\sqrt{\\frac{v_A}{DSR_A^2}+\\frac{v_B}{DSR_B^2}},\\qquad ",
      "\\operatorname{SE}(DSR_A-DSR_B)=\\sqrt{v_A+v_B}$$"
    ),
    explanation = paste(
      "Rates for different populations are not comparable if the populations differ in, say, age structure.",
      "**Direct standardization** applies each population's own stratum-specific rates $d_i/T_i$ to the *same*",
      "**standard population**, so the resulting rates differ only because the stratum rates differ.",
      "",
      "Enter, per stratum (age band, sex, ...), the **events** and the **person-time** (or population at risk) of the",
      "study group, and the size of the **standard population** in that stratum; only the proportions matter.",
      "Optionally add a **second group** over the same strata to compare the two standardized rates by their ratio",
      "and difference (normal-scale intervals; a first-order approximation).",
      "",
      "Every stratum with a non-zero standard weight needs person-time. Strata with few events make the",
      "standardized rate unstable; the Fay-Feuer gamma interval is designed for that case. The crude rate is shown",
      "for comparison, with an exact Poisson interval.",
      sep = "\n"
    ),
    worked_example = paste(
      "Thrusfield (2007), as in the `epiR::epi.directadj()` help page: leptospirosis in dogs, stratified by sex.",
      "Edinburgh: 15 cases in 48 male dog-years and 46 in 212 female dog-years; Glasgow: 53 in 180 and 16 in 71.",
      "Standard population: 250 males, 250 females. Crude rates 0.235 (Edinburgh) and 0.275 (Glasgow) per dog-year,",
      "but **sex-standardized** rates 0.265 (95% CI 0.187 to 0.369) and **0.260 (0.196 to 0.341)** -- the published",
      "26 per 100 dog-years (95% CI 20 to 34) for Glasgow, reproduced here.",
      sep = "\n"
    ),
    citation = .analyze_std_citation_direct,
    backend = "closed forms and gamma quantiles (Fay-Feuer); verified against epiR::epi.directadj() and the published Thrusfield example"
  ),
  indirect = list(
    title = "Indirect standardization: expected events and the standardized ratio (SMR)",
    formula_latex = paste0(
      "$$E=\\sum_i r_i\\,T_i,\\qquad SMR=\\frac{O}{E}$$",
      "$$\\text{exact 95\\% CI: }\\ \\left[\\frac{\\chi^2_{\\alpha/2,\\,2O}}{2E},\\ \\frac{\\chi^2_{1-\\alpha/2,\\,2(O+1)}}{2E}\\right]$$"
    ),
    explanation = paste(
      "Use **indirect standardization** when the study group is small or its stratum-specific rates are unreliable",
      "or unknown, but you have its person-time $T_i$ in each stratum and **reference rates** $r_i$ from a larger",
      "population. Multiplying gives the **expected** number of events $E$ if the group had the reference rates;",
      "the **standardized mortality (or morbidity) ratio** is $SMR=O/E$ with $O$ the observed number of events.",
      "",
      "The confidence interval treats $E$ as fixed and $O$ as Poisson: the **exact** (Garwood) interval and the less",
      "conservative **mid-P** interval are shown, with exact and mid-P tests of SMR = 1. SMRs of different groups",
      "standardized to the same reference are **not strictly comparable** with each other, because each uses its own",
      "stratum weights; compare each with 1 or use direct standardization for comparisons.",
      sep = "\n"
    ),
    worked_example = paste(
      "Adapted from the `epiR::epi.indirectadj()` help example (after Dohoo, Martin and Stryhn 2009): area A has",
      "550 beef herds and 450 dairy herds at risk; the reference incidences are 25 and 85 cases per 1000 herds. The",
      "expected number of cases is 550 x 0.025 + 450 x 0.085 = 52, and 58 were observed: SMR = 58/52 = 1.12",
      "(exact 95% CI 0.85 to 1.44; exact test p = 0.40). The expected count and SMR equal epiR's; the exact interval",
      "equals `poisson.test(58, 52)` (epiR's own SMR interval is a quantile-based variant and is not copied).",
      sep = "\n"
    ),
    citation = paste(
      "Breslow NE, Day NE. Statistical Methods in Cancer Research, Vol II: The Design and Analysis of Cohort Studies.",
      "IARC; 1987 (indirect standardization, SMR); Ulm K. A simple method to calculate the confidence interval of a",
      "standardized mortality ratio (SMR). Am J Epidemiol 1990;131:373-375 (exact interval); Lancaster HO. J Am Stat",
      "Assoc 1961;56:223-234 and Berry G, Armitage P. The Statistician 1995;44:417-423 (mid-P). The expected counts",
      "are checked against epiR::epi.indirectadj() and the exact interval against stats::poisson.test()."
    ),
    backend = "closed forms (Poisson quantiles); verified against stats::poisson.test() and epiR::epi.indirectadj() (expected counts)"
  ),
  smr = list(
    title = "SMR from observed and expected events",
    formula_latex = paste0(
      "$$SMR=\\frac{O}{E},\\qquad \\text{exact 95\\% CI: }\\ \\left[\\frac{\\chi^2_{\\alpha/2,\\,2O}}{2E},\\ \\frac{\\chi^2_{1-\\alpha/2,\\,2(O+1)}}{2E}\\right]$$"
    ),
    explanation = paste(
      "If you already have the **observed** number of events $O$ and the **expected** number $E$ (from published",
      "reference rates, or from a registry's own calculation), enter them directly. The SMR is $O/E$; the confidence",
      "interval and tests treat $E$ as fixed and $O$ as a Poisson count (exact and mid-P).",
      sep = "\n"
    ),
    worked_example = paste(
      "58 events observed, 52 expected: SMR = 1.12, exact 95% CI 0.85 to 1.44, mid-P CI 0.85 to 1.43, exact test",
      "p = 0.40; equal to `poisson.test(58, 52)`.",
      sep = "\n"
    ),
    citation = paste(
      "Breslow NE, Day NE. Statistical Methods in Cancer Research, Vol II. IARC; 1987; Ulm K. Am J Epidemiol",
      "1990;131:373-375 (exact interval); Berry G, Armitage P. The Statistician 1995;44:417-423 (mid-P)."
    ),
    backend = "closed forms (Poisson quantiles); verified against stats::poisson.test()"
  )
)
