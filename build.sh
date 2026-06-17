#!/usr/bin/env bash
#
# Build all versions of the notes, refresh the versioned PDFs in the repo
# root, and clean up all build artefacts.
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

# build target → output base name in the repo root
declare -A OUTNAME=(
	[notes]="AZ_lectures"
	[exam]="AZ_exam_notes"
	[exam_highlighted]="AZ_exam_notes_highlighted"
)

# directories to build, in order
TARGETS=(notes exam exam_highlighted)

# ── compile all versions ─────────────────────────────────────────
# latexmk is run inside each directory so that \input{../preamble}
# resolves relative to the current working directory. Each directory
# carries its own .latexmkrc selecting LuaLaTeX ($pdf_mode = 4).
for dir in "${TARGETS[@]}"; do
	echo "==> Compiling $dir/main.tex"
	if [ "$VERBOSE" -eq 1 ]; then
		( cd "$dir" && latexmk main.tex )
	else
		# Stay quiet on success; dump the captured output only if the
		# compile fails (warnings and hints are not worth printing).
		log="$(mktemp)"
		if ! ( cd "$dir" && latexmk main.tex ) >"$log" 2>&1; then
			echo "!!! Compile failed in $dir/ — latexmk output:" >&2
			cat "$log" >&2
			rm -f "$log"
			exit 1
		fi
		rm -f "$log"
	fi
done

# ── refresh the versioned PDFs in the repo root ──────────────────
echo "==> Removing old root PDFs"
rm -f AZ_*.pdf

for dir in "${TARGETS[@]}"; do
	dest="${OUTNAME[$dir]}_${VERSION}.pdf"
	echo "==> Copying $dir/main.pdf -> $dest"
	cp "$dir/main.pdf" "$dest"
done

# ── clean build artefacts from all directories ───────────────────
# latexmk -C removes auxiliary files *and* the generated main.pdf
# (already copied out and git-ignored). indent.log is left behind by
# latexindent, so remove it explicitly.
for dir in "${TARGETS[@]}"; do
	echo "==> Cleaning $dir"
	( cd "$dir" && latexmk -C >/dev/null )
	rm -f "$dir/indent.log"
done

echo "==> Done. Produced:"
ls -1 AZ_*.pdf
