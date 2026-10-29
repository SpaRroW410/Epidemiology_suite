#!/usr/bin/env python3
"""One-off: make the plain-text roxygen comments safe for roxygen's markdown mode. Square brackets that are interval notation or
indexing ("[0, 1)", "ni[1]") are escaped so they are not read as links, and a continuation line that starts with ">" (">= 2") is
escaped so it is not read as a block quote. Real links ([run_app()], [shiny::runApp()]) and @examples code are left alone.
Idempotent. Usage: python3 tools/docs/fix_markdown.py"""
import glob, re

LINK = re.compile(r"\[(?:[A-Za-z_.][A-Za-z0-9_.]*::[A-Za-z_.][A-Za-z0-9_.]*(?:\(\))?|[A-Za-z_.][A-Za-z0-9_.]*\(\))\]")


def fix_line(l):
    body = l[2:]
    # protect real links
    marks = []
    def keep(m):
        marks.append(m.group(0)); return "\x00%d\x00" % (len(marks) - 1)
    t = LINK.sub(keep, body)
    t = re.sub(r"(?<!\\)\[", r"\\[", t)
    t = re.sub(r"(?<!\\)\]", r"\\]", t)
    t = re.sub(r"^(\s*)>", r"\1\\>", t)
    t = re.sub("\x00(\\d+)\x00", lambda m: marks[int(m.group(1))], t)
    return "#'" + t


changed = 0
for path in sorted(glob.glob("R/*.R")):
    L = open(path, encoding="utf8").read().split("\n")
    in_examples = False
    out = []
    for l in L:
        if l.startswith("#'"):
            if re.match(r"^#' @examples\b", l):
                in_examples = True
            elif re.match(r"^#' @\w+", l):
                in_examples = False
            nl = l if in_examples else fix_line(l)
            if nl != l:
                changed += 1
            out.append(nl)
        else:
            in_examples = False
            out.append(l)
    if out != L:
        open(path, "w", encoding="utf8").write("\n".join(out))
print("lines changed:", changed)
