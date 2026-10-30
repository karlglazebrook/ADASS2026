#!/usr/bin/env python3
"""compare_runs.py — scatter plot of run23.log relative speeds against the
canonical run22.log values, joined by (family, variant) test identity.

Output: figs/run22_vs_run23.pdf

The interesting things to look at on the plot:
  * how tightly the points hug the y=x diagonal (perfect reproducibility)
  * which tests are outliers (typically GC-heavy or thermal-sensitive)
  * the assembler reference (1.00) shifts in absolute terms between runs
    because timing jitter rescales every relative number; everything
    else moves by the same factor.
"""
import os, re
import matplotlib.pyplot as plt
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
LOGS = {
    "run22 (canonical)": os.path.join(HERE, "run22.log"),
    "run23 (post-rebuild)": os.path.join(HERE, "run23.log"),
}
OUT_PDF = os.path.join(HERE, "figs", "run22_vs_run23.pdf")

REL_RE = re.compile(
    r"^\s*(\S.*?)\s{2,}(\S.*?)\s+1K Iter:\s+\S+,\s+Relative time\s+([0-9.]+)"
)

def parse(path):
    """Return dict (family, variant) -> relative time."""
    rows = {}
    in_block = False
    with open(path) as f:
        for line in f:
            if "Summary of relative speeds:" in line:
                in_block = True
                continue
            if in_block:
                if line.startswith("Compiler,"):
                    break
                m = REL_RE.match(line)
                if m:
                    family, variant, rel = m.groups()
                    rows[(family.strip(), variant.strip())] = float(rel)
    return rows

a = parse(LOGS["run22 (canonical)"])
b = parse(LOGS["run23 (post-rebuild)"])

common = sorted(set(a) & set(b))
only22 = sorted(set(a) - set(b))
only23 = sorted(set(b) - set(a))
print(f"Tests in both runs: {len(common)}")
print(f"Tests only in run22: {len(only22)}  {only22[:3]}")
print(f"Tests only in run23: {len(only23)}  {only23[:3]}")

x = np.array([a[k] for k in common])  # canonical
y = np.array([b[k] for k in common])  # new run

# Compute fractional differences per point: (new - old) / old
frac = (y - x) / x

# Plot
fig, (ax_main, ax_resid) = plt.subplots(
    1, 2, figsize=(12, 5.5),
    gridspec_kw={"width_ratios": [1.2, 1]},
)

# --- left: log-log scatter -------------------------------------------------
ax = ax_main
ax.set_xscale("log")
ax.set_yscale("log")
lo = min(x.min(), y.min()) * 0.5
hi = max(x.max(), y.max()) * 2.0
ax.plot([lo, hi], [lo, hi], "k--", lw=0.8, alpha=0.6, label="perfect agreement")
# Colour points by family for legibility
families = sorted({k[0] for k in common})
cmap = plt.get_cmap("tab20", len(families))
for i, fam in enumerate(families):
    idx = [j for j, k in enumerate(common) if k[0] == fam]
    ax.scatter(x[idx], y[idx], s=24, alpha=0.8, color=cmap(i), label=fam,
               edgecolor="white", linewidth=0.4)

# Annotate the outliers (>20% off the diagonal)
big = np.abs(frac) > 0.20
for j in np.where(big)[0]:
    fam, var = common[j]
    ax.annotate(
        f"{fam}/{var}",
        xy=(x[j], y[j]),
        xytext=(4, 4), textcoords="offset points",
        fontsize=6.5, alpha=0.85,
    )

ax.set_xlim(lo, hi)
ax.set_ylim(lo, hi)
ax.set_xlabel("Relative time, run22 (canonical)")
ax.set_ylabel("Relative time, run23 (post toolchain rebuild)")
ax.set_title("Per-test relative speed: run22 vs run23")
ax.grid(True, which="both", ls=":", lw=0.5, alpha=0.5)
ax.legend(loc="upper left", fontsize=6, ncol=2, framealpha=0.85)

# --- right: histogram of fractional differences ----------------------------
ax = ax_resid
ax.hist(frac * 100.0, bins=40, color="#4477aa", edgecolor="white", linewidth=0.5)
ax.axvline(0, color="k", lw=0.8, alpha=0.6)
median = np.median(frac) * 100
mean = np.mean(frac) * 100
std = np.std(frac) * 100
ax.set_xlabel("(run23 − run22) / run22  [%]")
ax.set_ylabel("number of tests")
ax.set_title(f"Distribution of fractional change\nmedian={median:+.1f}%   mean={mean:+.1f}%   σ={std:.1f}%")
ax.grid(True, ls=":", lw=0.5, alpha=0.5)

plt.tight_layout()
os.makedirs(os.path.dirname(OUT_PDF), exist_ok=True)
plt.savefig(OUT_PDF)
print(f"Wrote {OUT_PDF}")

# Also print the top-5 biggest movers, both directions
order = np.argsort(frac)
print("\nTop-5 SLOWED-DOWN tests (run23 slower than run22):")
for j in order[-5:][::-1]:
    print(f"  {common[j][0]:20s} {common[j][1]:30s} "
          f"{x[j]:>9.2f} -> {y[j]:>9.2f}  ({frac[j]*100:+.1f}%)")
print("\nTop-5 SPED-UP tests (run23 faster than run22):")
for j in order[:5]:
    print(f"  {common[j][0]:20s} {common[j][1]:30s} "
          f"{x[j]:>9.2f} -> {y[j]:>9.2f}  ({frac[j]*100:+.1f}%)")
