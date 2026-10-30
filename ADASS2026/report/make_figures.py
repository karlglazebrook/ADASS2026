#!/usr/bin/env python3
"""
make_figures.py -- generate the five PDF figures used in the 2026
report.  Reads run19.log (the canonical reference run) and writes
PDFs into figs/.

Figures:
  fig1_heatmap.pdf      -- successor to Shortridge 2019 Figure 1.
                           Language x compiler-option matrix, log-scaled
                           colour, log-scale numeric annotation.
  fig2_tiers.pdf        -- horizontal histogram of all 131 tests bucketed
                           into the seven tiers used in the report.
  fig3_top30.pdf        -- horizontal bar chart of the 30 fastest tests.
  fig4_octave.pdf       -- the Octave 800x loop-vs-vectorised gap.
  fig5_2019_vs_2026.pdf -- side-by-side comparison of 2019 (x86) and
                           2026 (arm64) numbers for the languages that
                           appeared in both studies.
"""

from __future__ import annotations
import csv
import os
import re
from collections import OrderedDict
import matplotlib
matplotlib.use("Agg")  # no display needed
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(HERE, "run22.log")
OUT = os.path.join(HERE, "figs")
os.makedirs(OUT, exist_ok=True)

# Use a serif font so figures harmonise with LaTeX article body.
plt.rcParams.update({
    "font.family": "serif",
    "font.size": 9,
    "axes.titlesize": 10,
    "axes.labelsize": 9,
    "xtick.labelsize": 8,
    "ytick.labelsize": 8,
    "legend.fontsize": 8,
    "pdf.fonttype": 42,
})


# ----------------------------------------------------------------------
# parse run19.log
# ----------------------------------------------------------------------

def parse_csv():
    """Return the language x compiler matrix from the CSV at the end of
    the run log.  Returns (langs, opts, table) where table[i,j] is the
    relative speed of opts[i] x langs[j] (NaN where empty)."""
    with open(LOG) as f:
        text = f.read()
    csv_start = text.rfind("\nCompiler,")
    csv_text = text[csv_start + 1 :]
    rows = list(csv.reader(csv_text.strip().splitlines()))
    header = rows[0]
    langs = header[1:]
    opts = []
    table = []
    for row in rows[1:]:
        opts.append(row[0])
        table.append([float(x) if x else float("nan") for x in row[1:]])
    return langs, opts, np.array(table, dtype=float)


def parse_summary():
    """Return list of (rel, lang, opt) tuples from the 'Summary of
    relative speeds' block."""
    rel_re = re.compile(
        r"^\s*(\S.*?)\s{2,}(\S.*?)\s+1K Iter:\s+\S+,\s+Relative time\s+([0-9.]+)"
    )
    out = []
    in_block = False
    for line in open(LOG):
        if "Summary of relative speeds:" in line:
            in_block = True
            continue
        if in_block:
            if line.startswith("Compiler,"):
                break
            m = rel_re.match(line)
            if m:
                lang, opt, rel = m.groups()
                out.append((float(rel), lang.strip(), opt.strip()))
    return out


# ----------------------------------------------------------------------
# Figure 1: language x compiler-option heatmap, the successor to
# Shortridge 2019 Figure 1.
# ----------------------------------------------------------------------

def figure_heatmap():
    langs, opts, table = parse_csv()

    # Order the columns by the *fastest* result in each language column,
    # so the green band (fastest languages) sits to the left.
    col_min = np.nanmin(np.where(np.isnan(table), np.inf, table), axis=0)
    col_order = np.argsort(col_min)
    langs = [langs[i] for i in col_order]
    table = table[:, col_order]

    # Order the rows roughly fastest->slowest using the same idea.
    # Group rows by toolchain family (clang/g++/gfortran/Rustc/julia/...)
    # in the order they tend to appear at the top of the speed list.
    family_priority = [
        "clang (arm64)",
        "clang -O3 native", "g++ -O3 native", "gfortran -O3 native",
        "clang -O3", "g++ -O3", "gfortran -O3",
        "clang -O2", "g++ -O2", "gfortran -O2",
        "clang -O1", "g++ -O1", "gfortran -O1",
        "clang -O", "g++ -O", "gfortran -O",
        "clang", "g++", "gfortran",
        "ldc2 -O3 -release", "zig -O ReleaseFast", "nim -d:danger",
        "crystal --release", "ocamlopt -O3", "GHC -O2",
        "Rustc -O3 native", "Rustc -O3", "Rustc -O", "Rustc",
        "Rustc iterators", "Rustc unsafe",
        "julia (int32)", "julia -O3", "julia -O2", "julia -O1", "julia -O0", "julia",
        ".NET 8 AOT", ".NET 8",
        "kotlinc + JVM", "Java",
        "jconsole",
        "Swiftc -Ounchecked", "Swiftc -O", "Swiftc -Onone", "Swiftc",
        "LuaJIT",
        "SBCL typed", "SBCL untyped",
        "Bun", "Deno", "Node.js", "Node.js --no-opt",
        "Python3 numba",
        "Perl/PDL",
        "ruby 3.3 +YJIT", "ruby 3.3", "ruby 2.6",
        "Python3", "Python2", "PyPy3",
        "octave vectorised", "octave loop",
        "Rscript",
        "Perl",
        "tclsh",
    ]
    order = []
    used = set()
    for f in family_priority:
        if f in opts and f not in used:
            order.append(opts.index(f))
            used.add(f)
    for i, o in enumerate(opts):
        if i not in used and i not in order:
            order.append(i)
    opts_o = [opts[i] for i in order]
    table_o = table[order, :]

    # Drop empty rows and columns.
    nz_rows = [i for i in range(len(opts_o))
               if not np.all(np.isnan(table_o[i, :]))]
    table_o = table_o[nz_rows, :]
    opts_o = [opts_o[i] for i in nz_rows]

    nz_cols = [j for j in range(len(langs))
               if not np.all(np.isnan(table_o[:, j]))]
    table_o = table_o[:, nz_cols]
    langs = [langs[j] for j in nz_cols]

    # Colour map: log-scaled green->yellow->orange->red->purple, with
    # NaN cells in light grey.  Boundaries follow the seven tiers
    # described in the report.
    cmap = mcolors.LinearSegmentedColormap.from_list(
        "tiers", [
            (0.00, "#1a9850"),  # bright green: <2x
            (0.20, "#a6d96a"),  # 2-5x
            (0.40, "#fee08b"),  # 5-15x
            (0.55, "#fdae61"),  # 15-50x
            (0.70, "#f46d43"),  # 50-1000x
            (0.85, "#d73027"),  # 1000-50000x
            (1.00, "#7a0177"),  # >50000x: purple (the R outlier)
        ],
    )
    norm = mcolors.LogNorm(vmin=1.0, vmax=1e6)

    fig, ax = plt.subplots(figsize=(10.5, 11.5))
    masked = np.ma.masked_invalid(table_o)
    cmap.set_bad("#eeeeee")
    im = ax.imshow(masked, aspect="auto", cmap=cmap, norm=norm,
                   interpolation="nearest")

    # Annotate every populated cell with its number, formatted compactly.
    for i in range(table_o.shape[0]):
        for j in range(table_o.shape[1]):
            v = table_o[i, j]
            if np.isnan(v):
                continue
            if v >= 1e4:
                txt = f"{v:.0f}".replace("0000", "0e4") if v < 1e5 else \
                      f"{v:.0e}".replace("e+0", "e").replace("e+", "e")
                txt = f"{v:.0f}" if v < 1e5 else f"{int(v/1000)}k"
            elif v >= 100:
                txt = f"{v:.0f}"
            elif v >= 10:
                txt = f"{v:.1f}"
            else:
                txt = f"{v:.2f}"
            # Pick text colour for contrast.
            tc = "white" if (v < 2 or v > 1000) else "black"
            # Smaller font for larger-magnitude numbers (which need
            # more characters and would otherwise crowd the cell).
            if v >= 1000:
                fs = 4.5
            elif v >= 100:
                fs = 5.0
            else:
                fs = 5.5
            ax.text(j, i, txt, ha="center", va="center",
                    fontsize=fs, color=tc)

    ax.set_xticks(range(len(langs)))
    ax.set_xticklabels(langs, rotation=70, ha="left")
    ax.set_yticks(range(len(opts_o)))
    ax.set_yticklabels(opts_o)
    # X-axis labels and ticks on TOP (not bottom).
    ax.tick_params(axis="x", which="both", top=True, labeltop=True,
                   bottom=False, labelbottom=False)
    ax.xaxis.set_label_position("top")
    ax.set_xlabel("Language / variant", labelpad=10)
    ax.set_ylabel("Compiler / interpreter / option")

    # Cell-boundary gridlines to guide the eye.
    ax.set_xticks(np.arange(-0.5, len(langs), 1), minor=True)
    ax.set_yticks(np.arange(-0.5, len(opts_o), 1), minor=True)
    ax.grid(which="minor", color="#bbbbbb", linewidth=0.3, alpha=0.6)
    ax.tick_params(which="minor", length=0)

    # Colour bar
    cbar = fig.colorbar(im, ax=ax, fraction=0.024, pad=0.02,
                        ticks=[1, 2, 5, 15, 50, 1000, 1e5])
    cbar.ax.set_yticklabels(["1x", "2x", "5x", "15x", "50x",
                             "1000x", "100000x"])
    cbar.set_label("Relative time (1.0 = arm64 NEON assembler)")

    plt.tight_layout()
    out = os.path.join(OUT, "fig1_heatmap.pdf")
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)
    print("wrote", out)


# ----------------------------------------------------------------------
# Figure 2: tier histogram (which tiers contain how many tests).
# ----------------------------------------------------------------------

TIERS = [
    ("1. Hand-tuned NEON", 1.00, 1.10),
    ("2. AOT native, vectorised", 1.10, 2.50),
    ("3. AOT native, default opt", 2.50, 7.00),
    ("4. JIT VM / managed AOT", 7.00, 15.00),
    ("5. Vector-library wrappers", 15.00, 100.00),
    ("6. JIT-aided dynamic", 100.00, 600.00),
    ("7. Pure interpreted dynamic", 600.00, 20_000.00),
    ("8. Pathological", 20_000.00, 10**7),
]
TIER_COLOURS = [
    "#1a9850", "#66bd63", "#a6d96a",
    "#fee08b", "#fdae61", "#f46d43",
    "#d73027", "#7a0177",
]


def figure_tiers():
    rows = parse_summary()
    counts = []
    for name, lo, hi in TIERS:
        counts.append(sum(1 for r, _, _ in rows if lo <= r < hi))

    fig, ax = plt.subplots(figsize=(7.5, 4.5))
    ypos = np.arange(len(TIERS))
    bars = ax.barh(ypos, counts, color=TIER_COLOURS, edgecolor="k",
                   linewidth=0.5)
    for bar, count in zip(bars, counts):
        ax.text(bar.get_width() + 0.5, bar.get_y() + bar.get_height() / 2,
                str(count), va="center", fontsize=9)
    ax.set_yticks(ypos)
    ax.set_yticklabels([t[0] for t in TIERS])
    ax.invert_yaxis()  # tier 1 at top
    ax.set_xlabel("number of test variants in tier")
    ax.set_xlim(0, max(counts) * 1.15)
    ax.set_title("Distribution of the 131 test variants across the eight tiers")
    plt.tight_layout()
    out = os.path.join(OUT, "fig2_tiers.pdf")
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)
    print("wrote", out)


# ----------------------------------------------------------------------
# Figure 3: top 30 fastest tests, horizontal bar chart, log axis.
# ----------------------------------------------------------------------

def figure_top30():
    """Per-language-family aggregate: best (= bar height), with whiskers
    showing the family's min/max range across all its variants and a
    diamond at the geometric mean.  Sorted by family-best so the
    fastest families are at the top.  Replaces the old 30-individual-
    bars chart with a richer per-family view that captures dispersion."""

    rows = parse_summary()
    fams = OrderedDict()
    for r, lang, opt in rows:
        fams.setdefault(lang, []).append(r)

    # Sort families by their *best* result (= the bar height).
    sorted_fams = sorted(fams.items(), key=lambda kv: min(kv[1]))

    labels = [k for k, _ in sorted_fams]
    bests = np.array([min(v) for _, v in sorted_fams])
    mins = bests  # by definition the min equals the best
    maxs = np.array([max(v) for _, v in sorted_fams])
    # Geometric mean (more meaningful on log-scaled data than arithmetic).
    means = np.array([np.exp(np.mean(np.log(v))) for _, v in sorted_fams])
    nvars = [len(v) for _, v in sorted_fams]

    # Tier colour for the *best* of each family.
    def tier_colour(r):
        for (n, lo, hi), c in zip(TIERS, TIER_COLOURS):
            if lo <= r < hi:
                return c
        return "#777777"
    colours = [tier_colour(r) for r in bests]

    fig, ax = plt.subplots(figsize=(9, 9.0))
    ypos = np.arange(len(sorted_fams))
    # Bar = best
    ax.barh(ypos, bests, color=colours, edgecolor="k", linewidth=0.4,
            height=0.7, label="best variant")

    # Whisker = min..max (in log space, draw a horizontal line)
    for y, lo, hi in zip(ypos, mins, maxs):
        if lo == hi:
            continue
        ax.plot([lo, hi], [y, y], color="black", linewidth=1.2,
                solid_capstyle="butt")
        ax.plot([lo, lo], [y - 0.2, y + 0.2], color="black", linewidth=1.2)
        ax.plot([hi, hi], [y - 0.2, y + 0.2], color="black", linewidth=1.2)

    # Diamond = geometric mean across the family
    ax.scatter(means, ypos, marker="D", color="white",
               edgecolor="black", linewidth=0.6, s=22, zorder=5,
               label="geometric mean")

    # Annotate each row with best, mean, max, n
    xmax = max(maxs)
    for y, lo, mn, hi, n in zip(ypos, mins, means, maxs, nvars):
        if lo == hi:
            ax.text(hi * 1.6, y, f"{lo:.2g}  (n={n})",
                    va="center", fontsize=6.5)
        else:
            ax.text(hi * 1.6, y,
                    f"{lo:.2g} … {hi:.2g}  (n={n})",
                    va="center", fontsize=6.5)

    ax.set_yticks(ypos)
    ax.set_yticklabels(labels, fontsize=7.5)
    ax.invert_yaxis()
    ax.set_xscale("log")
    ax.set_xlabel("Relative time (log scale; 1.0 = arm64 NEON assembler)")
    ax.set_xlim(0.7, xmax * 8)
    ax.set_title(
        "Per-language-family relative speed:\n"
        "bar = best variant, whisker = min..max range, "
        "diamond = geometric mean")
    ax.legend(loc="lower right", fontsize=8)
    plt.tight_layout()
    out = os.path.join(OUT, "fig3_top30.pdf")
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)
    print("wrote", out)


# ----------------------------------------------------------------------
# Figure 6 (new): log-scale histogram of all 131 relative-time values.
# ----------------------------------------------------------------------

def figure_histogram():
    """Distribution of relative times across all 131 variants, on a log
    scale, coloured by tier."""
    rows = parse_summary()
    vals = np.array([r[0] for r in rows])

    # Logarithmically-spaced bins covering the full data range.
    bins = np.logspace(0, 6, 25)

    fig, ax = plt.subplots(figsize=(8, 4.4))
    n, edges, patches = ax.hist(vals, bins=bins, edgecolor="k",
                                linewidth=0.4)
    # Colour each bar by which tier its centre falls into.
    for p, lo, hi in zip(patches, edges[:-1], edges[1:]):
        centre = np.sqrt(lo * hi)  # geometric centre
        for (name, t_lo, t_hi), col in zip(TIERS, TIER_COLOURS):
            if t_lo <= centre < t_hi:
                p.set_facecolor(col)
                break
        else:
            p.set_facecolor("#777777")

    # Tier boundary markers (light dashed verticals).
    for name, lo, hi in TIERS[:-1]:
        ax.axvline(hi, color="#888888", linewidth=0.5,
                   linestyle="--", alpha=0.6)

    # Tier numbers at the top (just digits, no overlap).
    for (name, lo, hi), col in zip(TIERS, TIER_COLOURS):
        # Cap the upper boundary for the highest tier so the label
        # sits within the plot.
        hi_capped = min(hi, 1e6)
        ax.text(np.sqrt(lo * hi_capped), max(n) * 1.10,
                name.split(".", 1)[0],  # "1", "2", ... "8"
                ha="center", va="bottom", fontsize=10, color=col,
                fontweight="bold")

    ax.set_xscale("log")
    ax.set_xlim(0.9, 1e6)
    ax.set_ylim(0, max(n) * 1.30)
    ax.set_xlabel("Relative time (log scale; 1.0 = arm64 NEON assembler)")
    ax.set_ylabel("number of test variants")
    ax.set_title(
        "Distribution of all 131 relative-time results.\n"
        "Bins are log-spaced; colours and numbers above mark the eight tiers.")
    ax.grid(True, which="major", axis="y", linewidth=0.3, alpha=0.5)
    plt.tight_layout()
    out = os.path.join(OUT, "fig6_histogram.pdf")
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)
    print("wrote", out)


# ----------------------------------------------------------------------
# Figure 4: Octave loop vs vectorised -- the dramatic intra-language
# spread.  Plot on a log axis with annotation.
# ----------------------------------------------------------------------

def figure_octave():
    rows = parse_summary()
    # Find Octave loop and vectorised, plus a few comparisons.
    # Numbers below are taken directly from run19.log.
    targets = [
        ("hand assembler", 1.00, "#1a9850"),
        ("optimal C", 1.19, "#1a9850"),
        ("numpy vectorised (Py3)", 16.0, "#fee08b"),
        ("Octave vectorised", 57.45, "#fee08b"),
        ("Tcl raw", 13456.0, "#d73027"),
        ("Octave loop", 46705.0, "#7a0177"),
    ]
    fig, ax = plt.subplots(figsize=(7.5, 3.6))
    ypos = np.arange(len(targets))
    rels = [t[1] for t in targets]
    cols = [t[2] for t in targets]
    ax.barh(ypos, rels, color=cols, edgecolor="k", linewidth=0.4)
    for y, (lab, r, _) in zip(ypos, targets):
        ax.text(r * 1.1, y, f"{r:,.0f}" if r > 100 else f"{r:.2f}",
                va="center", fontsize=8)
    ax.set_yticks(ypos)
    ax.set_yticklabels([t[0] for t in targets])
    ax.invert_yaxis()
    ax.set_xscale("log")
    ax.set_xlabel("Relative time (log scale, 1.0 = NEON assembler)")
    ax.set_xlim(0.5, 1e6)
    ax.set_title(
        "Octave's 800x intra-language spread\n"
        "(loop and vectorised forms have identical algorithmic content)")
    plt.tight_layout()
    out = os.path.join(OUT, "fig4_octave.pdf")
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)
    print("wrote", out)


# ----------------------------------------------------------------------
# Figure 5: 2019 vs 2026 comparison (languages in both studies).
# ----------------------------------------------------------------------

def figure_2019_vs_2026():
    # Numbers from the 2019 paper Figure 1 (relative to fastest C in
    # 2019) and the 2026 reference run (relative to NEON assembler).
    # 2019 numbers from Shortridge (2019) Figure 1.  2026 numbers from
    # the canonical reference run (run19.log -- now containing the
    # post-correction run22 results).
    rows = [
        ("C raw clang -O3 native",  1.00, 1.20),
        ("Fortran -O3 native",      1.06, 2.05),
        ("Java",                    7.60, 3.70),
        ("Node.js",                28.62, 25.88),
        ("Python lists Py3",      1808.0, 644.0),
        ("Python numpy raw Py3", 20879.0, 2883.0),
        ("Python numpy vectors",   55.75, 16.0),
        ("Tcl",                  19704.0, 13456.0),
        ("Perl",                  1283.7, 716.0),
        ("Perl/PDL arrays",         51.4, 25.08),
        ("Rust -O3 native (safe)",  17.5, 12.08),
        ("Rscript raw",             354.8, 794.0),
        ("Swift -O",                33.85, 18.14),
    ]
    labels = [r[0] for r in rows]
    a2019 = [r[1] for r in rows]
    a2026 = [r[2] for r in rows]
    ypos = np.arange(len(rows))

    fig, ax = plt.subplots(figsize=(8, 6.5))
    h = 0.4
    ax.barh(ypos - h / 2, a2019, h, label="2019 (x86)",
            color="#888888", edgecolor="k", linewidth=0.4)
    ax.barh(ypos + h / 2, a2026, h, label="2026 (arm64)",
            color="#1f77b4", edgecolor="k", linewidth=0.4)
    ax.set_yticks(ypos)
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xscale("log")
    ax.set_xlabel("Relative time (log scale)")
    ax.set_xlim(0.7, 1e5)
    ax.legend(loc="lower right")
    ax.set_title(
        "2019 vs. 2026 -- languages tested in both studies\n"
        "(2019 baseline was fastest C; 2026 baseline is NEON assembler)")
    for y, v in zip(ypos - h / 2, a2019):
        ax.text(v * 1.1, y, f"{v:,.1f}" if v < 100 else f"{v:,.0f}",
                va="center", fontsize=7)
    for y, v in zip(ypos + h / 2, a2026):
        ax.text(v * 1.1, y, f"{v:,.1f}" if v < 100 else f"{v:,.0f}",
                va="center", fontsize=7)
    plt.tight_layout()
    out = os.path.join(OUT, "fig5_2019_vs_2026.pdf")
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)
    print("wrote", out)


# ----------------------------------------------------------------------

if __name__ == "__main__":
    figure_heatmap()
    figure_tiers()
    figure_top30()
    figure_octave()
    figure_2019_vs_2026()
    figure_histogram()
