#!/usr/bin/env python3
"""The report's per-family figure (fig3) for the talk, with the languages
new in 2026 labelled in red.

    python3 make_family_figure.py   # writes img/fig3_top30.png
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "report"))
import make_figures  # noqa: E402

# Run.py family names (first word) of the 15 languages new in 2026.
NEW = {"C#", "F#", "Go", "Kotlin", "Haskell", "D", "Zig", "Crystal", "Nim",
       "OCaml", "Ruby", "Lua", "J", "Lisp", "Octave"}

if __name__ == "__main__":
    make_figures.figure_top30(highlight=NEW, out=os.path.join(HERE, "img", "fig3_top30.png"))
