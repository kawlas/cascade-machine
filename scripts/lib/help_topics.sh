#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/router_core.sh"

preview_secret() {
    local value="${1:-}"
    [ -n "$value" ] && printf '%s...\n' "${value:0:16}" || printf 'nie ustawiony\n'
}

install_source_file() {
    printf '%s\n' "$(cascade_home_dir)/.install-source"
}

install_source_dir() {
    local source_file source_dir
    source_file="$(install_source_file)"
    [ -f "$source_file" ] || return 1
    source_dir="$(cat "$source_file" 2>/dev/null)"
    [ -n "$source_dir" ] || return 1
    [ -f "$source_dir/install.sh" ] || return 1
    printf '%s\n' "$source_dir"
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

remove_env_export() {
    local var_name="$1"
    local env_file tmp_file
    env_file="$(cascade_home_dir)/.env"
    ensure_parent_dir "$env_file"
    touch "$env_file"
    tmp_file="$(mktemp)"
    grep -v "^export ${var_name}=" "$env_file" > "$tmp_file" 2>/dev/null || true
    mv "$tmp_file" "$env_file"
}

preferred_model_value() {
    printf '%s\n' "${CASCADE_PREFERRED_MODEL:-}"
}

preferred_provider_value() {
    printf '%s\n' "${CASCADE_PREFERRED_PROVIDER:-}"
}

mode_preference_var_name() {
    local mode="$1" kind="$2"
    printf 'CASCADE_%s_PREFERRED_%s\n' "$(printf '%s' "$mode" | tr '[:lower:]' '[:upper:]')" "$(printf '%s' "$kind" | tr '[:lower:]' '[:upper:]')"
}

mode_preference_value() {
    local mode="$1" kind="$2" var_name value
    var_name="$(mode_preference_var_name "$mode" "$kind")"
    eval "value=\"\${$var_name:-}\""
    printf '%s\n' "$value"
}

print_router_preferences() {
    local preferred_model preferred_provider
    preferred_model="$(preferred_model_value)"
    preferred_provider="$(preferred_provider_value)"
    echo "CASCADE routing preferences"
    [ -n "$preferred_model" ] && echo "preferred model: $preferred_model" || echo "preferred model: auto"
    [ -n "$preferred_provider" ] && echo "preferred provider: $preferred_provider" || echo "preferred provider: auto"
    for mode in quick reason cloud; do
        [ -n "$(mode_preference_value "$mode" model)" ] && echo "$mode preferred model: $(mode_preference_value "$mode" model)"
        [ -n "$(mode_preference_value "$mode" provider)" ] && echo "$mode preferred provider: $(mode_preference_value "$mode" provider)"
    done
    echo "fallback: always enabled"
    echo "note: manual preference is first choice only; if it fails, CASCADE falls back automatically"
}

set_preferred_model() {
    local model="${1:-}"
    if [ -z "$model" ] || [[ "$model" != */* ]]; then
        echo 'Usage: cascade model provider/model-id'
        return 1
    fi
    update_env_export "CASCADE_PREFERRED_MODEL" "$model"
    echo "Preferred model set: $model"
    echo "Fallback remains automatic."
}

set_preferred_provider() {
    local provider="${1:-}"
    if [ -z "$provider" ]; then
        echo 'Usage: cascade provider provider-name'
        return 1
    fi
    update_env_export "CASCADE_PREFERRED_PROVIDER" "$provider"
    echo "Preferred provider set: $provider"
    echo "Fallback remains automatic."
}

clear_routing_preferences() {
    remove_env_export "CASCADE_PREFERRED_MODEL"
    remove_env_export "CASCADE_PREFERRED_PROVIDER"
    remove_env_export "CASCADE_QUICK_PREFERRED_MODEL"
    remove_env_export "CASCADE_QUICK_PREFERRED_PROVIDER"
    remove_env_export "CASCADE_REASON_PREFERRED_MODEL"
    remove_env_export "CASCADE_REASON_PREFERRED_PROVIDER"
    remove_env_export "CASCADE_CLOUD_PREFERRED_MODEL"
    remove_env_export "CASCADE_CLOUD_PREFERRED_PROVIDER"
    echo "Routing preferences cleared."
    echo "CASCADE is back to full automatic selection."
}

validate_mode_name() {
    case "${1:-}" in
        quick|reason|cloud) return 0 ;;
        *) echo 'Mode must be one of: quick, reason, cloud'; return 1 ;;
    esac
}

set_mode_preference_model() {
    local mode="${1:-}" model="${2:-}" var_name
    validate_mode_name "$mode" || return 1
    if [ -z "$model" ] || [[ "$model" != */* ]]; then
        echo 'Usage: cascade pin <quick|reason|cloud> provider/model-id'
        return 1
    fi
    var_name="$(mode_preference_var_name "$mode" model)"
    update_env_export "$var_name" "$model"
    echo "Pinned $mode mode to model: $model"
    echo "Fallback remains automatic."
}

set_mode_preference_provider() {
    local mode="${1:-}" provider="${2:-}" var_name
    validate_mode_name "$mode" || return 1
    if [ -z "$provider" ]; then
        echo 'Usage: cascade pin-provider <quick|reason|cloud> provider-name'
        return 1
    fi
    var_name="$(mode_preference_var_name "$mode" provider)"
    update_env_export "$var_name" "$provider"
    echo "Pinned $mode mode to provider: $provider"
    echo "Fallback remains automatic."
}

clear_mode_preference() {
    local mode="${1:-}"
    validate_mode_name "$mode" || return 1
    remove_env_export "$(mode_preference_var_name "$mode" model)"
    remove_env_export "$(mode_preference_var_name "$mode" provider)"
    echo "Cleared $mode mode preference."
}

print_providers_help() {
    refresh_model_catalog_if_needed
    provider_catalog_summary
}

print_models_help() {
    local provider_filter="${1:-}"
    refresh_model_catalog_if_needed
    if [ -f "${CASCADE_MODEL_CATALOG_FILE:-$(cascade_home_dir)/model_catalog.tsv}" ]; then :; fi
    echo "CASCADE models"
    if [ -n "$provider_filter" ]; then
        echo "provider: $provider_filter"
        list_catalog_records | awk -F'\t' -v provider="$provider_filter" '$1==provider { printf "%s\t%s\t%s\n", $2, $4, ($5 ? $5 : "-") }'
    else
        list_catalog_records | awk -F'\t' '{ printf "%s\t%s\t%s\n", $1, $2, $4 }'
    fi
    if [ -z "$(list_catalog_records)" ]; then
        echo "No live catalog cached yet. Run: bash ~/.cascade/router.sh refresh"
    fi
    echo ""
    echo "Preference commands:"
    echo "- cascade current"
    echo "- cascade model openrouter/mistralai/devstral-2"
    echo "- cascade provider gemini"
    echo "- cascade pin quick gemini/gemini-2.0-flash"
    echo "- cascade pin-provider cloud openrouter"
    echo "- cascade unpin quick"
    echo "- cascade auto"
}

recommend_for_task() {
    local task="${*:-}"
    if [ -z "$task" ]; then
        echo 'Usage: cascade recommend "task description"'
        return 1
    fi
    echo "CASCADE recommend"
    echo "task: $task"
    echo "type: $(classify_task "$task")"
    echo "best: $(bash "$(cascade_home_dir)/router.sh" best "$task" 2>/dev/null || true)"
    echo ""
    bash "$(cascade_home_dir)/router.sh" plan "$task"
}

print_start_help() {
    cat <<'START'
CASCADE start

- Uzyj po nowym terminalu albo po zmianach w ~/.cascade/.env
- Przeladowuje ~/.cascade/.env i aliasy w biezacej sesji
- Dziala najlepiej jako komenda shellowa: cascade start
- Potem wpisz: cascade
START
}

print_mode_usage() {
    case "$1" in
        quick)
            cat <<'USAGE'
CASCADE quick

Chat mode biased toward lightweight models.
Example:
  quick "fix typo in README"
USAGE
            ;;
        think|reason)
            cat <<'USAGE'
CASCADE think

Chat mode for analysis, debugging, and explanation.
Example:
  think "why does this test fail?"
USAGE
            ;;
        cloud)
            cat <<'USAGE'
CASCADE cloud

Cloud-first chat mode with local fallback.
Example:
  cloud "analyze the code and suggest fixes"
USAGE
            ;;
        *)
            cat <<'USAGE'
CASCADE

Usage:
  cascade
  cascade "task"
USAGE
            ;;
    esac
}

shell_integration_ready() {
    local shell_config
    shell_config="$(choose_shell_config 2>/dev/null)" || return 1
    [ -f "$shell_config" ] || return 1
    grep -q '# >>> CASCADE Machine >>>' "$shell_config" 2>/dev/null
}

runtime_shortcut_defined() {
    local name="$1"
    local aliases_file output
    aliases_file="$(cascade_home_dir)/aliases.sh"
    [ -f "$aliases_file" ] || return 1
    output="$(bash "$aliases_file" --show 2>/dev/null)" || return 1
    printf '%s\n' "$output" | grep -Eq "^(alias ${name}=|${name}\(\) \{)"
}

print_doctor() {
    local ok="✅" fail="❌" warn="⚠️ "
    echo "CASCADE doctor"
    command -v ollama >/dev/null 2>&1 && echo "$ok ollama" || echo "$fail ollama"
    command -v aider >/dev/null 2>&1 && echo "$ok aider" || echo "$fail aider"
    is_ollama_available && echo "$ok ollama runtime" || echo "$warn ollama runtime"
    [ -f "$(cascade_home_dir)/heal.sh" ] && echo "$ok runtime files" || echo "$fail runtime files"
    shell_integration_ready && echo "$ok shell integration" || echo "$warn shell integration"
    [ -n "${OPENROUTER_API_KEY:-}" ] && echo "$ok OPENROUTER_API_KEY" || echo "$warn OPENROUTER_API_KEY"
    [ -n "${GROQ_API_KEY:-}" ] && echo "$ok GROQ_API_KEY" || echo "$warn GROQ_API_KEY"
    [ -n "${GEMINI_API_KEY:-}" ] && echo "$ok GEMINI_API_KEY" || echo "$warn GEMINI_API_KEY"
    for alias_name in cascade quick fast think cloud smart heal tokens cascade-init; do
        runtime_shortcut_defined "$alias_name" && echo "$ok $alias_name" || echo "$warn $alias_name"
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

run_sync() {
    local source_dir
    if ! source_dir="$(install_source_dir)"; then
        echo "Brak zapisanego repo zrodlowego."
        echo "Uruchom instalator z repo raz, aby powiazac runtime z kodem."
        return 1
    fi
    echo "Synchronizuje runtime z repo:"
    echo "$source_dir"
    (
        cd "$source_dir" &&
        bash ./install.sh
    )
}

print_keys_help() {
    echo "OpenRouter: https://openrouter.ai/keys"
    echo "Google: https://aistudio.google.com/app/apikey"
    echo "Groq: https://console.groq.com/keys"
    echo "Plik kluczy: ~/.cascade/.env"
}

count_configured_providers() {
    local provider count=0
    while IFS= read -r provider; do
        [ -n "$provider" ] || continue
        [ -n "$(provider_api_key "$provider")" ] && count=$((count + 1))
    done << EOF
$(catalog_providers)
EOF
    printf '%s\n' "$count"
}

print_welcome_dashboard() {
    local blue cyan green yellow bold reset current_model provider_count
    blue='\033[34m'
    cyan='\033[36m'
    green='\033[32m'
    yellow='\033[33m'
    bold='\033[1m'
    reset='\033[0m'
    current_model="${AIDER_MODEL:-cloud auto -> local fallback}"
    provider_count="$(count_configured_providers)"

    printf '%b\n' "${bold}${cyan}╔══════════════════════════════════════════════════════╗${reset}"
    printf '%b\n' "${bold}${cyan}║                   CASCADE Machine                   ║${reset}"
    printf '%b\n' "${bold}${cyan}╚══════════════════════════════════════════════════════╝${reset}"
    printf '%b\n' "${blue}  /\\\\   /\\\\   automatic coding workflow${reset}"
    printf '%b\n' "${blue} /  \\\\_/  \\\\  self-healing + routing + local/cloud${reset}"
    printf '%b\n' "${blue}/_/\\\\___/\\\\_\\\\${reset}"
    printf '\n'
    printf '%b\n' "${bold}Now:${reset}"
    printf '%b\n' "  ${green}default model:${reset} ${current_model}"
    printf '%b\n' "  ${green}configured providers:${reset} ${provider_count}"
    printf '%b\n' "  ${green}runtime:${reset} $(cascade_home_dir)"
    printf '\n'
    printf '%b\n' "${bold}Use most often:${reset}"
    printf '%b\n' "  ${yellow}cascade${reset}                opens chat on best cloud model, fallback to local"
    printf '%b\n' "  ${yellow}cascade \"zadanie\"${reset}      opens chat and keeps your task visible in the app"
    printf '%b\n' "  ${yellow}fast \"zadanie\"${reset}         direct local coding model"
    printf '%b\n' "  ${yellow}quick \"zadanie\"${reset}        opens lightweight chat"
    printf '%b\n' "  ${yellow}think \"zadanie\"${reset}        opens reasoning chat"
    printf '%b\n' "  ${yellow}cloud${reset}                  opens chat preferring cloud, fallback to local"
    printf '%b\n' "  ${yellow}cloud \"zadanie\"${reset}        opens cloud-first chat"
    printf '%b\n' "  ${yellow}cascade run \"zadanie\"${reset}  unattended self-healing mode"
    printf '\n'
    printf '%b\n' "${bold}Preferences:${reset}"
    printf '%b\n' "  ${yellow}cascade current${reset}         show preferred model/provider"
    printf '%b\n' "  ${yellow}cascade model <provider/model>${reset}    prefer one model, keep fallback"
    printf '%b\n' "  ${yellow}cascade provider <name>${reset}  prefer one provider, keep fallback"
    printf '%b\n' "  ${yellow}cascade pin <mode> <model>${reset}      pin quick/reason/cloud with fallback"
    printf '%b\n' "  ${yellow}cascade pin-provider <mode> <provider>${reset}  pin provider per mode"
    printf '%b\n' "  ${yellow}cascade unpin <mode>${reset}        clear one mode preference"
    printf '%b\n' "  ${yellow}cascade auto${reset}            clear manual preferences"
    printf '\n'
    printf '%b\n' "${bold}Maintenance:${reset}"
    printf '%b\n' "  ${yellow}cascade start${reset}           run once after opening terminal"
    printf '%b\n' "  ${yellow}cascade dashboard${reset}       show this welcome screen again"
    printf '%b\n' "  ${yellow}cascade doctor${reset}          check runtime and keys"
    printf '%b\n' "  ${yellow}cascade sync${reset}            update ~/.cascade after repo changes"
    printf '\n'
    printf '%b\n' "  ${cyan}Start here:${reset} type ${yellow}cascade${reset} for chat or ${yellow}cascade run \"...\"${reset} for unattended automation."
    printf '%b\n' "  ${cyan}Also:${reset} slash commands work too, eg. ${yellow}cascade /doctor${reset} or ${yellow}cascade /models${reset}."
}

print_main_help() {
    cat <<'HELP'
CASCADE Machine

Session start:
- cascade start        # raz po otwarciu nowego terminala
- cascade              # otwiera chat na najlepszym modelu cloud, z fallbackiem lokalnym
- cascade "zadanie"    # otwiera app i chat z widocznym zadaniem startowym
- cascade dashboard    # ekran startowy i skróty

Daily shortcuts:
- quick "zadanie"      # otwiera chat lekkiego trybu
- fast "zadanie"       # glowny lokalny model do kodu
- think "zadanie"      # otwiera chat reasoning
- think                # otwiera chat reasoning
- cloud                # otwiera chat cloud-first z fallbackiem lokalnym
- cloud "zadanie"      # otwiera chat cloud-first
- smart "zadanie"      # mocniejszy model cloud
- turbo "zadanie"
- gem "zadanie"
- grok "zadanie"

Automatic self-healing:
- cascade run "zadanie"
- cascade do "zadanie"
- cascade go "zadanie"
- heal "zadanie"  # compatibility / advanced entrypoint

Tools:
- cascade help
- cascade doctor
- cascade status
- cascade config
- cascade models
- cascade providers
- cascade current
- cascade model provider/model-id
- cascade provider provider-name
- cascade recommend "task"
- cascade pin quick provider/model-id
- cascade pin-provider cloud provider-name
- cascade unpin quick
- cascade auto
- cascade keys
- cascade logs
- cascade update
- cascade-init
- tokens

Maintenance:
- cascade sync         # tylko po zmianach w repo CASCADE

Slash commands:
- cascade /doctor
- cascade /models
- cascade /providers
- cascade /current
- cascade /recommend "task"
- cascade /pin quick provider/model-id
- cascade /pin-provider cloud provider-name
- cascade /unpin quick
- cascade /auto
- cascade /status
- cascade /sync
HELP
}
