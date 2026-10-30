# ADASS 2026 — competitive talk submission (v2)

> **STATUS: Accepted as an oral talk — ADASS 2026, Perth, November 2026.**
> This file is kept as the submitted record; the submitted abstract text
> below is unchanged.  Live talk-prep material (deck outline, discussion
> points, slide ordering) lives in `Discussion-outline.md` and the figure
> set in `figs/`.


## Title

**Same Source, Three Orders of Magnitude:
A 2026 Reprise of Shortridge's Compiler Benchmark, Co-Authored with an LLM**

(Backup: *Languages, Compilers, and the JIT Tier That Didn't Exist in 2019*)

---

## Authors

Karl Glazebrook (Swinburne University of Technology)
*With analysis assistance from Claude Sonnet 4.7 (Anthropic)*

---

## Abstract (≈ 140 words)

In 2019, Shortridge benchmarked twelve programming languages on a
trivial 2-D-array kernel and found a million-fold range of execution
speeds --- the sort of result that quietly reshapes how one thinks
about code performance. We have reprised that study seven years
later, on modern Apple-Silicon hardware, expanded it to twenty-nine
languages, and --- as a first for ADASS --- used a large language
model as porting and analysis partner.

The most useful new finding for working astronomers is that the
choice that matters most is no longer *which language*, but
*which runtime*. A Python loop can now run two or three orders of
magnitude faster than the unmodified CPython baseline simply by
swapping the interpreter or adding a JIT decorator --- no rewrite,
no C extension, no language switch. We discuss what this implies
for scientific Python practice, what the AI co-author contributed,
and what it did not.

---

## One-line punch (for the conference programme)

> Same Python source, three orders of magnitude, no rewrite ---
> 2026's JIT tier puts native speeds within reach of working
> scientists who never leave the interpreter.

---

## Why this is competitive for ADASS 2026

1. **Direct community continuation** of a popular ADASS 2019 paper;
   title will be recognised on sight.
2. **A fresh actionable headline** for working astronomers: stop
   thinking about choice of language, start thinking about choice
   of runtime. Reach for `@njit` before reaching for C.
3. **Methodological novelty** — the LLM-as-co-author workflow,
   demonstrated live, including the auditor pattern.
4. **A concrete erratum to the 2019 study**: PDL "raw" was
   inadvertently using a slice-construction primitive instead of
   element access; the corrected number moves PDL out of the
   pathological tier and into the same ballpark as numpy raw. The
   PDL community will want to know.
5. **Apple Silicon is now standard kit in observational
   astronomy** --- these are the first published benchmarks of the
   full Shortridge suite on M-series.

---

## Suggested keywords

benchmarking; programming languages; LLM-assisted research;
JIT compilation; numba; PyPy; LuaJIT; PDL; numpy; Apple Silicon;
arm64; reproducibility

---

## Talk structure (15 min slot)

| min | content |
|---|---|
| 0–2 | The 2019 finding and why it matters; what changed in 7 years |
| 2–5 | The runtime story: same Python source, three orders of magnitude (CPython → PyPy → numba) |
| 5–8 | The new JIT-aided dynamic tier; LuaJIT, Ruby+YJIT, V8 |
| 8–10 | Three small surprises: PyPy×numpy footgun; PDL `->slice` correction; SBCL type-declaration cliff |
| 10–13 | The LLM partnership: what worked, what didn't, the audit-loop pattern |
| 13–14 | Recommendations for working astronomers (one slide) |
| 14–15 | Q & A |

---

## Supplementary material on submission

* Full 21-page write-up (`Report-2026.pdf`)
* All source (extended fork of `KnaveAndVarlet/ADASS2019`)
* Frozen reference benchmark log (`run22.log`)
* `CLAUDE.md` orientation file documenting run-and-rebuild workflow
* Full LLM dialogue trail (every prompt and response across the
  several-day collaborative session, including the audit rounds)
