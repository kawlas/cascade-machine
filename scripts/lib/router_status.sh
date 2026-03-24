#!/usr/bin/env bash

show_provider_status() {
    provider_catalog_summary | while IFS=$'\t' read -r provider kind tier key_state models_count; do
        printf "║  %-11s %-8s %-8s %-12s %s models\n" "$provider:" "$kind" "$tier" "$key_state" "$models_count"
    done
}

show_status() {
    local total_used=0 total_limit=0
    ensure_router_storage
    refresh_model_catalog_if_needed
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  CASCADE — Routing Status ($TODAY)                    ║"
    echo "╠═══════════════════════════════════════════════════════╣"
    if is_ollama_available; then
        local models
        models="$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ', ' | sed 's/, $//')"
        echo "║  Ollama:      ✅ BACKUP      [${models:-no models}]"
    else
        echo "║  Ollama:      ⚪ BACKUP OFF  (uruchom: ollama serve)"
    fi
    echo "║───────────────────────────────────────────────────────║"
    show_provider_status
    while IFS= read -r provider; do
        local used limit
        used="$(count_today "$provider")"; limit="$(provider_limit "$provider")"
        total_used=$((total_used + used)); total_limit=$((total_limit + limit))
    done << EOF
$(catalog_providers)
EOF
    echo "║───────────────────────────────────────────────────────║"
    echo "║  Cloud total:  $total_used/$total_limit requests used today"
    echo "║  Remaining:    $((total_limit - total_used)) cloud requests"
    echo "╚═══════════════════════════════════════════════════════╝"
}
