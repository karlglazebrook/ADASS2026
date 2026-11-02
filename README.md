# ADASS 2026: a reprise of Shortridge (2019)

This repo is a fork of Keith Shortridge's benchmark suite
([KnaveAndVarlet/ADASS2019](https://github.com/KnaveAndVarlet/ADASS2019);
his original readme is `README-2019.md`, and his full write-up is
`FullWriteUp.pdf`), extended for the talk *Same Source, Three Orders of
Magnitude*, Karl Glazebrook, ADASS 2026, Perth.

The kernel is unchanged: `Out[iy][ix] = In[iy][ix] + ix + iy` on a 2000 × 10
float array. The 2026 runs are on Apple Silicon (arm64), with times relative to
Keith's hand-written NEON assembler kernel (`cnrsub_arm.s`) = 1.00. The talk used
27 languages (Keith's 12 plus 15 new) in 131 variants (run22). The suite has since
grown to 41 languages in 192 variants (run30): the talk's 131 plus
- 14 more languages: APL, Ada, Chapel, Clojure, Dart, Elixir, GDL (IDL), MATLAB,
  Mojo, PHP, Raku, Scheme (Chez), awk and bash;
- new compilers and runtimes for existing languages: Cython, Pythran, Codon,
  GraalPy, the CPython JIT, TruffleRuby, PUC Lua 5.5, Perl `Inline::C`, and C
  compiled to WebAssembly (wasmtime and Node.js);
- idiom and precision variants: Keith's C kernel in `double`, Fortran array
  syntax and `do concurrent`, Julia broadcast, flat `Float64Array` JavaScript,
  and Swift on a flat array or a `Grid` struct.

Then an expert code-idiom review (2 Nov 2026). Two independent reviewers, ChatGPT
and seven Claude Fable reviewers each covering a group of languages, judged every
kernel as an expert in its language would. The 168 variants they recommended are
now tests too: 360 in all (run31). Each new test names the test it improves on,
and the kind of change: idiom, compiler flags, float32 precision, or a fairness
fix such as integer data in a supposedly floating-point test. The reviews
themselves are kept outside this repo.

The new ports (`csubraw.*`, `csubraw-typed.lisp`, `csubvec.m`, `csubnumo.rb`,
`csubpdlpp.pl`, the C#/F# project directories and the other new `csub*` and
`c*test*` files) sit next to Keith's 2019 files and `Run.py`. Each source file's
header says what it tests.

Porting, toolchain work and analysis were done with Claude Sonnet 4.7 (Anthropic)
as co-author, and the November 2026 extension with Claude Opus 5.5. The talk and the full write-up are kept outside this repo.

## Contents

| Path | What |
|---|---|
| `results/run22.log` | The frozen reference run (30 Apr 2026). Every number in the talk comes from it |
| `results/run23.log` | Re-run after a full toolchain rebuild (1 May 2026) |
| `results/run30.log` | The full 192-test suite (1 Nov 2026), 192/192 passed |
| `results/run31.log` | The 360-test suite with the idiom-review variants (2 Nov 2026), 360/360 passed |
| `results/run31-matlab.log` | The eight MATLAB tests re-run with MATLAB's internal timing (see below); use these in place of run31's MATLAB lines |
| `run-benchmarks.sh` | Sets up PATH and environment for every toolchain, then runs `Run.py` |
| `install-tools.sh` | Installs the pinned toolchains into `tools/` (about 3 GB, 7–10 min) |
| `bin/` | Shims for tools whose own `bin/` directories would hijack other tests (they ship their own `python`, `ruby` or `gcc`), and for MATLAB, GDL and Mojo launchers |

## Running it

```sh
./install-tools.sh            # or TOOLS=/elsewhere ./install-tools.sh
./run-benchmarks.sh | tee run32.log
```

A full run of all 360 tests takes about 35 minutes on an M-series Mac.

`install-tools.sh` does not install a few prerequisites: Homebrew gfortran,
Octave and libyaml, Java 17+, Apple clang, the PDL distribution in
`/Applications/PDL`, conda environments `adass-{py2,r,sbcl,ocaml,kotlin,rb}`
under `$CONDA_ROOT` (default `~/anaconda3`), several Homebrew packages for the
newer languages (Clojure, Elixir, Chapel, Lua, PHP, Chez Scheme, mawk, gawk,
bash, Dart), Dyalog APL, and a licensed MATLAB. See the header of
`install-tools.sh`.

## Changes to the 2019 code

`csubpdl.pl` (PDL "raw") now uses `->at` and `->set` for element access instead
of `->slice`, which builds a one-element slice on every access. This makes it
about 11× faster (103,570 → 9,207). Keith's 2019 write-up already noted that
`->slice` was not the way PDL should be used. `Run.py` has extra test blocks for
the new languages; the environment setup lives in `run-benchmarks.sh`.

The idiom review found three problems in the 2019 harness and code, fixed in
November 2026:
- **Rust timed a transposed array.** Keith's `crsmain.rs`, `crsmain_iter.rs` and
  `crsmain_unsafe.rs` read their arguments as `nrpt ny nx`, but `Run.py` passes
  `nrpt nx ny`. So every Rust result, 2019 included, timed 2,000 rows of 10
  columns. They now read `nrpt nx ny`, which makes Rust 1.3–1.5× faster at `-O`
  and `-O3`.
- **`Run.py` checked only the exit status.** Every test program prints "Error"
  when its result check fails and still exits with status 0. Also, the
  one-repeat run overwrote the status of the timed run. A test now fails if
  either run reports an error.
- **The reference was the fastest test, not the assembler.** Relative times are
  now against `Assembler clang (arm64)` explicitly, because one 2026 float32
  variant (Rust, flat array with `u32` indices, 0.96) beats it.

`Run.py` also times with a monotonic clock now, and uses a program's own timer
when it prints `Internal time <secs> s`. Only the MATLAB programs do, because
MATLAB's start-up varies by several seconds from one launch to the next, which
the wall-clock subtraction cannot remove.

The labels of Keith's tests are unchanged, so results can still be matched to
2019. Two of them are misleading on macOS: `g++` is Apple clang, the same
compiler as `c++` (the `g++-15` tests are real GCC), and `-march=native` makes
no difference to the generated code.
