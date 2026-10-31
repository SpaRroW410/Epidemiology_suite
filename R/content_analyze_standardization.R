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

.analyze_smr_formulas <- paste0(
  "$$SMR=\\frac{O}{E}\\qquad \\text{Exact: }\\ \\left[\\frac{\\chi^2_{\\alpha/2,\\,2O}}{2E},\\ \\frac{\\chi^2_{1-\\alpha/2,\\,2(O+1)}}{2E}\\right]$$",
  "$$\\text{Byar: }\\ \\frac{O\\left(1-\\frac1{9O}-\\frac{z}{3\\sqrt O}\\right)^3}{E}\\ \\text{to}\\ \\frac{(O+1)\\left(1-\\frac1{9(O+1)}+\\frac{z}{3\\sqrt{O+1}}\\right)^3}{E}$$",
  "$$\\text{Rothman-Greenland: }\\ SMR\\cdot e^{\\pm z/\\sqrt O},\\qquad \\text{Vandenbroucke: }\\ \\frac{(\\sqrt O\\mp z/2)^2}{E},\\qquad \\text{Wald: }\\ \\frac{O\\pm z\\sqrt O}{E}$$",
  "The mid-P exact limits solve $P(X>O)+\\tfrac12P(X=O)=\\alpha/2$ (lower) and $P(X<O)+\\tfrac12P(X=O)=\\alpha/2$ (upper) ",
  "for a Poisson mean $\\lambda$, divided by $E$."
)

.analyze_smr_methods_text <- paste(
  "- **Exact (Garwood / Ulm / Liddell)** treats $O$ as Poisson and inverts the Poisson distribution through the",
  "  chi-square distribution. It never undercovers, but is conservative (wide). The usual choice when $O$ is small.",
  "- **Mid-P exact** gives the observed count only half weight in each tail: still based on the exact distribution,",
  "  but narrower and closer to nominal coverage on average.",
  "- **Byar** is a cube-root (Wilson-Hilferty type) approximation to the exact limits and tracks them closely once",
  "  $O$ is moderate.",
  "- **Rothman-Greenland** assumes $\\ln SMR$ is normal with variance $1/O$; it is undefined at $O=0$ and poor for small $O$.",
  "- **Vandenbroucke** is a square-root (variance-stabilizing) shortcut: $\\sqrt O$ is roughly normal with variance 1/4.",
  "- **Wald** is $O\\pm z\\sqrt O$ over $E$; shown only for comparison (zero width at $O=0$).",
  "",
  "Guidance from the `epiR` documentation: exact intervals and tests when the observed count is 5 or fewer, the",
  "approximations for larger counts. The tests of SMR = 1 are the exact Poisson test, its mid-P version, the",
  "chi-square statistic $(O-E)^2/E$ and Byar's normal approximation. The expected count $E$ is treated as fixed",
  "(known); SMRs of different groups, each standardized with its own stratum weights, are **not strictly comparable**",
  "with each other.",
  "",
  "Which interval to trust is your decision: if they agree, the choice does not matter; if they disagree (small $O$),",
  "report the exact or mid-P interval and say which you used.",
  sep = "\n"
)

.analyze_smr_citation <- paste(
  "Exact: Liddell FDK. Simple exact analysis of the standardised mortality ratio. J Epidemiol Community Health",
  "1984;38:85-88; Ulm K. A simple method to calculate the confidence interval of a standardized mortality ratio",
  "(SMR). Am J Epidemiol 1990;131:373-375; Breslow NE, Day NE. Statistical Methods in Cancer Research, Vol II. IARC;",
  "1987. Mid-P: Miettinen OS. Comment. J Am Stat Assoc 1974;69:380-382; Rothman K, Boice J. Epidemiologic Analysis",
  "with a Programmable Calculator. NIH Publication 79-1649; 1979. Byar's approximation: attributed to Byar",
  "(unpublished) by Rothman & Boice 1979 and given in Breslow & Day 1987. Rothman-Greenland: Lash TL, VanderWeele TJ,",
  "Haneuse S, Rothman KJ. Modern Epidemiology, 4th ed. 2021. Vandenbroucke JP. A shortcut method for calculating the",
  "95 per cent confidence interval of the standardized mortality ratio (letter). Am J Epidemiol 1982;115:303-304.",
  "Verification: the existence, journal, volume and pages of these references were checked by web search; the",
  "original papers could not be read, so each formula was checked numerically against epiR 3.0.0 epi.smr(),",
  "stats::poisson.test() and DescTools::PoissonCI() instead. Not offered: the Ury-Wiggins (1985) shortcut, whose",
  "constants could not be verified, and epiR's 'fisher' confidence limits, whose lower limit differs from the exact",
  "(Garwood) lower limit by an apparent off-by-one."
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
    formula_latex = .analyze_smr_formulas,
    explanation = paste(
      "Use **indirect standardization** when the study group is small or its stratum-specific rates are unreliable",
      "or unknown, but you have its person-time $T_i$ in each stratum and **reference rates** $r_i$ from a larger",
      "population. Multiplying gives the **expected** number of events $E=\\sum_i r_iT_i$ if the group had the",
      "reference rates; the **standardized mortality (or morbidity) ratio** is $SMR=O/E$ with $O$ the observed number",
      "of events.",
      "",
      .analyze_smr_methods_text,
      sep = "\n"
    ),
    worked_example = paste(
      "Adapted from the `epiR::epi.indirectadj()` help example (after Dohoo, Martin and Stryhn 2009): area A has",
      "550 beef herds and 450 dairy herds at risk; the reference incidences are 25 and 85 cases per 1000 herds. The",
      "expected number of cases is 550 x 0.025 + 450 x 0.085 = 52, and 58 were observed: SMR = 58/52 = 1.12. The",
      "intervals by method are shown in the app (exact 0.85 to 1.44, mid-P 0.85 to 1.43, Byar 0.85 to 1.44,",
      "Rothman-Greenland 0.86 to 1.44, Vandenbroucke 0.85 to 1.42, Wald 0.83 to 1.40); with 58 events they all agree",
      "closely. The expected count equals epiR's.",
      sep = "\n"
    ),
    citation = .analyze_smr_citation,
    backend = "closed forms (Poisson/chi-square quantiles, approximations); checked against epiR 3.0.0 epi.smr(), stats::poisson.test(), DescTools::PoissonCI() and epiR::epi.indirectadj() (expected counts)"
  ),
  smr = list(
    title = "SMR from observed and expected events",
    formula_latex = .analyze_smr_formulas,
    explanation = paste(
      "If you already have the **observed** number of events $O$ and the **expected** number $E$ (from published",
      "reference rates, or from a registry's own calculation), enter them directly. The SMR is $O/E$. Several confidence",
      "intervals are shown side by side:",
      "",
      .analyze_smr_methods_text,
      sep = "\n"
    ),
    worked_example = paste(
      "The epiR help example: 4 events observed, 3.3 expected. SMR = 1.21; mid-P exact 95% CI 0.39 to 2.92 (p = 0.657);",
      "exact 0.33 to 3.10; Byar 0.33 to 3.10; Rothman-Greenland 0.45 to 3.23; Vandenbroucke 0.32 to 2.69. With so few",
      "events the methods visibly disagree -- the reason they are all shown.",
      sep = "\n"
    ),
    citation = .analyze_smr_citation,
    backend = "closed forms (Poisson/chi-square quantiles, approximations); checked against epiR 3.0.0 epi.smr(), stats::poisson.test() and DescTools::PoissonCI()"
  )
)
