#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/local_models.sh"
source "$LIB_DIR/model_catalog.sh"
source "$LIB_DIR/model_health.sh"
source "$LIB_DIR/router_policy.sh"

CASCADE_HOME_DIR="$(cascade_home_dir)"
USAGE_FILE="${CASCADE_USAGE_FILE:-$CASCADE_HOME_DIR/usage.jsonl}"
LEARNINGS_FILE="${CASCADE_LEARNINGS_FILE:-$CASCADE_HOME_DIR/learnings.jsonl}"
PROVIDER_FAILURE_FILE="${CASCADE_PROVIDER_FAILURE_FILE:-$CASCADE_HOME_DIR/provider_failures.jsonl}"
TODAY="$(date +%Y-%m-%d)"
MODEL_FAILURE_COOLDOWN="${CASCADE_MODEL_FAILURE_COOLDOWN:-2}"
PROVIDER_FAILURE_COOLDOWN_SECONDS="${CASCADE_PROVIDER_FAILURE_COOLDOWN_SECONDS:-1800}"

ensure_router_storage() {
    ensure_parent_dir "$USAGE_FILE"
    ensure_parent_dir "$LEARNINGS_FILE"
    ensure_parent_dir "$PROVIDER_FAILURE_FILE"
    touch "$USAGE_FILE" "$LEARNINGS_FILE" "$PROVIDER_FAILURE_FILE"
}

count_today() {
    local provider="$1"
    ensure_router_storage
    awk -v provider="$provider" -v day="$TODAY" '
        $0 ~ "\"provider\":\"" provider "\"" && $0 ~ "\"date\":\"" day "\"" { count++ }
        END { print count + 0 }
    ' "$USAGE_FILE" 2>/dev/null
}

log_usage() {
    local provider="$1" model="$2" task_type="$3" success="$4"
    ensure_router_storage
    append_jsonl "$USAGE_FILE" \
        "{\"date\":\"$TODAY\",\"provider\":\"$provider\",\"model\":\"$model\",\"task_type\":\"$task_type\",\"success\":$success,\"ts\":$(date +%s)}"
}

log_provider_failure() {
    local provider="$1" reason="$2"
    ensure_router_storage
    append_jsonl "$PROVIDER_FAILURE_FILE" \
        "{\"date\":\"$TODAY\",\"provider\":\"$provider\",\"reason\":\"$reason\",\"ts\":$(date +%s)}"
}

classify_task() {
    local task_lower
    task_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    if echo "$task_lower" | grep -qE 'wyjaśnij|explain|dlaczego|why|architektur|design|zaproponuj|koncep|teoria|różnic|porównaj|compare|debug|diagnoz|analiz|review|przyjrzyj|sprawd[zź]|oce[nń]|niedokoncz'; then printf 'reason\n'; return; fi
    if echo "$task_lower" | grep -qE 'refaktor|refactor|przenieś|move|reorganiz|split|extract|restructur|migrat|upgrad|convert'; then printf 'refactor\n'; return; fi
    if echo "$task_lower" | grep -qE '(^|[^[:alnum:]_])(test|tests|spec|specs|assert|mock|stub|fixture|coverage|pytest|vitest)([^[:alnum:]_]|$)|jest\.|npx jest|npm test|yarn test|pnpm test'; then printf 'test\n'; return; fi
    if echo "$task_lower" | grep -qE '(^|[^[:alnum:]_])(fix|typo|rename|change|bump)([^[:alnum:]_]|$)|popraw|zmień|add import|dodaj import|update version'; then printf 'quick\n'; return; fi
    printf 'code\n'
}

check_history() {
    local task_type="$1" count best_model
    ensure_router_storage
    count="$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null | grep '"success":true' | wc -l | tr -d ' ')"
    [ "$count" -lt 5 ] && return 0
    best_model="$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null | grep '"success":true' \
        | grep -oE '"model":"[^"]*"' | sort | uniq -c | sort -rn | head -1 | grep -oE '"[^"]*"$' | tr -d '"')"
    printf '%s\n' "$best_model"
}

normalize_provider_name() {
    [ "$1" = "google" ] && printf 'gemini\n' || printf '%s\n' "$1"
}

preferred_model_override() {
    local task_type="${1:-}" specific_var specific_value
    if [ -n "$task_type" ]; then
        specific_var="CASCADE_$(printf '%s' "$task_type" | tr '[:lower:]' '[:upper:]')_PREFERRED_MODEL"
        eval "specific_value=\"\${$specific_var:-}\""
        [ -n "$specific_value" ] && { printf '%s\n' "$specific_value"; return; }
    fi
    printf '%s\n' "${CASCADE_PREFERRED_MODEL:-}"
}

preferred_provider_override() {
    local task_type="${1:-}" specific_var specific_value
    if [ -n "$task_type" ]; then
        specific_var="CASCADE_$(printf '%s' "$task_type" | tr '[:lower:]' '[:upper:]')_PREFERRED_PROVIDER"
        eval "specific_value=\"\${$specific_var:-}\""
        [ -n "$specific_value" ] && { normalize_provider_name "$specific_value"; return; }
    fi
    [ -n "${CASCADE_PREFERRED_PROVIDER:-}" ] && normalize_provider_name "${CASCADE_PREFERRED_PROVIDER}" || printf '\n'
}

provider_limit() {
    local provider prefix override
    provider="$(normalize_provider_name "$1")"
    prefix="$(provider_var_prefix "$provider")"
    eval "override=\"\${${prefix}_LIMIT:-}\""
    [ -n "$override" ] && { printf '%s\n' "$override"; return; }
    case "$provider" in
        groq) printf '800\n' ;;
        cerebras) printf '150\n' ;;
        gemini) printf '1200\n' ;;
        openrouter) printf '150\n' ;;
        xai) printf '400\n' ;;
        ollama*) printf '999999\n' ;;
        *) [ "$(provider_tier "$provider")" = "free" ] && printf '500\n' || printf '999999\n' ;;
    esac
}

provider_configured() {
    local provider key
    provider="$(normalize_provider_name "$1")"
    [[ "$provider" == ollama* ]] && { is_ollama_available; return; }
    key="$(provider_api_key "$provider")"
    [ -n "$key" ]
}

provider_available() {
    local provider used limit
    provider="$(normalize_provider_name "$1")"
    provider_configured "$provider" || { printf 'false\n'; return; }
    used="$(count_today "$provider")"
    limit="$(provider_limit "$provider")"
    [ "$used" -lt "$limit" ] && printf 'true\n' || printf 'false\n'
}

record_field() { printf '%s\n' "$1" | cut -f "$2"; }
record_provider() { record_field "$1" 1; }
record_display_model() { record_field "$1" 2; }
record_aider_model() { record_field "$1" 3; }
record_tier() { record_field "$1" 4; }
record_context() { record_field "$1" 5; }
record_api_base() { record_field "$1" 6; }
record_key_var() { record_field "$1" 7; }

default_models_for_task() {
    local_model_candidates "$1" | paste -sd, -
}

default_cloud_models_for_task() {
    case "$1" in
        reason) printf '%s\n' 'openrouter/mistralai/devstral-2,gemini/gemini-2.0-flash,cerebras/llama-3.3-70b,xai/grok-3-mini,groq/llama-3.3-70b-versatile' ;;
        quick|test) printf '%s\n' 'openrouter/mistralai/devstral-2,gemini/gemini-2.0-flash,cerebras/llama-3.3-70b,xai/grok-3-mini,groq/llama-3.3-70b-versatile' ;;
        *) printf '%s\n' 'openrouter/mistralai/devstral-2,gemini/gemini-2.0-flash,cerebras/llama-3.3-70b,xai/grok-3-mini,groq/llama-3.3-70b-versatile' ;;
    esac
}

models_for_task() {
    local task_type="$1" var_name default_value
    var_name="CASCADE_$(printf '%s' "$task_type" | tr '[:lower:]' '[:upper:]')_MODELS"
    default_value="$(default_models_for_task "$task_type")"
    eval "printf '%s\n' \"\${$var_name:-$default_value}\""
}

model_record_from_name() {
    local model="$1" provider rest aider_model tier api_base key_var
    provider="$(normalize_provider_name "${model%%/*}")"
    rest="${model#*/}"
    case "$provider" in
        ollama_chat) aider_model="$model"; tier="local"; api_base=""; key_var="" ;;
        openrouter|groq|gemini|cerebras|xai) aider_model="$model"; tier="$(provider_tier "$provider")"; api_base=""; key_var="$(provider_api_key_var "$provider")" ;;
        *) aider_model="openai/$rest"; tier="$(provider_tier "$provider")"; api_base="$(provider_base_url "$provider")"; key_var="$(provider_api_key_var "$provider")"; model="$provider/$rest" ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$provider" "$model" "$aider_model" "$tier" "" "$api_base" "$key_var"
}

fallback_records() {
    local task_type="$1" model_filter="${2:-}" force_cloud="${3:-false}" source_models
    if [ -n "$model_filter" ]; then model_record_from_name "$model_filter"; return; fi
    if [ "$force_cloud" = "true" ]; then
        source_models="$(default_cloud_models_for_task "$task_type")"
    else
        source_models="$(default_cloud_models_for_task "$task_type"),$(models_for_task "$task_type")"
    fi
    printf '%s\n' "$source_models" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | awk 'NF' | while IFS= read -r model; do
        model_record_from_name "$model"
    done
}

catalog_records() {
    local task_type="$1" model_filter="${2:-}" force_cloud="${3:-false}" preferred_model
    refresh_model_catalog_if_needed
    preferred_model="$(preferred_model_override "$task_type")"
    if [ -n "$model_filter" ]; then
        { list_catalog_records | awk -F'\t' -v model="$model_filter" '$2==model'; fallback_records "$task_type" "$model_filter" "$force_cloud"; } | awk -F'\t' '!seen[$2]++'
        return
    fi
    {
        [ -n "$preferred_model" ] && model_record_from_name "$preferred_model"
        list_catalog_records
        fallback_records "$task_type" "" "$force_cloud"
    } | awk -F'\t' '!seen[$2]++'
}

ollama_model_installed() {
    local model_name="${1#ollama_chat/}"
    command -v ollama >/dev/null 2>&1 || return 1
    ollama list 2>/dev/null | awk '{print $1}' | grep -Fxq "$model_name"
}

model_usage_stats() {
    local model="$1"
    ensure_router_storage
    awk -v model="$model" -v day="$TODAY" '
        $0 ~ "\"date\":\"" day "\"" && $0 ~ "\"model\":\"" model "\"" {
            if ($0 ~ "\"success\":true") success++
            if ($0 ~ "\"success\":false") failure++
        }
        END { print success + 0, failure + 0 }
    ' "$USAGE_FILE" 2>/dev/null
}

model_in_cooldown() {
    local stats success failure
    stats="$(model_usage_stats "$1")"
    success="${stats%% *}"
    failure="${stats##* }"
    [ "$failure" -ge "$MODEL_FAILURE_COOLDOWN" ] && [ "$failure" -gt "$success" ]
}

provider_in_cooldown() {
    local provider="$1" now
    ensure_router_storage
    now="$(date +%s)"
    awk -v provider="$provider" -v now="$now" -v ttl="$PROVIDER_FAILURE_COOLDOWN_SECONDS" '
        $0 ~ "\"provider\":\"" provider "\"" {
            if (match($0, /"ts":([0-9]+)/, m)) {
                ts = m[1] + 0
                if ((now - ts) <= ttl) found = 1
            }
        }
        END { exit found ? 0 : 1 }
    ' "$PROVIDER_FAILURE_FILE" >/dev/null 2>&1
}

tier_bonus() {
    case "$1" in
        free) printf '70\n' ;;
        prepaid) printf '35\n' ;;
        paid) printf '5\n' ;;
        local) printf '%s\n' '-25' ;;
        *) printf '0\n' ;;
    esac
}

task_affinity_score() {
    local model_lower
    model_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$2" in
        reason) echo "$model_lower" | grep -qE 'reason|r1|think|grok|flash|pro' && printf '18\n' || printf '6\n' ;;
        quick|test) echo "$model_lower" | grep -qE 'mini|small|4b|8b|flash|lite|nano' && printf '18\n' || printf '8\n' ;;
        *) echo "$model_lower" | grep -qE 'coder|code|devstral|deepseek|qwen|llama|gpt-oss|codestral' && printf '20\n' || printf '8\n' ;;
    esac
}

candidate_status() {
    local record="$1" force_cloud="$2" provider_filter="$3"
    local provider display tier aider_model api_base cached_health
    provider="$(record_provider "$record")"; display="$(record_display_model "$record")"; tier="$(record_tier "$record")"
    aider_model="$(record_aider_model "$record")"; api_base="$(record_api_base "$record")"; provider_filter="$(normalize_provider_name "$provider_filter")"
    [ -n "$provider_filter" ] && [ "$provider" != "$provider_filter" ] && { printf 'filtered\n'; return; }
    [ "$force_cloud" = "true" ] && [ "$tier" = "local" ] && { printf 'filtered\n'; return; }
    model_allowed_by_policy "$provider" "$tier" || { printf 'policy_blocked\n'; return; }
    [[ "$aider_model" == openai/* ]] && [ -z "$api_base" ] && { printf 'missing_base\n'; return; }
    if ! provider_configured "$provider"; then [[ "$provider" == ollama* ]] && printf 'runtime_down\n' || printf 'missing_key\n'; return; fi
    [[ "$provider" == ollama* ]] && ! ollama_model_installed "$aider_model" && { printf 'model_missing\n'; return; }
    [ "$(provider_available "$provider")" = "false" ] && { printf 'limit_reached\n'; return; }
    provider_in_cooldown "$provider" && { printf 'provider_cooldown\n'; return; }
    model_in_cooldown "$display" && { printf 'cooldown\n'; return; }
    if cached_health="$(cached_model_health "$display" 2>/dev/null)"; then
        [ "${cached_health%%$'\t'*}" = "ok" ] || { printf 'probe_failed\n'; return; }
    fi
    printf 'ok\n'
}

candidate_reason() {
    case "$1" in
        ok) printf 'ready\n' ;;
        filtered) printf 'filtered by manual selection\n' ;;
        missing_key) printf 'provider key missing\n' ;;
        missing_base) printf 'provider base URL missing\n' ;;
        runtime_down) printf 'ollama runtime unavailable\n' ;;
        model_missing) printf 'local model not installed\n' ;;
        limit_reached) printf 'daily limit reached\n' ;;
        policy_blocked) printf 'filtered by routing policy\n' ;;
        provider_cooldown) printf 'provider cooling down after recent failure\n' ;;
        cooldown) printf 'cooldown after recent failures\n' ;;
        probe_failed) printf 'recent live probe failed\n' ;;
        *) printf 'unknown\n' ;;
    esac
}

candidate_score() {
    local record="$1" task_type="$2" position="$3" history_model="$4"
    local display stats success failure score context preferred_provider
    display="$(record_display_model "$record")"; context="$(record_context "$record")"; stats="$(model_usage_stats "$display")"
    success="${stats%% *}"; failure="${stats##* }"
    score=$((120 + $(tier_bonus "$(record_tier "$record")") + $(provider_priority_score "$(record_provider "$record")") + $(task_affinity_score "$display" "$task_type") + $(model_priority_score "$display" "$task_type") - position * 4 + success * 12 - failure * 18))
    [ "$display" = "$history_model" ] && score=$((score + 25))
    preferred_provider="$(preferred_provider_override "$task_type")"
    [ -n "$preferred_provider" ] && [ "$(record_provider "$record")" = "$preferred_provider" ] && score=$((score + 40))
    [[ "$context" =~ ^[0-9]+$ ]] && [ "$context" -ge 100000 ] && score=$((score + 5))
    printf '%s\n' "$score"
}

ranked_candidates() {
    local task_type="$1" force_cloud="$2" provider_filter="$3" model_filter="$4" position=0 history_model
    history_model="$(check_history "$task_type")"
    while IFS= read -r record; do
        local status reason score
        position=$((position + 1))
        status="$(candidate_status "$record" "$force_cloud" "$provider_filter")"
        reason="$(candidate_reason "$status")"
        score="-999"
        [ "$status" = "ok" ] && score="$(candidate_score "$record" "$task_type" "$position" "$history_model")"
        printf '%s|%s|%s|%s\n' "$score" "$status" "$reason" "$record"
    done << EOF
$(catalog_records "$task_type" "$model_filter" "$force_cloud")
EOF
}

source "$LIB_DIR/router_selection.sh"
source "$LIB_DIR/router_status.sh"
