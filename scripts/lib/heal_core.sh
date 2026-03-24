#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/chat_session.sh"
source "$LIB_DIR/router_core.sh"
source "$LIB_DIR/project_tools.sh"

HEAL_LEARNINGS_FILE="${CASCADE_LEARNINGS_FILE:-$(cascade_home_dir)/learnings.jsonl}"
HEAL_TODAY="$(date +%Y-%m-%d)"
MAX_RETRIES="${CASCADE_HEAL_MAX_RETRIES:-2}"

parse_heal_args() {
    HEAL_TASK_TYPE_OVERRIDE=""
    HEAL_FORCE_CLOUD="false"
    HEAL_PROVIDER_FILTER=""
    HEAL_MODEL_FILTER=""
    HEAL_ARGS=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --reason|--think) HEAL_TASK_TYPE_OVERRIDE="reason" ;;
            --fast|--quick) HEAL_TASK_TYPE_OVERRIDE="quick" ;;
            --cloud) HEAL_FORCE_CLOUD="true" ;;
            --provider)
                [ "$#" -lt 2 ] && { echo "Missing value for --provider"; return 1; }
                HEAL_PROVIDER_FILTER="$2"; shift
                ;;
            --model)
                [ "$#" -lt 2 ] && { echo "Missing value for --model"; return 1; }
                HEAL_MODEL_FILTER="$2"; shift
                ;;
            *) HEAL_ARGS+=("$1" ) ;;
        esac
        shift
    done
    if [ "${#HEAL_ARGS[@]}" -eq 0 ]; then
        HEAL_TASK=""
    else
        HEAL_TASK="${HEAL_ARGS[*]}"
    fi
}

build_tier_list() {
    available_candidate_records "$1" "$2" "$3" "$4"
}

git_worktree_dirty() {
    [ -n "$(git status --porcelain 2>/dev/null)" ]
}

ensure_safe_heal_workspace() {
    local baseline="$1"
    [ "$baseline" = "no-git" ] && return 0
    git_worktree_dirty || return 0
    echo "Refusing to run heal on a dirty git worktree. Commit or stash your changes first."
    return 1
}

reset_heal_workspace() {
    [ "$1" = "no-git" ] && return 0
    git reset --hard "$1" >/dev/null 2>&1
}

collect_heal_tier_list() {
    local task_type="$1" force_cloud="$2" provider_filter="$3" model_filter="$4"
    local record probe_count=0
    while IFS= read -r record; do
        [ -n "$record" ] || continue
        if [ "$MODEL_HEALTH_ENABLED" = "true" ] && [ "$probe_count" -lt "$MODEL_HEALTH_PROBE_LIMIT" ]; then
            probe_count=$((probe_count + 1))
            probe_model_record "$record" >/dev/null || continue
        fi
        printf '%s\n' "$record"
    done << EOF
$(build_tier_list "$task_type" "$force_cloud" "$provider_filter" "$model_filter")
EOF
}

load_heal_tier_list() {
    local task_type="$1" force_cloud="$2" provider_filter="$3" model_filter="$4"
    HEAL_TIER_LIST=()
    while IFS= read -r model; do
        [ -n "$model" ] && HEAL_TIER_LIST+=("$model")
    done << EOF
$(collect_heal_tier_list "$task_type" "$force_cloud" "$provider_filter" "$model_filter")
EOF
}

record_heal_result() {
    local task="$1" model="$2" task_type="$3" tier="$4" attempts="$5" success="$6" extra="$7"
    append_jsonl "$HEAL_LEARNINGS_FILE" \
        "{\"date\":\"$HEAL_TODAY\",\"task\":\"$(echo "$task" | head -c 120 | tr '"' "'")\",\"model\":\"$model\",\"task_type\":\"$task_type\",\"tier\":$tier,\"attempts\":$attempts,\"success\":$success${extra},\"ts\":$(date +%s)}"
}

aider_failure_kind() {
    local output="$1" lower
    lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"
    if printf '%s' "$lower" | grep -qE 'rate.?limit|rate limited|tpm|tokens per minute|try again later|quota'; then
        printf '%s\n' "rate_limit"
        return
    fi
    if printf '%s' "$lower" | grep -qE 'auth rejected|unauthorized|invalid api key|incorrect api key|forbidden'; then
        printf '%s\n' "auth"
        return
    fi
    if printf '%s' "$lower" | grep -qE 'model unavailable|not found|does not exist|unknown model'; then
        printf '%s\n' "model_unavailable"
        return
    fi
    printf '%s\n' "generic"
}

aider_failure_message() {
    local kind="$1" provider="$2" model="$3"
    case "$kind" in
        rate_limit) printf 'Provider %s hit a rate limit for %s\n' "$provider" "$model" ;;
        auth) printf 'Provider %s rejected credentials for %s\n' "$provider" "$model" ;;
        model_unavailable) printf 'Provider %s cannot serve %s right now\n' "$provider" "$model" ;;
        *) printf 'Aider failed for %s\n' "$model" ;;
    esac
}

heal_provider_blocked() {
    local blocked_provider
    for blocked_provider in "${HEAL_BLOCKED_PROVIDERS[@]:-}"; do
        [ "$blocked_provider" = "$1" ] && return 0
    done
    return 1
}

heal_model_blocked() {
    local blocked_model
    for blocked_model in "${HEAL_BLOCKED_MODELS[@]:-}"; do
        [ "$blocked_model" = "$1" ] && return 0
    done
    return 1
}

heal_record_blocked() {
    local record="$1"
    heal_provider_blocked "$(record_provider "$record")" && return 0
    heal_model_blocked "$(record_display_model "$record")"
}

register_heal_failover_target() {
    local failure_kind="$1" provider="$2" model="$3"
    case "$failure_kind" in
        rate_limit|auth) HEAL_BLOCKED_PROVIDERS+=("$provider") ;;
        model_unavailable) HEAL_BLOCKED_MODELS+=("$model") ;;
    esac
}

cache_heal_failover() {
    local failure_kind="$1" provider="$2" model="$3"
    case "$failure_kind" in
        rate_limit|auth|model_unavailable)
            cache_model_health "$model" "fail" "$(aider_failure_message "$failure_kind" "$provider" "$model")"
            ;;
    esac
}

build_heal_attempt_task() {
    local task="$1" error_context="$2"
    if [ -n "$error_context" ]; then
        printf '%s\n\nIMPORTANT - Previous attempt failed with this error:\n%s\n' "$task" "$error_context"
        return
    fi
    printf '%s\n' "$task"
}

run_lint_validation() {
    local lint_cmd="$1" lint_output lint_exit
    [ -n "$lint_cmd" ] || return 0
    lint_output="$(eval "$lint_cmd" 2>&1)" && return 0
    lint_exit=$?
    HEAL_ERROR_CONTEXT="$(printf '%s\n' "$lint_output" | tail -20)"
    [ -n "$HEAL_ERROR_CONTEXT" ] || HEAL_ERROR_CONTEXT="Lint failed with exit code $lint_exit"
    return 1
}

run_test_validation() {
    local test_cmd="$1" test_output test_exit
    [ -n "$test_cmd" ] || return 0
    test_output="$($test_cmd 2>&1)" && return 0
    test_exit=$?
    HEAL_ERROR_CONTEXT="$(printf '%s\n' "$test_output" | tail -20)"
    [ -n "$HEAL_ERROR_CONTEXT" ] || HEAL_ERROR_CONTEXT="Tests failed with exit code $test_exit"
    return 1
}

heal_changes_detected() {
    local baseline="$1" changes
    [ "$baseline" = "no-git" ] && return 0
    changes="$(git diff --stat "$baseline" 2>/dev/null | tail -1 || true)"
    [ -n "$changes" ]
}

run_heal() {
    parse_heal_args "$@"
    if [ -z "$HEAL_TASK" ]; then
        echo 'Usage: heal "opis zadania" [--reason|--fast|--cloud] [--provider name] [--model provider/model]'
        return 1
    fi
    ensure_aider_installed || return 1

    local task_type test_cmd lint_cmd baseline total_attempts
    local tier_idx attempt record display_model aider_model provider aider_exit
    local full_task api_base key_var key_value aider_output aider_failure
    total_attempts=0
    test_cmd="$(detect_test_cmd)"
    lint_cmd="$(detect_lint_cmd)"
    baseline="$(git_baseline)"
    ensure_safe_heal_workspace "$baseline" || return 1
    task_type="${HEAL_TASK_TYPE_OVERRIDE:-$(classify_task "$HEAL_TASK")}"
    load_heal_tier_list "$task_type" "$HEAL_FORCE_CLOUD" "$HEAL_PROVIDER_FILTER" "$HEAL_MODEL_FILTER"
    if [ "${#HEAL_TIER_LIST[@]}" -eq 0 ] && [ "$HEAL_FORCE_CLOUD" = "true" ]; then
        load_heal_tier_list "$task_type" "false" "$HEAL_PROVIDER_FILTER" "$HEAL_MODEL_FILTER"
    fi
    [ "${#HEAL_TIER_LIST[@]}" -eq 0 ] && {
        print_model_unavailable_hint
        return 1
    }

    HEAL_ERROR_CONTEXT=""
    HEAL_BLOCKED_PROVIDERS=()
    HEAL_BLOCKED_MODELS=()
    for tier_idx in "${!HEAL_TIER_LIST[@]}"; do
        record="${HEAL_TIER_LIST[$tier_idx]}"
        heal_record_blocked "$record" && continue
        display_model="$(record_display_model "$record")"
        aider_model="$(record_aider_model "$record")"
        provider="$(record_provider "$record")"
        api_base="$(record_api_base "$record")"
        key_var="$(record_key_var "$record")"
        key_value=""
        [ -n "$key_var" ] && eval "key_value=\"\${$key_var:-}\""
        for attempt in $(seq 1 "$MAX_RETRIES"); do
            total_attempts=$((total_attempts + 1))
            [ "$total_attempts" -gt 1 ] && reset_heal_workspace "$baseline" || true
            full_task="$(build_heal_attempt_task "$HEAL_TASK" "$HEAL_ERROR_CONTEXT")"
            aider_exit=0
            aider_output=""
            if [ -n "$api_base" ]; then
                aider_output="$(aider --model "$aider_model" --openai-api-base "$api_base" --openai-api-key "$key_value" --message "$full_task" --yes --auto-commits --no-stream 2>&1)" || aider_exit=$?
            else
                aider_output="$(aider --model "$aider_model" --message "$full_task" --yes --auto-commits --no-stream 2>&1)" || aider_exit=$?
            fi
            if [ "$aider_exit" -ne 0 ]; then
                aider_failure="$(aider_failure_kind "$aider_output")"
                HEAL_ERROR_CONTEXT="$(aider_failure_message "$aider_failure" "$provider" "$display_model")"
                log_usage "$provider" "$display_model" "$task_type" false
                case "$aider_failure" in
                    rate_limit|auth|model_unavailable) log_provider_failure "$provider" "$aider_failure" ;;
                esac
                cache_heal_failover "$aider_failure" "$provider" "$display_model"
                register_heal_failover_target "$aider_failure" "$provider" "$display_model"
                if [ "$aider_failure" != "generic" ]; then
                    printf 'FAILOVER: %s\n' "$HEAL_ERROR_CONTEXT"
                    break
                fi
                [ -n "$aider_output" ] && HEAL_ERROR_CONTEXT="$(printf '%s\n' "$aider_output" | tail -20)"
                [ -n "$HEAL_ERROR_CONTEXT" ] || HEAL_ERROR_CONTEXT="Aider crashed with exit code $aider_exit"
                continue
            fi
            if ! run_lint_validation "$lint_cmd"; then
                log_usage "$provider" "$display_model" "$task_type" false
                continue
            fi
            if ! run_test_validation "$test_cmd"; then
                log_usage "$provider" "$display_model" "$task_type" false
                continue
            fi
            if [ -n "$test_cmd" ]; then
                record_heal_result "$HEAL_TASK" "$display_model" "$task_type" "$((tier_idx + 1))" "$total_attempts" true ""
                log_usage "$provider" "$display_model" "$task_type" true
                echo "SUCCESS: $display_model"
                return 0
            fi
            if heal_changes_detected "$baseline"; then
                record_heal_result "$HEAL_TASK" "$display_model" "$task_type" "$((tier_idx + 1))" "$total_attempts" true ',"no_tests":true'
                log_usage "$provider" "$display_model" "$task_type" true
                echo "SUCCESS: $display_model"
                return 0
            fi
            HEAL_ERROR_CONTEXT="AI did not make any changes to the code"
        done
    done

    reset_heal_workspace "$baseline" || true
    record_heal_result "$HEAL_TASK" "all_failed" "$task_type" 0 "$total_attempts" false ""
    echo "ALL TIERS EXHAUSTED"
    [ -n "$HEAL_ERROR_CONTEXT" ] && echo "$HEAL_ERROR_CONTEXT"
    return 1
}
