# Metadata for the Epidemic Models and Herd Immunity module (ROADMAP Track B5, item 20): formula text,
# plain-language explanation, worked example and citation per design. Content is data, rendered generically by
# mod_epidemic_model.R.

.epi_model_citation <- paste(
  "Kermack WO, McKendrick AG. A contribution to the mathematical theory of epidemics. Proc R Soc Lond A 1927;115:700-721 (the SIR",
  "model and the final-size relation; not web-confirmed in this session); Hethcote HW. The mathematics of infectious diseases.",
  "SIAM Rev 2000;42(4):599-653 (SIR and SEIR models, thresholds, final size; existence, journal, volume and pages confirmed by web search);",
  "Fine P, Eames K, Heymann DL. \"Herd immunity\": a rough guide. Clin Infect Dis 2011;52(7):911-916 (threshold 1 - 1/R0 and its",
  "assumptions; confirmed); Wallinga J, Lipsitch M. How generation intervals shape the relationship between growth rates and",
  "reproductive numbers. Proc R Soc B 2007;274:599-604 (R from the growth rate through the generation-interval distribution, which for",
  "exponential stage durations gives the formulas used here; confirmed); Anderson RM, May RM. Infectious Diseases of Humans:",
  "Dynamics and Control. Oxford University Press; 1991 (the book exists; its pages were not read here). The numerical solution equals",
  "deSolve::ode() at tight tolerance and the closed forms equal the stepped solution (tests; deSolve is an oracle only). None of the",
  "originals could be read here. The model is a teaching tool, not a forecast."
)

epidemic_model_content <- list(
  herd = list(
    title = "Herd-immunity threshold and vaccination coverage needed",
    formula_latex = paste0(
      "$$HIT=1-\\frac1{R_0},\\qquad c_{needed}=\\frac{HIT}{E},\\qquad R_e=R_0\\,(1-cE)$$"
    ),
    explanation = paste(
      "Enter the basic reproduction number **R0** (how many people one case infects in a fully susceptible population) and the **vaccine efficacy** $E$",
      "against infection (the share of vaccinated people who are protected). The **herd-immunity threshold** is the share of the population that must be",
      "immune for each case to infect less than one other person on average: $1-1/R_0$. With an imperfect vaccine the **coverage** needed is that",
      "threshold divided by $E$; if it exceeds 100%, vaccination alone cannot reach the threshold.",
      "",
      "Enter a **coverage** to see the **effective reproduction number** $R_e=R_0(1-cE)$ and the share of the population that would eventually be infected after a",
      "single introduction, with and without that coverage. Below $R_e=1$ an introduced case does not start an epidemic.",
      "",
      "**Assumptions:** everyone mixes at random, immunity is spread evenly and not clustered in some groups, the vaccine protects a fixed share of those vaccinated (",
      "it does not wane), and R0 is one number for the whole population. Clusters of unvaccinated people, and uneven mixing, mean the real threshold is higher.",
      sep = "\n"
    ),
    worked_example = "R0 = 12 (measles-like) and a vaccine of 95% efficacy: threshold 91.7%, coverage needed 96.5%. At 90% coverage the immune share is 85.5% and Re = 1.74, still above 1, so outbreaks are still possible.",
    citation = .epi_model_citation,
    backend = "closed forms; final size by root finding of the final-size equation (stats::uniroot)"
  ),
  sim = list(
    title = "SIR / SEIR epidemic with vaccination (deterministic)",
    formula_latex = paste0(
      "$$S'=-\\beta SI,\\quad E'=\\beta SI-\\sigma E,\\quad I'=\\sigma E-\\gamma I,\\quad R'=\\gamma I,\\qquad \\beta=R_0\\gamma,\\ \\gamma=\\tfrac1{D_{inf}},\\ \\sigma=\\tfrac1{D_{lat}}$$",
      "$$s_\\infty=s_0\\,e^{-R_0(1-s_\\infty-v)},\\qquad I_{max}=i_0+s_0-\\frac{1+\\ln(R_0 s_0)}{R_0}\\ \\ (\\text{SIR})$$"
    ),
    explanation = paste(
      "The population is split into **S**usceptible, (**E**xposed, if you give a latent period), **I**nfectious and **R**emoved (recovered or immune) people. Enter R0, the",
      "mean **infectious period** and, for an SEIR model, the mean **latent period** in days (0 gives an SIR model). Enter the **vaccination coverage** and **vaccine",
      "efficacy**: the vaccinated and protected share $v=cE$ starts in the removed group, before the epidemic starts. The epidemic is seeded with the given number of infectious people.",
      "",
      "The table gives the **final size** (share of the population ever infected), the **peak** (number infectious and the day), the **early growth rate** and doubling",
      "time, and the **infections averted** by the vaccination compared with none. The final size and the SIR peak are also computed from their closed formulas as a",
      "check. The latent period delays and lowers the peak but does not change the final size. The plot shows the compartments over time; the equations are solved in the app by",
      "fixed-step Runge-Kutta stepping.",
      "",
      "**Assumptions:** closed population (no births, deaths or movement), random mixing, constant rates (exponential stage durations; real durations are less spread out,",
      "which changes the speed of the early growth), immunity after infection, vaccination before the start only. It shows how quantities relate, it does not predict a real epidemic.",
      sep = "\n"
    ),
    worked_example = "R0 = 2.5, infectious period 7 days, 100,000 people, 10 seeded: 89.3% infected in the end, peak 23,351 infectious on day 45 (closed form 23,352), doubling time 3.2 days. With 50% coverage of a vaccine of 90% efficacy (45% immune at the start) only 27.0% are infected (27,005 people, peak 2,269 on day 130), 62,261 fewer infections than without vaccination: the epidemic is far smaller because the susceptible share falls from 100% to 55%.",
    citation = .epi_model_citation,
    backend = "base R fixed-step Runge-Kutta (order 4); verified against deSolve::ode() and the closed forms (tests)"
  ),
  r0 = list(
    title = "R0 from a growth rate or from a final attack fraction",
    formula_latex = paste0(
      "$$\\text{SIR: } R_0=1+\\frac{r}{\\gamma},\\qquad \\text{SEIR: } R_0=\\Big(1+\\frac r\\sigma\\Big)\\Big(1+\\frac r\\gamma\\Big),\\qquad r=\\frac{\\ln 2}{T_d}$$",
      "$$\\text{final size: } R_0=\\frac{\\ln\\big(s_0/s_\\infty\\big)}{s_0-s_\\infty},\\quad s_0=1-v,\\ s_\\infty=1-v-z$$"
    ),
    explanation = paste(
      "**From the growth rate.** In the early phase cases grow exponentially at rate $r$ per day (or double every $T_d$ days). Together with the mean **infectious period**",
      "(and **latent period**, if any) this gives R0. The formula assumes exponentially distributed stages, as in the models here; a",
      "generation interval that is more peaked gives a lower R0 for the same growth rate, so the value is approximate.",
      "",
      "**From the final size.** If $z$ is the share of the whole population infected over a **completed** epidemic in a population that was otherwise fully susceptible",
      "(or had an immune share $v$ before), the final-size relation gives R0, and the herd-immunity threshold follows.",
      "",
      "Both rely on the same model assumptions as the simulation: random mixing, a closed population and no intervention changing the rates over the period used. Use data from the early",
      "exponential phase for the growth rate, and a count of all infections (not just detected cases) for the final size.",
      sep = "\n"
    ),
    worked_example = "Cases doubling every 3 days with a 5-day infectious period (SIR): r = 0.231 per day, R0 = 2.16. If 80% of a susceptible population is infected over the whole epidemic, R0 = 2.01.",
    citation = .epi_model_citation,
    backend = "closed forms (generation-interval relation for exponential stages; final-size relation); recovered from the stepped simulation in tests"
  )
)
