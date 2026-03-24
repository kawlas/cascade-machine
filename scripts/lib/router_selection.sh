#!/usr/bin/env bash

available_candidate_records() {
    ranked_candidates "$1" "$2" "$3" "$4" | sort -t'|' -k1,1nr -k4,4 | awk -F'|' '$2=="ok" { print $4 }'
}

resolve_best_record() {
    local task_type record probe_count=0
    task_type="$(classify_task "${1:-code}")"
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

probe_candidates() {
    local task_type="$1" force_cloud="$2" provider_filter="$3" model_filter="$4" record count=0
    while IFS= read -r record; do
        local result
        [ -n "$record" ] || continue
        count=$((count + 1))
        if result="$(probe_model_record "$record")"; then :; else :; fi
        printf '%-45s %s\n' "$(record_display_model "$record")" "$result"
        [ "$count" -ge "$MODEL_HEALTH_PROBE_LIMIT" ] && return 0
    done << EOF
$(available_candidate_records "$task_type" "$force_cloud" "$provider_filter" "$model_filter")
EOF
}

get_best_model() {
    local record
    record="$(resolve_best_record "$1" "${2:-false}" "${3:-}" "${4:-}")" && { record_display_model "$record"; return 0; }
    [ -n "${4:-}" ] && { printf 'UNAVAILABLE_MODEL\n'; return 1; }
    printf 'LIMIT_EXCEEDED\n'
    return 1
}

show_plan() {
    local task="${1:-code}" task_type
    task_type="$(classify_task "$task")"
    echo "Routing plan for: $task"
    echo "Task type: $task_type"
    ranked_candidates "$task_type" "${2:-false}" "${3:-}" "${4:-}" | sort -t'|' -k1,1nr -k4,4 | while IFS='|' read -r score status reason record; do
        printf '%-45s %-8s %-10s %s\n' "$(record_display_model "$record")" "$(record_tier "$record")" "$status" "$reason"
    done
}
