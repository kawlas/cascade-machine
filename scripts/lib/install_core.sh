#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"

CASCADE_DIR="$HOME/.cascade"
LOGS_DIR="$CASCADE_DIR/logs"
DOCS_DIR="$CASCADE_DIR/docs"
CASCADE_TEMPLATE_DIR="$CASCADE_DIR/.cascade"
LIB_TARGET_DIR="$CASCADE_DIR/lib"
ENV_FILE="$CASCADE_DIR/.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

check_dependencies() {
    log_info "Sprawdzam zależności..."
    local missing=0
    for cmd in git bash curl; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            log_error "$cmd nie zainstalowany"
            missing=$((missing + 1))
        else
            log_success "$cmd: $(command -v "$cmd")"
        fi
    done
    if command -v ollama > /dev/null 2>&1; then
        log_success "ollama: $(ollama --version 2>/dev/null | head -1)"
    else
        log_warning "ollama nie zainstalowany (opcjonalne, zalecane)"
    fi
    if command -v aider > /dev/null 2>&1; then
        log_success "aider: $(command -v aider)"
    else
        log_warning "aider nie zainstalowany (opcjonalne, zalecane)"
    fi
    return "$missing"
}

create_directories() {
    local dry_run="$1"
    log_info "Tworzę katalogi..."
    for dir in "$CASCADE_DIR" "$LOGS_DIR" "$DOCS_DIR" "$CASCADE_TEMPLATE_DIR" "$LIB_TARGET_DIR"; do
        if [ "$dry_run" = "true" ]; then
            echo "  [DRY-RUN] mkdir -p $dir"
        else
            mkdir -p "$dir"
            log_success "Utworzono $dir"
        fi
    done
}

copy_entry() {
    local source_path="$1" target_path="$2" dry_run="$3"
    if [ "$dry_run" = "true" ]; then
        echo "  [DRY-RUN] cp ./$source_path $target_path"
        return
    fi
    ensure_parent_dir "$target_path"
    cp "./$source_path" "$target_path"
    log_success "Skopiowano ${target_path#$CASCADE_DIR/}"
}

copy_runtime_scripts() {
    local dry_run="$1"
    log_info "Kopiuję skrypty do $CASCADE_DIR..."
    local file
    for file in scripts/heal.sh scripts/help.sh scripts/router.sh scripts/nightly.sh scripts/init-project.sh; do
        copy_entry "$file" "$CASCADE_DIR/$(basename "$file")" "$dry_run"
        [ "$dry_run" = "true" ] || chmod +x "$CASCADE_DIR/$(basename "$file")"
    done
}

copy_runtime_support() {
    local dry_run="$1"
    log_info "Kopiuję pliki pomocnicze i dokumentację..."
    local entry
    for entry in \
        "scripts/aliases.sh:aliases.sh" \
        "README.md:README.md" \
        "docs/INSTALL.md:docs/INSTALL.md" \
        "docs/COMMANDS.md:docs/COMMANDS.md" \
        "docs/ARCHITECTURE.md:docs/ARCHITECTURE.md" \
        "docs/STRUCTURE.md:docs/STRUCTURE.md" \
        "docs/CONTRIBUTING.md:docs/CONTRIBUTING.md" \
        "docs/CHANGELOG.md:docs/CHANGELOG.md" \
        ".cascade/commands.md:.cascade/commands.md" \
        ".cascade/decisions.md:.cascade/decisions.md" \
        ".cascade/learnings.md:.cascade/learnings.md" \
        ".aider.conf.yml:.aider.conf.yml" \
        ".kilocode:.kilocode" \
        "LICENSE:LICENSE" \
        "AGENTS.md:AGENTS.md"; do
        copy_entry "${entry%%:*}" "$CASCADE_DIR/${entry##*:}" "$dry_run"
    done
    local lib_file
    for lib_file in scripts/lib/*.sh; do
        copy_entry "${lib_file#./}" "$LIB_TARGET_DIR/$(basename "$lib_file")" "$dry_run"
    done
}

copy_env_template() {
    local dry_run="$1"
    log_info "Kopiuję pliki konfiguracyjne..."
    if [ "$dry_run" = "true" ]; then
        echo "  [DRY-RUN] cp ./.env.cascade $CASCADE_DIR/.env.cascade"
        echo "  [DRY-RUN] cp ./.env.cascade $ENV_FILE (tylko jeśli nie istnieje)"
        return
    fi
    cp "./.env.cascade" "$CASCADE_DIR/.env.cascade"
    log_success "Skopiowano szablon $CASCADE_DIR/.env.cascade"
    if [ ! -f "$ENV_FILE" ]; then
        cp "./.env.cascade" "$ENV_FILE"
        log_success "Utworzono $ENV_FILE (edytuj i dodaj klucze API)"
    else
        log_warning "$ENV_FILE już istnieje, pominięto"
    fi
}

setup_aliases_block() {
    local dry_run="$1"
    local shell_config
    log_info "Konfiguruję aliasy..."
    if ! shell_config="$(choose_shell_config)"; then
        log_warning "Nie wykryto konfiguracji shella"
        return 0
    fi
    if [ "$dry_run" = "true" ]; then
        echo "  [DRY-RUN] Dodam aliasy do $shell_config"
        return
    fi
    if grep -q "# >>> CASCADE Machine >>>" "$shell_config" 2>/dev/null; then
        log_warning "CASCADE block już skonfigurowany w $shell_config"
        return
    fi
    cat >> "$shell_config" << 'ALIASES'

# >>> CASCADE Machine >>>
[ -f "$HOME/.cascade/.env" ] && source "$HOME/.cascade/.env"
[ -f "$HOME/.cascade/aliases.sh" ] && source "$HOME/.cascade/aliases.sh" --load >/dev/null 2>&1
# <<< CASCADE Machine <<<
ALIASES
    log_success "Dodano aliasy do $shell_config"
}

show_install_summary() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         ✅ Instalacja zakończona                         ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║  Katalog instalacji: $CASCADE_DIR"
    echo "║  1. Edytuj ~/.cascade/.env i dodaj klucze API            ║"
    echo "║  2. Uruchom: source ~/.zshrc (lub ~/.bashrc)             ║"
    echo "║  3. Sprawdź: cascade doctor                              ║"
    echo "║  4. Zacznij kodować: fast lub heal \"zadanie\"             ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}
