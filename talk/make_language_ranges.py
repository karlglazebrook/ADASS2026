#!/usr/bin/env python3
"""Per-language range of run22 relative times, for the talk.

One column per language (27, counted as Keith counted his 12: C/C++ and
Perl/PDL are one each, PyPy is Python). Dots are the variants, the bar
spans best to worst. The 15 languages new in 2026 are drawn in red.

    python3 make_language_ranges.py      # writes img/fig7_language_ranges.png
"""
import os
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(HERE, "..", "report", "run22.log")
OUT = os.path.join(HERE, "img", "fig7_language_ranges.png")

NEW = {"C#", "F#", "Go", "Kotlin", "Haskell", "D", "Zig", "Crystal", "Nim",
       "OCaml", "Ruby", "Lua", "J", "Common Lisp", "Octave"}
MERGE = {"C": "C/C++", "C++": "C/C++", "Perl": "Perl/PDL", "Perl/PDL": "Perl/PDL",
         "Lisp": "Common Lisp", "Javascript": "JavaScript"}
TIER_EDGES = [1.10, 2.50, 7.00, 15.00, 100.0, 600.0, 20000.0]
RED, OLD = "#D73027", "#3B4A6B"


def run22():
    txt = open(LOG).read()
    txt = txt[txt.index("Summary of relative speeds:"):txt.index("\nCompiler,")]
    langs = {}
    for line in txt.split("\n"):
        m = re.match(r"\s*(\S+).*?1K Iter:.*Relative time\s+([0-9.]+)", line)
        if m:
            lang = MERGE.get(m.group(1), m.group(1))
            langs.setdefault(lang, []).append(float(m.group(2)))
    return langs


def main():
    langs = run22()
    assert len(langs) == 27, sorted(langs)
    assert sum(len(v) for v in langs.values()) == 131
    assert NEW <= set(langs), NEW - set(langs)
    order = sorted(langs, key=lambda k: min(langs[k]))

    plt.rcParams.update({"font.family": "sans-serif", "font.size": 13})
    fig, ax = plt.subplots(figsize=(13.0, 5.6), dpi=200)
    for e in TIER_EDGES:
        ax.axhline(e, color="#D9DEE7", lw=0.8, zorder=0)
    for i, k in enumerate(order):
        v = langs[k]
        c = RED if k in NEW else OLD
        ax.plot([i, i], [min(v), max(v)], color=c, lw=6, alpha=0.35, solid_capstyle="round", zorder=1)
        ax.scatter([i] * len(v), v, s=26, color=c, edgecolor="white", linewidth=0.6, zorder=2)
    ax.set_yscale("log")
    ax.set_ylim(0.7, 1e6)
    ax.set_xlim(-0.7, len(order) - 0.3)
    ax.set_xticks(range(len(order)))
    ax.set_xticklabels([f"{k} ({len(langs[k])})" for k in order], rotation=50, ha="right", rotation_mode="anchor")
    for lab, k in zip(ax.get_xticklabels(), order):
        lab.set_color(RED if k in NEW else OLD)
        lab.set_fontweight("bold" if k in NEW else "normal")
    ax.set_yticks([1, 10, 100, 1e3, 1e4, 1e5, 1e6])
    ax.set_yticklabels(["1", "10", "100", "1,000", "10⁴", "10⁵", "10⁶"])
    ax.set_ylabel("Time relative to assembler (log)")
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="x", length=0)
    ax.scatter([], [], s=40, color=RED, label="New in 2026 (15)")
    ax.scatter([], [], s=40, color=OLD, label="Keith's 2019 languages (12)")
    ax.legend(loc="upper left", frameon=False, fontsize=13)
    fig.tight_layout()
    fig.savefig(OUT, bbox_inches="tight")
    print("wrote", OUT, "order:", ", ".join(order))


if __name__ == "__main__":
    main()
