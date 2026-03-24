#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/router_core.sh"

ensure_aider_installed() {
    if ! command -v aider >/dev/null 2>&1; then
        echo "aider is not installed or not in PATH"
        return 1
    fi
}

print_model_unavailable_hint() {
    local local_models cloud_keys=0
    for key_name in OPENROUTER_API_KEY GROQ_API_KEY GEMINI_API_KEY GOOGLE_AI_KEY CEREBRAS_API_KEY XAI_API_KEY; do
        eval "[ -n \"\${$key_name:-}\" ]" && cloud_keys=$((cloud_keys + 1))
    done
    local_models="$(ollama_installed_models | paste -sd, -)"
    echo "No models available for this task"
    [ "$cloud_keys" -eq 0 ] && echo "Cloud providers: no API keys configured"
    is_ollama_available || echo "Ollama runtime: unavailable (start it with: ollama serve)"
    [ -n "$local_models" ] && echo "Installed local models: $local_models" || echo "Installed local models: none"
    echo "Recommended local fallback: ollama pull qwen3-coder"
    echo "Run: cascade doctor"
}

select_record_for_task_type() {
    local task_type="$1" record probe_count=0
    while IFS= read -r record; do
        [ -n "$record" ] || continue
        if [ "$MODEL_HEALTH_ENABLED" = "true" ] && [ "$probe_count" -lt "$MODEL_HEALTH_PROBE_LIMIT" ]; then
            probe_count=$((probe_count + 1))
            probe_model_record "$record" >/dev/null && { printf '%s\n' "$record"; return 0; }
            continue
        fi
        printf '%s\n' "$record"
        return 0
    done << EOF
$(available_candidate_records "$task_type" "${2:-false}" "${3:-}" "${4:-}")
EOF
    return 1
}

resolve_interactive_record() {
    local task_type="$1" force_cloud="${2:-false}" record
    if record="$(select_record_for_task_type "$task_type" "$force_cloud" "${3:-}" "${4:-}")"; then
        printf '%s\n' "$record"
        return 0
    fi
    [ "$force_cloud" = "true" ] || return 1
    select_record_for_task_type "$task_type" "false" "${3:-}" "${4:-}"
}

session_task_type() {
    case "${1:-default}" in
        quick) printf 'quick\n' ;;
        think|reason) printf 'reason\n' ;;
        *) printf 'code\n' ;;
    esac
}

print_chat_launcher() {
    local mode="$1" record="$2" initial_task="${3:-}" task_type
    task_type="$(session_task_type "$mode")"
    printf '%s\n' '╔══════════════════════════════════════════════════════╗'
    printf '%s\n' '║                    CASCADE App                      ║'
    printf '%s\n' '╚══════════════════════════════════════════════════════╝'
    printf 'mode: %s\n' "$task_type"
    printf 'model: %s\n' "$(record_display_model "$record")"
    [ -n "$initial_task" ] && printf 'first prompt: %s\n' "$initial_task"
    printf '%s\n' 'chat: write the next message directly in the app'
    printf '%s\n' 'model switch: exit and use cascade model <provider/model> or cascade provider <name>'
    printf '%s\n' 'close: Ctrl+C or /exit'
    printf '\n'
}

interactive_session_dir() {
    local dir
    dir="$(cascade_home_dir)/sessions"
    mkdir -p "$dir"
    printf '%s\n' "$dir"
}

run_captured_chat() {
    local record="$1" history_file="$2" log_file="$3" api_base key_var key_value aider_model
    local -a cmd
    aider_model="$(record_aider_model "$record")"
    api_base="$(record_api_base "$record")"
    key_var="$(record_key_var "$record")"
    key_value=""
    [ -n "$key_var" ] && eval "key_value=\"\${$key_var:-}\""
    cmd=(aider --model "$aider_model" --yes --auto-commits --chat-history-file "$history_file" --restore-chat-history)
    if [ -n "$api_base" ]; then
        cmd=(aider --model "$aider_model" --openai-api-base "$api_base" --openai-api-key "$key_value" --yes --auto-commits --chat-history-file "$history_file" --restore-chat-history)
    fi
    : > "$log_file"
    if [ -t 1 ] && command -v script >/dev/null 2>&1 && [ "${CASCADE_APP_DISABLE_TTY_CAPTURE:-false}" != "true" ]; then
        script -q "$log_file" "${cmd[@]}" || return $?
        return 0
    fi
    set -o pipefail
    "${cmd[@]}" 2>&1 | tee "$log_file"
}

interactive_failure_kind() {
    local log_file="$1" output
    [ -f "$log_file" ] || return 1
    output="$(tail -200 "$log_file" 2>/dev/null || true)"
    [ -n "$output" ] || return 1
    case "$(aider_failure_kind "$output")" in
        generic) return 1 ;;
        *) aider_failure_kind "$output" ;;
    esac
}

resolve_next_record() {
    local task_type="$1" force_cloud="$2" blocked_provider="${3:-}" blocked_model="${4:-}" record
    while IFS= read -r record; do
        [ -n "$record" ] || continue
        [ -n "$blocked_provider" ] && [ "$(record_provider "$record")" = "$blocked_provider" ] && continue
        [ -n "$blocked_model" ] && [ "$(record_display_model "$record")" = "$blocked_model" ] && continue
        printf '%s\n' "$record"
        return 0
    done << EOF
$(available_candidate_records "$task_type" "$force_cloud" "" "")
EOF
    return 1
}

print_failover_notice() {
    printf '\n'
    printf 'CASCADE reroute: %s\n' "$1"
    printf 'New model: %s\n\n' "$2"
}

start_interactive_session() {
    local mode="${1:-default}" initial_task="${2:-}" task_type force_cloud=true record session_dir history_file log_file
    local failure_kind exit_code=0 blocked_provider="" blocked_model="" max_failovers=3 failovers=0
    local failed_provider failed_model
    task_type="$(session_task_type "$mode")"
    ensure_aider_installed || return 1
    session_dir="$(interactive_session_dir)"
    history_file="$session_dir/chat-$(date +%s)-$$.md"
    log_file="$session_dir/chat-$(date +%s)-$$.log"
    record="$(resolve_interactive_record "$task_type" "$force_cloud")" || { print_model_unavailable_hint; return 1; }
    while :; do
        [ "$failovers" -eq 0 ] && print_chat_launcher "$mode" "$record" "$initial_task"
        run_captured_chat "$record" "$history_file" "$log_file" || exit_code=$?
        exit_code="${exit_code:-0}"
        failure_kind="$(interactive_failure_kind "$log_file" || true)"
        [ -z "$failure_kind" ] && { log_usage "$(record_provider "$record")" "$(record_display_model "$record")" "$task_type" true; return "$exit_code"; }
        failed_provider="$(record_provider "$record")"
        failed_model="$(record_display_model "$record")"
        log_usage "$(record_provider "$record")" "$(record_display_model "$record")" "$task_type" false
        case "$failure_kind" in
            rate_limit|auth|model_unavailable) log_provider_failure "$failed_provider" "$failure_kind" ;;
        esac
        cache_model_health "$(record_display_model "$record")" "fail" "$(aider_failure_message "$failure_kind" "$failed_provider" "$failed_model")"
        [ "$failure_kind" = "model_unavailable" ] && blocked_model="$failed_model" || blocked_provider="$failed_provider"
        failovers=$((failovers + 1))
        [ "$failovers" -gt "$max_failovers" ] && return "$exit_code"
        record="$(resolve_next_record "$task_type" "$force_cloud" "$blocked_provider" "$blocked_model")" || return "$exit_code"
        print_failover_notice "$(aider_failure_message "$failure_kind" "$failed_provider" "$failed_model")" "$(record_display_model "$record")"
        exit_code=0
    done
}
