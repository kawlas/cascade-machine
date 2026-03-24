#!/usr/bin/env bash

set -o pipefail

resolve_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

resolve_lib_dir() {
    local script_dir
    script_dir="$(resolve_script_dir)"
    if [ -d "$script_dir/lib" ]; then
        printf '%s\n' "$script_dir/lib"
    elif [ -d "$HOME/.cascade/lib" ]; then
        printf '%s\n' "$HOME/.cascade/lib"
    else
        printf '%s\n' "$script_dir/lib"
    fi
}

load_cascade_env() {
    [ -f "$HOME/.cascade/.env" ] && source "$HOME/.cascade/.env" 2>/dev/null
}

cascade_home_dir() {
    printf '%s\n' "${CASCADE_HOME:-$HOME/.cascade}"
}

ensure_parent_dir() {
    local target="$1"
    mkdir -p "$(dirname "$target")"
}

append_jsonl() {
    local target="$1"
    local line="$2"
    ensure_parent_dir "$target"
    touch "$target"
    printf '%s\n' "$line" >> "$target"
}

is_ollama_available() {
    curl -s --connect-timeout 1 "${OLLAMA_HOST:-http://localhost:11434}/api/tags" \
        > /dev/null 2>&1
}

print_box_line() {
    printf '%s\n' "$1"
}

choose_shell_config() {
    if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
        printf '%s\n' "$HOME/.zshrc"
        return 0
    fi
    if [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
        printf '%s\n' "$HOME/.bashrc"
        return 0
    fi
    if [ -f "$HOME/.bash_profile" ]; then
        printf '%s\n' "$HOME/.bash_profile"
        return 0
    fi
    return 1
}
