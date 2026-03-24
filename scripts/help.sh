#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/chat_session.sh"
source "$SCRIPT_DIR/lib/heal_core.sh"
source "$SCRIPT_DIR/lib/help_topics.sh"

load_cascade_env

if [[ "${1:-}" == /* ]]; then
    if [ "$1" = "/" ]; then
        print_main_help
        exit 0
    fi
    set -- "${1#/}" "${@:2}"
fi

case "${1:-}" in
    ""|chat) start_interactive_session "default" ;;
    dashboard|welcome) print_welcome_dashboard ;;
    current) print_router_preferences ;;
    auto) clear_routing_preferences ;;
    providers) print_providers_help ;;
    recommend)
        shift
        recommend_for_task "$@"
        ;;
    pin)
        shift
        set_mode_preference_model "${1:-}" "${2:-}"
        ;;
    pin-provider)
        shift
        set_mode_preference_provider "${1:-}" "${2:-}"
        ;;
    unpin)
        shift
        clear_mode_preference "${1:-}"
        ;;
    model|prefer-model)
        shift
        set_preferred_model "${1:-}"
        ;;
    provider|prefer-provider)
        shift
        set_preferred_provider "${1:-}"
        ;;
    go|do|run)
        shift
        [ "$#" -eq 0 ] && { print_mode_usage "default"; exit 1; }
        run_heal "$@"
        ;;
    think|reason)
        shift
        start_interactive_session "think" "${*:-}"
        ;;
    quick|fastfix)
        shift
        start_interactive_session "quick" "${*:-}"
        ;;
    cloud)
        shift
        start_interactive_session "cloud" "${*:-}"
        ;;
    stop|exit|quit)
        echo "Close the active Aider chat with Ctrl+C or /exit inside the session."
        ;;
    start|reload|restart) print_start_help ;;
    models)
        shift
        print_models_help "${1:-}"
        ;;
    doctor) print_doctor ;;
    config) handle_config ;;
    status|tokens) print_status ;;
    logs|log) print_logs ;;
    sync|reinstall) run_sync ;;
    update) run_update ;;
    keys|key) print_keys_help ;;
    help|-h|--help) print_main_help ;;
    *)
        [ "$#" -eq 0 ] && { print_mode_usage "default"; exit 1; }
        start_interactive_session "default" "$*"
        ;;
esac
