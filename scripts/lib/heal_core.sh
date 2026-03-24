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

run_heal() {
    parse_heal_args "$@"
    if [ -z "$HEAL_TASK" ]; then
        echo 'Usage: heal "opis zadania" [--reason|--fast|--cloud] [--provider name] [--model provider/model]'
        return 1
    fi
    ensure_aider_installed || return 1

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
$(build_tier_list "$task_type" "$HEAL_FORCE_CLOUD" "$HEAL_PROVIDER_FILTER" "$HEAL_MODEL_FILTER")
EOF

    if [ "${#tier_list[@]}" -eq 0 ] && [ "$HEAL_FORCE_CLOUD" = "true" ]; then
        while IFS= read -r model; do
            [ -n "$model" ] && tier_list+=("$model")
        done << EOF
$(build_tier_list "$task_type" "false" "$HEAL_PROVIDER_FILTER" "$HEAL_MODEL_FILTER")
EOF
    fi

    [ "${#tier_list[@]}" -eq 0 ] && {
        print_model_unavailable_hint
        return 1
    }

    local tier_idx attempt record display_model aider_model provider aider_exit full_task test_output test_exit changes api_base key_var key_value aider_output aider_failure
    for tier_idx in "${!tier_list[@]}"; do
        record="${tier_list[$tier_idx]}"
        display_model="$(record_display_model "$record")"
        aider_model="$(record_aider_model "$record")"
        provider="$(record_provider "$record")"
        api_base="$(record_api_base "$record")"
        key_var="$(record_key_var "$record")"
        key_value=""
        [ -n "$key_var" ] && eval "key_value=\"\${$key_var:-}\""
        for attempt in $(seq 1 "$MAX_RETRIES"); do
            total_attempts=$((total_attempts + 1))
            [ "$baseline" != "no-git" ] && [ "$total_attempts" -gt 1 ] && git reset --hard "$baseline" >/dev/null 2>&1 || true
            full_task="$HEAL_TASK"
            [ -n "$error_context" ] && full_task="$HEAL_TASK

IMPORTANT — Previous attempt failed with this error:
$error_context"
            aider_exit=0
            aider_output=""
            if [ -n "$api_base" ]; then
                aider_output="$(aider --model "$aider_model" --openai-api-base "$api_base" --openai-api-key "$key_value" --message "$full_task" --yes --auto-commits --no-stream 2>&1)" || aider_exit=$?
            else
                aider_output="$(aider --model "$aider_model" --message "$full_task" --yes --auto-commits --no-stream 2>&1)" || aider_exit=$?
            fi
            if [ "$aider_exit" -ne 0 ] && [ "$aider_exit" -ne 1 ]; then
                aider_failure="$(aider_failure_kind "$aider_output")"
                error_context="$(aider_failure_message "$aider_failure" "$provider" "$display_model")"
                log_usage "$provider" "$display_model" "$task_type" false
                case "$aider_failure" in
                    rate_limit|auth|model_unavailable) log_provider_failure "$provider" "$aider_failure" ;;
                esac
                if [ "$aider_failure" != "generic" ]; then
                    printf 'FAILOVER: %s\n' "$error_context"
                    break
                fi
                [ -n "$aider_output" ] && error_context="$(printf '%s\n' "$aider_output" | tail -20)"
                [ -z "$error_context" ] && error_context="Aider crashed with exit code $aider_exit"
                break
            fi
            [ -n "$lint_cmd" ] && eval "$lint_cmd" >/dev/null 2>&1 || true
            if [ -n "$test_cmd" ]; then
                test_output="$($test_cmd 2>&1)" && test_exit=0 || test_exit=$?
                if [ "$test_exit" -eq 0 ]; then
                    record_heal_result "$HEAL_TASK" "$display_model" "$task_type" "$((tier_idx + 1))" "$total_attempts" true ""
                    log_usage "$provider" "$display_model" "$task_type" true
                    echo "SUCCESS: $display_model"
                    return 0
                fi
                error_context="$(echo "$test_output" | tail -20)"
                log_usage "$provider" "$display_model" "$task_type" false
                continue
            fi
            if [ "$baseline" = "no-git" ]; then
                echo "SUCCESS: $display_model"
                return 0
            fi
            changes="$(git diff --stat "$baseline" 2>/dev/null | tail -1 || true)"
            if [ -n "$changes" ]; then
                record_heal_result "$HEAL_TASK" "$display_model" "$task_type" "$((tier_idx + 1))" "$total_attempts" true ',"no_tests":true'
                log_usage "$provider" "$display_model" "$task_type" true
                echo "SUCCESS: $display_model"
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
