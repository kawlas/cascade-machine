#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT_DIR/scripts/lib/install_core.sh"

DRY_RUN=false
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
    esac
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         CASCADE MACHINE — Installer                      ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Instaluję framework do automatyzacji kodowania z AI     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

check_dependencies || {
    log_error "Zainstaluj brakujące zależności i uruchom ponownie"
    exit 1
}

echo ""
create_directories "$DRY_RUN"
copy_runtime_scripts "$DRY_RUN"
copy_runtime_support "$DRY_RUN"
copy_env_template "$DRY_RUN"
write_install_metadata "$DRY_RUN"
setup_aliases_block "$DRY_RUN"
show_install_summary
