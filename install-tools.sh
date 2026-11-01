#!/usr/bin/env bash
#
# install-tools.sh — fetch and build every toolchain the ADASS-2019-redux
# benchmark suite needs, into ./tools/ next to this script.
#
# Pinned versions match what produced run22.log (the canonical reference
# the report cites).  Re-running this script on a fresh checkout should
# reproduce the same toolchain layout, modulo systemwide tools (Apple
# clang, system Java, brew gfortran/Octave/libyaml, conda envs) which
# are out of scope — see PREREQUISITES below.
#
# Usage:
#   ./install-tools.sh                  # install everything missing
#   ./install-tools.sh julia ruby ghc   # install just these
#   ./install-tools.sh --force          # reinstall everything
#   ./install-tools.sh --list           # show what each step would do
#
# Disk: about 7-8 GB once everything is installed.  Wall time on a
# modern Apple Silicon Mac with a decent connection: 30-60 min,
# dominated by the Ruby and Nim source builds.
#
# Platform: macOS arm64 only.  The download URLs all pick the
# aarch64-apple-darwin asset where one is offered.
#
# PREREQUISITES (NOT installed by this script):
#   * Apple clang from Xcode CLT             (xcode-select --install)
#   * system Java 17+ (brew install openjdk@17 or system)
#   * brew gfortran                          (brew install gcc)
#   * brew octave                            (brew install octave)
#   * brew libyaml                           (brew install libyaml — Ruby psych)
#   * conda envs:
#       conda create -n adass-py2    -c conda-forge python=2.7 numpy
#       conda create -n adass-r      -c conda-forge r-base
#       conda create -n adass-sbcl   -c conda-forge sbcl
#       conda create -n adass-ocaml  -c conda-forge ocaml ocaml-base-compiler
#       conda create -n adass-kotlin -c conda-forge kotlin
#       conda create -n adass-rb     -c conda-forge ruby   # fallback only

set -e

# ---------------------------------------------------------------------------
# Pinned versions — change these together with run22.log if you ever
# re-baseline the suite.
# ---------------------------------------------------------------------------
JULIA_VER=1.10.4
BUN_VER=1.3.13
DENO_VER=2.7.13
GO_VER=1.22.0
CRYSTAL_VER=1.16.3
JLANG_VER=9.6                    # the J version family — installs latest 9.6.x
PYPY_PYVER=3.10                  # PyPy's claimed Python version
PYPY_VER=7.3.16                  # PyPy's own version
ZIG_VER=0.13.0
LDC_VER=1.41.0-beta1
NIM_VER=2.0.8
LUAJIT_COMMIT=v2.1.ROLLING       # LuaJIT v2.1 has no semver release; we pin a tag
LUAJIT_REF=v2.1                  # ...rolling tag of "2.1" branch
RUBY_VER=3.3.6
GHC_VER=9.10.1
RUSTC_VER=1.95.0
DOTNET_CHANNEL=8.0
BOOST_VER=1.85.0
BOOST_VER_UNDER=1_85_0           # boost archive uses underscores
# Compiled-Python tests (added 1 Nov 2026, after run22).
CODON_VER=0.20.4
CYTHON_VER=3.3.0
PYTHRAN_VER=0.19.0
MOJO_VER=1.2.0
RAKUDO_VER=2026.09               # binary release, build revision 01

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLS="${TOOLS:-$HERE/tools}"
mkdir -p "$TOOLS"
DOWNLOADS="$TOOLS/.downloads"
mkdir -p "$DOWNLOADS"

FORCE=0
LIST_ONLY=0
ARGS=()
for a in "$@"; do
    case "$a" in
        --force) FORCE=1 ;;
        --list)  LIST_ONLY=1 ;;
        --help|-h) sed -n '2,30p' "$0"; exit 0 ;;
        *) ARGS+=("$a") ;;
    esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
say()   { printf "\n=== %s ===\n" "$*"; }
note()  { printf "    %s\n" "$*"; }
skip()  { printf "    [skip] %s\n" "$*"; }
fetch() {
    # fetch URL FILE — download to FILE (skip if file already exists)
    local url=$1 dst=$2
    if [[ -s "$dst" ]] && [[ $FORCE -eq 0 ]]; then
        skip "already downloaded: $(basename "$dst")"
    else
        note "fetching $(basename "$dst")"
        curl -fL --retry 3 --progress-bar -o "$dst" "$url"
    fi
}
have_target() {
    # have_target BINARY EXPECTED — return 0 if BINARY exists and its
    # version output contains EXPECTED.
    local bin=$1 expected=$2
    [[ -x "$bin" ]] || return 1
    "$bin" --version 2>&1 | grep -q -- "$expected"
}
should_run() {
    # should_run NAME — return 0 if user asked for NAME (or all).
    local name=$1
    if [[ ${#ARGS[@]} -eq 0 ]]; then return 0; fi
    for a in "${ARGS[@]}"; do
        [[ "$a" == "$name" ]] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# Install functions — one per tool.  Each is idempotent.
# ---------------------------------------------------------------------------

install_julia() {
    should_run julia || return 0
    say "Julia $JULIA_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install julia $JULIA_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/julia/bin/julia" "$JULIA_VER"; then
        skip "julia $JULIA_VER already at $TOOLS/julia"; return
    fi
    local tarball="$DOWNLOADS/julia-$JULIA_VER-macaarch64.tar.gz"
    fetch "https://julialang-s3.julialang.org/bin/mac/aarch64/${JULIA_VER%.*}/julia-$JULIA_VER-macaarch64.tar.gz" "$tarball"
    rm -rf "$TOOLS/julia" "$TOOLS/julia-$JULIA_VER"
    tar -C "$TOOLS" -xzf "$tarball"
    mv "$TOOLS/julia-$JULIA_VER" "$TOOLS/julia"
    "$TOOLS/julia/bin/julia" --version
}

install_bun() {
    should_run bun || return 0
    say "Bun $BUN_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install bun $BUN_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/bun/bin/bun" "$BUN_VER"; then
        skip "bun $BUN_VER already at $TOOLS/bun"; return
    fi
    local zip="$DOWNLOADS/bun-darwin-aarch64-v$BUN_VER.zip"
    fetch "https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VER/bun-darwin-aarch64.zip" "$zip"
    rm -rf "$TOOLS/bun"
    mkdir -p "$TOOLS/bun/bin"
    unzip -q -j "$zip" -d "$TOOLS/bun/bin/"
    chmod +x "$TOOLS/bun/bin/bun"
    "$TOOLS/bun/bin/bun" --version
}

install_deno() {
    should_run deno || return 0
    say "Deno $DENO_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install deno $DENO_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/deno/bin/deno" "$DENO_VER"; then
        skip "deno $DENO_VER already at $TOOLS/deno"; return
    fi
    local zip="$DOWNLOADS/deno-aarch64-apple-darwin-$DENO_VER.zip"
    fetch "https://github.com/denoland/deno/releases/download/v$DENO_VER/deno-aarch64-apple-darwin.zip" "$zip"
    rm -rf "$TOOLS/deno"
    mkdir -p "$TOOLS/deno/bin"
    unzip -q -j "$zip" -d "$TOOLS/deno/bin/"
    chmod +x "$TOOLS/deno/bin/deno"
    "$TOOLS/deno/bin/deno" --version | head -1
}

install_go() {
    should_run go || return 0
    say "Go $GO_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install go $GO_VER"; return; }
    # Go's CLI uses `go version`, not `go --version`, so have_target won't work.
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/go/bin/go" ]] \
       && "$TOOLS/go/bin/go" version 2>&1 | grep -q "go$GO_VER"; then
        skip "go $GO_VER already at $TOOLS/go"; return
    fi
    local tarball="$DOWNLOADS/go$GO_VER.darwin-arm64.tar.gz"
    fetch "https://go.dev/dl/go$GO_VER.darwin-arm64.tar.gz" "$tarball"
    rm -rf "$TOOLS/go"
    tar -C "$TOOLS" -xzf "$tarball"
    "$TOOLS/go/bin/go" version
}

install_crystal() {
    should_run crystal || return 0
    say "Crystal $CRYSTAL_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install crystal $CRYSTAL_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/crystal/bin/crystal" "$CRYSTAL_VER"; then
        skip "crystal $CRYSTAL_VER already at $TOOLS/crystal"; return
    fi
    local tarball="$DOWNLOADS/crystal-$CRYSTAL_VER-1-darwin-universal.tar.gz"
    fetch "https://github.com/crystal-lang/crystal/releases/download/$CRYSTAL_VER/crystal-$CRYSTAL_VER-1-darwin-universal.tar.gz" "$tarball"
    rm -rf "$TOOLS/crystal" "$TOOLS/crystal-$CRYSTAL_VER-1"
    tar -C "$TOOLS" -xzf "$tarball"
    mv "$TOOLS/crystal-$CRYSTAL_VER-1" "$TOOLS/crystal"
    "$TOOLS/crystal/bin/crystal" --version | head -1
}

install_jlang() {
    should_run jlang || return 0
    say "J $JLANG_VER (latest .x in family)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install J $JLANG_VER"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/jlang/j64/jconsole" ]]; then
        skip "J already at $TOOLS/jlang"; return
    fi
    # jsoftware.com's URL for the macOS arm64/Intel install zip:
    local zip="$DOWNLOADS/j${JLANG_VER}_mac64.zip"
    fetch "https://www.jsoftware.com/download/j$JLANG_VER/install/j${JLANG_VER}_mac64.zip" "$zip"
    rm -rf "$TOOLS/jlang"
    mkdir -p "$TOOLS/jlang"
    unzip -q "$zip" -d "$TOOLS/jlang/"
    # Normalise the top-level dir name to "j64" — the zip names it after
    # the version family (e.g. "j9.6/"), but our PATH entry in
    # run-benchmarks.sh expects "j64/" for compatibility with older J builds.
    [[ -d "$TOOLS/jlang/j64" ]] || {
        local first
        first=$(ls "$TOOLS/jlang" | head -1)
        mv "$TOOLS/jlang/$first" "$TOOLS/jlang/j64"
    }
    # The 9.6 install puts the real binary at j64/bin/jconsole AND its
    # libj.dylib in the same dir.  jconsole loads libj.dylib via dlopen
    # of the relative path "bin/libj.dylib", which is interpreted
    # relative to the *caller's* cwd — so invoking jconsole from anywhere
    # other than j64/ fails with a "Load library bin/libj.dylib failed"
    # error.  We work around this by replacing the j64/jconsole entry
    # (which Run.py expects on PATH) with a thin wrapper that sets
    # DYLD_LIBRARY_PATH and exec's the real binary, preserving the
    # caller's cwd so script-file arguments still resolve.
    rm -f "$TOOLS/jlang/j64/jconsole"
    cat > "$TOOLS/jlang/j64/jconsole" <<'JCONSOLE_WRAPPER'
#!/bin/sh
# jconsole wrapper — see install-tools.sh / install_jlang for why
HERE=$(cd "$(dirname "$0")" && pwd)
exec env DYLD_LIBRARY_PATH="$HERE/bin${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$HERE/bin/jconsole" "$@"
JCONSOLE_WRAPPER
    chmod +x "$TOOLS/jlang/j64/jconsole" "$TOOLS/jlang/j64/bin/jconsole"
    # Strip Apple quarantine xattr so macOS doesn't refuse to run the
    # binary the first time (jsoftware ships an unsigned dmg/zip).
    /usr/bin/xattr -rc "$TOOLS/jlang/j64" 2>/dev/null || true
    "$TOOLS/jlang/j64/jconsole" "$HERE/verJ.ijs"
}

install_pypy() {
    should_run pypy || return 0
    say "PyPy $PYPY_VER (Python $PYPY_PYVER)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install pypy $PYPY_VER"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/pypy/bin/pypy3" ]] \
       && "$TOOLS/pypy/bin/pypy3" --version 2>&1 | grep -q "PyPy $PYPY_VER"; then
        skip "pypy $PYPY_VER already at $TOOLS/pypy"; return
    fi
    local tarball="$DOWNLOADS/pypy$PYPY_PYVER-v$PYPY_VER-macos_arm64.tar.bz2"
    fetch "https://downloads.python.org/pypy/pypy$PYPY_PYVER-v$PYPY_VER-macos_arm64.tar.bz2" "$tarball"
    rm -rf "$TOOLS/pypy" "$TOOLS/pypy$PYPY_PYVER-v$PYPY_VER-macos_arm64"
    tar -C "$TOOLS" -xjf "$tarball"
    mv "$TOOLS/pypy$PYPY_PYVER-v$PYPY_VER-macos_arm64" "$TOOLS/pypy"
    "$TOOLS/pypy/bin/pypy3" --version | head -1
    note "Installing numpy in PyPy..."
    "$TOOLS/pypy/bin/pypy3" -m ensurepip 2>/dev/null
    "$TOOLS/pypy/bin/pypy3" -m pip install --upgrade pip wheel 2>&1 | tail -3
    "$TOOLS/pypy/bin/pypy3" -m pip install numpy 2>&1 | tail -3
}

install_codon() {
    should_run codon || return 0
    say "Codon $CODON_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install codon $CODON_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/codon/bin/codon" "$CODON_VER"; then
        skip "codon $CODON_VER already at $TOOLS/codon"; return
    fi
    local tarball="$DOWNLOADS/codon-$CODON_VER-darwin-arm64.tar.gz"
    fetch "https://github.com/exaloop/codon/releases/download/v$CODON_VER/codon-darwin-arm64.tar.gz" "$tarball"
    rm -rf "$TOOLS/codon" && mkdir -p "$TOOLS/codon"
    tar -C "$TOOLS/codon" -xzf "$tarball" --strip-components=1
    "$TOOLS/codon/bin/codon" --version
}

install_pyext() {
    # Cython and Pythran, in a venv on the Anaconda base python (which
    # supplies numpy).  Reached only through bin/pyext-python: the venv's
    # own bin/ has python and python3, so it must never go on PATH.
    should_run pyext || return 0
    say "Cython $CYTHON_VER + Pythran $PYTHRAN_VER (venv tools/pyext)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would create tools/pyext with cython $CYTHON_VER, pythran $PYTHRAN_VER"; return; }
    local py="${CONDA_ROOT:-$HOME/anaconda3}/bin/python3"
    if [[ $FORCE -eq 1 ]] || [[ ! -x "$TOOLS/pyext/bin/python" ]]; then
        rm -rf "$TOOLS/pyext"
        "$py" -m venv --system-site-packages "$TOOLS/pyext"
    fi
    "$TOOLS/pyext/bin/python" -m pip install -q "cython==$CYTHON_VER" "pythran==$PYTHRAN_VER"
    "$TOOLS/pyext/bin/python" -m cython --version
}

install_mojo() {
    # Mojo from PyPI, in its own venv; reached only through bin/mojo.
    should_run mojo || return 0
    say "Mojo $MOJO_VER (venv tools/mojo)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would create tools/mojo with mojo $MOJO_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/mojo/bin/mojo" "Mojo $MOJO_VER"; then
        skip "mojo $MOJO_VER already at $TOOLS/mojo"; return
    fi
    local py="${CONDA_ROOT:-$HOME/anaconda3}/bin/python3"
    rm -rf "$TOOLS/mojo"
    "$py" -m venv "$TOOLS/mojo"
    "$TOOLS/mojo/bin/python" -m pip install -q "mojo==$MOJO_VER"
    "$TOOLS/mojo/bin/mojo" --version
}

install_rakudo() {
    should_run rakudo || return 0
    say "Rakudo $RAKUDO_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install rakudo $RAKUDO_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/rakudo/bin/raku" "v$RAKUDO_VER"; then
        skip "rakudo $RAKUDO_VER already at $TOOLS/rakudo"; return
    fi
    local tarball="$DOWNLOADS/rakudo-moar-$RAKUDO_VER-01-macos-arm64-clang.tar.gz"
    fetch "https://rakudo.org/dl/rakudo/rakudo-moar-$RAKUDO_VER-01-macos-arm64-clang.tar.gz" "$tarball"
    rm -rf "$TOOLS/rakudo" && mkdir -p "$TOOLS/rakudo"
    tar -C "$TOOLS/rakudo" -xzf "$tarball" --strip-components=1
    "$TOOLS/rakudo/bin/raku" --version | head -1
}

install_zig() {
    should_run zig || return 0
    say "Zig $ZIG_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install zig $ZIG_VER"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/zig/zig" ]] \
       && "$TOOLS/zig/zig" version 2>&1 | grep -q "$ZIG_VER"; then
        skip "zig $ZIG_VER already at $TOOLS/zig"; return
    fi
    local tarball="$DOWNLOADS/zig-macos-aarch64-$ZIG_VER.tar.xz"
    fetch "https://ziglang.org/download/$ZIG_VER/zig-macos-aarch64-$ZIG_VER.tar.xz" "$tarball"
    rm -rf "$TOOLS/zig" "$TOOLS/zig-macos-aarch64-$ZIG_VER"
    tar -C "$TOOLS" -xJf "$tarball"
    mv "$TOOLS/zig-macos-aarch64-$ZIG_VER" "$TOOLS/zig"
    "$TOOLS/zig/zig" version
}

install_ldc() {
    should_run ldc || return 0
    say "LDC $LDC_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install ldc $LDC_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/ldc/bin/ldc2" "$LDC_VER"; then
        skip "ldc $LDC_VER already at $TOOLS/ldc"; return
    fi
    local tarball="$DOWNLOADS/ldc2-$LDC_VER-osx-arm64.tar.xz"
    fetch "https://github.com/ldc-developers/ldc/releases/download/v$LDC_VER/ldc2-$LDC_VER-osx-arm64.tar.xz" "$tarball"
    rm -rf "$TOOLS/ldc" "$TOOLS/ldc2-$LDC_VER-osx-arm64"
    tar -C "$TOOLS" -xJf "$tarball"
    mv "$TOOLS/ldc2-$LDC_VER-osx-arm64" "$TOOLS/ldc"
    "$TOOLS/ldc/bin/ldc2" --version | head -1
}

install_nim() {
    should_run nim || return 0
    say "Nim $NIM_VER (build from source)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would build nim $NIM_VER"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/nim-$NIM_VER/bin/nim" ]] \
       && "$TOOLS/nim-$NIM_VER/bin/nim" --version 2>&1 | grep -q "$NIM_VER"; then
        skip "nim $NIM_VER already at $TOOLS/nim-$NIM_VER"; return
    fi
    local tarball="$DOWNLOADS/nim-$NIM_VER.tar.xz"
    fetch "https://nim-lang.org/download/nim-$NIM_VER.tar.xz" "$tarball"
    rm -rf "$TOOLS/nim-$NIM_VER"
    tar -C "$TOOLS" -xJf "$tarball"
    note "compiling nim..."
    ( cd "$TOOLS/nim-$NIM_VER" && sh build.sh && bin/nim c koch && ./koch boot -d:release )
    "$TOOLS/nim-$NIM_VER/bin/nim" --version | head -1
}

install_luajit() {
    should_run luajit || return 0
    say "LuaJIT $LUAJIT_REF (build from source)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would build luajit $LUAJIT_REF"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/luajit/bin/luajit" ]]; then
        skip "luajit already at $TOOLS/luajit"; return
    fi
    local src="$TOOLS/.luajit-src"
    rm -rf "$src" "$TOOLS/luajit"
    git clone --depth 1 --branch "$LUAJIT_REF" https://github.com/LuaJIT/LuaJIT.git "$src"
    # LuaJIT's Makefile demands MACOSX_DEPLOYMENT_TARGET be set explicitly
    # on macOS — without it, `make` aborts at line 322 of src/Makefile.
    ( cd "$src" \
      && export MACOSX_DEPLOYMENT_TARGET=11.0 \
      && make -j"$(sysctl -n hw.ncpu)" \
      && make install PREFIX="$TOOLS/luajit" )
    rm -rf "$src"
    # The build installs as `luajit-2.1.X`; symlink to plain `luajit`.
    ( cd "$TOOLS/luajit/bin" && ln -sf luajit-2.1.* luajit )
    "$TOOLS/luajit/bin/luajit" -v
}

install_ruby() {
    should_run ruby || return 0
    say "Ruby $RUBY_VER + YJIT (build from source)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would build ruby $RUBY_VER"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/ruby/bin/ruby" "$RUBY_VER"; then
        skip "ruby $RUBY_VER already at $TOOLS/ruby"; return
    fi
    if ! [[ -e /opt/homebrew/include/yaml.h ]]; then
        note "ERROR: brew libyaml not found. Run: brew install libyaml"
        return 1
    fi
    if ! [[ -x "$TOOLS/cargo/bin/rustc" ]]; then
        note "ERROR: rustc needed for --enable-yjit; install rust first"
        return 1
    fi
    local tarball="$DOWNLOADS/ruby-$RUBY_VER.tar.gz"
    fetch "https://cache.ruby-lang.org/pub/ruby/${RUBY_VER%.*}/ruby-$RUBY_VER.tar.gz" "$tarball"
    local src="$TOOLS/.ruby-src"
    rm -rf "$src" "$TOOLS/ruby"
    mkdir -p "$src"
    tar -C "$src" -xzf "$tarball" --strip-components=1
    ( cd "$src" \
      && export RUSTUP_HOME="$TOOLS/rustup" \
      && export CARGO_HOME="$TOOLS/cargo" \
      && export PATH="$TOOLS/cargo/bin:$PATH" \
      && export CPPFLAGS="-I/opt/homebrew/include" \
      && export LDFLAGS="-L/opt/homebrew/lib" \
      && ./configure --prefix="$TOOLS/ruby" --enable-yjit --disable-install-doc \
      && make -j"$(sysctl -n hw.ncpu)" \
      && make install )
    rm -rf "$src"
    "$TOOLS/ruby/bin/ruby" --version
    note "installing numo-narray (used by RubyNumo benchmark)..."
    "$TOOLS/ruby/bin/gem" install numo-narray --no-document
}

install_rust() {
    should_run rust || return 0
    say "Rust $RUSTC_VER"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install rust $RUSTC_VER via rustup"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/cargo/bin/rustc" ]]; then
        local v
        v=$(RUSTUP_HOME="$TOOLS/rustup" CARGO_HOME="$TOOLS/cargo" \
            "$TOOLS/cargo/bin/rustc" --version 2>&1 || true)
        if echo "$v" | grep -q "$RUSTC_VER"; then
            skip "rust $RUSTC_VER already at $TOOLS/cargo"; return
        fi
    fi
    local installer="$DOWNLOADS/rustup-init.sh"
    fetch "https://sh.rustup.rs" "$installer"
    chmod +x "$installer"
    RUSTUP_HOME="$TOOLS/rustup" CARGO_HOME="$TOOLS/cargo" \
        "$installer" -y --no-modify-path \
        --default-toolchain "$RUSTC_VER" \
        --default-host aarch64-apple-darwin \
        --profile minimal
    RUSTUP_HOME="$TOOLS/rustup" CARGO_HOME="$TOOLS/cargo" \
        "$TOOLS/cargo/bin/rustc" --version
}

install_ghc() {
    should_run ghc || return 0
    say "GHC $GHC_VER (via ghcup)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install ghc $GHC_VER via ghcup"; return; }
    if [[ $FORCE -eq 0 ]] && have_target "$TOOLS/ghcup-prefix/.ghcup/bin/ghc" "$GHC_VER"; then
        skip "ghc $GHC_VER already installed via ghcup"; return
    fi
    local prefix="$TOOLS/ghcup-prefix"
    if ! [[ -x "$prefix/.ghcup/bin/ghcup" ]]; then
        note "bootstrapping ghcup..."
        export GHCUP_INSTALL_BASE_PREFIX="$prefix"
        export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
        export BOOTSTRAP_HASKELL_MINIMAL=1
        export BOOTSTRAP_HASKELL_NO_UPGRADE=1
        curl -fsSL https://get-ghcup.haskell.org | sh
        unset GHCUP_INSTALL_BASE_PREFIX BOOTSTRAP_HASKELL_NONINTERACTIVE \
              BOOTSTRAP_HASKELL_MINIMAL BOOTSTRAP_HASKELL_NO_UPGRADE
    fi
    note "installing ghc $GHC_VER..."
    GHCUP_INSTALL_BASE_PREFIX="$prefix" \
        "$prefix/.ghcup/bin/ghcup" install ghc "$GHC_VER" --force --set
    "$prefix/.ghcup/bin/ghc" --version
}

install_dotnet() {
    should_run dotnet || return 0
    say ".NET SDK $DOTNET_CHANNEL"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install .NET $DOTNET_CHANNEL"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -x "$TOOLS/dotnet/dotnet" ]]; then
        skip ".NET already at $TOOLS/dotnet"; return
    fi
    local installer="$DOWNLOADS/dotnet-install.sh"
    fetch "https://dot.net/v1/dotnet-install.sh" "$installer"
    chmod +x "$installer"
    "$installer" --channel "$DOTNET_CHANNEL" --install-dir "$TOOLS/dotnet" --no-path
    "$TOOLS/dotnet/dotnet" --version
}

install_boost() {
    should_run boost || return 0
    say "Boost $BOOST_VER (headers only)"
    [[ $LIST_ONLY -eq 1 ]] && { note "would install boost $BOOST_VER source"; return; }
    if [[ $FORCE -eq 0 ]] && [[ -d "$TOOLS/boost-src/boost" ]]; then
        skip "boost-src already at $TOOLS/boost-src"; return
    fi
    local tarball="$DOWNLOADS/boost_$BOOST_VER_UNDER.tar.bz2"
    fetch "https://archives.boost.io/release/$BOOST_VER/source/boost_$BOOST_VER_UNDER.tar.bz2" "$tarball"
    rm -rf "$TOOLS/boost-src"
    mkdir -p "$TOOLS/boost-src"
    tar -C "$TOOLS/boost-src" -xjf "$tarball" --strip-components=1
    note "boost headers at $TOOLS/boost-src/boost/"
}

# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

FAILED_STEPS=()
run_step() {
    # run_step NAME — invoke install_NAME, recording but not propagating
    # any failure.  This isolates per-tool errors (a J URL 404 should not
    # prevent the other 15 tools from installing).
    local name=$1
    if ! "install_$name"; then
        echo ""
        echo "*** WARNING: $name installation FAILED — continuing ***"
        echo ""
        FAILED_STEPS+=("$name")
    fi
}

main() {
    cat <<EOF
ADASS-2019-redux toolchain installer
====================================
Target dir: $TOOLS
Force mode: $([[ $FORCE -eq 1 ]] && echo yes || echo no)
Selection : ${ARGS[*]:-all}

EOF
    # Install rust before ruby (ruby --enable-yjit needs rustc).
    # Install ghc late so ghcup's download time doesn't gate everything.
    run_step julia
    run_step rust
    run_step bun
    run_step deno
    run_step go
    run_step crystal
    run_step jlang
    run_step pypy
    run_step zig
    run_step ldc
    run_step luajit
    run_step dotnet
    run_step boost
    run_step nim
    run_step ruby
    run_step ghc
    run_step codon
    run_step pyext
    run_step mojo
    run_step rakudo

    say "Installation summary"
    if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
        note "All requested toolchains installed successfully."
    else
        note "${#FAILED_STEPS[@]} tool(s) failed: ${FAILED_STEPS[*]}"
        note "(everything else succeeded; re-run individual steps after fixing)"
    fi
    note "Total disk used by tools/:"
    du -sh "$TOOLS"
    note "Run the benchmark with: ./run-benchmarks.sh"
}

main
