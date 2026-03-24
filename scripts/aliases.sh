#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE MACHINE — Shell Aliases
#
# Użycie:
#   source aliases.sh              # dodaje aliasy do current shell
#   ./aliases.sh --install         # instaluje do ~/.zshrc lub ~/.bashrc
# ═══════════════════════════════════════════════════════════════

CASCADE_DIR="$HOME/.cascade"

managed_block() {
    cat << 'ALIASES'
# >>> CASCADE Machine >>>
[ -f "$HOME/.cascade/.env" ] && source "$HOME/.cascade/.env"
[ -f "$HOME/.cascade/aliases.sh" ] && source "$HOME/.cascade/aliases.sh" --load >/dev/null 2>&1
# <<< CASCADE Machine <<<
ALIASES
}

runtime_aliases() {
    cat << 'ALIASES'
export PATH="$HOME/.cascade:$PATH"
alias quick='aider --model ollama_chat/devstral-small --auto-commits --yes'
alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
alias think='aider --model ollama_chat/deepseek-r1:14b --auto-commits --yes'
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
}

# ─── Instalacja aliasów do config shella ───
install_aliases() {
    local shell_config=""
    
    if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        shell_config="$HOME/.bash_profile"
    else
        echo "❌ Nie wykryto konfiguracji shella"
        echo "   Dodaj ręcznie do ~/.zshrc lub ~/.bashrc"
        return 1
    fi
    
    if ! grep -q "# >>> CASCADE Machine >>>" "$shell_config" 2>/dev/null; then
        managed_block >> "$shell_config"
        echo "✅ Dodano aliasy do $shell_config"
        echo "   Uruchom: source $shell_config"
    else
        echo "⚠️  CASCADE block już istnieje w $shell_config"
    fi
}

# ─── Load aliases do current shell ───
load_aliases() {
    export PATH="$CASCADE_DIR:$PATH"
    eval "$(runtime_aliases)"
    echo "✅ Aliasy załadowane"
}

# ─── CLI ───
case "${1:-}" in
    --install|-i) install_aliases ;;
    --load|-l) load_aliases ;;
    --show|-s) runtime_aliases ;;
    *)
        echo "CASCADE Machine — Shell Aliases"
        echo ""
        echo "Usage:"
        echo "  source aliases.sh              # load to current shell"
        echo "  ./aliases.sh --install         # install to ~/.zshrc"
        echo "  ./aliases.sh --load            # load to current shell"
        echo "  ./aliases.sh --show            # show alias definitions"
        echo ""
        ;;
esac
