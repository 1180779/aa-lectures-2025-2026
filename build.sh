#!/usr/bin/env bash
#
# Build the notes (three variants) and the examples booklet from their single
# sources and refresh the versioned PDFs in the repo root.
#
# Two PDFs are produced from one source by toggling the AZ_HIGHLIGHT environment
# variable, which the preamble reads (via LuaTeX) to switch the obowiazkowy
# highlight on or off:
#   AZ_HIGHLIGHT unset/0 → AZ_lectures             (plain)
#   AZ_HIGHLIGHT=1       → AZ_lectures_highlighted  (obligatory material on a tint)
# AZ_SKIP=1 additionally drops the non-obligatory proofs entirely:
#   AZ_HIGHLIGHT=1 AZ_SKIP=1 → AZ_lectures_exam     (quick-revision: essentials only)
#
# Usage:  ./build.sh [-h|--help] [-v|--verbose] [--notes|--examples|--exams] [VERSION]
#   -h, --help     print this usage and exit
#   -v, --verbose  stream the full latexmk output (default: only show it
#                  when a compile fails; warnings and hints are hidden)
#   --notes        build only the notes
#   --examples     build only the examples booklet
#   --exams        build only the exam solutions (needs notes/main.aux for refs)
#   VERSION        tag for the output file names, e.g. v1.0.0
#                  (default: latest git tag, or "dev" if there are none)
#
# Build artefacts from the last compile are left in place (cleaned at the
# start of the next run), so editors / viewers keep working aux files around.
#
set -euo pipefail

# ── parse arguments ──────────────────────────────────────────────
VERBOSE=0
VERSION=""
TARGET=all   # all | notes | examples | exams
usage() {
	sed -n '14,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}
want() { [ "$TARGET" = all ] || [ "$TARGET" = "$1" ]; }
for arg in "$@"; do
	case "$arg" in
		-h|--help)    usage; exit 0 ;;
		-v|--verbose) VERBOSE=1 ;;
		--notes)      TARGET=notes ;;
		--examples)   TARGET=examples ;;
		--exams)      TARGET=exams ;;
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

# ── clean stale artefacts up front (last run's are kept until now) ──
# latexmk -C removes auxiliary files *and* the generated PDFs (already copied
# out and git-ignored). indent.log is left behind by latexindent.
clean_dir() {
	( cd "$1" && latexmk -C >/dev/null 2>&1 || true )
	rm -f "$1/indent.log"
}
echo "==> Cleaning stale artefacts"
if want notes;    then clean_dir notes; fi
if want examples; then clean_dir examples; fi
if want exams; then clean_dir exams; fi

# ── refresh the versioned PDFs in the repo root ──────────────────
echo "==> Removing old root PDFs"
if want notes;    then rm -f AZ_lectures*.pdf; fi
if want examples; then rm -f AZ_examples*.pdf; fi
if want exams; then rm -f AZ_exams*.pdf; fi

# ── compile each version ─────────────────────────────────────────
# latexmk runs inside notes/ so that \input{../preamble} resolves relative to
# the current working directory; notes/.latexmkrc selects LuaLaTeX ($pdf_mode=4).
# Both builds share the same source bytes (only AZ_HIGHLIGHT differs), so latexmk
# cannot tell them apart from file timestamps — we force a rebuild with -g and
# copy main.pdf out before the next build overwrites it.
if want notes; then
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
fi

# ── compile the examples booklet (single version, no highlight) ──
if want examples; then
EX_SRC=examples
EX_DEST="AZ_examples_${VERSION}.pdf"
echo "==> Compiling $EX_SRC/examples.tex -> $EX_DEST"
if [ "$VERBOSE" -eq 1 ]; then
	( cd "$EX_SRC" && latexmk -g examples.tex )
else
	log="$(mktemp)"
	if ! ( cd "$EX_SRC" && latexmk -g examples.tex ) >"$log" 2>&1; then
		echo "!!! Compile failed ($EX_SRC) — latexmk output:" >&2
		cat "$log" >&2
		rm -f "$log"
		exit 1
	fi
	rm -f "$log"
fi
cp "$EX_SRC/examples.pdf" "$EX_DEST"
fi

# ── compile the exam solutions (single version; refs to notes/main.aux) ──
if want exams; then
EG_DEST="AZ_exams_${VERSION}.pdf"
echo "==> Compiling exams/exams.tex -> $EG_DEST"
if [ "$VERBOSE" -eq 1 ]; then
	( cd exams && latexmk -g exams.tex )
else
	log="$(mktemp)"
	if ! ( cd exams && latexmk -g exams.tex ) >"$log" 2>&1; then
		echo "!!! Compile failed (exams) — latexmk output:" >&2
		cat "$log" >&2
		rm -f "$log"
		exit 1
	fi
	rm -f "$log"
fi
cp exams/exams.pdf "$EG_DEST"
fi

# Build artefacts are intentionally kept (cleaned at the start of the next run).
echo "==> Done. Produced:"
ls -1 AZ_*.pdf
