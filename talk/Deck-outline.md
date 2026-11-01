# Deck outline — ADASS 2026, 15-min oral (v2)

All numbers are relative times from `run22.log` (NEON assembler = 1.00)
unless marked otherwise. Sources for the story slides: Shortridge
FullWriteUp (Nov 2019), "Email from Keith.rtfd" (Jan 2024),
SESSION-NOTES.md (Apr–May 2026).

| min | slides | section |
|---|---|---|
| 0–1 | 1–2 | Title; Keith's 2019 study |
| 1–3 | 3–4 | How I got involved; then Claude Code |
| 3–4 | 5 | The 2026 suite at a glance |
| 4–6.5 | 6–7 | Runtime beats language |
| 6.5–8 | 8 | Runtimes new to the suite |
| 8–9.5 | 9 | Three small surprises (incl. the PDL loop-back) |
| 9.5–12.5 | 10–11 | The LLM partnership |
| 12.5–13.5 | 12 | Recommendations |
| 13.5–15 | 13 | Thanks / Q&A |

---

## Part A — the story

### 1. Title
*Same Source, Three Orders of Magnitude: A 2026 Reprise of Shortridge's
Compiler Benchmark, Co-Authored with an LLM.* Karl Glazebrook
(Swinburne), with analysis assistance from Claude Sonnet 4.7
(Anthropic). Model name confirmed by Karl, 30 Oct.

### 2. Keith Shortridge, ADASS 2019 (a reminder)
- Paper P9-17 and poster: *Languages, Compilers, Options and
  Astronomical Images*.
- 12 languages: C/C++, Fortran, Java, JavaScript, Julia, Perl/PDL,
  Python, R, Rust, Swift, Tcl, assembler.
- One trivial kernel, `Out[iy][ix] = In[iy][ix] + ix + iy` (2000 × 10
  floats). It measures how each language reaches an array element.
- Headline: a range of about a million. Compiler options alone gave
  nearly 500× within a single program.
- The conference feedback went straight back into the study: a Julia
  tweak matched the best C, Rust idioms gave 2×, and numba was added.
  ADASS doing its job.
- Show the paper's title block and one of Keith's result plots.

### 3. Where I came in (2019 → 2024)
- **2019:** I sent Keith the one-line "arrays" forms for both PDL
  (`sequence($Nx) + sequence($Ny)->dummy(0,1)`) and numpy
  (`newaxis`). He credits both in the FullWriteUp.
- Keith already had doubts about his PDL raw test: `->slice` element
  access was "emphatically not the way PDL should be used". Hold
  that thought until slide 9.
- **2022:** Keith wrote an arm64 NEON assembler kernel (Aug 2022).
- **Jan 2024:** we emailed about PDL::PP (`csubpdlpp.pl`), with
  Inline compiler flags: no optimise 9.3 s, -O1 2.9 s, -O2/-O3
  2.2 s on my M1. Keith then sent me the assembler kernel, which
  became the 1.00 reference for all of 2026.
- Quote from Keith (Jan 2024): gains from assembler over C are
  "marginal and not worth the effort".
- Footnote: I wrote PDL (1996), so treat my PDL views as biased.

### 4. Then Claude Code: seven days in April 2026
A timeline graphic of language families against day:
- **25 Apr:** cloned KnaveAndVarlet/ADASS2019 and ran it. 58 of 103
  tests passed. "The goal is maximum coverage."
- **26 Apr:** 103/103. Assembler made the 1.00 reference. PDL::PP,
  Ruby, Bun and Deno added.
- **27 Apr:** Ruby 3.3 built from source with YJIT; 111/111.
- **28–29 Apr, "a bit mad":** Go, LuaJIT, C#, Crystal, OCaml, J,
  then PyPy, Zig, SBCL, Haskell. INTERCAL fails ("PROGRAMMER IS
  OVERLY POLITE"). Reached 24 families and 123 tests. Me: "Do #1 to
  #7 please and then we will stop :)". Then Octave, giving
  **27 languages, 131 tests**.
- **29 Apr – 1 May:** a 20-page report, about 7 rounds of auditing
  by a second LLM, the PDL correction, run22 frozen, and a script
  that reinstalls every toolchain (7.5 min).
- **Scale:** 7 days, 23 benchmark runs, about 1,060 of my prompts
  and 935 tool calls.

---

## Part B — results (as planned)

### 5. The 2026 suite at a glance
- Apple Silicon arm64, Keith's NEON kernel = 1.00.
- 27 languages (Keith's 12 + 15 new), 131 variants, 131/131 passing (run22).
- Range about 4.8×10⁵ (1.00 to the R reference class at 481,009).
- The tiers: 1/20/41/16/30/4/16/3 entries. Tier 3 (2.5–7) is the
  crowd.
- Figure: `fig2_tiers` or `fig6_histogram`.

### 6. Same Python source, three orders of magnitude (headline)
A ladder graphic:
- CPython + numpy, element loop: **2,883**
- CPython, plain lists: **644**
- PyPy, plain lists: **36.2** (17.8× faster from a different
  interpreter)
- numpy, vectorised: **16.1**
- numba `@njit` on the element-loop code: **3.15**, which is **915×**
  from one decorator.

### 7. The pattern holds beyond Python
- Within one language, the runtime or idiom spans 2–3 orders of
  magnitude:
  - Octave loop 46,705 → vectorised 57.5 (813×)
  - PDL raw 9,207 → PDL::PP 5.47 (1,683×)
  - Ruby 755 → YJIT 284
- Across compiled languages, the spread is under 10×: Julia int32
  1.17, best C 1.19, Fortran 2.05, D 2.76, Zig 2.84, Java 3.70,
  Go 6.91.

### 8. Runtimes new to the suite
**"New" means new to this benchmark, not new technology.** Put
this table on the slide:

| | entries | run22 |
|---|---|---|
| Already in Keith's 2019 study | Java (HotSpot JIT), Node (V8), Julia, numba | 3.70 / 25.88 / 1.17–3.40 / 3.15 |
| Old technology, first time in this suite | LuaJIT (2005), PyPy (2007), C# .NET JIT, SBCL, J | 7.59 / 36.2 / 5.31 / 10.6 / 8.24 |
| Genuinely post-2019 | Deno (1.0 in 2020), Ruby YJIT (Ruby 3.1, 2021), Bun (1.0 in 2023), .NET native AOT (2023) | 24.43 / 284 / 12.29 / 5.39 |

- What it shows: dynamic languages with a good JIT now sit inside
  compiled territory. LuaJIT at 7.59 beats safe Rust -O3 (12.04)
  and Swift -O (18.14).
- Bun is about 2× faster than Node (12.29 vs 25.88).
- Don't claim V8's optimiser drives Node here: Node `--no-opt` is
  26.54, almost the same.
- Julia, in one line: a loop with the same shape as the Python list
  version runs at 1.17 against 644.
- **Drop the backup title** "...the JIT Tier That Didn't Exist in
  2019". Java, V8, Julia and numba were all in 2019.
- Q&A risk: CPython 3.13's experimental JIT isn't tested (run22
  used Python 3.12.7).

### 9. Three small surprises
1. **PyPy + numpy = 22,015**: 609× slower than PyPy on lists, and
   7.6× slower than CPython + numpy. Each numpy call goes through
   PyPy's `cpyext` C-extension layer, which wipes out the JIT's
   advantage. Use one or the other.
2. **The PDL loop-back (keep it short):** the "raw" test now uses
   PDL's element-access primitives `->at`/`->set` instead of
   `->slice`. 103,570 → 9,207 (about 11×), roughly level with
   numpy's element loop (2,883) rather than far below it. Keith
   flagged `->slice` in 2019; I made the switch in 2026. The LLM
   ran the old code faithfully and reported "PDL is just slow".
3. **SBCL type declarations:** untyped 167 → typed 10.6 (15.7×).
   Give the compiler the types.

---

## Part C — the LLM and the take-home

### 10. What the LLM did well
- Ported 15 new languages in about 4 days (counted as Keith did:
  C/C++ and Perl/PDL are one each; PyPy is Python), adapting the kernel to
  each language's idioms. J came in at 9 lines and needed no hints
  from me ("I never 'supplied J hints' – that was all you").
- Fixed the environment clashes. PyPy's `python3` symlink took over
  7 numpy tests; conda's Octave shipped its own perl and python;
  the Kotlin wrapper needed `CONDA_PREFIX`; GHC and Ruby had the
  install path baked into 235 files.
- Built the figure and table pipeline and a toolchain installer
  that reproduces everything (rebuilt in 7.5 min, re-run matched).

### 11. What it didn't do, and the audit loop
- Didn't spot the PDL problem (see slide 9).
- **Silent drift:** it quoted numbers from older runs and fixed the
  prose but not the table, or the table but not the prose. Auditing
  by a second LLM over about 7 rounds caught 14 distinct errors in
  the first four. Examples: Crystal 3.21 → 3.67, F# 6.85 → 7.21, an
  OCaml ratio quoted as 18× when it was 13×.
- **Undiscriminating:** asked what to add, it produced a long, flat
  list. Choosing from it was my job. My verdict on one abstract
  draft: it "would appeal only to an LLM not a human".
- INTERCAL is a toolchain failure (C-INTERCAL's arm64 `va_arg`
  bug), not an LLM failure. Use it as the joke, not as evidence.
- Diagram: write → criticise (second LLM) → re-check against the
  log → repeat.
- Continuity: in my Jan 2024 email I was already "asking ChatGPT
  for hints" on PDL::PP compiler flags.

### 12. What to tell a working astronomer
1. Before rewriting a loop in C, try `@njit`.
2. Use PyPy for pure-Python code only, never with numpy.
3. Don't loop element by element over numpy arrays; it is 4.5×
   slower than plain lists.
4. In PDL, use `->at`/`->set` for single elements, broadcasting or
   PDL::PP for speed.
5. Apple Silicon penalises no language here.
6. An LLM co-author works with an audit loop and your own domain
   expertise behind it.

### 13. Thanks / Q&A
Thank Keith first and by name. Then links: the repo fork, the
report, `run22.log`.

---

## Backup slides
- Reproducibility: `run22_vs_run23.pdf`. The fast tiers agree; the
  slow entries moved (Octave loop −44%, Rust unoptimised +30%).
- 2019 vs 2026 (`fig5`): different hardware (x86 AVX, now arm64
  NEON).
- Caveats: Python 2.7 runs under Rosetta; the assembler reference
  drifts about 10% between runs.
- Octave detail (`fig4_octave`); full ranked list (Appendix C).

---

## Revisions, 1 Nov 2026

- New slide after "suite at a glance": every language from best to worst
  variant, the 15 new ones in red (`make_language_ranges.py` →
  `img/fig7_language_ranges.png`).
- Main code wall is now 4 × 4: the 15 new languages plus Keith's C as the
  reference. The backup wall holds one kernel from each of Keith's 12.
- "Raw" is called "element lookup" on the slides (Keith's harness label
  stays "raw"); the surprises slide has a one-line note.
- PyPy + numpy meme uses the 1895 Gare Montparnasse photo (public domain,
  Wikimedia Commons).
- "What it didn't do" adds the authorship caveat: I didn't write the ports,
  and nobody with language expertise has reviewed them; future work is
  expert and multi-LLM review of the kernels.
- New slide after it: what the ChatGPT red team caught.
