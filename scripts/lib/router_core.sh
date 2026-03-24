#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"

CASCADE_HOME_DIR="$(cascade_home_dir)"
USAGE_FILE="${CASCADE_USAGE_FILE:-$CASCADE_HOME_DIR/usage.jsonl}"
LEARNINGS_FILE="${CASCADE_LEARNINGS_FILE:-$CASCADE_HOME_DIR/learnings.jsonl}"
TODAY="$(date +%Y-%m-%d)"
OLLAMA_URL="${OLLAMA_HOST:-http://localhost:11434}"

GROQ_LIMIT="${CASCADE_GROQ_LIMIT:-800}"
CEREBRAS_LIMIT="${CASCADE_CEREBRAS_LIMIT:-150}"
GOOGLE_LIMIT="${CASCADE_GOOGLE_LIMIT:-1200}"
OPENROUTER_LIMIT="${CASCADE_OPENROUTER_LIMIT:-150}"
XAI_LIMIT="${CASCADE_XAI_LIMIT:-400}"

ensure_router_storage() {
    ensure_parent_dir "$USAGE_FILE"
    ensure_parent_dir "$LEARNINGS_FILE"
    touch "$USAGE_FILE" "$LEARNINGS_FILE"
}

count_today() {
    local provider="$1"
    ensure_router_storage
    grep "\"provider\":\"$provider\"" "$USAGE_FILE" 2>/dev/null \
        | grep "\"date\":\"$TODAY\"" \
        | wc -l \
        | tr -d ' '
}

log_usage() {
    local provider="$1" model="$2" task_type="$3" success="$4"
    ensure_router_storage
    append_jsonl "$USAGE_FILE" \
        "{\"date\":\"$TODAY\",\"provider\":\"$provider\",\"model\":\"$model\",\"task_type\":\"$task_type\",\"success\":$success,\"ts\":$(date +%s)}"
}

classify_task() {
    local task="$1"
    local task_lower
    task_lower="$(printf '%s' "$task" | tr '[:upper:]' '[:lower:]')"

    if echo "$task_lower" | grep -qE \
        'wyjaśnij|explain|dlaczego|why|architektur|design|zaproponuj|koncep|teoria|różnic|porównaj|compare|debug|diagnoz|analiz|review'; then
        printf 'reason\n'
        return
    fi
    if echo "$task_lower" | grep -qE \
        'refaktor|refactor|przenieś|move|reorganiz|split|extract|restructur|migrat|upgrad|convert'; then
        printf 'refactor\n'
        return
    fi
    if echo "$task_lower" | grep -qE \
        'test|spec|assert|mock|stub|fixture|coverage|jest|pytest|vitest'; then
        printf 'test\n'
        return
    fi
    if echo "$task_lower" | grep -qE \
        'fix|popraw|typo|rename|zmień|change|add import|dodaj import|update version|bump'; then
        printf 'quick\n'
        return
    fi
    printf 'code\n'
}

check_history() {
    local task_type="$1"
    local count best_model
    ensure_router_storage
    count="$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null \
        | grep '"success":true' \
        | wc -l | tr -d ' ')"
    [ "$count" -lt 5 ] && return 0
    best_model="$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null \
        | grep '"success":true' \
        | grep -oE '"model":"[^"]*"' \
        | sort | uniq -c | sort -rn \
        | head -1 \
        | grep -oE '"[^"]*"$' \
        | tr -d '"')"
    printf '%s\n' "$best_model"
}

provider_limit() {
    case "$1" in
        groq) printf '%s\n' "$GROQ_LIMIT" ;;
        cerebras) printf '%s\n' "$CEREBRAS_LIMIT" ;;
        google|gemini) printf '%s\n' "$GOOGLE_LIMIT" ;;
        openrouter) printf '%s\n' "$OPENROUTER_LIMIT" ;;
        xai) printf '%s\n' "$XAI_LIMIT" ;;
        ollama*) printf '%s\n' "999999" ;;
        *) printf '%s\n' "100" ;;
    esac
}

provider_configured() {
    case "$1" in
        groq) [ -n "${GROQ_API_KEY:-}" ] ;;
        cerebras) [ -n "${CEREBRAS_API_KEY:-}" ] ;;
        google|gemini) [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_AI_KEY:-}" ] ;;
        openrouter) [ -n "${OPENROUTER_API_KEY:-}" ] ;;
        xai) [ -n "${XAI_API_KEY:-}" ] ;;
        ollama*) is_ollama_available ;;
        *) return 1 ;;
    esac
}

provider_available() {
    local provider="$1"
    local used limit
    provider_configured "$provider" || {
        printf 'false\n'
        return
    }
    used="$(count_today "$provider")"
    limit="$(provider_limit "$provider")"
    [ "$used" -lt "$limit" ] && printf 'true\n' || printf 'false\n'
}

local_model_for_task() {
    case "$1" in
        reason) printf 'ollama_chat/deepseek-r1:14b\n' ;;
        quick) printf 'ollama_chat/devstral-small\n' ;;
        *) printf 'ollama_chat/qwen3-coder\n' ;;
    esac
}

build_cloud_candidates() {
    case "$1" in
        reason)
            printf '%s\n' \
                "gemini:gemini/gemini-2.0-flash" \
                "groq:groq/llama-3.3-70b-versatile" \
                "cerebras:cerebras/llama-3.3-70b" \
                "openrouter:openrouter/mistralai/devstral-2" \
                "xai:xai/grok-3-mini"
            ;;
        refactor|code)
            printf '%s\n' \
                "openrouter:openrouter/mistralai/devstral-2" \
                "groq:groq/llama-3.3-70b-versatile" \
                "cerebras:cerebras/llama-3.3-70b" \
                "gemini:gemini/gemini-2.0-flash" \
                "xai:xai/grok-3-mini"
            ;;
        *)
            printf '%s\n' \
                "groq:groq/llama-3.3-70b-versatile" \
                "cerebras:cerebras/llama-3.3-70b" \
                "gemini:gemini/gemini-2.0-flash" \
                "openrouter:openrouter/mistralai/devstral-2" \
                "xai:xai/grok-3-mini"
            ;;
    esac
}

get_best_model() {
    local task="$1"
    local force_cloud="${2:-false}"
    local task_type history_model hist_provider
    task_type="$(classify_task "$task")"
    history_model="$(check_history "$task_type")"

    if [ -n "$history_model" ] && [ "$force_cloud" != "true" ]; then
        hist_provider="$(echo "$history_model" | cut -d'/' -f1)"
        if [ "$(provider_available "$hist_provider")" = "true" ]; then
            printf '%s\n' "$history_model"
            return 0
        fi
    fi
    if [ "$force_cloud" != "true" ] && is_ollama_available; then
        printf '%s\n' "$(local_model_for_task "$task_type")"
        return 0
    fi

    while IFS= read -r entry; do
        local provider model
        provider="$(echo "$entry" | cut -d: -f1)"
        model="$(echo "$entry" | cut -d: -f2-)"
        if [ "$(provider_available "$provider")" = "true" ]; then
            printf '%s\n' "$model"
            return 0
        fi
    done << EOF
$(build_cloud_candidates "$task_type")
EOF

    printf 'LIMIT_EXCEEDED\n'
    return 1
}

show_status() {
    local total_used=0
    local total_limit=0
    ensure_router_storage
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  CASCADE — Token Usage ($TODAY)                       ║"
    echo "╠═══════════════════════════════════════════════════════╣"
    if is_ollama_available; then
        local models
        models="$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ', ' | sed 's/, $//')"
        echo "║  Ollama:      ✅ UNLIMITED  [${models:-no models}]"
    else
        echo "║  Ollama:      ❌ NOT RUNNING (uruchom: ollama serve)"
    fi
    echo "║───────────────────────────────────────────────────────║"
    while IFS= read -r provider_info; do
        local name prov limit used pct icon configured
        name="$(echo "$provider_info" | cut -d: -f1)"
        prov="$(echo "$provider_info" | cut -d: -f2)"
        limit="$(echo "$provider_info" | cut -d: -f3)"
        used="$(count_today "$prov")"
        pct=$((used * 100 / limit))
        total_used=$((total_used + used))
        total_limit=$((total_limit + limit))
        icon="✅"
        configured="configured"
        provider_configured "$prov" || {
            configured="missing key"
            icon="⚪"
        }
        [ "$pct" -ge 80 ] && icon="⚠️"
        [ "$pct" -ge 100 ] && icon="❌"
        printf "║  %-11s %s %d/%d (%d%%) %s\n" "$name:" "$icon" "$used" "$limit" "$pct" "$configured"
    done << EOF
Groq:groq:$GROQ_LIMIT
Cerebras:cerebras:$CEREBRAS_LIMIT
Google:google:$GOOGLE_LIMIT
OpenRouter:openrouter:$OPENROUTER_LIMIT
x.ai:xai:$XAI_LIMIT
EOF
    echo "║───────────────────────────────────────────────────────║"
    echo "║  Cloud total:  $total_used/$total_limit requests used today"
    echo "║  Remaining:    $((total_limit - total_used)) cloud requests"
    echo "╚═══════════════════════════════════════════════════════╝"
}
