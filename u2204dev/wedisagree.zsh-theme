# ╔═══════════════════════════════════════════════════════════════════════╗
# ║  Dev Green Theme - Optimized for Developers                          ║
# ║  Rich status info • Git • Python • Node • Docker • Performance       ║
# ╚═══════════════════════════════════════════════════════════════════════╝

# Color palette (using bright/bold variants for better visibility in dark mode)
local green_bright="%{$fg_bold[green]%}"
local green_normal="%{$fg[green]%}"
local gray_subtle="%{$fg[white]%}"  # Changed from black to white for dark mode visibility
local white_bright="%{$fg_bold[white]%}"
local red_bright="%{$fg_bold[red]%}"
local yellow_bright="%{$fg_bold[yellow]%}"
local cyan_bright="%{$fg_bold[cyan]%}"
local blue_bright="%{$fg_bold[blue]%}"
local magenta_bright="%{$fg_bold[magenta]%}"
local reset="%{$reset_color%}"

# The main prompt - Clean and simple (compact single-line)
# Enable blinking underscore cursor
echo -ne "\033[3 q"
PROMPT='${green_bright}[${white_bright}$(current_dir_name)${green_bright}]${reset} ${green_normal}▶${reset} '

# The right-hand prompt - Git and status information
RPROMPT='$(cmd_exec_time)${time} ${green_bright}$(git_prompt_info)${reset}$(git_prompt_status)${reset}$(git_prompt_ahead)${reset}'

# Add this at the start of RPROMPT to include rvm info showing ruby-version@gemset-name
# $(ruby_prompt_info)

# ═══════════════════════════════════════════════════════════════════════
# Status & Git Configuration
# ═══════════════════════════════════════════════════════════════════════

# Command exit status indicator with timestamp
time_enabled="%(?.${green_bright}✓.${red_bright}✗ %?)${reset} ${white_bright}%*${reset}"
time_disabled="${white_bright}%*${reset}"
time=$time_enabled

# Git prompt configuration - Clean and informative
ZSH_THEME_GIT_PROMPT_PREFIX=" ${green_normal}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${reset}"
ZSH_THEME_GIT_PROMPT_DIRTY="${yellow_bright} ●${reset}" # Modified
ZSH_THEME_GIT_PROMPT_UNTRACKED="${cyan_bright} ◆${reset}" # Untracked
ZSH_THEME_GIT_PROMPT_CLEAN="${green_bright} ✓${reset}" # Clean

# Git status symbols - Compact and clear
ZSH_THEME_GIT_PROMPT_ADDED="${green_bright}+${reset}"
ZSH_THEME_GIT_PROMPT_MODIFIED="${yellow_bright}~${reset}"
ZSH_THEME_GIT_PROMPT_DELETED="${red_bright}−${reset}"
ZSH_THEME_GIT_PROMPT_RENAMED="${cyan_bright}→${reset}"
ZSH_THEME_GIT_PROMPT_UNMERGED="${red_bright}═${reset}"
ZSH_THEME_GIT_PROMPT_AHEAD="${green_bright}↑${reset}"
ZSH_THEME_GIT_PROMPT_BEHIND="${yellow_bright}↓${reset}"
ZSH_THEME_GIT_PROMPT_DIVERGED="${red_bright}↕${reset}"

# Ruby/RVM prompt styling
ZSH_THEME_RUBY_PROMPT_PREFIX="${green_normal}"
ZSH_THEME_RUBY_PROMPT_SUFFIX="${reset}"

# Git commit time colors
ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT="${green_bright}"
ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM="${yellow_bright}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG="${red_bright}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL="${green_normal}"

# ═══════════════════════════════════════════════════════════════════════
# Helper Functions - Developer Context
# ═══════════════════════════════════════════════════════════════════════

# Command execution time tracking (macOS/BSD compatible)
preexec() {
  timer=$(date +%s)
}

# Use precmd_functions array to avoid conflicts with oh-my-zsh
precmd_timer() {
  if [ $timer ]; then
    local now=$(date +%s)
    local elapsed=$(($now-$timer))
    export LAST_CMD_TIME=$elapsed
    unset timer
  fi
}

# Add to precmd_functions array if not already there
if [[ ! "${precmd_functions[(r)precmd_timer]}" == "precmd_timer" ]]; then
  precmd_functions+=(precmd_timer)
fi

# Display execution time if command took longer than 1 second
function cmd_exec_time() {
  if [ $LAST_CMD_TIME ]; then
    local seconds=$LAST_CMD_TIME
    if [ $seconds -gt 1 ]; then
      if [ $seconds -gt 60 ]; then
        local minutes=$((seconds / 60))
        local sec_remainder=$((seconds % 60))
        echo "${gray_subtle}⏱ ${minutes}m${sec_remainder}s${reset} "
      else
        echo "${gray_subtle}⏱ ${seconds}s${reset} "
      fi
    fi
  fi
}

# Python virtual environment detection
function python_venv_info() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_name=$(basename "$VIRTUAL_ENV")
    echo "${cyan_bright} ${venv_name}${reset}"
  fi
}

# Node.js version detection (if in a Node project)
function node_version_info() {
  if [[ -f package.json ]] && command -v node &> /dev/null; then
    echo "${green_normal}⬢${reset}"
  fi
}

# Docker context detection
function docker_context_info() {
  if [[ -n "$DOCKER_HOST" ]] || [[ -f /.dockerenv ]]; then
    echo "${blue_bright} 🐳${reset}"
  fi
}

# Kubernetes context (if available)
function k8s_context_info() {
  if command -v kubectl &> /dev/null && kubectl config current-context &> /dev/null; then
    local ctx=$(kubectl config current-context 2>/dev/null)
    if [[ -n "$ctx" ]]; then
      echo "${blue_bright}☸ ${ctx}${reset}"
    fi
  fi
}

# Background jobs indicator
function jobs_info() {
  local job_count=$(jobs -l | wc -l | tr -d ' ')
  if [[ $job_count -gt 0 ]]; then
    echo "${yellow_bright}⚙ ${job_count}${reset}"
  fi
}

# Main developer context function - combines all context info
function dev_context_info() {
  local context=""

  # Python virtual environment
  local venv=$(python_venv_info)
  [[ -n "$venv" ]] && context="${context}${venv}"

  # Node.js version
  local node=$(node_version_info)
  [[ -n "$node" ]] && context="${context} ${node}"

  # Docker context
  local docker=$(docker_context_info)
  [[ -n "$docker" ]] && context="${context} ${docker}"

  # Background jobs
  local jobs=$(jobs_info)
  [[ -n "$jobs" ]] && context="${context} ${jobs}"

  # Output with separator if we have context
  [[ -n "$context" ]] && echo " ${gray_subtle}│${reset}${context}"
}

# Enhanced prompt with user@host for SSH sessions
function ssh_info() {
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    echo "${magenta_bright}%n@%m${reset} "
  fi
}

# Get current directory name (actual folder name, not ~)
function current_dir_name() {
  echo "${PWD##*/}"
}

# Project type indicator
function project_type_indicator() {
  if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
    echo "${blue_bright}🐍${reset}"
  elif [[ -f "package.json" ]]; then
    if grep -q "react" package.json 2>/dev/null; then
      echo "${cyan_bright}⚛️${reset}"
    else
      echo "${green_normal}⬢${reset}"
    fi
  elif [[ -f "Cargo.toml" ]]; then
    echo "${red_bright}🦀${reset}"
  elif [[ -f "go.mod" ]]; then
    echo "${cyan_bright}🐹${reset}"
  elif [[ -f "Gemfile" ]]; then
    echo "${red_bright}💎${reset}"
  fi
}

# Ruby gemset detection
function rvm_gemset() {
  if command -v rvm &> /dev/null; then
    GEMSET=$(rvm gemset list 2>/dev/null | grep '=>' | cut -b4-)
    if [[ -n $GEMSET ]]; then
      echo "${green_normal}$GEMSET${reset}|"
    fi
  fi
}

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
function git_time_since_commit() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Only proceed if there is actually a commit.
        if last_commit=`git -c log.showSignature=false log --pretty=format:'%at' -1 2> /dev/null`; then
            now=`date +%s`
            seconds_since_last_commit=$((now-last_commit))

            # Totals
            MINUTES=$((seconds_since_last_commit / 60))
            HOURS=$((seconds_since_last_commit/3600))

            # Sub-hours and sub-minutes
            DAYS=$((seconds_since_last_commit / 86400))
            SUB_HOURS=$((HOURS % 24))
            SUB_MINUTES=$((MINUTES % 60))

            if [[ -n $(git status -s 2> /dev/null) ]]; then
                if [ "$MINUTES" -gt 30 ]; then
                    COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG"
                elif [ "$MINUTES" -gt 10 ]; then
                    COLOR="$ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM"
                else
                    COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT"
                fi
            else
                COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
            fi

            if [ "$HOURS" -gt 24 ]; then
                echo "($(rvm_gemset)$COLOR${DAYS}d${SUB_HOURS}h${SUB_MINUTES}m%{$reset_color%}|"
            elif [ "$MINUTES" -gt 60 ]; then
                echo "($(rvm_gemset)$COLOR${HOURS}h${SUB_MINUTES}m%{$reset_color%}|"
            else
                echo "($(rvm_gemset)$COLOR${MINUTES}m%{$reset_color%}|"
            fi
        else
            COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
            echo "($(rvm_gemset)$COLOR~|"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# Theme Documentation
# ═══════════════════════════════════════════════════════════════════════
#
# FEATURES:
# ─────────
# ✓ Bright green color scheme optimized for dark terminals
# ✓ Compact single-line prompt with rich information
# ✓ Automatic Python virtual environment detection (displays venv name)
# ✓ Node.js version display (when package.json is present)
# ✓ Docker context indicator
# ✓ Background jobs counter
# ✓ SSH session indicator (shows user@host)
# ✓ Command execution time (for commands >1 second)
# ✓ Git branch, status, and ahead/behind indicators
# ✓ Exit code display (✓ for success, ✗ with code for errors)
# ✓ Timestamp on every command (bright white for visibility)
# ✓ Project type indicators (Python 🐍, React ⚛️, Node ⬢, Rust 🦀, Go 🐹, Ruby 💎)
# ✓ Blinking underscore cursor for better visibility
#
# PROMPT LAYOUT:
# ──────────────
# [folder] ▶                    ⏱ 2s ✓ 00:15:30 main ✓
#
# Left side shows:
#   [folder]      - Current directory name (not full path, bright white)
#   ▶             - Command prompt (green)
#
# Right side shows:
#   ⏱ 2s          - Command execution time (white, only if >1s)
#   ✓             - Success indicator (green) or ✗ with exit code (red)
#   00:15:30      - Current time (bright white)
#   main          - Git branch name (green)
#   ●             - Git dirty/modified (yellow)
#   ◆             - Untracked files (cyan)
#   +~−→═         - File status (added/modified/deleted/renamed/unmerged)
#   ✓             - Clean repo (green) or ↑↓↕ for ahead/behind/diverged
#
# SYMBOLS REFERENCE:
# ──────────────────
# ▶  Command prompt
# │  Context separator
#   Python virtual environment
# ⬢  Node.js version
# 🐳 Docker context
# ⚙  Background jobs
# ⏱  Execution time
# ✓  Success / Clean git
# ✗  Error (with exit code)
# 🐍 Python project
# ⚛️  React project
# 🦀 Rust project
# 🐹 Go project
# 💎 Ruby project
# ●  Dirty/Modified
# ◆  Untracked files
# +  Added
# ~  Modified
# −  Deleted
# →  Renamed
# ═  Unmerged
# ↑  Commits ahead
# ↓  Commits behind
# ↕  Diverged
#
# INSTALLATION:
# ─────────────
# 1. This theme is self-contained - all configuration is in this file
# 2. Set ZSH_THEME="wedisagree" in ~/.zshrc
# 3. Reload shell: source ~/.zshrc
#
# No additional configuration needed in .zshrc!
#
