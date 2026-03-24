#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/router_core.sh"

NIGHTLY_HOME="$(cascade_home_dir)"
NIGHTLY_LEARNINGS="${CASCADE_LEARNINGS_FILE:-$NIGHTLY_HOME/learnings.jsonl}"
NIGHTLY_USAGE="${CASCADE_USAGE_FILE:-$NIGHTLY_HOME/usage.jsonl}"
NIGHTLY_LOG_DIR="$NIGHTLY_HOME/logs"
NIGHTLY_LOG_FILE="$NIGHTLY_LOG_DIR/nightly-$(date +%Y%m%d).log"
NIGHTLY_TODAY="$(date +%Y-%m-%d)"

nightly_count_for() {
    local pattern="$1"
    { grep "\"date\":\"$NIGHTLY_TODAY\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | \
        { grep "$pattern" || true; } | wc -l | tr -d ' '
}

nightly_print_header() {
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  CASCADE NIGHTLY REPORT — $(date '+%Y-%m-%d %H:%M')         ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    return 0
}

nightly_print_stats() {
    local total success fail success_rate t1 t2 t0
    total="$({ grep "\"date\":\"$NIGHTLY_TODAY\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | wc -l | tr -d ' ')"
    success="$(nightly_count_for '"success":true')"
    fail="$(nightly_count_for '"success":false')"

    if [ "$total" -eq 0 ]; then
        echo "📊 Brak aktywności dzisiaj. Raport pominięty."
        return 1
    fi

    success_rate=$((success * 100 / total))
    t1="$(nightly_count_for '"tier":1')"
    t2="$(nightly_count_for '"tier":[2-9]')"
    t0="$(nightly_count_for '"tier":0')"

    echo "═══ STATYSTYKI ═══"
    echo "Zadania:     $total (✅ $success  ❌ $fail)"
    echo "Success rate: $success_rate%"
    echo ""
    echo "Tier 1 (local Ollama):  $t1 zadań"
    echo "Tier 2+ (cloud free):   $t2 zadań"
    echo "Failed (all tiers):     $t0 zadań"
    echo ""
    echo "Per typ zadania:"
    local tt ttcount ttsuccess ttrate
    for tt in code reason refactor test quick; do
        ttcount="$({ grep "\"date\":\"$NIGHTLY_TODAY\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | { grep "\"task_type\":\"$tt\"" || true; } | wc -l | tr -d ' ')"
        ttsuccess="$({ grep "\"date\":\"$NIGHTLY_TODAY\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | { grep "\"task_type\":\"$tt\"" || true; } | { grep '"success":true' || true; } | wc -l | tr -d ' ')"
        if [ "$ttcount" -gt 0 ]; then
            ttrate=$((ttsuccess * 100 / ttcount))
            printf "  %-10s %d/%d (%d%%)\n" "$tt" "$ttsuccess" "$ttcount" "$ttrate"
        fi
    done
    echo ""

    NIGHTLY_TOTAL="$total"
    NIGHTLY_SUCCESS="$success"
    NIGHTLY_FAIL="$fail"
    NIGHTLY_SUCCESS_RATE="$success_rate"
    NIGHTLY_T1="$t1"
    NIGHTLY_T2="$t2"
    NIGHTLY_T0="$t0"
    return 0
}

nightly_print_cloud_usage() {
    echo "═══ CLOUD TOKEN USAGE ═══"
    local prov used
    for prov in groq cerebras google openrouter xai; do
        used="$(count_today "$prov")"
        if [ "$used" -gt 0 ]; then
            echo "  $prov: $used requests"
        fi
    done
    echo ""
    return 0
}

nightly_print_recommendations() {
    local recs=0 local_pct yest yest_total yest_success yest_rate diff
    echo "═══ 🎯 REKOMENDACJE ═══"
    echo ""

    local_pct=$((NIGHTLY_T1 * 100 / NIGHTLY_TOTAL))
    if [ "$local_pct" -ge 90 ]; then
        echo "✅ $local_pct% zadań ukończonych lokalnie — doskonale!"
        echo "   → Ollama radzi sobie świetnie z Twoim projektem."
        recs=$((recs + 1))
        echo ""
    elif [ "$local_pct" -ge 60 ]; then
        echo "⚠️  $local_pct% lokalnie — dużo eskalacji do cloud."
        echo "   → ZRÓB: przejrzyj typy zadań, które wymagają cloud."
        recs=$((recs + 1))
        echo ""
    else
        echo "🚨 Tylko $local_pct% lokalnie — sprawdź modele Ollama i AGENTS.md."
        recs=$((recs + 1))
        echo ""
    fi

    if [ "$NIGHTLY_FAIL" -gt 0 ]; then
        echo "📋 Nieudane zadania dzisiaj:"
        { grep "\"date\":\"$NIGHTLY_TODAY\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | \
            { grep '"success":false' || true; } | \
            python3 -c "
import sys, json
for line in sys.stdin:
    try:
        row = json.loads(line)
        print(f\"   • [{row.get('task_type','?')}] {row.get('task','?')[:60]}\")
    except Exception:
        pass
" 2>/dev/null || true
        echo ""
        recs=$((recs + 1))
    fi

    yest="$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null || echo "")"
    if [ -n "$yest" ]; then
        yest_total="$({ grep "\"date\":\"$yest\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | wc -l | tr -d ' ')"
        yest_success="$({ grep "\"date\":\"$yest\"" "$NIGHTLY_LEARNINGS" 2>/dev/null || true; } | { grep '"success":true' || true; } | wc -l | tr -d ' ')"
        if [ "$yest_total" -gt 0 ]; then
            yest_rate=$((yest_success * 100 / yest_total))
            diff=$((NIGHTLY_SUCCESS_RATE - yest_rate))
            echo "Trend vs wczoraj: ${diff}pp"
            echo ""
            recs=$((recs + 1))
        fi
    fi

    NIGHTLY_RECS="$recs"
    return 0
}

nightly_print_agents_suggestions() {
    echo "═══ 📝 SUGESTIE DO AGENTS.MD ═══"
    echo ""
    echo "  - Dodawaj reguły dla typów zadań, które często eskalują."
    echo "  - Przy hot files wymagaj testów przed commitem."
    echo "  - Dopisuj politykę zależności, jeśli często dochodzą nowe pakiety."
    echo ""
    return 0
}

nightly_print_summary() {
    echo "═══ PODSUMOWANIE ═══"
    echo ""
    echo "Dzisiejszy wynik: $NIGHTLY_SUCCESS_RATE% success ($NIGHTLY_SUCCESS/$NIGHTLY_TOTAL)"
    echo "Rekomendacji:     ${NIGHTLY_RECS:-0}"
    echo ""
    echo "Następna analiza: jutro o 23:00"
    echo "Logi: $NIGHTLY_LOG_FILE"
    return 0
}

run_nightly_report() {
    mkdir -p "$NIGHTLY_LOG_DIR"
    ensure_router_storage
    {
        nightly_print_header
        nightly_print_stats || exit 0
        nightly_print_cloud_usage
        nightly_print_recommendations
        nightly_print_agents_suggestions
        nightly_print_summary
    } 2>&1 | tee "$NIGHTLY_LOG_FILE"
}
