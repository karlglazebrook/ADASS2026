#!/usr/bin/env python3
"""make_raw_table.py -- emit a LaTeX longtable of all 131 sorted results
from run19.log, for inclusion as an appendix in Report-2026.tex.

Reads:  run19.log  (frozen reference run, alongside this script)
Writes: raw_table.tex  (a self-contained \begin{longtable}...\end{longtable})
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(HERE, "run22.log")
OUT = os.path.join(HERE, "raw_table.tex")

rel_re = re.compile(
    r"^\s*(\S.*?)\s{2,}(\S.*?)\s+1K Iter:\s+(\S+),\s+Relative time\s+([0-9.]+)"
)

def parse():
    rows = []
    in_block = False
    with open(LOG) as f:
        for line in f:
            if "Summary of relative speeds:" in line:
                in_block = True; continue
            if in_block:
                if line.startswith("Compiler,"): break
                m = rel_re.match(line)
                if m:
                    lang, opt, kiter, rel = m.groups()
                    rows.append((float(rel), lang.strip(), opt.strip(), kiter.strip()))
    rows.sort()
    return rows

# Tier boundaries -- match the report.
TIERS = [
    (1.10,   "tg1"),
    (2.50,   "tg2"),
    (7.00,   "tg3"),
    (15.00,  "ty"),
    (100.00, "to1"),
    (600.00, "to2"),
    (20000.0,"tr"),
    (1e9,    "tp"),
]

def tier_swatch(r):
    for hi, c in TIERS:
        if r < hi:
            return r"\swatch{%s}" % c
    return r"\swatch{tp}"

def fmt_rel(r):
    if r >= 10000:
        return r"%s" % f"{r:,.0f}"
    if r >= 100:
        return r"%.0f" % r
    if r >= 10:
        return r"%.2f" % r
    return r"%.2f" % r

def latex_escape(s):
    # Minimal escaping.  Underscores in compiler-option strings need it.
    return (s.replace("\\", "\\textbackslash{}")
             .replace("_", r"\_")
             .replace("&", r"\&")
             .replace("#", r"\#")
             .replace("%", r"\%")
             .replace("$", r"\$")
             .replace("{", r"\{")
             .replace("}", r"\}"))

def emit():
    rows = parse()
    out = []
    out.append(r"\begingroup")
    out.append(r"\footnotesize")
    out.append(r"\setlength{\tabcolsep}{4pt}")
    out.append(r"\begin{longtable}{@{}clllr@{}}")
    out.append(r"\toprule")
    out.append(r"\textbf{Tier} & \textbf{Rel.\ time} & \textbf{Family} & \textbf{Variant} & \textbf{ms / 1k iter} \\")
    out.append(r"\midrule")
    out.append(r"\endfirsthead")
    out.append(r"\multicolumn{5}{l}{\emph{(continued from previous page)}} \\")
    out.append(r"\toprule")
    out.append(r"\textbf{Tier} & \textbf{Rel.\ time} & \textbf{Family} & \textbf{Variant} & \textbf{ms / 1k iter} \\")
    out.append(r"\midrule")
    out.append(r"\endhead")
    out.append(r"\midrule")
    out.append(r"\multicolumn{5}{r}{\emph{continued on next page}} \\")
    out.append(r"\endfoot")
    out.append(r"\bottomrule")
    out.append(r"\endlastfoot")
    for rel, lang, opt, kiter in rows:
        out.append(
            "{tier} & {rel} & {lang} & {opt} & {kiter} \\\\".format(
                tier=tier_swatch(rel),
                rel=fmt_rel(rel),
                lang=latex_escape(lang),
                opt=latex_escape(opt),
                kiter=latex_escape(kiter),
            )
        )
    out.append(r"\end{longtable}")
    out.append(r"\endgroup")
    with open(OUT, "w") as f:
        f.write("\n".join(out) + "\n")
    print("wrote", OUT, f"({len(rows)} rows)")

if __name__ == "__main__":
    emit()
