#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

readarray -t SH_FILES < <(find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -type f -name "*.sh" -print)

if [[ ${#SH_FILES[@]} -eq 0 ]]; then
    echo "No shell scripts detected for formatting."
    exit 0
fi

if command -v shfmt >/dev/null 2>&1; then
    shfmt -w "${SH_FILES[@]}"
    echo "Formatted shell scripts using local shfmt."
elif command -v docker >/dev/null 2>&1; then
    # Use shfmt via Docker without requiring a local install
    docker run --rm -v "$ROOT_DIR":/work -w /work mvdan/shfmt:3.8.0 -w "${SH_FILES[@]/$ROOT_DIR\//}"
    echo "Formatted shell scripts using Dockerized shfmt."
else
    echo "shfmt not available locally or via Docker. Skipping formatting." >&2
fi
