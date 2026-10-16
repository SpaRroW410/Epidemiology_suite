# Metadata for the Analyze: Rates module (ROADMAP Track B1): formula text,
# plain-language explanation, worked example and citation per design. Content is
# data, rendered generically by mod_analyze_rates.R.

analyze_rates_content <- list(
  single = list(
    title = "Confidence interval for an incidence rate (events per person-time)",
    formula_latex = paste0(
      "$$\\hat\\lambda=\\frac{d}{T}$$",
      "$$\\text{Exact (Garwood): }\\ \\left[\\frac{\\chi^2_{\\alpha/2,\\,2d}}{2T},\\ \\frac{\\chi^2_{1-\\alpha/2,\\,2(d+1)}}{2T}\\right]$$",
      "$$\\text{Byar (}a'=d+\\tfrac12\\text{): }\\ \\frac{a'}{T}\\left(1-\\frac1{9a'}\\mp\\frac{z}{3\\sqrt{a'}}\\right)^3,\\qquad ",
      "\\text{Wald: }\\ \\frac{d\\pm z\\sqrt d}{T}$$",
      "The mid-P exact limits solve $P(X>d)+\\tfrac12P(X=d)=\\alpha/2$ (lower) and $P(X<d)+\\tfrac12P(X=d)=\\alpha/2$ (upper) ",
      "for the Poisson mean, then divide by $T$."
    ),
    explanation = paste(
      "Enter the **number of events** $d$ and the **person-time** $T$ (for example person-years) and choose",
      "the unit the rate is reported in (events per 1000 person-years, per 100,000, ...). The rate is",
      "$d/T$. Four confidence intervals for it are shown side by side:",
      "",
      "- **Exact (Garwood)** is based on the Poisson distribution and is never anti-conservative; it is the",
      "  usual default, but slightly wide.",
      "- **Mid-P exact** is the less conservative exact interval.",
      "- **Byar** is a cube-root approximation (here in the form $a'=d+\\tfrac12$ used by Rothman and by `epiR`).",
      "- **Wald** is $d\\pm z\\sqrt d$ over $T$; it is shown for comparison only and is unreliable for small $d$",
      "  (zero width at $d=0$).",
      "",
      "The intervals assume events follow a Poisson process with a constant rate and are independent.",
      sep = "\n"
    ),
    worked_example = paste(
      "7 events in 1000 person-years (rate 7 per 1000 person-years), 95% confidence: exact 2.81 to 14.42,",
      "mid-P 3.06 to 13.85, Byar 3.12 to 13.75, Wald 1.81 to 12.19 per 1000 person-years. The exact and Byar",
      "limits equal `epiR::epi.conf(ctype = \"inc.rate\")`; the exact limits also equal `poisson.test()`.",
      sep = "\n"
    ),
    citation = paste(
      "Garwood F. Fiducial limits for the Poisson distribution. Biometrika 1936;28:437-442; Ulm K. A simple",
      "method to calculate the confidence interval of a standardized mortality ratio (SMR). Am J Epidemiol",
      "1990;131:373-375; Rothman KJ. Epidemiology: An Introduction. 2nd ed. Oxford University Press; 2012",
      "(Byar's approximation, as implemented in epiR::epi.conf()); Lancaster HO. J Am Stat Assoc 1961;56:223-234",
      "and Berry G, Armitage P. The Statistician 1995;44:417-423 (mid-P)."
    ),
    backend = "closed forms (chi-square / Poisson quantiles); exact and Byar verified against epiR::epi.conf(), exact also against poisson.test()"
  ),
  ratio = list(
    title = "Comparing two incidence rates: rate ratio, rate difference, attributable fractions",
    formula_latex = paste0(
      "$$\\widehat{IRR}=\\frac{d_1/T_1}{d_0/T_0},\\qquad \\widehat{RD}=\\frac{d_1}{T_1}-\\frac{d_0}{T_0},\\quad ",
      "\\operatorname{SE}(\\widehat{RD})=\\sqrt{\\frac{d_1}{T_1^2}+\\frac{d_0}{T_0^2}}$$",
      "$$\\text{Exact: }\\ \\widehat{IRR}\\in\\left[\\frac{p_L}{1-p_L}\\frac{T_0}{T_1},\\ \\frac{p_U}{1-p_U}\\frac{T_0}{T_1}\\right],\\quad ",
      "[p_L,p_U]=\\text{Clopper-Pearson interval for }d_1/(d_1+d_0)$$",
      "$$\\text{Wald (log): }\\ \\exp\\{\\ln\\widehat{IRR}\\pm z\\sqrt{1/d_1+1/d_0}\\}$$",
      "$$AF_e=\\frac{IRR-1}{IRR},\\qquad PAF=\\frac{I_{pop}-I_0}{I_{pop}},\\ I_{pop}=\\frac{d_1+d_0}{T_1+T_0},\\quad ",
      "\\operatorname{Var}\\{\\ln(I_{pop}/I_0)\\}=\\frac1{d_0}-\\frac1{d_1+d_0}$$"
    ),
    explanation = paste(
      "Enter events and person-time for the **exposed** and the **unexposed** group. The app reports each",
      "group's rate (with an exact interval), the **incidence rate ratio** with three intervals (exact,",
      "mid-P exact and Wald on the log scale), the **rate difference**, the **attributable fraction among the",
      "exposed** and the **population attributable fraction**, and three tests of 'no difference in rates':",
      "the exact conditional test, its mid-P version and the score ($\\chi^2$, 1 df) test.",
      "",
      "The exact methods condition on the total number of events: given $d_1+d_0$ events, the exposed",
      "group's share is binomial with a probability that depends only on the rate ratio and the person-time",
      "split, which turns a Poisson problem into the binomial one.",
      "",
      "The **population attributable fraction** uses the study's own exposed share of person-time, so it",
      "applies to a population only when the study is representative of its exposure distribution. Its interval",
      "uses the covariance of the overall and unexposed rates (both contain the unexposed events), which is why it",
      "can differ from simpler intervals that combine separate limits. A negative fraction means the exposure",
      "is protective. With zero events in a group the rate ratio is undefined (it is reported as n/a); the exact",
      "interval still gives a one-sided limit.",
      sep = "\n"
    ),
    worked_example = paste(
      "Feychting et al. (1998), as in the `epiR::epi.2by2()` help page: cancer occurred at 136 per 22,050",
      "person-years among the blind and 1709 per 127,650 person-years among those who were visually impaired",
      "but not blind. Rate per 1000 person-years: 6.17 vs 13.39; **rate ratio 0.46 (95% CI 0.38 to 0.55)**, rate",
      "difference -7.22 per 1000 person-years (95% CI -8.44 to -6.00) -- the published figures, reproduced here.",
      sep = "\n"
    ),
    citation = paste(
      "Kirkwood BR, Sterne JAC. Essential Medical Statistics. 2nd ed. Blackwell; 2003 (exact conditional",
      "interval for the rate ratio, as used by epiR); Feychting M, Osterlund B, Ahlbom A. Reduced cancer",
      "incidence among the blind. Epidemiology 1998;9:490-494 (worked example, as cited in the epiR help page);",
      "Lancaster HO. J Am Stat Assoc 1961;56:223-234 and Berry G, Armitage P. The Statistician 1995;44:417-423",
      "(mid-P); the population-attributable-fraction interval is derived by the delta method (checked by",
      "simulation in the unit tests). Cross-checked against epiR::epi.2by2(method = 'cohort.time') and",
      "stats::poisson.test()."
    ),
    backend = "closed forms (conditional binomial, Wald, delta method); verified against epiR::epi.2by2(), poisson.test() and prop.test()"
  )
)
