# Metadata for the Simon Two-Stage module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_simon.R (SDD 4.2: "content is data, not hardcoded UI").

simon_content <- list(
  ph2simon = list(
    title = "Simon's Two-Stage Phase II Design",
    formula_latex = paste0(
      "$$\\text{Stage 1: enroll } n_1 \\text{; stop for futility if} \\le r_1 \\text{ responses}$$",
      "$$\\text{Stage 2: enroll to } n \\text{ total; reject } H_0 \\text{ if} > r \\text{ responses}$$",
      "$$(r_1, n_1, r, n) \\text{ chosen to minimize } EN(p_u) \\text{ (optimal) or } n \\text{ (minimax)}$$"
    ),
    explanation = paste(
      "Use this for a single-arm Phase II trial testing whether a",
      "treatment's response rate clears a minimum bar worth pursuing",
      "further, while allowing the trial to stop early if the drug looks",
      "ineffective -- sparing patients from a treatment unlikely to help",
      "them.",
      "",
      "- **pu (unacceptable rate)** - the response rate that would make",
      "  the treatment *not* worth pursuing further.",
      "- **pa (desirable rate)** - the response rate that would make the",
      "  treatment worth pursuing; must exceed pu.",
      "- **alpha** - the target probability of declaring an ineffective",
      "  (pu-level) treatment promising (a false positive).",
      "- **beta** - the target probability of rejecting an effective",
      "  (pa-level) treatment (a false negative); power = 1 - beta.",
      "",
      "This returns two designs, not one:",
      "",
      "- **Minimax** - the design with the smallest *maximum* (worst-case)",
      "  total sample size n.",
      "- **Optimal** - the design with the smallest *expected* sample size",
      "  under pu, EN(pu) -- i.e. the fewest patients on average if the",
      "  drug turns out ineffective, at the cost of a (usually slightly)",
      "  larger worst-case n.",
      "",
      "Both stop early (after n1 patients) if r1 or fewer respond;",
      "otherwise the trial continues to the full n, and the treatment is",
      "considered promising only if more than r patients respond in",
      "total. PET(pu) is the probability of stopping early if the true",
      "rate is pu.",
      sep = "\n"
    ),
    worked_example = paste(
      "A classic textbook scenario: an unacceptable response rate of 20%",
      "(pu = 0.20), a desirable rate of 40% (pa = 0.40), with alpha = 0.10",
      "and beta = 0.10 (90% power). This calculator returns:",
      "",
      "- **Minimax**: stop early if <= 3 responses in the first 19",
      "  patients; otherwise continue to 36 total, needing > 10 responses",
      "  overall (EN(pu) = 28.3, 45.5% chance of stopping early).",
      "- **Optimal**: stop early if <= 3 responses in the first 17",
      "  patients; otherwise continue to 37 total, needing > 10 responses",
      "  overall (EN(pu) = 26.0, 54.9% chance of stopping early).",
      sep = "\n"
    ),
    citation = paste(
      "Simon R. Optimal two-stage designs for phase II clinical trials.",
      "Control Clin Trials. 1989;10(1):1-10; Jung SH, Carey M, Kim KM.",
      "Graphical search for two-stage designs for phase II clinical",
      "trials. Control Clin Trials. 2001;22(4):367-372."
    ),
    backend = "clinfun::ph2simon()"
  )
)
