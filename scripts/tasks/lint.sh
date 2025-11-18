#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

lint_shell() {
    local files=("$@")
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No shell scripts to lint."
        return 0
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck "${files[@]}"
        echo "Shell scripts linted with shellcheck."
    elif command -v docker >/dev/null 2>&1; then
        docker run --rm -v "$ROOT_DIR":/work -w /work koalaman/shellcheck:stable "${files[@]/$ROOT_DIR\//}"
        echo "Shell scripts linted with Dockerized shellcheck."
    else
        echo "shellcheck not available locally or via Docker. Skipping shell lint." >&2
    fi
}

lint_dockerfiles() {
    local dockerfiles=("$@")
    if [[ ${#dockerfiles[@]} -eq 0 ]]; then
        echo "No Dockerfiles to lint."
        return 0
    fi

    if command -v hadolint >/dev/null 2>&1; then
        hadolint "${dockerfiles[@]}"
        echo "Dockerfiles linted with hadolint."
    elif command -v docker >/dev/null 2>&1; then
        for file in "${dockerfiles[@]}"; do
            docker run --rm -i hadolint/hadolint <"$file"
        done
        echo "Dockerfiles linted with Dockerized hadolint."
    else
        echo "hadolint not available locally or via Docker. Skipping Dockerfile lint." >&2
    fi
}

readarray -t SH_FILES < <(find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -type f -name "*.sh" -print)
readarray -t DOCKERFILES < <(find "$ROOT_DIR" -type f -name "Dockerfile")

lint_shell "${SH_FILES[@]}"
lint_dockerfiles "${DOCKERFILES[@]}"
