#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/router_core.sh"

preview_secret() {
    local value="${1:-}"
    [ -n "$value" ] && printf '%s...\n' "${value:0:16}" || printf 'nie ustawiony\n'
}

update_env_export() {
    local var_name="$1"
    local var_value="$2"
    local env_file tmp_file
    env_file="$(cascade_home_dir)/.env"
    ensure_parent_dir "$env_file"
    touch "$env_file"
    tmp_file="$(mktemp)"
    grep -v "^export ${var_name}=" "$env_file" > "$tmp_file" 2>/dev/null || true
    printf 'export %s="%s"\n' "$var_name" "$var_value" >> "$tmp_file"
    mv "$tmp_file" "$env_file"
}

print_models_help() {
    cat <<'MODELS'
CASCADE models

Local:
- quick  -> ollama_chat/devstral-small
- fast   -> ollama_chat/qwen3-coder
- think  -> ollama_chat/deepseek-r1:14b

Cloud:
- cloud  -> groq/llama-3.3-70b-versatile
- smart  -> openrouter/mistralai/devstral-2
- turbo  -> cerebras/llama-3.3-70b
- gem    -> gemini/gemini-2.0-flash
- grok   -> xai/grok-3-mini
MODELS
}

print_doctor() {
    local ok="✅" fail="❌" warn="⚠️ "
    echo "CASCADE doctor"
    command -v ollama >/dev/null 2>&1 && echo "$ok ollama" || echo "$fail ollama"
    command -v aider >/dev/null 2>&1 && echo "$ok aider" || echo "$fail aider"
    is_ollama_available && echo "$ok ollama runtime" || echo "$warn ollama runtime"
    [ -f "$(cascade_home_dir)/heal.sh" ] && echo "$ok runtime files" || echo "$fail runtime files"
    [ -n "${OPENROUTER_API_KEY:-}" ] && echo "$ok OPENROUTER_API_KEY" || echo "$warn OPENROUTER_API_KEY"
    [ -n "${GROQ_API_KEY:-}" ] && echo "$ok GROQ_API_KEY" || echo "$warn GROQ_API_KEY"
    [ -n "${GEMINI_API_KEY:-}" ] && echo "$ok GEMINI_API_KEY" || echo "$warn GEMINI_API_KEY"
    for alias_name in quick fast think cloud smart heal tokens cascade-init; do
        type "$alias_name" >/dev/null 2>&1 && echo "$ok $alias_name" || echo "$warn $alias_name"
    done
}

print_config_menu() {
    echo "CASCADE config"
    echo "1) Dodaj klucz API"
    echo "2) Zmień domyślny model"
    echo "3) Ustaw nightly cron"
    echo "4) Pokaż aktualną konfigurację"
    echo "5) Wyjdź"
}

handle_config() {
    local choice key_choice key model_choice new_model
    print_config_menu
    read -r -p "Wybierz (1-5): " choice
    case "$choice" in
        1)
            echo "1) OpenRouter"
            echo "2) Google Gemini"
            echo "3) Groq"
            read -r -p "Wybierz (1-3): " key_choice
            case "$key_choice" in
                1) read -r -p "Wklej klucz OpenRouter: " key; update_env_export "OPENROUTER_API_KEY" "$key" ;;
                2) read -r -p "Wklej klucz Gemini: " key; update_env_export "GEMINI_API_KEY" "$key" ;;
                3) read -r -p "Wklej klucz Groq: " key; update_env_export "GROQ_API_KEY" "$key" ;;
                *) return 1 ;;
            esac
            ;;
        2)
            echo "1) ollama_chat/qwen3-coder"
            echo "2) ollama_chat/devstral-small"
            echo "3) ollama_chat/deepseek-r1:14b"
            echo "4) groq/llama-3.3-70b-versatile"
            read -r -p "Wybierz (1-4): " model_choice
            case "$model_choice" in
                1) new_model="ollama_chat/qwen3-coder" ;;
                2) new_model="ollama_chat/devstral-small" ;;
                3) new_model="ollama_chat/deepseek-r1:14b" ;;
                4) new_model="groq/llama-3.3-70b-versatile" ;;
                *) return 1 ;;
            esac
            update_env_export "AIDER_MODEL" "$new_model"
            ;;
        3)
            if crontab -l 2>/dev/null | grep -q nightly.sh; then
                echo "Nightly cron już istnieje"
            else
                (crontab -l 2>/dev/null; echo "0 23 * * * ~/.cascade/nightly.sh >> ~/.cascade/logs/nightly.log 2>&1") | crontab -
            fi
            ;;
        4)
            echo "OPENROUTER: $(preview_secret "${OPENROUTER_API_KEY:-}")"
            echo "GEMINI: $(preview_secret "${GEMINI_API_KEY:-}")"
            echo "GROQ: $(preview_secret "${GROQ_API_KEY:-}")"
            echo "AIDER_MODEL: ${AIDER_MODEL:-nie ustawiony}"
            ;;
        *)
            return 0
            ;;
    esac
}

print_status() {
    show_status
    echo ""
    echo "Klucze:"
    [ -n "${OPENROUTER_API_KEY:-}" ] && echo "  OpenRouter: configured" || echo "  OpenRouter: missing"
    [ -n "${GROQ_API_KEY:-}" ] && echo "  Groq: configured" || echo "  Groq: missing"
    [ -n "${GEMINI_API_KEY:-}" ] && echo "  Gemini: configured" || echo "  Gemini: missing"
}

print_logs() {
    local today_file
    today_file="$(cascade_home_dir)/logs/nightly-$(date +%Y%m%d).log"
    if [ -f "$today_file" ]; then
        cat "$today_file"
        return
    fi
    echo "Brak raportu na dziś"
    ls -lt "$(cascade_home_dir)"/logs/*.log 2>/dev/null | head -5 | awk '{print $NF}'
}

run_update() {
    echo "Aktualizacja zależności"
    command -v pip3 >/dev/null 2>&1 && pip3 install --upgrade aider-chat >/dev/null 2>&1 || true
    command -v brew >/dev/null 2>&1 && brew upgrade ollama >/dev/null 2>&1 || true
    echo "Update zakończony"
}

print_keys_help() {
    echo "OpenRouter: https://openrouter.ai/keys"
    echo "Google: https://aistudio.google.com/app/apikey"
    echo "Groq: https://console.groq.com/keys"
    echo "Plik kluczy: ~/.cascade/.env"
}

print_main_help() {
    cat <<'HELP'
CASCADE Machine

Coding:
- quick
- fast
- think
- cloud
- smart
- turbo
- gem
- grok
- heal "zadanie"

Tools:
- cascade help
- cascade doctor
- cascade status
- cascade config
- cascade models
- cascade keys
- cascade logs
- cascade update
- cascade-init
- tokens
HELP
}
