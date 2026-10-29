#!/usr/bin/env python3
"""One-off documentation tool: completes the roxygen block above every calc_*() function so that each one has a title, every argument
documented, a @return, an @examples taken from a real (verified) call in the tests, and @export.

Inputs (made by R, see tools/docs/extract_examples.R):  FORMALS_JSON (name -> argument names), EXAMPLES_JSON (name -> call, seconds, fields).
Usage:  python3 tools/docs/write_roxygen.py /tmp/formals.json /tmp/examples.json [--apply]
Without --apply it only reports what would change. Idempotent: running it again changes nothing.
"""
import glob, json, re, sys

formals = json.load(open(sys.argv[1]))
examples = json.load(open(sys.argv[2]))
APPLY = "--apply" in sys.argv

# ---- text that cannot be derived: titles for the three functions that had no block, descriptions for the arguments that had none
TITLES = {
    "calc_multilevel_two_level": "Subjects per arm for a two-level longitudinal design (subjects with repeated measures)",
    "calc_multilevel_three_level": "Clusters per arm for a three-level longitudinal design (subjects nested in clusters)",
    "calc_tsa_information_size": "Required information size for a trial sequential analysis (fixed-effect meta-analysis)",
}
DESCRIPTIONS = {
    "calc_multilevel_two_level": [
        "Power of the test of a difference in slopes between two arms when each subject is measured repeatedly (random intercept",
        "and random slope, equal numbers of subjects per arm, equally spaced occasions, no missing data). The closed form of",
        "`powerlmm::study_parameters()` with `get_power()`, which it reproduces exactly (see the file header for how it was checked).",
    ],
    "calc_multilevel_three_level": [
        "As [calc_multilevel_two_level()], with subjects nested in clusters that are the unit of randomisation (for example a",
        "cluster-randomised trial with repeated measures): the number of clusters per arm, for a given number of subjects per cluster.",
    ],
    "calc_tsa_information_size": [
        "The number of participants a meta-analysis needs before its evidence is adequately powered for the anticipated effect, the",
        "quantity trial sequential analysis uses to build its monitoring boundaries. Fixed-effect form for a risk ratio, odds ratio,",
        "risk difference or mean difference; it is not adjusted for heterogeneity.",
    ],
}
STD = {
    "alpha": "Significance level (type I error rate), strictly between 0 and 1.",
    "power": "Desired power, strictly between 0 and 1.",
    "alternative": 'Alternative hypothesis: `"two.sided"`, `"less"` or `"greater"`.',
}
PARAMS = {  # function -> {argument: description}
    "calc_analyze_exposure_table": {"conf_level": "Confidence level of the intervals reported for each exposure (default 0.95)."},
    "calc_analyze_secondary_attack": {"conf_level": "Confidence level of the interval for the secondary attack rate (default 0.95)."},
    "calc_analyze_case_fatality": {"conf_level": "Confidence level of the interval for the case fatality (default 0.95)."},
    "calc_surveillance_cusum": {"min_sd": "Smallest baseline standard deviation allowed (default 0.5), so that a flat baseline does not inflate the statistic."},
    "calc_multilevel_two_level": {
        "n1": "Number of measurement occasions per subject (at least 2: a baseline and at least one follow-up), equally spaced.",
        "T_end": "Study duration: the time of the last measurement, the first being at time 0 (any time unit).",
        "var_ratio": "Variance of the subject-level slopes divided by the residual variance `sigma_error^2` (greater than 0).",
        "delta": "Expected difference between the two arms in the outcome at the end of the study, that is the slope difference times `T_end` (not 0).",
        "sigma_error": "Residual (single-occasion) standard deviation, default 10.",
        "alpha": STD["alpha"], "power": STD["power"],
    },
    "calc_multilevel_three_level": {
        "n1": "Number of measurement occasions per subject (at least 2), equally spaced.",
        "n2": "Subjects per cluster.",
        "T_end": "Study duration: the time of the last measurement, the first being at time 0 (any time unit).",
        "var_ratio": "Variance of the subject-level slopes divided by the residual variance `sigma_error^2` (greater than 0).",
        "icc_slope": "Share of the slope variance that lies between clusters rather than between subjects of the same cluster, in [0, 1).",
        "delta": "Expected difference between the two arms in the outcome at the end of the study, that is the slope difference times `T_end` (not 0).",
        "sigma_error": "Residual (single-occasion) standard deviation, default 10.",
        "alpha": STD["alpha"], "power": STD["power"],
    },
    "calc_multiplicity_proportion_1s": {"m": "Number of simultaneous comparisons the significance level is shared between (at least 1).",
        "method": '`"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.'},
    "calc_multiplicity_proportion_2s": {"m": "Number of simultaneous comparisons the significance level is shared between (at least 1).",
        "method": '`"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.'},
    "calc_multiplicity_means_1s": {"m": "Number of simultaneous comparisons the significance level is shared between (at least 1).",
        "method": '`"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.'},
    "calc_multiplicity_means_2s": {"m": "Number of simultaneous comparisons the significance level is shared between (at least 1).",
        "method": '`"bonferroni"` (alpha / m) or `"sidak"` (1 - (1 - alpha)^(1/m)) adjustment of the significance level.'},
    "calc_patient_units_needed": {
        "p1": "Proportion of units with the outcome in group 1 (`design = \"between_binary\"`; strictly between 0 and 1).",
        "p2": "Proportion of units with the outcome in group 2 (`design = \"between_binary\"`; different from `p1`).",
    },
    "calc_survey_select_systematic": {"N": "Size of the list (number of units, a whole number of at least 2).", "n": "Number of units to select.",
        "seed": "Whole-number seed, so that the same seed and settings give the same sample.", "labels": "Optional unit labels, one per unit of the list."},
    "calc_survey_select_pps": {"seed": "Whole-number seed, so that the same seed and settings give the same sample.", "labels": "Optional unit labels, one per unit."},
    "calc_survey_epi_clusters": {"sizes": "Positive sizes (for example village populations), one per cluster in the list.",
        "seed": "Whole-number seed, so that the same seed and settings give the same sample.", "labels": "Optional cluster labels, one per cluster in the list."},
    "calc_survey_effective_n": {"weights": "Survey weights, one per respondent (at least two, all positive)."},
    "calc_tsa_information_size": {
        "outcome": '`"RR"` (risk ratio), `"OR"` (odds ratio), `"RD"` (risk difference) or `"MD"` (mean difference).',
        "mc": "Anticipated effect: the ratio for `RR` / `OR`, the risk difference for `RD`, the mean difference for `MD`.",
        "pC": "Event probability in the control arm (`RR`, `OR` and `RD`; strictly between 0 and 1).",
        "p1": "Event probability in the intervention arm (`RD` only).",
        "sd_mc": "Standard deviation of the outcome (`MD` only; greater than 0).",
        "alpha": STD["alpha"], "beta": "Type II error rate, strictly between 0 and 1 (power = 1 - beta); default 0.1.",
        "side": "1 for a one-sided or 2 for a two-sided test (default 2).",
    },
}
INHERIT = {  # function -> functions whose @param texts it reuses for arguments of the same name
    "calc_sem_rmsea_samplesize": ["calc_sem_rmsea_power"],
    "calc_meta_analysis_k": ["calc_meta_analysis_power"],
    "calc_multiplicity_proportion_1s": ["calc_proportion_1s"],
    "calc_multiplicity_proportion_2s": ["calc_proportion_2s"],
    "calc_multiplicity_means_1s": ["calc_means_1s"],
    "calc_multiplicity_means_2s": ["calc_means_2s"],
    "calc_patient_units_between_binary": ["calc_patient_units_between_continuous"],
    "calc_patient_units_needed": ["calc_patient_units_between_continuous"],
}

RET_STD = ("A named list of class `ss_result` (printed by `print()`) with the components {fields} and `inputs`, "
           "the arguments the result was calculated from.")


def read_blocks(path):
    L = open(path, encoding="utf8").read().split("\n")
    return L


def split_inline(blk):
    res = []
    for l in blk:
        body = l[2:]
        parts = re.split(r"\s(?=@(?:param|return)\s)", body)
        res.append("#'" + parts[0])
        for p in parts[1:]:
            res.append("#' " + p)
    return res


def documented(blk):
    names = set()
    for l in blk:
        m = re.match(r"^#' @param ([^ ]+)", l)
        if m:
            names.update(m.group(1).split(","))
    return names


def build(name, blk):
    blk = split_inline(blk)
    out = [l for l in blk]
    # title / description
    if not out:
        out = ["#' " + TITLES[name], "#'"] + ["#' " + t for t in DESCRIPTIONS[name]]
    elif name in TITLES and not out[0].strip("#' ").strip():
        raise SystemExit("odd block for " + name)
    # remove old @export / @examples / @inheritParams so the tool is idempotent
    out = [l for l in out if not re.match(r"^#' @(export|inheritParams)\b", l)]
    ex_start = next((i for i, l in enumerate(out) if re.match(r"^#' @examples\b", l)), None)
    if ex_start is not None:
        out = out[:ex_start]
    # a block whose first line is a tag has no title: not expected
    inherit = INHERIT.get(name, [])
    have = documented(out)
    own = PARAMS.get(name, {})
    missing = [a for a in formals[name] if a not in have]
    add = []
    unresolved = []
    for a in missing:
        if a in own:
            add.append("#' @param %s %s" % (a, own[a]))
        elif inherit:
            continue  # reused from the inherited function; checked below
        elif a in STD:
            add.append("#' @param %s %s" % (a, STD[a]))
        else:
            unresolved.append(a)
    # @return
    has_ret = any(l.startswith("#' @return") for l in out)
    if not has_ret:
        ex = examples.get(name)
        if ex and ex.get("fields"):
            flds = ", ".join("`%s`" % f for f in ex["fields"])
            add.append("#' @return " + RET_STD.format(fields=flds))
        else:
            add.append("#' @return A named list of class `ss_result` (printed by `print()`) holding the result and `inputs`, the arguments the result was calculated from.")
    if inherit:
        for src in inherit:
            add.append("#' @inheritParams %s" % src)
    ex = examples.get(name)
    if ex:
        code = ex["call"].split("\n")
        wrap = ex["seconds"] > 1.5
        add.append("#' @examples")
        if wrap:
            add.append("#' \\donttest{")
        add.extend("#' " + c for c in code)
        if wrap:
            add.append("#' }")
    add.append("#' @export")
    return out + add, unresolved


changes = 0
problems = {}
for path in sorted(glob.glob("R/calc_*.R")):
    L = read_blocks(path)
    new = []
    i = 0
    n_lines = len(L)
    # walk and rewrite blocks that sit directly above a calc_ definition
    idx = [k for k, l in enumerate(L) if re.match(r"^calc_[A-Za-z0-9_]+ <- function", l)]
    out = list(L)
    for k in reversed(idx):
        name = re.match(r"^(calc_[A-Za-z0-9_]+)", L[k]).group(1)
        j = k - 1
        while j >= 0 and L[j].startswith("#'"):
            j -= 1
        old = L[j + 1:k]
        blk, unresolved = build(name, old)
        if unresolved:
            problems[name] = unresolved
        out[j + 1:k] = blk
        if blk != old:
            changes += 1
    if APPLY:
        open(path, "w", encoding="utf8").write("\n".join(out))
print("blocks changed:", changes)
if problems:
    print("UNRESOLVED arguments (add them to PARAMS):")
    for n, a in problems.items():
        print(" ", n, a)
    sys.exit(1)
