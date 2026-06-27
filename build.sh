#!/usr/bin/env bash
#
# Build both versions of the notes from the single notes/ source, refresh the
# versioned PDFs in the repo root, and clean up all build artefacts.
#
# Two PDFs are produced from one source by toggling the AZ_HIGHLIGHT environment
# variable, which the preamble reads (via LuaTeX) to switch the obowiazkowy
# highlight on or off:
#   AZ_HIGHLIGHT unset/0 → AZ_lectures             (plain)
#   AZ_HIGHLIGHT=1       → AZ_lectures_highlighted  (obligatory material on a tint)
# AZ_SKIP=1 additionally drops the non-obligatory proofs entirely:
#   AZ_HIGHLIGHT=1 AZ_SKIP=1 → AZ_lectures_exam     (quick-revision: essentials only)
#
# Usage:  ./build.sh [-v|--verbose] [VERSION]
#   -v, --verbose  stream the full latexmk output (default: only show it
#                  when a compile fails; warnings and hints are hidden)
#   VERSION        tag for the output file names, e.g. v1.0.0
#                  (default: latest git tag, or "dev" if there are none)
#
set -euo pipefail

# ── parse arguments ──────────────────────────────────────────────
VERBOSE=0
VERSION=""
for arg in "$@"; do
	case "$arg" in
		-v|--verbose) VERBOSE=1 ;;
		*)            VERSION="$arg" ;;
	esac
done

# ── resolve paths and version ────────────────────────────────────
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo dev)}"

SRC=notes

# builds to produce: "output base name:AZ_HIGHLIGHT:AZ_SKIP"
#   plain        — wszystko, bez wyróżnień
#   highlighted  — materiał obowiązkowy na tle, nieobowiązkowe dowody w szarych ramkach
#   exam         — wyróżnienia + nieobowiązkowe dowody wycięte (szybka powtórka)
BUILDS=(
	"AZ_lectures:0:0"
	"AZ_lectures_highlighted:1:0"
	"AZ_lectures_exam:1:1"
)

# ── refresh the versioned PDFs in the repo root ──────────────────
echo "==> Removing old root PDFs"
rm -f AZ_*.pdf

# ── compile each version ─────────────────────────────────────────
# latexmk runs inside notes/ so that \input{../preamble} resolves relative to
# the current working directory; notes/.latexmkrc selects LuaLaTeX ($pdf_mode=4).
# Both builds share the same source bytes (only AZ_HIGHLIGHT differs), so latexmk
# cannot tell them apart from file timestamps — we force a rebuild with -g and
# copy main.pdf out before the next build overwrites it.
for entry in "${BUILDS[@]}"; do
	IFS=: read -r name hl skip <<<"$entry"
	dest="${name}_${VERSION}.pdf"
	echo "==> Compiling $SRC/main.tex (AZ_HIGHLIGHT=$hl AZ_SKIP=$skip) -> $dest"
	if [ "$VERBOSE" -eq 1 ]; then
		( cd "$SRC" && AZ_HIGHLIGHT="$hl" AZ_SKIP="$skip" latexmk -g main.tex )
	else
		# Stay quiet on success; dump the captured output only if the
		# compile fails (warnings and hints are not worth printing).
		log="$(mktemp)"
		if ! ( cd "$SRC" && AZ_HIGHLIGHT="$hl" AZ_SKIP="$skip" latexmk -g main.tex ) >"$log" 2>&1; then
			echo "!!! Compile failed ($SRC, AZ_HIGHLIGHT=$hl AZ_SKIP=$skip) — latexmk output:" >&2
			cat "$log" >&2
			rm -f "$log"
			exit 1
		fi
		rm -f "$log"
	fi
	cp "$SRC/main.pdf" "$dest"
done

# ── compile the examples booklet (single version, no highlight) ──
EX_SRC=examples
EX_DEST="AZ_examples_${VERSION}.pdf"
echo "==> Compiling $EX_SRC/przyklady.tex -> $EX_DEST"
if [ "$VERBOSE" -eq 1 ]; then
	( cd "$EX_SRC" && latexmk -g przyklady.tex )
else
	log="$(mktemp)"
	if ! ( cd "$EX_SRC" && latexmk -g przyklady.tex ) >"$log" 2>&1; then
		echo "!!! Compile failed ($EX_SRC) — latexmk output:" >&2
		cat "$log" >&2
		rm -f "$log"
		exit 1
	fi
	rm -f "$log"
fi
cp "$EX_SRC/przyklady.pdf" "$EX_DEST"
( cd "$EX_SRC" && latexmk -C >/dev/null )
rm -f "$EX_SRC/indent.log"

# ── clean build artefacts ────────────────────────────────────────
# latexmk -C removes auxiliary files *and* the generated main.pdf (already
# copied out and git-ignored). indent.log is left behind by latexindent, so
# remove it explicitly.
echo "==> Cleaning $SRC"
( cd "$SRC" && latexmk -C >/dev/null )
rm -f "$SRC/indent.log"

echo "==> Done. Produced:"
ls -1 AZ_*.pdf
