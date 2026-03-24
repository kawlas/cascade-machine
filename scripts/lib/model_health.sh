#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/model_catalog.sh"

MODEL_HEALTH_FILE="${CASCADE_MODEL_HEALTH_FILE:-$(cascade_home_dir)/model_health.tsv}"
MODEL_HEALTH_ENABLED="${CASCADE_MODEL_HEALTH_ENABLED:-true}"
MODEL_HEALTH_TTL="${CASCADE_MODEL_HEALTH_TTL_SECONDS:-900}"
MODEL_HEALTH_TIMEOUT="${CASCADE_MODEL_HEALTH_TIMEOUT_SECONDS:-12}"
MODEL_HEALTH_PROBE_LIMIT="${CASCADE_MODEL_HEALTH_PROBE_LIMIT:-5}"

health_field() { printf '%s\n' "$1" | cut -f "$2"; }
health_display_model() { health_field "$1" 2; }
health_aider_model() { health_field "$1" 3; }
health_provider() { health_field "$1" 1; }
health_api_base() { health_field "$1" 6; }
health_key_var() { health_field "$1" 7; }

health_reason_text() {
    printf '%s' "${1:-unknown}" | tr '\t\r\n' '   '
}

health_request_model() {
    local record="$1"
    case "$(health_provider "$record")" in
        ollama_chat) printf '%s\n' "$(health_aider_model "$record" | sed 's#^ollama_chat/##')" ;;
        *) printf '%s\n' "$(health_display_model "$record" | cut -d'/' -f2-)" ;;
    esac
}

health_inference_base() {
    local record="$1" api_base provider
    api_base="$(health_api_base "$record")"
    [ -n "$api_base" ] && { printf '%s\n' "$api_base"; return; }
    provider="$(health_provider "$record")"
    provider_base_url "$provider"
}

health_api_key_value() {
    local record="$1" key_var value
    key_var="$(health_key_var "$1")"
    [ -n "$key_var" ] && eval "value=\"\${$key_var:-}\""
    [ -n "$value" ] && { printf '%s\n' "$value"; return; }
    provider_api_key "$(health_provider "$record")"
}

provider_health_enabled() {
    local provider="$1" prefix enabled
    prefix="$(provider_var_prefix "$provider")"
    eval "enabled=\"\${${prefix}_HEALTHCHECK:-true}\""
    [ "$enabled" != "false" ]
}

cached_model_health() {
    local model="$1" now
    [ -f "$MODEL_HEALTH_FILE" ] || return 1
    now="$(date +%s)"
    awk -F'\t' -v model="$model" -v now="$now" -v ttl="$MODEL_HEALTH_TTL" '
        $1 == model { line = $0 }
        END {
            if (!line) exit 1
            split(line, fields, "\t")
            if ((now - fields[2]) > ttl) exit 2
            print fields[3] "\t" fields[4]
        }
    ' "$MODEL_HEALTH_FILE" 2>/dev/null
}

cache_model_health() {
    local model="$1" status="$2" reason="$3"
    ensure_parent_dir "$MODEL_HEALTH_FILE"
    touch "$MODEL_HEALTH_FILE"
    printf '%s\t%s\t%s\t%s\n' "$model" "$(date +%s)" "$status" "$(health_reason_text "$reason")" >> "$MODEL_HEALTH_FILE"
}

probe_local_model() {
    local model_name="${1#ollama_chat/}"
    command -v ollama >/dev/null 2>&1 || { printf 'fail\tollama binary missing\n'; return 1; }
    is_ollama_available || { printf 'fail\tollama runtime unavailable\n'; return 1; }
    ollama list 2>/dev/null | awk '{print $1}' | grep -Fxq "$model_name" || { printf 'fail\tlocal model not installed\n'; return 1; }
    printf 'ok\tlocal model ready\n'
}

probe_openai_like_model() {
    local base_url="$1" model="$2" api_key="$3" response_file http_code
    response_file="$(mktemp)"
    http_code="$(curl -sS --connect-timeout 5 --max-time "$MODEL_HEALTH_TIMEOUT" \
        -H "Authorization: Bearer $api_key" -H "Content-Type: application/json" \
        -o "$response_file" -w '%{http_code}' "$base_url/chat/completions" \
        -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with OK\"}],\"max_tokens\":1,\"temperature\":0}")" || {
            rm -f "$response_file"; printf 'fail\trequest failed\n'; return 1;
        }
    rm -f "$response_file"
    case "$http_code" in
        2*) printf 'ok\tlive probe ok\n' ;;
        429) printf 'fail\trate limited\n'; return 1 ;;
        401|403) printf 'fail\tauth rejected\n'; return 1 ;;
        404) printf 'fail\tmodel unavailable\n'; return 1 ;;
        5*) printf 'fail\tprovider error %s\n' "$http_code"; return 1 ;;
        *) printf 'fail\thttp %s\n' "$http_code"; return 1 ;;
    esac
}

probe_gemini_model() {
    local base_url="$1" model="$2" api_key="$3" response_file http_code
    response_file="$(mktemp)"
    http_code="$(curl -sS --connect-timeout 5 --max-time "$MODEL_HEALTH_TIMEOUT" \
        -H "x-goog-api-key: $api_key" -H "Content-Type: application/json" \
        -o "$response_file" -w '%{http_code}' "$base_url/models/$model:generateContent" \
        -d '{"contents":[{"role":"user","parts":[{"text":"Reply with OK"}]}],"generationConfig":{"temperature":0,"maxOutputTokens":1}}')" || {
            rm -f "$response_file"; printf 'fail\trequest failed\n'; return 1;
        }
    rm -f "$response_file"
    case "$http_code" in
        2*) printf 'ok\tlive probe ok\n' ;;
        429) printf 'fail\trate limited\n'; return 1 ;;
        401|403) printf 'fail\tauth rejected\n'; return 1 ;;
        404) printf 'fail\tmodel unavailable\n'; return 1 ;;
        5*) printf 'fail\tprovider error %s\n' "$http_code"; return 1 ;;
        *) printf 'fail\thttp %s\n' "$http_code"; return 1 ;;
    esac
}

live_probe_model() {
    local record="$1" provider base_url api_key model_name
    provider="$(health_provider "$record")"
    provider_health_enabled "$provider" || { printf 'ok\thealthcheck disabled\n'; return 0; }
    [ "$provider" = "ollama_chat" ] && { probe_local_model "$(health_aider_model "$record")"; return; }
    base_url="$(health_inference_base "$record")"
    api_key="$(health_api_key_value "$record")"
    model_name="$(health_request_model "$record")"
    [ -n "$base_url" ] || { printf 'fail\tmissing base url\n'; return 1; }
    [ -n "$api_key" ] || { printf 'fail\tmissing api key\n'; return 1; }
    [ "$(provider_kind "$provider")" = "gemini" ] && { probe_gemini_model "$base_url" "$model_name" "$api_key"; return; }
    probe_openai_like_model "$base_url" "$model_name" "$api_key"
}

probe_model_record() {
    local record="$1" display cached status reason
    display="$(health_display_model "$record")"
    [ "$MODEL_HEALTH_ENABLED" != "true" ] && { printf 'ok\thealth disabled\n'; return 0; }
    if cached="$(cached_model_health "$display")"; then
        printf '%s\n' "$cached"
        [ "${cached%%$'\t'*}" = "ok" ]
        return
    fi
    if cached="$(live_probe_model "$record")"; then
        status="${cached%%$'\t'*}"; reason="${cached#*$'\t'}"
        cache_model_health "$display" "$status" "$reason"
        printf '%s\n' "$cached"
        return 0
    fi
    status="${cached%%$'\t'*}"; reason="${cached#*$'\t'}"
    cache_model_health "$display" "$status" "$reason"
    printf '%s\n' "$cached"
    return 1
}
