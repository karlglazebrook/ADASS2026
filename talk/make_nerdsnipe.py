#!/usr/bin/env python3
"""xkcd-style closing cartoon for the talk's thank-you slide: an invitation
to be the next one nerd-sniped.

    python3 make_nerdsnipe.py      # writes img/nerdsnipe.png
"""
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "img", "nerdsnipe.png")


def main():
    with plt.xkcd(scale=1.2, length=120, randomness=2):
        plt.rcParams["font.family"] = ["Comic Sans MS"]
        fig, ax = plt.subplots(figsize=(6.4, 4.4), dpi=220)
        ax.plot([2019, 2026], [12, 27], "o-", color="#1B1F2B", lw=2.5, ms=9)
        ax.plot([2026, 2028], [27, 31], "--", color="#D73027", lw=2.5)
        ax.plot([2028], [31], "o", color="#D73027", ms=12)
        ax.annotate("KEITH,\nBY HAND", xy=(2019, 12), xytext=(2019.3, 21), fontsize=12,
                    arrowprops=dict(arrowstyle="->", color="#1B1F2B"))
        ax.annotate("ME + AN LLM,\nFOUR DAYS", xy=(2026, 27), xytext=(2022.3, 30.5), fontsize=12,
                    arrowprops=dict(arrowstyle="->", color="#1B1F2B"))
        ax.annotate("YOU?", xy=(2028, 31), xytext=(2026.6, 18.5), fontsize=20, color="#D73027", weight="bold",
                    arrowprops=dict(arrowstyle="->", color="#D73027", lw=2))
        ax.plot([2026], [5], "x", color="#D73027", ms=16, mew=3.5)
        ax.text(2024.0, 7.3, "INTERCAL:\nSTILL UNDEFEATED", fontsize=11, color="#D73027", ha="center")
        ax.set_xlim(2018, 2029.3)
        ax.set_ylim(0, 36)
        ax.set_xticks([2019, 2026, 2028])
        ax.set_xticklabels(["2019", "2026", "NEXT"])
        ax.set_yticks([0, 12, 27])
        ax.set_ylabel("LANGUAGES BENCHMARKED")
        ax.set_title("PULL REQUESTS WELCOME", fontsize=15)
        for side in ("top", "right"):
            ax.spines[side].set_visible(False)
        fig.tight_layout()
        fig.savefig(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
