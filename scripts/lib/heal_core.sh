#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/router_core.sh"
source "$LIB_DIR/project_tools.sh"

HEAL_LEARNINGS_FILE="${CASCADE_LEARNINGS_FILE:-$(cascade_home_dir)/learnings.jsonl}"
HEAL_TODAY="$(date +%Y-%m-%d)"
MAX_RETRIES="${CASCADE_HEAL_MAX_RETRIES:-2}"

parse_heal_args() {
    HEAL_TASK_TYPE_OVERRIDE=""
    HEAL_FORCE_CLOUD="false"
    HEAL_ARGS=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            --reason|--think) HEAL_TASK_TYPE_OVERRIDE="reason" ;;
            --fast|--quick) HEAL_TASK_TYPE_OVERRIDE="quick" ;;
            --cloud) HEAL_FORCE_CLOUD="true" ;;
            *) HEAL_ARGS+=("$arg") ;;
        esac
    done
    HEAL_TASK="${HEAL_ARGS[*]}"
}

build_tier_list() {
    local task_type="$1"
    local force_cloud="$2"
    local tiers=()
    local history_model
    history_model="$(check_history "$task_type")"
    if [ "$force_cloud" != "true" ] && is_ollama_available; then
        tiers+=("$(local_model_for_task "$task_type")")
    fi
    if [ -n "$history_model" ] && [[ ! " ${tiers[*]} " =~ " $history_model " ]]; then
        tiers+=("$history_model")
    fi
    while IFS= read -r entry; do
        local provider model
        provider="$(echo "$entry" | cut -d: -f1)"
        model="$(echo "$entry" | cut -d: -f2-)"
        [ "$(provider_available "$provider")" = "false" ] && continue
        [[ " ${tiers[*]} " =~ " $model " ]] && continue
        tiers+=("$model")
    done << EOF
$(build_cloud_candidates "$task_type")
EOF
    printf '%s\n' "${tiers[@]}"
}

record_heal_result() {
    local task="$1" model="$2" task_type="$3" tier="$4" attempts="$5" success="$6" extra="$7"
    append_jsonl "$HEAL_LEARNINGS_FILE" \
        "{\"date\":\"$HEAL_TODAY\",\"task\":\"$(echo "$task" | head -c 120 | tr '"' "'")\",\"model\":\"$model\",\"task_type\":\"$task_type\",\"tier\":$tier,\"attempts\":$attempts,\"success\":$success${extra},\"ts\":$(date +%s)}"
}

run_heal() {
    parse_heal_args "$@"
    if [ -z "$HEAL_TASK" ]; then
        echo 'Usage: heal "opis zadania" [--reason|--fast|--cloud]'
        return 1
    fi
    if ! command -v aider >/dev/null 2>&1; then
        echo "aider is not installed or not in PATH"
        return 1
    fi

    local task_type test_cmd lint_cmd baseline error_context total_attempts
    local tier_list=()
    error_context=""
    total_attempts=0
    test_cmd="$(detect_test_cmd)"
    lint_cmd="$(detect_lint_cmd)"
    baseline="$(git_baseline)"
    task_type="${HEAL_TASK_TYPE_OVERRIDE:-$(classify_task "$HEAL_TASK")}"
    while IFS= read -r model; do
        [ -n "$model" ] && tier_list+=("$model")
    done << EOF
$(build_tier_list "$task_type" "$HEAL_FORCE_CLOUD")
EOF

    [ "${#tier_list[@]}" -eq 0 ] && {
        echo "No models available for this task"
        return 1
    }

    local tier_idx attempt model provider aider_exit full_task test_output test_exit changes
    for tier_idx in "${!tier_list[@]}"; do
        model="${tier_list[$tier_idx]}"
        provider="$(echo "$model" | cut -d'/' -f1)"
        for attempt in $(seq 1 "$MAX_RETRIES"); do
            total_attempts=$((total_attempts + 1))
            [ "$baseline" != "no-git" ] && [ "$total_attempts" -gt 1 ] && git reset --hard "$baseline" >/dev/null 2>&1 || true
            full_task="$HEAL_TASK"
            [ -n "$error_context" ] && full_task="$HEAL_TASK

IMPORTANT — Previous attempt failed with this error:
$error_context"
            aider_exit=0
            aider --model "$model" --message "$full_task" --yes --auto-commits --no-stream >/dev/null 2>&1 || aider_exit=$?
            if [ "$aider_exit" -ne 0 ] && [ "$aider_exit" -ne 1 ]; then
                error_context="Aider crashed with exit code $aider_exit"
                log_usage "$provider" "$model" "$task_type" false
                break
            fi
            [ -n "$lint_cmd" ] && eval "$lint_cmd" >/dev/null 2>&1 || true
            if [ -n "$test_cmd" ]; then
                test_output="$($test_cmd 2>&1)" && test_exit=0 || test_exit=$?
                if [ "$test_exit" -eq 0 ]; then
                    record_heal_result "$HEAL_TASK" "$model" "$task_type" "$((tier_idx + 1))" "$total_attempts" true ""
                    log_usage "$provider" "$model" "$task_type" true
                    echo "SUCCESS: $model"
                    return 0
                fi
                error_context="$(echo "$test_output" | tail -20)"
                log_usage "$provider" "$model" "$task_type" false
                continue
            fi
            if [ "$baseline" = "no-git" ]; then
                echo "SUCCESS: $model"
                return 0
            fi
            changes="$(git diff --stat "$baseline" 2>/dev/null | tail -1 || true)"
            if [ -n "$changes" ]; then
                record_heal_result "$HEAL_TASK" "$model" "$task_type" "$((tier_idx + 1))" "$total_attempts" true ',"no_tests":true'
                log_usage "$provider" "$model" "$task_type" true
                echo "SUCCESS: $model"
                return 0
            fi
            error_context="AI did not make any changes to the code"
        done
    done

    [ "$baseline" != "no-git" ] && git reset --hard "$baseline" >/dev/null 2>&1 || true
    record_heal_result "$HEAL_TASK" "all_failed" "$task_type" 0 "$total_attempts" false ""
    echo "ALL TIERS EXHAUSTED"
    [ -n "$error_context" ] && echo "$error_context"
    return 1
}
