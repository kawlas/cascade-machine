#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/router_core.sh"

case "${1:-}" in
    status)
        show_status
        ;;
    best)
        get_best_model "${*:2}"
        ;;
    classify)
        classify_task "${*:2}"
        ;;
    *)
        echo "Usage: router.sh {status|best \"task description\"|classify \"task\"}"
        exit 1
        ;;
esac
