#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE MACHINE — Installer
#
# Użycie:
#   ./install.sh              # interaktywna instalacja
#   ./install.sh --dry-run    # pokaż co zostanie zrobione
#   ./install.sh --force      # nadpisz istniejące pliki
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

CASCADE_DIR="$HOME/.cascade"
LOGS_DIR="$CASCADE_DIR/logs"
DOCS_DIR="$CASCADE_DIR/docs"
CASCADE_TEMPLATE_DIR="$CASCADE_DIR/.cascade"
ENV_FILE="$CASCADE_DIR/.env"

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         CASCADE MACHINE — Installer                      ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Instaluję framework do automatyzacji kodowania z AI     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ─── Parse argumentów ───
DRY_RUN=false
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
    esac
done

# ─── Funkcje pomocnicze ───
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ─── Sprawdzenie zależności ───
check_dependencies() {
    log_info "Sprawdzam zależności..."
    
    local missing=0
    
    # Git
    if ! command -v git > /dev/null 2>&1; then
        log_error "git nie zainstalowany"
        missing=$((missing + 1))
    else
        log_success "git: $(git --version)"
    fi
    
    # Bash
    if ! command -v bash > /dev/null 2>&1; then
        log_error "bash nie zainstalowany"
        missing=$((missing + 1))
    else
        log_success "bash: $(bash --version | head -1)"
    fi
    
    # Curl
    if ! command -v curl > /dev/null 2>&1; then
        log_error "curl nie zainstalowany"
        missing=$((missing + 1))
    else
        log_success "curl: $(curl --version | head -1)"
    fi
    
    # Ollama (opcjonalne)
    if command -v ollama > /dev/null 2>&1; then
        log_success "ollama: $(ollama --version 2>/dev/null | head -1)"
    else
        log_warning "ollama nie zainstalowany (opcjonalne, zalecane)"
        echo "   Zainstaluj: brew install ollama"
    fi
    
    # Aider (opcjonalne)
    if command -v aider > /dev/null 2>&1; then
        log_success "aider: $(command -v aider)"
    else
        log_warning "aider nie zainstalowany (opcjonalne, zalecane)"
        echo "   Zainstaluj: pip3 install aider-chat"
    fi
    
    return $missing
}

# ─── Tworzenie katalogów ───
create_directories() {
    log_info "Tworzę katalogi..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] mkdir -p $CASCADE_DIR"
        echo "  [DRY-RUN] mkdir -p $LOGS_DIR"
        echo "  [DRY-RUN] mkdir -p $DOCS_DIR"
        echo "  [DRY-RUN] mkdir -p $CASCADE_TEMPLATE_DIR"
        return
    fi
    
    mkdir -p "$CASCADE_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$DOCS_DIR"
    mkdir -p "$CASCADE_TEMPLATE_DIR"
    log_success "Utworzono $CASCADE_DIR"
    log_success "Utworzono $LOGS_DIR"
    log_success "Utworzono $DOCS_DIR"
    log_success "Utworzono $CASCADE_TEMPLATE_DIR"
}

# ─── Kopiowanie skryptów ───
copy_scripts() {
    log_info "Kopiuję skrypty do $CASCADE_DIR..."
    
    local scripts=(
        "heal.sh"
        "help.sh"
        "router.sh"
        "nightly.sh"
        "init-project.sh"
    )
    
    for script in "${scripts[@]}"; do
        local source_path="./scripts/$script"
        if [ -f "$source_path" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [DRY-RUN] cp $source_path $CASCADE_DIR/$script"
            else
                if [ "$FORCE" = true ] || [ ! -f "$CASCADE_DIR/$script" ]; then
                    cp "$source_path" "$CASCADE_DIR/$script"
                    chmod +x "$CASCADE_DIR/$script"
                    log_success "Skopiowano $script"
                else
                    log_warning "$script już istnieje, pominięto (użyj --force)"
                fi
            fi
        else
            log_error "Nie znaleziono ./$script"
        fi
    done
}

copy_support_files() {
    log_info "Kopiuję pliki pomocnicze i dokumentację..."

    local entries=(
        "scripts/aliases.sh:aliases.sh"
        "README.md:README.md"
        "docs/INSTALL.md:docs/INSTALL.md"
        "docs/COMMANDS.md:docs/COMMANDS.md"
        "docs/ARCHITECTURE.md:docs/ARCHITECTURE.md"
        "docs/STRUCTURE.md:docs/STRUCTURE.md"
        "docs/CONTRIBUTING.md:docs/CONTRIBUTING.md"
        "docs/CHANGELOG.md:docs/CHANGELOG.md"
        "LICENSE:LICENSE"
        "AGENTS.md:AGENTS.md"
        ".aider.conf.yml:.aider.conf.yml"
        ".kilocode:.kilocode"
        ".cascade/commands.md:.cascade/commands.md"
        ".cascade/decisions.md:.cascade/decisions.md"
        ".cascade/learnings.md:.cascade/learnings.md"
    )

    for entry in "${entries[@]}"; do
        local source_path="${entry%%:*}"
        local target_name="${entry##*:}"
        [ -f "./$source_path" ] || continue
        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY-RUN] cp ./$source_path $CASCADE_DIR/$target_name"
            continue
        fi
        mkdir -p "$CASCADE_DIR/$(dirname "$target_name")"
        cp "./$source_path" "$CASCADE_DIR/$target_name"
        log_success "Skopiowano $target_name"
    done
}

# ─── Kopiowanie plików konfiguracyjnych ───
copy_config() {
    log_info "Kopiuję pliki konfiguracyjne..."
    
    # .env.cascade → katalog instalacji + .env (tylko jeśli nie istnieje)
    if [ -f "./.env.cascade" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY-RUN] cp ./.env.cascade $CASCADE_DIR/.env.cascade"
            echo "  [DRY-RUN] cp ./.env.cascade $ENV_FILE (tylko jeśli nie istnieje)"
        else
            cp "./.env.cascade" "$CASCADE_DIR/.env.cascade"
            log_success "Skopiowano szablon $CASCADE_DIR/.env.cascade"
            if [ ! -f "$ENV_FILE" ]; then
                cp "./.env.cascade" "$ENV_FILE"
                log_success "Utworzono $ENV_FILE (edytuj i dodaj klucze API)"
            else
                log_warning "$ENV_FILE już istnieje, pominięto"
            fi
        fi
    fi
    
    # Szablony .cascade dla projektów
    if [ -d "./.cascade" ]; then
        log_info "Szablony .cascade/ dostępne w projekcie"
        log_info "Użyj cascade-init aby zainicjować nowy projekt"
    fi
}

# ─── Setup aliasów ───
setup_aliases() {
    log_info "Konfiguruję aliasy..."
    
    local shell_config=""
    
    if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        shell_config="$HOME/.bash_profile"
    else
        log_warning "Nie wykryto konfiguracji shella"
        echo "   Dodaj aliasy ręcznie do ~/.zshrc lub ~/.bashrc"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Dodam aliasy do $shell_config"
        return
    fi
    
    # Dodaj aliasy jeśli nie istnieją
    if ! grep -q "alias heal=" "$shell_config" 2>/dev/null; then
        cat >> "$shell_config" << 'ALIASES'

# CASCADE Machine aliases
export PATH="$HOME/.cascade:$PATH"
alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
alias think='aider --model ollama_chat/deepseek-r1:14b --auto-commits --yes'
alias quick='aider --model ollama_chat/devstral-small --auto-commits --yes'
alias cloud='aider --model groq/llama-3.3-70b-versatile --auto-commits --yes'
alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'
alias grok='aider --model xai/grok-3-mini --auto-commits --yes'
alias turbo='aider --model cerebras/llama-3.3-70b --auto-commits --yes'
alias gem='aider --model gemini/gemini-2.0-flash --auto-commits --yes'
alias heal="$HOME/.cascade/heal.sh"
alias cascade="$HOME/.cascade/help.sh"
alias cascade-init="$HOME/.cascade/init-project.sh"
alias cascade-status="$HOME/.cascade/help.sh status"
alias cascade-doctor="$HOME/.cascade/help.sh doctor"
alias cascade-config="$HOME/.cascade/help.sh config"
alias cascade-models="$HOME/.cascade/help.sh models"
alias cascade-logs="$HOME/.cascade/help.sh logs"
alias cascade-update="$HOME/.cascade/help.sh update"
alias tokens="$HOME/.cascade/router.sh status"
ALIASES
        log_success "Dodano aliasy do $shell_config"
        echo "   Uruchom: source $shell_config"
    else
        log_warning "Aliasy już skonfigurowane w $shell_config"
    fi
}

# ─── Podsumowanie ───
show_summary() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         ✅ Instalacja zakończona                         ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║                                                           ║"
    echo "║  Katalog instalacji: $CASCADE_DIR"
    echo "║                                                           ║"
    echo "║  Następne kroki:                                          ║"
    echo "║  1. Edytuj ~/.cascade/.env i dodaj klucze API            ║"
    echo "║  2. Uruchom: source ~/.zshrc (lub ~/.bashrc)             ║"
    echo "║  3. Sprawdź: cascade doctor                              ║"
    echo "║  4. Zacznij kodować: fast lub heal \"zadanie\"             ║"
    echo "║                                                           ║"
    echo "║  Dokumentacja:                                            ║"
    echo "║  • README.md — przegląd                                  ║"
    echo "║  • docs/COMMANDS.md — wszystkie komendy                  ║"
    echo "║  • docs/INSTALL.md — szczegółowa instalacja              ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

# ─── Główny flow ───
main() {
    check_dependencies || {
        log_error "Zainstaluj brakujące zależności i uruchom ponownie"
        exit 1
    }
    
    echo ""
    
    create_directories
    copy_scripts
    copy_support_files
    copy_config
    setup_aliases
    
    show_summary
}

main "$@"
