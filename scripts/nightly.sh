#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE NIGHTLY v3 — Analiza + Akcyjne Rekomendacje
#
# Nowości v3:
#   • Konkretne rekomendacje zamiast suchych statystyk
#   • Automatyczne sugestie zmian do AGENTS.md
#   • Analiza wzorców w git log
#   • Wykrywanie degradacji
# ═══════════════════════════════════════════════════════════════

LEARNINGS="$HOME/.cascade/learnings.jsonl"
USAGE="$HOME/.cascade/usage.jsonl"
LOG="$HOME/.cascade/logs/nightly-$(date +%Y%m%d).log"
TODAY=$(date +%Y-%m-%d)

mkdir -p ~/.cascade/logs

{
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  CASCADE NIGHTLY REPORT — $(date '+%Y-%m-%d %H:%M')         ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ═══ SEKCJA 1: Statystyki dnia ═══
TOTAL=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | wc -l | tr -d ' ')
SUCCESS=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"success":true' | wc -l | tr -d ' ')
FAIL=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"success":false' | wc -l | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
    echo "📊 Brak aktywności dzisiaj. Raport pominięty."
    exit 0
fi

SUCCESS_RATE=$((SUCCESS * 100 / TOTAL))

echo "═══ STATYSTYKI ═══"
echo "Zadania:     $TOTAL (✅ $SUCCESS  ❌ $FAIL)"
echo "Success rate: $SUCCESS_RATE%"
echo ""

# Breakdown per tier
T1=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"tier":1' | wc -l | tr -d ' ')
T2=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep -E '"tier":[2-9]' | wc -l | tr -d ' ')
T0=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"tier":0' | wc -l | tr -d ' ')

echo "Tier 1 (local Ollama):  $T1 zadań"
echo "Tier 2+ (cloud free):   $T2 zadań"
echo "Failed (all tiers):     $T0 zadań"
echo ""

# Breakdown per task type
echo "Per typ zadania:"
for tt in code reason refactor test quick; do
    ttcount=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | \
        grep "\"task_type\":\"$tt\"" | wc -l | tr -d ' ')
    ttsuccess=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | \
        grep "\"task_type\":\"$tt\"" | grep '"success":true' | wc -l | tr -d ' ')
    if [ "$ttcount" -gt 0 ]; then
        ttrate=$((ttsuccess * 100 / ttcount))
        printf "  %-10s %d/%d (%d%%)\n" "$tt" "$ttsuccess" "$ttcount" "$ttrate"
    fi
done
echo ""

# ═══ SEKCJA 2: Użycie tokenów cloud ═══
echo "═══ CLOUD TOKEN USAGE ═══"
source "$HOME/.cascade/router.sh" 2>/dev/null || source "./router.sh" 2>/dev/null || true
for prov in groq cerebras google openrouter xai; do
    used=$(count_today "$prov")
    if [ "$used" -gt 0 ]; then
        echo "  $prov: $used requests"
    fi
done
echo ""

# ═══════════════════════════════════════════════════════════════
# SEKCJA 3: AKCYJNE REKOMENDACJE
# Nie "ciekawy fakt" ale "ZRÓB TO"
# ═══════════════════════════════════════════════════════════════
echo "═══ 🎯 REKOMENDACJE ═══"
echo ""

RECS=0

# Rekomendacja 1: Model selection
if [ "$TOTAL" -gt 0 ]; then
    LOCAL_PCT=$((T1 * 100 / TOTAL))
        
    if [ "$LOCAL_PCT" -ge 90 ]; then
        echo "✅ $LOCAL_PCT% zadań ukończonych lokalnie — doskonale!"
        echo "   → Ollama radzi sobie świetnie z Twoim projektem."
        echo "   → Rozważ: jeśli masz wolne miejsce na dysku, ollama pull"
        echo "     qwen3-coder:72b może dać jeszcze lepsze wyniki."
        RECS=$((RECS+1))
    elif [ "$LOCAL_PCT" -ge 60 ]; then
        echo "⚠️  $LOCAL_PCT% lokalnie — dużo eskalacji do cloud."
        echo "   → ZRÓB: Sprawdź typy zadań które wymagają cloud:"
        # Pokaż które typy zadań najczęściej eskalują
        for tt in code reason refactor test quick; do
            cloud_count=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | \
                grep "\"task_type\":\"$tt\"" | grep -E '"tier":[2-9]' | wc -l | tr -d ' ')
            if [ "$cloud_count" -gt 1 ]; then
                echo "     • '$tt' eskalował $cloud_count razy"
            fi
        done
        echo "   → ZRÓB: Dodaj lepsze instrukcje do AGENTS.md dla tych typów."
        RECS=$((RECS+1))
    elif [ "$LOCAL_PCT" -lt 60 ]; then
        echo "🚨 Tylko $LOCAL_PCT% lokalnie — Ollama może być za słaba."
        echo "   → ZRÓB: ollama pull qwen3-coder (jeśli nie masz)"
        echo "   → ZRÓB: Sprawdź czy AGENTS.md zawiera wystarczająco"
        echo "     kontekstu projektowego."
        RECS=$((RECS+1))
    fi
    echo ""
fi

# Rekomendacja 2: Failure patterns
if [ "$FAIL" -gt 0 ]; then
    echo "📋 Nieudane zadania dzisiaj:"
    grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | \
        grep '"success":false' | \
        python3 -c "
import sys, json
for line in sys.stdin:
    try:
        r = json.loads(line)
        task = r.get('task','?')[:60]
        tt = r.get('task_type','?')
        attempts = r.get('attempts',0)
        print(f'   • [{tt}] {task} ({attempts} attempts)')
    except: pass
" 2>/dev/null || grep "\"date\":\"$TODAY\"" "$LEARNINGS" | grep '"success":false' | head -5
    
    echo ""
    echo "   → ZRÓB: Rozważ podzielenie złożonych zadań na mniejsze"
    echo "     kroki zamiast jednego dużego prompta."
    RECS=$((RECS+1))
    echo ""
fi

# Rekomendacja 3: Porównanie z wczoraj (trend)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null || echo "")
if [ -n "$YESTERDAY" ]; then
    YEST_TOTAL=$(grep "\"date\":\"$YESTERDAY\"" "$LEARNINGS" 2>/dev/null | wc -l | tr -d ' ')
    YEST_SUCCESS=$(grep "\"date\":\"$YESTERDAY\"" "$LEARNINGS" 2>/dev/null | grep '"success":true' | wc -l | tr -d ' ')
    
    if [ "$YEST_TOTAL" -gt 0 ]; then
        YEST_RATE=$((YEST_SUCCESS * 100 / YEST_TOTAL))
        DIFF=$((SUCCESS_RATE - YEST_RATE))
        
        if [ "$DIFF" -gt 5 ]; then
            echo "📈 Success rate wzrósł o ${DIFF}pp vs wczoraj ($YEST_RATE% → $SUCCESS_RATE%)"
            echo "   → System się poprawia! Kontynuuj obecne podejście."
        elif [ "$DIFF" -lt -5 ]; then
            echo "📉 Success rate spadł o ${DIFF#-}pp vs wczoraj ($YEST_RATE% → $SUCCESS_RATE%)"
            echo "   → ZRÓB: Sprawdź czy zmienił się typ zadań (trudniejsze?)"
            echo "     lub czy Ollama model potrzebuje aktualizacji."
        else
            echo "📊 Stabilny success rate ($YEST_RATE% → $SUCCESS_RATE%)"
        fi
        RECS=$((RECS+1))
        echo ""
    fi
fi

# ═══════════════════════════════════════════════════════════════
# SEKCJA 4: SUGESTIE DO AGENTS.MD (żywy dokument)
#
# Analizuje git log i learnings.jsonl aby zasugerować
# konkretne reguły do dodania do AGENTS.md
# ═══════════════════════════════════════════════════════════════
echo "═══ 📝 SUGESTIE DO AGENTS.MD ═══"
echo ""

# Znajdź projekty z git aktywnością dziś
ACTIVE_REPOS=()
for gitdir in $(find ~ -maxdepth 4 -name ".git" -type d 2>/dev/null | head -20); do
    repo_dir=$(dirname "$gitdir")
    # Sprawdź czy były commity dziś
    if cd "$repo_dir" 2>/dev/null && \
       git log --oneline --since="$TODAY" 2>/dev/null | head -1 | grep -q .; then
        ACTIVE_REPOS+=("$repo_dir")
    fi
done

for repo in "${ACTIVE_REPOS[@]}"; do
    if [ ! -f "$repo/AGENTS.md" ]; then
        continue
    fi
    
    cd "$repo" 2>/dev/null || continue
    
    echo "  Repo: $repo"
    
    # Analiza 1: Najczęściej zmieniane pliki
    HOT_FILES=$(git log --oneline --since="7 days ago" --name-only 2>/dev/null | \
        grep -vE '^[a-f0-9]{7}' | sort | uniq -c | sort -rn | head -3)
    
    if [ -n "$HOT_FILES" ]; then
        echo "  📁 Najczęściej zmieniane pliki (7 dni):"
        echo "$HOT_FILES" | while read count file; do
            echo "     $count zmian: $file"
        done
        
        # Jeśli jeden plik ma >10 zmian — sugestia
        TOP_COUNT=$(echo "$HOT_FILES" | head -1 | awk '{print $1}')
        TOP_FILE=$(echo "$HOT_FILES" | head -1 | awk '{print $2}')
        if [ "$TOP_COUNT" -gt 10 ]; then
            echo ""
            echo "  💡 SUGESTIA: $TOP_FILE miał $TOP_COUNT zmian w 7 dni."
            echo "     Rozważ dodanie do AGENTS.md:"
            echo "     \"## Hot File: $TOP_FILE\""
            echo "     \"Ten plik jest często modyfikowany. Przy zmianach:"
            echo "     - Zawsze uruchom testy przed commitem"  
            echo "     - Rozważ podział na mniejsze moduły\""
        fi
    fi
    
    # Analiza 2: Wzorce w commit messages
    ERROR_FIXES=$(git log --oneline --since="7 days ago" 2>/dev/null | \
        grep -ciE 'fix|bug|error|typo|hotfix' || echo "0")
    TOTAL_COMMITS=$(git log --oneline --since="7 days ago" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$TOTAL_COMMITS" -gt 5 ] && [ "$ERROR_FIXES" -gt 0 ]; then
        FIX_PCT=$((ERROR_FIXES * 100 / TOTAL_COMMITS))
        if [ "$FIX_PCT" -gt 40 ]; then
            echo ""
            echo "  💡 SUGESTIA: $FIX_PCT% commitów to poprawki błędów."
            echo "     Rozważ dodanie do AGENTS.md:"
            echo "     \"## Error Prevention\""
            echo "     \"Przed każdą zmianą: sprawdź edge cases,"
            echo "     dodaj walidację inputu, obsłuż null/undefined.\""
        fi
    fi
    
    # Analiza 3: Nowe zależności
    NEW_DEPS=$(git diff --since="7 days ago" -- package.json pyproject.toml Cargo.toml go.mod 2>/dev/null | \
        grep "^+" | grep -vE '^\+\+\+' | head -5)
    
    if [ -n "$NEW_DEPS" ]; then
        echo ""
        echo "  💡 SUGESTIA: Nowe zależności dodane w tym tygodniu."
        echo "     Rozważ dodanie do AGENTS.md:"
        echo "     \"## Dependencies Policy\""
        echo "     \"Uzasadnij każdą nową zależność w PR description."
        echo "     Preferuj stdlib przed zewnętrznymi pakietami.\""
    fi
    
    echo ""
done

if [ ${#ACTIVE_REPOS[@]} -eq 0 ]; then
    echo "  Brak aktywnych repozytoriów z AGENTS.md. Pominięto."
    echo ""
fi

# ═══ SEKCJA 5: Podsumowanie ═══
echo "═══ PODSUMOWANIE ═══"
echo ""
echo "Dzisiejszy wynik: $SUCCESS_RATE% success ($SUCCESS/$TOTAL)"
echo "Rekomendacji:     $RECS"
echo ""
echo "Następna analiza: jutro o 23:00"
echo "Logi: $LOG"

} 2>&1 | tee "$LOG"
