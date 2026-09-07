#!/usr/bin/env bash
# devbox-launch.sh — Create and launch a devbox container with configurable options.
#
# Usage:
#   ./devbox-launch.sh [OPTIONS]
#
# Options:
#   -w, --workspace PATH   Workspace directory to mount (default: current directory)
#   -n, --name NAME        Container name (default: auto-generated with "devbox-" prefix)
#   -i, --image IMAGE      Docker image to use (default: ghcr.io/luongnv89/devbox:latest)
#   -p, --port PORT        Port mapping (can be specified multiple times, e.g. -p 5173:5173)
#   -e, --env KEY=VALUE    Environment variable (can be specified multiple times)
#   -d, --detach           Run container in detached mode (no attach)
#   -h, --help             Show this help message
#
# Features:
#   - Workspace mounting (user-specified or current directory)
#   - Auto-generated or custom container names (prefix: devbox-)
#   - AI skills-only mounting (~/.agents → /root/.agents)
#   - SSH config volume with rewritten host paths for container compatibility
#   - gh CLI auth for GitHub operations
#   - Automatic container attachment after startup (unless --detach)

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
IMAGE="ghcr.io/luongnv89/devbox:latest"
WORKSPACE=""
CONTAINER_NAME=""
DETACH=false
declare -a PORT_MAPS=()
declare -a ENV_VARS=()
SSH_VOL="devbox-ssh-config"

# ── Helpers ───────────────────────────────────────────────────────────────────
usage() {
    sed -n '2,/^$/s/^# \?//p' "$0" | cat -n
    exit 0
}

log_info() { echo "[devbox] ℹ $*"; }
log_warn() { echo "[devbox] ⚠ $*" >&2; }
log_error() {
    echo "[devbox] ✗ $*" >&2
    exit 1
}

# Generate a unique container name with the devbox- prefix
generate_name() {
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    echo "devbox-${timestamp}"
}

# Check if docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "docker is not installed. Please install Docker Desktop or Docker CLI."
    fi
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running. Please start Docker Desktop or Docker Engine."
    fi
}

# ── Argument Parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
    -w | --workspace)
        WORKSPACE="$2"
        shift 2
        ;;
    -n | --name)
        CONTAINER_NAME="$2"
        shift 2
        ;;
    -i | --image)
        IMAGE="$2"
        shift 2
        ;;
    -p | --port)
        PORT_MAPS+=("-p" "$2")
        shift 2
        ;;
    -e | --env)
        ENV_VARS+=("-e" "$2")
        shift 2
        ;;
    -d | --detach)
        DETACH=true
        shift
        ;;
    -h | --help)
        usage
        ;;
    *)
        log_error "Unknown option: $1. Use --help for usage."
        ;;
    esac
done

# ── Validation ────────────────────────────────────────────────────────────────
check_docker

# Default workspace to current directory if not specified
if [[ -z "$WORKSPACE" ]]; then
    WORKSPACE="$(pwd)"
fi

# Validate workspace directory exists
if [[ ! -d "$WORKSPACE" ]]; then
    log_error "Workspace directory does not exist: $WORKSPACE"
fi

# Resolve to absolute path
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

# Generate container name if not provided
if [[ -z "$CONTAINER_NAME" ]]; then
    CONTAINER_NAME="$(generate_name)"
fi

# Check if container name already exists
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    log_error "A container with name '$CONTAINER_NAME' already exists. Use --name to specify a different name, or remove the existing container."
fi

# ── Prepare SSH volume (rewrites host paths for container) ───────────────────
if [[ -d "$HOME/.ssh" ]] && ls "$HOME/.ssh" >/dev/null 2>&1; then
    if ! docker volume inspect "$SSH_VOL" &>/dev/null 2>&1; then
        SSH_TMP=$(mktemp -d)
        cp -a "$HOME/.ssh" "$SSH_TMP/"
        # Rewrite host paths to container paths
        if [[ -f "$SSH_TMP/.ssh/config" ]]; then
            sed -i \
                -e "s|/home/montimage/.ssh/|/root/.ssh/|g" \
                -e "s|/home/\${USER}/.ssh/|/root/.ssh/|g" \
                -e "s|/home/montimage/|/root/|g" \
                "$SSH_TMP/.ssh/config"
        fi
        docker volume create "$SSH_VOL"
        docker run --rm \
            -v "$SSH_TMP/.ssh:/src:ro" \
            -v "$SSH_VOL:/dst" \
            alpine:latest \
            cp -a /src/. /dst/
        rm -rf "$SSH_TMP"
    fi
    log_info "Mounted ~/.ssh → /root/.ssh (via Docker volume, paths rewritten)"
else
    log_warn "$HOME/.ssh not found — SSH authentication not available"
fi

# ── Build docker run command ─────────────────────────────────────────────────
CMD=(docker run)

# Interactive and TTY for attachment
if [[ "$DETACH" == false ]]; then
    CMD+=("-it")
fi

# Container name
CMD+=("--name" "$CONTAINER_NAME")

# Workspace mount
CMD+=("-v" "${WORKSPACE}:/workspace")

# AI skills-only mount. Do not mount provider or agent state such as
# ~/.config/opencode or ~/.pi.
if [[ -d "$HOME/.agents" ]]; then
    CMD+=("-v" "${HOME}/.agents:/root/.agents")
    log_info "Mounted ~/.agents → /root/.agents"
else
    log_warn "$HOME/.agents not found — skipping AI agent skills mount"
fi

# SSH config mount via Docker volume
CMD+=("-v" "${SSH_VOL}:/root/.ssh")

# gh CLI auth mount
if [[ -d "$HOME/.config/gh" ]]; then
    CMD+=("-v" "${HOME}/.config/gh:/root/.config/gh")
    log_info "Mounted ~/.config/gh → /root/.config/gh"
fi

# Port mappings
for i in "${!PORT_MAPS[@]}"; do
    CMD+=("${PORT_MAPS[$i]}")
done

# Environment variables
for i in "${!ENV_VARS[@]}"; do
    CMD+=("-e" "${ENV_VARS[$i]}")
done

# Entry point: fix SSH permissions, configure git, setup gh auth, then exec zsh
CMD+=("--entrypoint" "zsh")
CMD+=("$IMAGE")
CMD+=(-c '
    chown -R root:root /root/.ssh
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/config /root/.ssh/config.bak 2>/dev/null || true
    chmod 600 /root/.ssh/id_* 2>/dev/null || true
    chmod 644 /root/.ssh/*.pub 2>/dev/null || true
    chmod 644 /root/.ssh/known_hosts /root/.ssh/known_hosts.old 2>/dev/null || true
    chmod 644 /root/.ssh/authorized_keys 2>/dev/null || true
    git config --global user.name "Lucian N. Viorel"
    git config --global user.email "luongnv89@gmail.com"
    git config --global init.defaultBranch main
    gh auth setup-git 2>/dev/null
    exec zsh
')

# ── Launch ────────────────────────────────────────────────────────────────────
log_info "Container: $CONTAINER_NAME"
log_info "Image:     $IMAGE"
log_info "Workspace: $WORKSPACE"
log_info "──────────────────────────────────────"

if [[ "$DETACH" == true ]]; then
    log_info "Starting in detached mode..."
    CMD+=("-d")
    CMD+=("sleep" "infinity")
    "${CMD[@]}"
    log_info "Container '$CONTAINER_NAME' started in background."
    log_info "Enter with: docker exec -it $CONTAINER_NAME zsh"
else
    log_info "Starting interactive container (press Ctrl+D or exit to stop)..."
    exec "${CMD[@]}"
fi
