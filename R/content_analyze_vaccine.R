# Metadata for the Analyze: Vaccine Efficacy module (ROADMAP Track B1): formula text,
# plain-language explanation, worked example and citation per design. Content is data,
# rendered generically by mod_analyze_vaccine.R.

.vaccine_citation <- paste(
  "Orenstein WA, Bernier RH, Dondero TJ, Hinman AR, Marks JS, Bart KJ, Sirotkin B. Field evaluation of vaccine efficacy.",
  "Bull World Health Organ 1985;63(6):1055-1068 (VE = (ARU - ARV)/ARU = 1 - RR; existence, volume and pages confirmed by",
  "web search, the paper itself could not be read here). The interval methods are those of the ratio tools they reuse:",
  "Koopman PAR. Confidence intervals for the ratio of two binomial proportions. Biometrics 1984;40:513-517; Katz D, Baptista J,",
  "Azen SP, Pike MC. Biometrics 1978;34:469-474; Woolf B. Ann Hum Genet 1955;19:251-253; Clopper CJ, Pearson ES. Biometrika",
  "1934;26:404-413 (exact); Lancaster HO. J Am Stat Assoc 1961;56:223-234 (mid-P). The interval for VE is simply 1 minus",
  "the interval for the ratio with the limits swapped. This tool was cross-checked against epiR::epi.2by2() and the",
  "definition; it makes no adjustment for confounding, waning or misclassification."
)

analyze_vaccine_content <- list(
  risk = list(
    title = "Vaccine efficacy from attack rates (cases and participants)",
    formula_latex = paste0(
      "$$VE=1-RR=\\\\frac{ARU-ARV}{ARU},\\\\qquad RR=\\\\frac{x_V/n_V}{x_U/n_U}$$",
      "$$\\\\text{CI for }VE:\\\\ \\\\left[\\\\,1-RR_{upper},\\\\ 1-RR_{lower}\\\\,\\\\right]$$"
    ),
    explanation = paste(
      "Enter the number of **cases** and the number of **participants** in the vaccinated and the unvaccinated (or placebo)",
      "group. **Vaccine efficacy** (from a randomized trial) or **effectiveness** (observational, routine use) is the",
      "proportionate reduction in the attack rate: $VE = 1 - RR$. 100% means no cases among the vaccinated, 0% no effect,",
      "and a negative value means more disease among the vaccinated.",
      "",
      "The confidence limits are one minus the limits of the risk ratio, shown by three methods side by side: **Koopman**",
      "score (the usual recommendation), **Katz** log and the **adjusted log** (+1/2, which stays defined when a group",
      "has no cases). The choice is yours.",
      "",
      "This is a crude comparison: it does not adjust for confounding (use stratified analysis or a regression model),",
      "assumes everyone was followed for the same period, and does not model waning. For unequal follow-up use the",
      "person-time version.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustrative numbers (not a real trial): 8 cases among 1000 vaccinated and 160 among 1000 unvaccinated participants.",
      "Risk ratio 0.05, so **VE = 95.0%**; Koopman 95% CI 90.0% to 97.5%, Katz 89.9% to 97.5%.",
      sep = "\n"
    ),
    citation = .vaccine_citation,
    backend = "1 - the Koopman / Katz / adjusted-log limits of calc_analyze_compare_proportions(); checked against epiR::epi.2by2()"
  ),
  rate = list(
    title = "Vaccine efficacy from incidence rates (cases and person-time)",
    formula_latex = paste0(
      "$$VE=1-IRR=1-\\\\frac{d_V/T_V}{d_U/T_U}$$",
      "$$\\\\text{Exact: }\\\\ IRR\\\\in\\\\left[\\\\tfrac{p_L}{1-p_L}\\\\tfrac{T_U}{T_V},\\\\ \\\\tfrac{p_U}{1-p_U}\\\\tfrac{T_U}{T_V}\\\\right],\\\\ [p_L,p_U]=\\\\text{Clopper-Pearson for }d_V/(d_V+d_U)$$"
    ),
    explanation = paste(
      "Enter the **cases** and the **person-time** (for example person-years, or days at risk) in the vaccinated and the",
      "unvaccinated group. This is the right version when follow-up differs between people or groups. $VE = 1 - IRR$, the",
      "proportionate reduction in the incidence rate.",
      "",
      "Limits are one minus the limits of the incidence rate ratio: **exact conditional** (the usual default),",
      "**mid-P exact** (less conservative) and **Wald** on the log scale (for comparison; unreliable with few cases).",
      "The exact method conditions on the total number of cases: given that total, the vaccinated share is binomial.",
      "",
      "As with the other versions the result is crude: no adjustment for confounding and constant rates are assumed.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustrative numbers: 8 cases in 2000 person-years among the vaccinated and 160 in 2100 person-years among the",
      "unvaccinated. Rate ratio 0.0525, **VE = 94.8%**; exact 95% CI 89.4% to 97.8%.",
      sep = "\n"
    ),
    citation = .vaccine_citation,
    backend = "1 - the exact / mid-P / Wald limits of calc_analyze_rate_ratio(); the exact limits equal a Clopper-Pearson interval mapped to the rate ratio"
  ),
  odds = list(
    title = "Vaccine effectiveness from a case-control (or test-negative) study",
    formula_latex = paste0(
      "$$VE=1-OR,\\\\qquad OR=\\\\frac{a/b}{c/d}$$",
      "$$a,b=\\\\text{vaccinated, unvaccinated cases};\\\\quad c,d=\\\\text{vaccinated, unvaccinated controls}$$"
    ),
    explanation = paste(
      "Enter the numbers of **vaccinated** and **unvaccinated** among the **cases** and among the **controls** (in a",
      "test-negative design the controls are the test-negative patients). The odds of vaccination among cases relative to",
      "controls is the exposure odds ratio $OR$, and $VE = 1 - OR$ estimates $1 - RR$ when controls represent the source",
      "population (the OR approximates the RR for a rare disease or with density sampling).",
      "",
      "Limits are one minus the limits of the odds ratio: **Woolf** (log) and the **conditional exact** (Fisher) interval,",
      "whose estimate is the conditional maximum-likelihood odds ratio rather than the sample odds ratio. Confounding by",
      "age, calendar time and so on usually needs a matched or regression analysis, which this tool does not do.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustrative numbers: 10 vaccinated and 40 unvaccinated cases, 50 vaccinated and 50 unvaccinated controls. Odds",
      "ratio 0.25, so **VE = 75.0%**; Woolf 95% CI 44.6% to 88.7%; exact (conditional estimate 74.8%) 41.7% to 89.9%.",
      sep = "\n"
    ),
    citation = .vaccine_citation,
    backend = "1 - the Woolf / Fisher limits of calc_analyze_compare_proportions(); the exact limits equal fisher.test()"
  )
)
