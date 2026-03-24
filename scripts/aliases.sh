#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE MACHINE — Shell Aliases
#
# Użycie:
#   source aliases.sh              # dodaje aliasy do current shell
#   ./aliases.sh --install         # instaluje do ~/.zshrc lub ~/.bashrc
# ═══════════════════════════════════════════════════════════════

CASCADE_DIR="$HOME/.cascade"

alias_block() {
    cat << 'ALIASES'
# CASCADE Machine aliases
export PATH="$HOME/.cascade:$PATH"
alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
alias think='aider --model ollama_chat/deepseek-r1:8b --auto-commits --yes'
alias quick='aider --model ollama_chat/qwen3:4b --auto-commits --yes'
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
    
    # Dodaj jeśli nie istnieje
    if ! grep -q "alias heal=" "$shell_config" 2>/dev/null; then
        alias_block >> "$shell_config"
        echo "✅ Dodano aliasy do $shell_config"
        echo "   Uruchom: source $shell_config"
    else
        echo "⚠️  Aliasy już istnieją w $shell_config"
    fi
}

# ─── Load aliases do current shell ───
load_aliases() {
    export PATH="$CASCADE_DIR:$PATH"
    alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
    alias think='aider --model ollama_chat/deepseek-r1:8b --auto-commits --yes'
    alias quick='aider --model ollama_chat/qwen3:4b --auto-commits --yes'
    alias cloud='aider --model groq/llama-3.3-70b-versatile --auto-commits --yes'
    alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'
    alias grok='aider --model xai/grok-3-mini --auto-commits --yes'
    alias turbo='aider --model cerebras/llama-3.3-70b --auto-commits --yes'
    alias gem='aider --model gemini/gemini-2.0-flash --auto-commits --yes'
    alias heal="$CASCADE_DIR/heal.sh"
    alias cascade="$CASCADE_DIR/help.sh"
    alias cascade-init="$CASCADE_DIR/init-project.sh"
    alias cascade-status="$CASCADE_DIR/help.sh status"
    alias cascade-doctor="$CASCADE_DIR/help.sh doctor"
    alias cascade-config="$CASCADE_DIR/help.sh config"
    alias cascade-models="$CASCADE_DIR/help.sh models"
    alias cascade-logs="$CASCADE_DIR/help.sh logs"
    alias cascade-update="$CASCADE_DIR/help.sh update"
    alias tokens="$CASCADE_DIR/router.sh status"
    echo "✅ Aliasy załadowane"
}

# ─── CLI ───
case "${1:-}" in
    --install|-i) install_aliases ;;
    --load|-l) load_aliases ;;
    --show|-s) alias_block ;;
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
