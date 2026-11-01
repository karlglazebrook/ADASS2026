# ADASS 2026: a reprise of Shortridge (2019)

This repo is a fork of Keith Shortridge's benchmark suite
([KnaveAndVarlet/ADASS2019](https://github.com/KnaveAndVarlet/ADASS2019);
his original readme is `README-2019.md`, and his full write-up is
`FullWriteUp.pdf`), extended for the talk *Same Source, Three Orders of
Magnitude*, Karl Glazebrook, ADASS 2026, Perth.

The kernel is unchanged: `Out[iy][ix] = In[iy][ix] + ix + iy` on a 2000 × 10
float array. The 2026 runs are on Apple Silicon (arm64), with times relative to
Keith's hand-written NEON assembler kernel (`cnrsub_arm.s`) = 1.00. The suite now
covers 27 languages (Keith's 12 plus 15 new) in 131 variants. The new ports (`csubraw.*`,
`csubraw-typed.lisp`, `csubvec.m`, `csubnumo.rb`, `csubpdlpp.pl` and the C#/F#
project directories) sit next to Keith's 2019 files and `Run.py`.

Porting, toolchain work and analysis were done with Claude Sonnet 4.7 (Anthropic)
as co-author. The talk and the full write-up are kept outside this repo.

## Contents

| Path | What |
|---|---|
| `results/run22.log` | The frozen reference run (30 Apr 2026). Every number in the talk comes from it |
| `results/run23.log` | Re-run after a full toolchain rebuild (1 May 2026) |
| `run-benchmarks.sh` | Sets up PATH and environment for every toolchain, then runs `Run.py` |
| `install-tools.sh` | Installs the pinned toolchains into `tools/` (about 3 GB, 7–10 min) |
| `bin/` | Shims for PyPy and Kotlin, whose own `bin/` directories would hijack other tests |

## Running it

```sh
./install-tools.sh            # or TOOLS=/elsewhere ./install-tools.sh
./run-benchmarks.sh | tee run24.log
```

A full run takes about 10 minutes on an M-series Mac.

`install-tools.sh` does not install a few prerequisites: Homebrew gfortran,
Octave and libyaml, Java 17+, Apple clang, the PDL distribution in
`/Applications/PDL`, and conda environments `adass-{py2,r,sbcl,ocaml,kotlin,rb}`
under `$CONDA_ROOT` (default `~/anaconda3`). See the header of `install-tools.sh`.

## Change to the 2019 code

`csubpdl.pl` (PDL "raw") now uses `->at` and `->set` for element access instead
of `->slice`, which builds a one-element slice on every access. This makes it
about 11× faster (103,570 → 9,207). Keith's 2019 write-up already noted that
`->slice` was not the way PDL should be used. `Run.py` has extra test blocks for
the new languages; the environment setup lives in `run-benchmarks.sh`.
