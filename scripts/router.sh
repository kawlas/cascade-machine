#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/router_core.sh"

parse_router_options() {
    ROUTER_FORCE_CLOUD="false"
    ROUTER_PROVIDER_FILTER=""
    ROUTER_MODEL_FILTER=""
    ROUTER_TASK=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --cloud) ROUTER_FORCE_CLOUD="true" ;;
            --provider)
                [ "$#" -lt 2 ] && { echo "Missing value for --provider" >&2; return 1; }
                ROUTER_PROVIDER_FILTER="$2"; shift
                ;;
            --model)
                [ "$#" -lt 2 ] && { echo "Missing value for --model" >&2; return 1; }
                ROUTER_MODEL_FILTER="$2"; shift
                ;;
            *) ROUTER_TASK="${ROUTER_TASK:+$ROUTER_TASK }$1" ;;
        esac
        shift
    done
    [ -n "$ROUTER_TASK" ] || ROUTER_TASK="code"
}

case "${1:-}" in
    status)
        show_status
        ;;
    refresh)
        refresh_model_catalog
        ;;
    providers)
        refresh_model_catalog_if_needed
        provider_catalog_summary
        ;;
    best)
        shift
        parse_router_options "$@"
        get_best_model "$ROUTER_TASK" "$ROUTER_FORCE_CLOUD" "$ROUTER_PROVIDER_FILTER" "$ROUTER_MODEL_FILTER"
        ;;
    resolve)
        shift
        parse_router_options "$@"
        if record="$(resolve_best_record "$ROUTER_TASK" "$ROUTER_FORCE_CLOUD" "$ROUTER_PROVIDER_FILTER" "$ROUTER_MODEL_FILTER")"; then
            printf 'display_model=%s\naider_model=%s\ntier=%s\napi_base=%s\napi_key_var=%s\n' \
                "$(record_display_model "$record")" \
                "$(record_aider_model "$record")" \
                "$(record_tier "$record")" \
                "$(record_api_base "$record")" \
                "$(record_key_var "$record")"
        else
            echo 'UNAVAILABLE_MODEL'
            exit 1
        fi
        ;;
    probe)
        shift
        parse_router_options "$@"
        probe_candidates "$(classify_task "$ROUTER_TASK")" "$ROUTER_FORCE_CLOUD" "$ROUTER_PROVIDER_FILTER" "$ROUTER_MODEL_FILTER"
        ;;
    plan)
        shift
        parse_router_options "$@"
        show_plan "$ROUTER_TASK" "$ROUTER_FORCE_CLOUD" "$ROUTER_PROVIDER_FILTER" "$ROUTER_MODEL_FILTER"
        ;;
    classify)
        classify_task "${*:2}"
        ;;
    *)
        echo 'Usage: router.sh {status|refresh|providers|best [--cloud] [--provider name] [--model provider/model] "task"|resolve [filters] "task"|probe [filters] "task"|plan [filters] "task"|classify "task"}'
        exit 1
        ;;
esac
