#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE MODEL ROUTER v3
# Automatycznie wybiera najlepszy DARMOWY model
# z uwzględnieniem:
#   1. Typu zadania (keyword analysis)
#   2. Historii sukcesu (learnings.jsonl)
#   3. Dziennych limitów tokenów per provider
# ═══════════════════════════════════════════════════════════════

USAGE_FILE="$HOME/.cascade/usage.jsonl"
LEARNINGS_FILE="$HOME/.cascade/learnings.jsonl"
TODAY=$(date +%Y-%m-%d)

# ─── Policz dzisiejsze użycie per provider ───
count_today() {
    local provider="$1"
    grep "\"provider\":\"$provider\"" "$USAGE_FILE" 2>/dev/null \
        | grep "\"date\":\"$TODAY\"" \
        | wc -l \
        | tr -d ' '
}

# ─── Zaloguj użycie ───
log_usage() {
    local provider="$1" model="$2" task_type="$3" success="$4"
    echo "{\"date\":\"$TODAY\",\"provider\":\"$provider\",\"model\":\"$model\",\"task_type\":\"$task_type\",\"success\":$success,\"ts\":$(date +%s)}" \
        >> "$USAGE_FILE"
}

# ─── Dzienne limity per provider (konserwatywne) ───
GROQ_LIMIT=800
CEREBRAS_LIMIT=150
GOOGLE_LIMIT=1200
OPENROUTER_LIMIT=150
XAI_LIMIT=400

# ═══════════════════════════════════════════════════════════════
# NOWE: Klasyfikuj typ zadania na podstawie słów kluczowych
# ═══════════════════════════════════════════════════════════════
classify_task() {
    local task="$1"
    task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    
    # Reasoning / wyjaśnianie / architektura
    if echo "$task_lower" | grep -qE \
        'wyjaśnij|explain|dlaczego|why|architektur|design|zaproponuj|koncep|teoria|różnic|porównaj|compare|debug|diagnoz|analiz|review'; then
        echo "reason"
        return
    fi
    
    # Refaktoryzacja / multi-file
    if echo "$task_lower" | grep -qE \
        'refaktor|refactor|przenieś|move|reorganiz|split|extract|restructur|migrat|upgrad|convert'; then
        echo "refactor"
        return
    fi
    
    # Testy
    if echo "$task_lower" | grep -qE \
        'test|spec|assert|mock|stub|fixture|coverage|jest|pytest|vitest'; then
        echo "test"
        return
    fi
    
    # Szybkie fixy / proste zmiany
    if echo "$task_lower" | grep -qE \
        'fix|popraw|typo|rename|zmień|change|add import|dodaj import|update version|bump'; then
        echo "quick"
        return
    fi
    
    # Domyślnie: generowanie kodu
    echo "code"
}

# ═══════════════════════════════════════════════════════════════
# NOWE: Sprawdź historię sukcesu dla danego typu zadania
# Zwraca model który historycznie najlepiej radził sobie
# z tym typem zadania (jeśli mamy wystarczająco danych)
# ═══════════════════════════════════════════════════════════════
check_history() {
    local task_type="$1"
    
    # Potrzebujemy min 5 rekordów dla danego typu
    local count=$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null \
        | grep '"success":true' \
        | wc -l | tr -d ' ')
    
    if [ "$count" -lt 5 ]; then
        echo ""  # Za mało danych — brak rekomendacji
        return
    fi
    
    # Znajdź model z najwyższym success rate dla tego typu
    # (prosty: policz sukcesy per model, weź najczęstszy)
    local best_model=$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null \
        | grep '"success":true' \
        | grep -oE '"model":"[^"]*"' \
        | sort | uniq -c | sort -rn \
        | head -1 \
        | grep -oE '"[^"]*"$' \
        | tr -d '"')
    
    echo "$best_model"
}

# ═══════════════════════════════════════════════════════════════
# NOWE: Sprawdź czy provider ma jeszcze limit
# ═══════════════════════════════════════════════════════════════
provider_available() {
    local provider="$1"
    local used=$(count_today "$provider")
    local limit
    
    case "$provider" in
        groq) limit=$GROQ_LIMIT ;;
        cerebras) limit=$CEREBRAS_LIMIT ;;
        google|gemini) limit=$GOOGLE_LIMIT ;;
        openrouter) limit=$OPENROUTER_LIMIT ;;
        xai) limit=$XAI_LIMIT ;;
        ollama*) echo "true"; return ;;
        *) limit=100 ;;
    esac
    
    [ "$used" -lt "$limit" ] && echo "true" || echo "false"
}

# ═══════════════════════════════════════════════════════════════
# GŁÓWNA FUNKCJA: Wybierz najlepszy model
# ═══════════════════════════════════════════════════════════════
get_best_model() {
    local task="$1"
    local force_cloud="${2:-false}"  # --cloud flag
    
    # Krok 1: Klasyfikuj zadanie
    local task_type=$(classify_task "$task")
    
    # Krok 2: Sprawdź historię (czy mamy proven winner?)
    local history_model=$(check_history "$task_type")
    
    if [ -n "$history_model" ] && [ "$force_cloud" != "true" ]; then
        # Sprawdź czy ten model jest dostępny
        local hist_provider=$(echo "$history_model" | cut -d'/' -f1)
        if [ "$(provider_available "$hist_provider")" = "true" ]; then
            echo "$history_model"
            echo "  (wybrano na podstawie historii sukcesu dla typu: $task_type)" >&2
            return 0
        fi
    fi
    
    # Krok 3: Wybierz na podstawie typu zadania + dostępności
    if [ "$force_cloud" != "true" ] && \
       curl -s --connect-timeout 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
        # Ollama dostępna — wybierz model wg typu zadania
        case "$task_type" in
            reason)
                echo "ollama_chat/deepseek-r1:8b"
                echo "  (typ: reasoning → deepseek-r1:8b)" >&2
                ;;
            refactor)
                echo "ollama_chat/qwen3-coder"
                echo "  (typ: refactor → qwen3-coder, multi-file)" >&2
                ;;
            test)
                echo "ollama_chat/qwen3-coder"
                echo "  (typ: test generation → qwen3-coder)" >&2
                ;;
            quick)
                echo "ollama_chat/qwen3:4b"
                echo "  (typ: quick fix → qwen3:4b, fastest)" >&2
                ;;
            *)
                echo "ollama_chat/qwen3-coder"
                echo "  (typ: code generation → qwen3-coder)" >&2
                ;;
        esac
        return 0
    fi
    
    # Krok 4: Ollama niedostępna lub force_cloud — rotacja cloud
    # Priorytet zależny od typu zadania
    case "$task_type" in
        reason)
            # Reasoning: Google Gemini > Groq > reszta
            local providers=("gemini:gemini/gemini-2.0-flash" \
                           "groq:groq/llama-3.3-70b-versatile" \
                           "cerebras:cerebras/llama-3.3-70b" \
                           "openrouter:openrouter/mistralai/devstral-2" \
                           "xai:xai/grok-3-mini")
            ;;
        refactor|code)
            # Kod: OpenRouter/Devstral > Groq > reszta
            local providers=("openrouter:openrouter/mistralai/devstral-2" \
                           "groq:groq/llama-3.3-70b-versatile" \
                           "cerebras:cerebras/llama-3.3-70b" \
                           "gemini:gemini/gemini-2.0-flash" \
                           "xai:xai/grok-3-mini")
            ;;
        *)
            # Default: Groq (fastest) > Cerebras > reszta
            local providers=("groq:groq/llama-3.3-70b-versatile" \
                           "cerebras:cerebras/llama-3.3-70b" \
                           "gemini:gemini/gemini-2.0-flash" \
                           "openrouter:openrouter/mistralai/devstral-2" \
                           "xai:xai/grok-3-mini")
            ;;
    esac
    
    for entry in "${providers[@]}"; do
        local prov=$(echo "$entry" | cut -d: -f1)
        local model=$(echo "$entry" | cut -d: -f2-)
        
        if [ "$(provider_available "$prov")" = "true" ]; then
            echo "$model"
            echo "  (cloud: $prov, typ: $task_type)" >&2
            return 0
        fi
    done
    
    echo "LIMIT_EXCEEDED"
    echo "  ⚠️  Wszystkie cloud limity wyczerpane! Uruchom Ollama." >&2
    return 1
}

# ═══════════════════════════════════════════════════════════════
# STATUS — pokaż dzienne limity
# ═══════════════════════════════════════════════════════════════
show_status() {
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  CASCADE — Token Usage ($TODAY)                       ║"
    echo "╠═══════════════════════════════════════════════════════╣"
    
    # Ollama status
    if curl -s --connect-timeout 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
        local models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')
        echo "║  Ollama:      ✅ UNLIMITED  [$models]"
    else
        echo "║  Ollama:      ❌ NOT RUNNING (uruchom: ollama serve)"
    fi
    
    echo "║───────────────────────────────────────────────────────║"
    
    local total_used=0
    local total_limit=0
    
    for provider_info in \
        "Groq:groq:$GROQ_LIMIT" \
        "Cerebras:cerebras:$CEREBRAS_LIMIT" \
        "Google:google:$GOOGLE_LIMIT" \
        "OpenRouter:openrouter:$OPENROUTER_LIMIT" \
        "x.ai:xai:$XAI_LIMIT"; do
        
        local name=$(echo "$provider_info" | cut -d: -f1)
        local prov=$(echo "$provider_info" | cut -d: -f2)
        local limit=$(echo "$provider_info" | cut -d: -f3)
        local used=$(count_today "$prov")
        local remaining=$((limit - used))
        local pct=$((used * 100 / limit))
        
        total_used=$((total_used + used))
        total_limit=$((total_limit + limit))
        
        # Bar wizualny
        local bar=""
        local filled=$((pct / 5))
        for i in $(seq 1 20); do
            [ "$i" -le "$filled" ] && bar="${bar}█" || bar="${bar}░"
        done
        
        local status_icon="✅"
        [ "$pct" -ge 80 ] && status_icon="⚠️"
        [ "$pct" -ge 100 ] && status_icon="❌"
        
        printf "║  %-11s %s %s %d/%d (%d%%)\n" "$name:" "$status_icon" "$bar" "$used" "$limit" "$pct"
    done
    
    echo "║───────────────────────────────────────────────────────║"
    echo "║  Cloud total:  $total_used/$total_limit requests used today"
    echo "║  Remaining:    $((total_limit - total_used)) cloud requests"
    echo "╚═══════════════════════════════════════════════════════╝"
    
    # Pokaż historię sukcesu per typ zadania
    if [ -s "$LEARNINGS_FILE" ]; then
        echo ""
        echo "📊 Task success history (last 7 days):"
        for task_type in code reason refactor test quick; do
            local total=$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null | wc -l | tr -d ' ')
            local success=$(grep "\"task_type\":\"$task_type\"" "$LEARNINGS_FILE" 2>/dev/null | grep '"success":true' | wc -l | tr -d ' ')
            if [ "$total" -gt 0 ]; then
                local rate=$((success * 100 / total))
                local best=$(check_history "$task_type")
                printf "  %-10s %d/%d (%d%%) best_model: %s\n" "$task_type" "$success" "$total" "$rate" "${best:-not enough data}"
            fi
        done
    fi
}

# ═══════════════════════════════════════════════════════════════
# CLI Interface
# ═══════════════════════════════════════════════════════════════
case "${1:-}" in
    status)  show_status ;;
    best)    get_best_model "${*:2}" ;;
    classify) classify_task "${*:2}" ;;
    *)
        echo "Usage: router.sh {status|best \"task description\"|classify \"task\"}"
        echo ""
        echo "Examples:"
        echo "  router.sh status"
        echo "  router.sh best \"add email validation\""
        echo "  router.sh classify \"explain how WebSockets work\""
        ;;
esac
