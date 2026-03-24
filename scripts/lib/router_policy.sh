#!/usr/bin/env bash

cloud_free_only_enabled() {
    [ "${CASCADE_CLOUD_FREE_ONLY:-true}" = "true" ]
}

preferred_openrouter_free_models() {
    printf '%s\n' "${CASCADE_OPENROUTER_PREFERRED_FREE_MODELS:-openrouter/nvidia/nemotron-3-super-120b-a12b:free,openrouter/arcee-ai/trinity-large-preview:free,openrouter/openrouter/free,openrouter/qwen/qwen3-coder-next,openrouter/stepfun/step-3.5-flash:free,openrouter/minimax/minimax-m2.5:free}"
}

model_in_csv_list() {
    local needle="$1" csv_list="${2:-}"
    printf '%s\n' "$csv_list" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | awk 'NF' | grep -Fxq "$needle"
}

model_allowed_by_policy() {
    local provider="$1" tier="$2"
    cloud_free_only_enabled || return 0
    [ "$provider" = "ollama_chat" ] && return 0
    [ "$tier" = "free" ]
}

provider_priority_score() {
    case "$1" in
        openrouter) printf '120\n' ;;
        gemini) printf '10\n' ;;
        cerebras) printf '0\n' ;;
        groq) printf '%s\n' '-120' ;;
        xai) printf '%s\n' '-140' ;;
        ollama*) printf '%s\n' '-15' ;;
        *) printf '0\n' ;;
    esac
}

model_priority_score() {
    local model_lower task_type="$2" score=0
    model_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    echo "$model_lower" | grep -q ':free' && score=$((score + 35))
    echo "$model_lower" | grep -qE 'nvidia|nemotron|opencode' && score=$((score + 25))
    echo "$model_lower" | grep -qE 'devstral|codestral|deepseek|qwen|coder' && score=$((score + 12))
    model_in_csv_list "$1" "$(preferred_openrouter_free_models)" && score=$((score + 50))
    [ "$task_type" = "reason" ] && echo "$model_lower" | grep -q 'groq/' && score=$((score - 35))
    [ "$task_type" = "code" ] && echo "$model_lower" | grep -q 'groq/' && score=$((score - 20))
    printf '%s\n' "$score"
}
