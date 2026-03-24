#!/usr/bin/env bash

local_model_for_task() {
    case "$1" in
        reason) printf 'ollama_chat/deepseek-r1:8b\n' ;;
        quick|test) printf 'ollama_chat/qwen3:4b\n' ;;
        *) printf 'ollama_chat/qwen3-coder\n' ;;
    esac
}

local_model_defaults() {
    case "$1" in
        reason) printf '%s\n' 'ollama_chat/deepseek-r1:8b,ollama_chat/qwen3-coder,ollama_chat/qwen3:4b' ;;
        quick|test) printf '%s\n' 'ollama_chat/qwen3:4b,ollama_chat/qwen3-coder,ollama_chat/devstral-small' ;;
        *) printf '%s\n' 'ollama_chat/qwen3-coder,ollama_chat/devstral-small,ollama_chat/qwen3:4b' ;;
    esac
}

ollama_installed_models() {
    command -v ollama >/dev/null 2>&1 || return 0
    ollama list 2>/dev/null | awk 'NR == 1 && $1 == "NAME" { next } NF { print "ollama_chat/" $1 }'
}

local_model_candidates() {
    local task_type="${1:-code}" configured_models preferred_model
    configured_models="$(local_model_defaults "$task_type")"
    preferred_model="${AIDER_MODEL:-}"
    [ -n "$preferred_model" ] && [[ "$preferred_model" == ollama_chat/* ]] && configured_models="$preferred_model,$configured_models"
    {
        printf '%s\n' "$configured_models"
        ollama_installed_models
    } | tr ',' '\n' | sed 's/^ *//; s/ *$//' | awk 'NF && !seen[$0]++'
}
