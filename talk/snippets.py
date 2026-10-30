#!/usr/bin/env python3
"""Extract the benchmark kernels shown on the talk's code slides.

Reads the real source files in the repo by line number, syntax-highlights
them with Pygments (github-dark), and writes snippets.json for build_deck.js.
Each snippet also carries its run22 relative time, looked up by test name.

    python3 snippets.py        # needs pygments
"""
import json
import os
import re

from pygments import lex
from pygments.lexers import get_lexer_by_name
from pygments.styles import get_style_by_name

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
STYLE = get_style_by_name("github-dark")
GAP = "⋮"  # vertical ellipsis, marks omitted lines

# (label, file, lines, lexer, run22 test name). Lines are 1-based and
# inclusive; a jump in the list is drawn as a GAP line.
WALL = [
    ("Assembler (arm64 NEON)", "cnrsub_arm.s", [*range(275, 279), *range(286, 290)], "gas", "Assembler clang (arm64)"),
    ("Julia", "csub.jl", range(84, 92), "julia", "Julia julia"),
    ("Fortran", "cfsub.f", [55, *range(60, 66)], "fortran", "Fortran gfortran -O3 native"),
    ("Python + numba", "csubnp-numba.py", range(113, 118), "python", "Python : numpy raw Python3 numba"),
    ("Go", "csubraw.go", range(13, 22), "go", "Go go"),
    ("LuaJIT", "csubraw.lua", range(9, 18), "lua", "Lua LuaJIT"),
    ("J", "csubraw.ijs", range(10, 14), "j", "J jconsole"),
    ("Nim", "csubraw.nim", range(12, 18), "nim", "Nim nim -d:danger"),
    ("PDL (arrays)", "csubpdlary.pl", range(109, 113), "perl", "Perl/PDL : arrays Perl/PDL"),
    ("R (outer)", "csubouter.r", range(122, 125), "r", "R : outer Rscript"),
    ("Common Lisp (SBCL)", "csubraw.lisp", range(19, 24), "common-lisp", "Lisp SBCL untyped"),
    ("Tcl", "ctest.tcl", [91, *range(94, 101)], "tcl", "Tcl : raw tclsh"),
]
NUMBA = ("Python + numba", "csubnp-numba.py", range(113, 118), "python", "Python : numpy raw Python3 numba")


def run22_times():
    txt = open(os.path.join(REPO, "report", "run22.log")).read()
    txt = txt[txt.index("Summary of relative speeds:"):]
    out = {}
    for line in txt.split("\n"):
        m = re.match(r"\s*(.+?)\s+1K Iter:.*Relative time\s+([0-9.]+)", line)
        if m:
            out[re.sub(r"\s+", " ", m.group(1))] = float(m.group(2))
    return out


def colour(ttype):
    while ttype not in STYLE.styles or not STYLE.style_for_token(ttype)["color"]:
        if ttype.parent is None:
            return "E6EDF3", False, False
        ttype = ttype.parent
    st = STYLE.style_for_token(ttype)
    return st["color"].upper(), st["bold"], st["italic"]


def snippet(label, fname, lines, lexer, test, times):
    src = open(os.path.join(REPO, fname)).read().expandtabs(3).split("\n")
    lines = list(lines)
    picked, prev = [], None
    for n in lines:
        if prev is not None and n != prev + 1:
            picked.append(None)
        text = src[n - 1].rstrip()
        if lexer == "gas":  # drop trailing assembler comments to fit the card
            text = text.split(";")[0].rstrip()
        picked.append(text)
        prev = n
    indent = min(len(t) - len(t.lstrip()) for t in picked if t)
    picked = [t[indent:] if t is not None else None for t in picked]
    lx = get_lexer_by_name(lexer)
    rows = []
    for t in picked:
        if t is None:
            rows.append([{"t": GAP, "c": "8B949E", "b": False, "i": False}])
            continue
        runs = []
        for ttype, val in lex(t, lx):
            val = val.rstrip("\n")
            if not val:
                continue
            c, b, i = colour(ttype)
            if runs and runs[-1]["c"] == c and runs[-1]["b"] == b and runs[-1]["i"] == i:
                runs[-1]["t"] += val
            else:
                runs.append({"t": val, "c": c, "b": b, "i": i})
        rows.append(runs or [{"t": " ", "c": "E6EDF3", "b": False, "i": False}])
    return {
        "label": label, "file": fname, "lines": f"{lines[0]}–{lines[-1]}",
        "test": test, "rel": times[test], "rows": rows,
        "width": max(len(t) for t in picked if t), "background": STYLE.background_color.lstrip("#").upper(),
    }


def main():
    times = run22_times()
    data = {"wall": [snippet(*s, times) for s in WALL], "numba": snippet(*NUMBA, times)}
    with open(os.path.join(HERE, "snippets.json"), "w") as f:
        json.dump(data, f, indent=1)
    for s in data["wall"]:
        print(f"{s['rel']:9.2f}  {s['label']:24s} {s['file']}:{s['lines']}  {len(s['rows'])} rows x {s['width']} cols")


if __name__ == "__main__":
    main()
