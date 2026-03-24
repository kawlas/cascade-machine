#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"

MODEL_CATALOG_FILE="${CASCADE_MODEL_CATALOG_FILE:-$(cascade_home_dir)/model_catalog.tsv}"
MODEL_CATALOG_TTL="${CASCADE_MODEL_CATALOG_TTL_SECONDS:-21600}"
MODEL_CATALOG_AUTO_REFRESH="${CASCADE_MODEL_CATALOG_AUTO_REFRESH:-true}"

provider_var_prefix() {
    printf '%s\n' "CASCADE_PROVIDER_$(printf '%s' "$1" | tr '[:lower:]-.' '[:upper:]__')"
}

provider_kind() {
    local provider="$1" prefix override
    prefix="$(provider_var_prefix "$provider")"
    eval "override=\"\${${prefix}_TYPE:-}\""
    [ -n "$override" ] && { printf '%s\n' "$override"; return; }
    case "$provider" in
        openrouter|groq|gemini|cerebras|xai) printf '%s\n' "$provider" ;;
        *) printf 'openai\n' ;;
    esac
}

provider_tier() {
    local provider="$1" prefix override
    prefix="$(provider_var_prefix "$provider")"
    eval "override=\"\${${prefix}_TIER:-}\""
    [ -n "$override" ] && { printf '%s\n' "$override"; return; }
    case "$provider" in
        openrouter|groq|gemini|cerebras) printf 'free\n' ;;
        xai) printf 'prepaid\n' ;;
        *) printf 'prepaid\n' ;;
    esac
}

provider_api_key_var() {
    local provider="$1" prefix override
    prefix="$(provider_var_prefix "$provider")"
    eval "override=\"\${${prefix}_KEY_VAR:-}\""
    [ -n "$override" ] && { printf '%s\n' "$override"; return; }
    case "$provider" in
        openrouter) printf 'OPENROUTER_API_KEY\n' ;;
        groq) printf 'GROQ_API_KEY\n' ;;
        gemini) printf 'GEMINI_API_KEY\n' ;;
        cerebras) printf 'CEREBRAS_API_KEY\n' ;;
        xai) printf 'XAI_API_KEY\n' ;;
        *) printf '%s_API_KEY\n' "$(printf '%s' "$provider" | tr '[:lower:]-.' '[:upper:]__')" ;;
    esac
}

provider_api_key() {
    local provider="$1" key_var
    key_var="$(provider_api_key_var "$1")"
    if [ "$provider" = "gemini" ] && [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_AI_KEY:-}" ]; then
        printf '%s\n' "$GOOGLE_AI_KEY"
        return
    fi
    eval "printf '%s\n' \"\${$key_var:-}\""
}

provider_base_url() {
    local provider="$1" prefix override kind
    prefix="$(provider_var_prefix "$provider")"
    eval "override=\"\${${prefix}_BASE_URL:-}\""
    [ -n "$override" ] && { printf '%s\n' "${override%/}"; return; }
    kind="$(provider_kind "$provider")"
    case "$kind" in
        openrouter) printf 'https://openrouter.ai/api/v1\n' ;;
        groq) printf 'https://api.groq.com/openai/v1\n' ;;
        gemini) printf 'https://generativelanguage.googleapis.com/v1beta\n' ;;
        cerebras) printf 'https://api.cerebras.ai/v1\n' ;;
        xai) printf 'https://api.x.ai/v1\n' ;;
        *) printf '\n' ;;
    esac
}

provider_models_url() {
    local provider="$1" prefix override base kind key
    prefix="$(provider_var_prefix "$provider")"
    eval "override=\"\${${prefix}_MODELS_URL:-}\""
    [ -n "$override" ] && { printf '%s\n' "$override"; return; }
    base="$(provider_base_url "$provider")"
    kind="$(provider_kind "$provider")"
    case "$kind" in
        gemini)
            key="$(provider_api_key "$provider")"
            [ -n "$key" ] && printf '%s/models?key=%s\n' "$base" "$key"
            ;;
        xai) printf '%s/language-models\n' "$base" ;;
        cerebras) printf 'https://api.cerebras.ai/public/v1/models?format=openrouter\n' ;;
        *) [ -n "$base" ] && printf '%s/models\n' "$base" ;;
    esac
}

catalog_providers() {
    printf '%s\n' "${CASCADE_MODEL_PROVIDERS:-openrouter,groq,gemini,cerebras,xai}" \
        | tr ',' '\n' | sed 's/^ *//; s/ *$//' | awk 'NF'
}

provider_enabled() {
    local provider="$1" prefix enabled
    prefix="$(provider_var_prefix "$provider")"
    eval "enabled=\"\${${prefix}_ENABLED:-true}\""
    [ "$enabled" != "false" ]
}

provider_ready_for_catalog() {
    local provider="$1" kind key url
    kind="$(provider_kind "$provider")"
    key="$(provider_api_key "$provider")"
    url="$(provider_models_url "$provider")"
    [ -n "$url" ] || return 1
    [ "$kind" = "cerebras" ] && return 0
    [ -n "$key" ]
}

catalog_file_mtime() {
    python3 - "$1" <<'PY'
import os, sys
path = sys.argv[1]
print(int(os.path.getmtime(path)) if os.path.exists(path) else 0)
PY
}

catalog_is_stale() {
    local now mtime
    [ ! -f "$MODEL_CATALOG_FILE" ] && return 0
    now="$(date +%s)"
    mtime="$(catalog_file_mtime "$MODEL_CATALOG_FILE")"
    [ $((now - mtime)) -ge "$MODEL_CATALOG_TTL" ]
}

fetch_provider_payload() {
    local provider="$1" target="$2" url key kind
    url="$(provider_models_url "$provider")"
    kind="$(provider_kind "$provider")"
    key="$(provider_api_key "$provider")"
    [ -n "$url" ] || return 1
    if [ "$kind" = "gemini" ] || [ -z "$key" ]; then
        curl -fsSL --connect-timeout 5 --max-time 20 "$url" -o "$target"
    else
        curl -fsSL --connect-timeout 5 --max-time 20 \
            -H "Authorization: Bearer $key" "$url" -o "$target"
    fi
}

parse_provider_payload() {
    local provider="$1" raw_file="$2"
    python3 "$LIB_DIR/catalog_parser.py" \
        "$provider" \
        "$(provider_kind "$provider")" \
        "$(provider_tier "$provider")" \
        "$(provider_base_url "$provider")" \
        "$(provider_api_key_var "$provider")" \
        "$raw_file"
}

refresh_model_catalog() {
    local tmp_file raw_file provider wrote_any="false"
    tmp_file="$(mktemp)"
    while IFS= read -r provider; do
        provider_enabled "$provider" || continue
        provider_ready_for_catalog "$provider" || continue
        raw_file="$(mktemp)"
        if fetch_provider_payload "$provider" "$raw_file" && parse_provider_payload "$provider" "$raw_file" >> "$tmp_file"; then
            wrote_any="true"
        fi
        rm -f "$raw_file"
    done << EOF
$(catalog_providers)
EOF
    if [ "$wrote_any" = "true" ] && [ -s "$tmp_file" ]; then
        ensure_parent_dir "$MODEL_CATALOG_FILE"
        mv "$tmp_file" "$MODEL_CATALOG_FILE"
        return 0
    fi
    rm -f "$tmp_file"
    return 1
}

refresh_model_catalog_if_needed() {
    [ "$MODEL_CATALOG_AUTO_REFRESH" = "true" ] || return 0
    catalog_is_stale || return 0
    refresh_model_catalog >/dev/null 2>&1 || true
}

list_catalog_records() {
    [ -f "$MODEL_CATALOG_FILE" ] || return 0
    cat "$MODEL_CATALOG_FILE"
}

provider_catalog_summary() {
    local provider
    while IFS= read -r provider; do
        local models_count key_state
        models_count="$(list_catalog_records | awk -F'\t' -v provider="$provider" '$1==provider { count++ } END { print count + 0 }')"
        [ -n "$(provider_api_key "$provider")" ] && key_state="configured" || key_state="missing key"
        printf '%s\t%s\t%s\t%s\t%s\n' \
            "$provider" "$(provider_kind "$provider")" "$(provider_tier "$provider")" "$key_state" "$models_count"
    done << EOF
$(catalog_providers)
EOF
}
