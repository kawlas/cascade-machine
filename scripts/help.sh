#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/help_topics.sh"

load_cascade_env

case "${1:-help}" in
    models|model) print_models_help ;;
    doctor) print_doctor ;;
    config) handle_config ;;
    status|tokens) print_status ;;
    logs|log) print_logs ;;
    update) run_update ;;
    keys|key) print_keys_help ;;
    help|-h|--help|"") print_main_help ;;
    *) print_main_help ;;
esac
