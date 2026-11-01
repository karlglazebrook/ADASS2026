#!/usr/bin/env python3
"""Histogram of all 131 run22 relative times, for the talk.

Same bins and tier colours as the report's fig6, but with no title and a
fixed axes box, so build_deck.js can place the grouping arrows at exact
data values. The geometry is written next to the image as JSON.

    python3 make_talk_histogram.py   # writes img/talk_histogram.{png,json}
"""
import json
import math
import os
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(HERE, "..", "report", "run22.log")
OUT = os.path.join(HERE, "img", "talk_histogram")

# Tier boundaries and colours, as in report/make_figures.py.
TIER_EDGES = [1.00, 1.10, 2.50, 7.00, 15.00, 100.0, 600.0, 20000.0, 1e7]
TIER_COLOURS = ["#1a9850", "#66bd63", "#a6d96a", "#fee08b", "#fdae61", "#f46d43", "#d73027", "#7a0177"]
FIG = (7.6, 3.0)               # inches
AX = [0.085, 0.19, 0.895, 0.78]  # left, bottom, width, height (figure fractions)
XLIM, YLIM = (0.9, 1e6), (0, 34)


def run22():
    txt = open(LOG).read()
    txt = txt[txt.index("Summary of relative speeds:"):txt.index("\nCompiler,")]
    return [float(m) for m in re.findall(r"1K Iter:.*Relative time\s+([0-9.]+)", txt)]


def main():
    vals = np.array(run22())
    assert len(vals) == 131
    plt.rcParams.update({"font.family": "sans-serif", "font.size": 11})
    fig = plt.figure(figsize=FIG, dpi=220)
    ax = fig.add_axes(AX)
    n, edges, patches = ax.hist(vals, bins=np.logspace(0, 6, 25), edgecolor="k", linewidth=0.4)
    for p, lo, hi in zip(patches, edges[:-1], edges[1:]):
        c = math.sqrt(lo * hi)
        p.set_facecolor(next(col for col, a, b in zip(TIER_COLOURS, TIER_EDGES, TIER_EDGES[1:]) if a <= c < b))
    for e in TIER_EDGES[1:-1]:
        ax.axvline(e, color="#888888", linewidth=0.5, linestyle="--", alpha=0.6)
    ax.set_xscale("log")
    ax.set_xlim(*XLIM)
    ax.set_ylim(*YLIM)
    ax.set_xlabel("Time relative to the arm64 NEON assembler (log scale)")
    ax.set_ylabel("Test variants")
    ax.grid(True, which="major", axis="y", linewidth=0.3, alpha=0.5)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    fig.savefig(OUT + ".png")  # no bbox_inches: the axes box must stay where AX says
    json.dump({"fig": FIG, "ax": AX, "xlim": XLIM, "ylim": YLIM}, open(OUT + ".json", "w"))
    print("wrote", OUT + ".png", "peak bin", int(n.max()))


if __name__ == "__main__":
    main()
