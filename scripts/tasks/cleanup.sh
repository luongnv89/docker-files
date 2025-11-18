#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Removing Python caches and temporary files..."
find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -name "__pycache__" -type d -exec rm -rf {} +
find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -name "*.py[co]" -type f -delete

if command -v docker >/dev/null 2>&1; then
    echo "Optionally removing the temporary pre-commit Docker image..."
    docker image rm -f u2204dev:pre-commit >/dev/null 2>&1 || true
fi

echo "Cleanup step completed."
