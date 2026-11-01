#!/bin/bash
#
# run-benchmarks.sh — wrapper that sets up PATH and tool-specific
# environment variables for the 2026 ADASS2019 benchmark suite, then
# runs Run.py (in this directory) inside that environment.
#
# All toolchain path hacks live HERE so that Run.py stays
# close to the upstream KnaveAndVarlet/ADASS2019 form (just the extra
# blocks of test-list constants for the new languages, no env munging).
#
# Usage:
#   ./run-benchmarks.sh                    # default 1 round, 2000x10
#   ./run-benchmarks.sh 1 2000 10          # explicit args
#   ./run-benchmarks.sh 2>&1 | tee run24.log
#
# Footguns this wrapper avoids — see CLAUDE.md "Run.py footguns" for
# the full history:
#   * PyPy ships its own python/python3 symlinks; tools/pypy/bin is
#     therefore NOT on PATH.  Instead we expose only pypy3 via a shim
#     in $HERE/bin/.
#   * Kotlin's bin/kotlinc shell wrapper requires CONDA_PREFIX; we
#     bypass it via another shim in $HERE/bin/ that exec's the real
#     libexec/kotlin/bin/kotlinc directly.
#   * The conda r-env ships gfortran/tclsh that don't link without
#     the env activated, so adass-r is on the *tail* of PATH, where
#     only Rscript falls through.
#   * The conda py2 env is ahead of base anaconda so `python` resolves
#     to 2.7 while `python3` still resolves to base's python3 (with
#     numpy + numba).

HERE="$(cd "$(dirname "$0")" && pwd)"
# The suite (Run.py and the csub* sources) lives alongside this script.
SUITE="$HERE"
# Toolchains from install-tools.sh; override with TOOLS=... to use a tree elsewhere.
TOOLS="${TOOLS:-$HERE/tools}"
# Anaconda install holding base (numpy/numba) and the adass-* envs.
# Moved from /opt/anaconda3 in 2026; override with CONDA_ROOT=... if it moves again.
CONDA_ROOT="${CONDA_ROOT:-$HOME/anaconda3}"

# Curated bin/ directory of shim scripts.  Holds shell shims for tools
# whose own bin/ directories cannot be added to PATH safely (PyPy,
# Kotlin).  Goes first on PATH so the shims win over any system copy.
HEAD_PATHS=(
    "$HERE/bin"
    # PDL perl must beat brew perl (pulled in as a brew dependency, no PDL).
    "/Applications/PDL/bin"
    "$TOOLS/julia/bin"
    "$TOOLS/cargo/bin"
    "$TOOLS/bun/bin"
    "$TOOLS/deno/bin"
    "$TOOLS/go/bin"
    "$TOOLS/luajit/bin"
    "$TOOLS/dotnet"
    "$TOOLS/crystal/bin"
    "$TOOLS/jlang/j64"
    "$TOOLS/zig"
    "$TOOLS/ghcup-prefix/.ghcup/bin"
    "$TOOLS/ldc/bin"
    "$TOOLS/nim-2.0.8/bin"
    "$TOOLS/codon/bin"          # holds only the codon binary
    "$TOOLS/rakudo/bin"         # raku, moar, nqp (its perl6 is Raku, not perl)
    "$CONDA_ROOT/envs/adass-ocaml/bin"
    "$CONDA_ROOT/envs/adass-sbcl/bin"
    "$TOOLS/ruby/bin"
    "$CONDA_ROOT/envs/adass-rb/bin"
    "$CONDA_ROOT/envs/adass-py2/bin"
    "$CONDA_ROOT/bin"
)

# Tail dirs — only used if the tool isn't already on PATH.  adass-r is
# here so system gfortran/tclsh win and only Rscript falls through.
TAIL_PATHS=(
    "$CONDA_ROOT/envs/adass-r/bin"
)

# Build PATH: HEAD : existing PATH : TAIL
NEW_PATH=""
for d in "${HEAD_PATHS[@]}"; do NEW_PATH="$NEW_PATH$d:"; done
NEW_PATH="$NEW_PATH$PATH"
for d in "${TAIL_PATHS[@]}"; do NEW_PATH="$NEW_PATH:$d"; done
export PATH="$NEW_PATH"

# Tool-specific environment.
export RUSTUP_HOME="$TOOLS/rustup"
export CARGO_HOME="$TOOLS/cargo"
# Boost is header-only for our purposes; expose it via CPLUS_INCLUDE_PATH
# so that the original `c++ -c cbsub.cpp ...` build commands need no edits.
export CPLUS_INCLUDE_PATH="$TOOLS/boost-src${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
export DOTNET_ROOT="$TOOLS/dotnet"
# OCaml's conda package was built with a -where path that doesn't exist
# on this host; hard-set the stdlib location.
export OCAMLLIB="$CONDA_ROOT/envs/adass-ocaml/lib/ocaml"

# Run from the test-suite directory so all the cs* source files are
# found relative to cwd, exactly as the upstream Run.py expects.
cd "$SUITE"
# -u: unbuffered stdout so progress is visible when piped to `tee`.
# stdin from /dev/null so any sub-tool that detects a TTY and would
# otherwise drop into a REPL (jconsole did this, octave can, sbcl
# can) gets EOF immediately and exits cleanly.
exec python3 -u Run.py "$@" < /dev/null
