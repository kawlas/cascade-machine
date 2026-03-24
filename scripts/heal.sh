#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE HEAL v3 — Self-healing coding
#
# Nowości v3:
#   • Linter pre-validation (eslint, ruff, clippy)
#   • Smart model selection z historii sukcesu
#   • Task type classification → lepszy pierwszy wybór
#   • Kontekst błędu przekazywany między próbami
#
# Użycie:
#   heal "dodaj walidację email"
#   heal --reason "wyjaśnij bug w auth"
#   heal --fast "popraw typo"
#   heal --cloud "wymuszaj cloud model"
# ═══════════════════════════════════════════════════════════════

set -uo pipefail

LEARNINGS="$HOME/.cascade/learnings.jsonl"
TODAY=$(date +%Y-%m-%d)
MAX_RETRIES=2

# Source router functions
if [ -f "$HOME/.cascade/router.sh" ]; then
    source "$HOME/.cascade/router.sh"
elif [ -f "$(dirname "$0")/router.sh" ]; then
    source "$(dirname "$0")/router.sh"
elif [ -f "./router.sh" ]; then
    source "./router.sh"
else
    echo "⚠️  router.sh not found - model routing will be limited"
fi

# ─── Parse argumentów ───
TASK_TYPE_OVERRIDE=""
FORCE_CLOUD="false"
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --reason|--think) TASK_TYPE_OVERRIDE="reason" ;;
        --fast|--quick)   TASK_TYPE_OVERRIDE="quick" ;;
        --cloud)          FORCE_CLOUD="true" ;;
        *)                ARGS+=("$arg") ;;
    esac
done

TASK="${ARGS[*]}"

if [ -z "$TASK" ]; then
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  CASCADE HEAL — Self-Healing Coding                   ║"
    echo "╠═══════════════════════════════════════════════════════╣"
    echo "║                                                       ║"
    echo "║  Usage:                                               ║"
    echo "║    heal \"opis zadania\"                               ║"
    echo "║    heal --reason \"wyjaśnij problem\"                  ║"
    echo "║    heal --fast \"szybki fix\"                          ║"
    echo "║    heal --cloud \"wymuś cloud model\"                  ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    show_status
    exit 1
fi

# ─── Klasyfikacja zadania ───
if [ -n "$TASK_TYPE_OVERRIDE" ]; then
    TASK_TYPE="$TASK_TYPE_OVERRIDE"
else
    TASK_TYPE=$(classify_task "$TASK")
fi

# ─── Detect projekt ───
detect_test_cmd() {
    if [ -f "package.json" ]; then
        if grep -q '"test"' package.json 2>/dev/null; then
            echo "npm test"
        fi
    elif [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
        echo "python -m pytest -x -q"
    elif [ -f "go.mod" ]; then
        echo "go test ./..."
    elif [ -f "Cargo.toml" ]; then
        echo "cargo test"
    fi
}

# ═══════════════════════════════════════════════════════════════
# NOWE: Detect i uruchom linter PRZED testami
# ═══════════════════════════════════════════════════════════════
detect_lint_cmd() {
    if [ -f "package.json" ]; then
        # Sprawdź czy jest eslint
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || \
           grep -q '"eslint"' package.json 2>/dev/null; then
            echo "npx eslint --fix . 2>/dev/null; npx prettier --write . 2>/dev/null"
        elif [ -f "biome.json" ]; then
            echo "npx biome check --fix . 2>/dev/null"
        fi
    elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if command -v ruff > /dev/null 2>&1; then
            echo "ruff check --fix . 2>/dev/null; ruff format . 2>/dev/null"
        elif command -v black > /dev/null 2>&1; then
            echo "black . 2>/dev/null; isort . 2>/dev/null"
        fi
    elif [ -f "Cargo.toml" ]; then
        echo "cargo clippy --fix --allow-dirty 2>/dev/null; cargo fmt 2>/dev/null"
    elif [ -f "go.mod" ]; then
        echo "gofmt -w . 2>/dev/null; go vet ./... 2>/dev/null"
    fi
}

TEST_CMD=$(detect_test_cmd)
LINT_CMD=$(detect_lint_cmd)
BASELINE=$(git rev-parse HEAD 2>/dev/null || echo "no-git")

# ─── Zbuduj listę modeli do spróbowania (smart order) ───
build_tier_list() {
    local task_type="$1"
    local force_cloud="$2"
    local tiers=()
    
    # Sprawdź historię — czy jest proven winner?
    local history_model=$(check_history "$task_type")
    
    if [ "$force_cloud" != "true" ]; then
        # Tier 1: Ollama (dobór modelu wg typu zadania)
        if curl -s --connect-timeout 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
            case "$task_type" in
                reason) tiers+=("ollama_chat/deepseek-r1:8b") ;;
                quick)  tiers+=("ollama_chat/qwen3:4b") ;;
                *)      tiers+=("ollama_chat/qwen3-coder") ;;
            esac
        fi
    fi
    
    # Tier 2: Cloud free (priorytet wg historii lub typu)
    if [ -n "$history_model" ] && [[ ! " ${tiers[*]} " =~ " $history_model " ]]; then
        tiers+=("$history_model")  # Proven winner first
    fi
    
    # Reszta cloud providerów (z rotacją wg limitów)
    for candidate in \
        "groq:groq/llama-3.3-70b-versatile" \
        "openrouter:openrouter/mistralai/devstral-2" \
        "cerebras:cerebras/llama-3.3-70b" \
        "gemini:gemini/gemini-2.0-flash" \
        "xai:xai/grok-3-mini"; do
        
        local prov=$(echo "$candidate" | cut -d: -f1)
        local model=$(echo "$candidate" | cut -d: -f2-)
        
        # Pomiń jeśli już na liście
        [[ " ${tiers[*]} " =~ " $model " ]] && continue
        
        # Pomiń jeśli limit wyczerpany
        [ "$(provider_available "$prov")" = "false" ] && continue
        
        tiers+=("$model")
    done
    
    echo "${tiers[@]}"
}

TIER_LIST=($(build_tier_list "$TASK_TYPE" "$FORCE_CLOUD"))

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  CASCADE HEAL v3                                      ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║  Task:    ${TASK:0:48}"
echo "║  Type:    $TASK_TYPE"
echo "║  Tests:   ${TEST_CMD:-none}"
echo "║  Linter:  ${LINT_CMD:-none}"
echo "║  Models:  ${#TIER_LIST[@]} available"
echo "║  Tiers:   ${TIER_LIST[*]:0:3}..."
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

ERROR_CONTEXT=""
TOTAL_ATTEMPTS=0

for tier_idx in "${!TIER_LIST[@]}"; do
    MODEL="${TIER_LIST[$tier_idx]}"
    PROVIDER=$(echo "$MODEL" | cut -d'/' -f1)
    
    for attempt in $(seq 1 $MAX_RETRIES); do
        TOTAL_ATTEMPTS=$((TOTAL_ATTEMPTS + 1))
        
        echo "⚡ [$((tier_idx+1))/${#TIER_LIST[@]}] $MODEL — próba $attempt/$MAX_RETRIES"
        
        # Rollback do baseline
        if [ "$BASELINE" != "no-git" ] && [ "$TOTAL_ATTEMPTS" -gt 1 ]; then
            git reset --hard "$BASELINE" 2>/dev/null
            echo "  ↩️  Git rollback do baseline"
        fi
        
        # Buduj prompt z kontekstem błędu
        FULL_TASK="$TASK"
        if [ -n "$ERROR_CONTEXT" ]; then
            FULL_TASK="$TASK

IMPORTANT — Previous attempt failed with this error:
$ERROR_CONTEXT

Fix this specific error in your implementation."
        fi
        
        # ─── Uruchom Aider ───
        echo "  🤖 Aider working..."
        AIDER_EXIT=0
        aider \
            --model "$MODEL" \
            --message "$FULL_TASK" \
            --yes \
            --auto-commits \
            --no-stream \
            2>/dev/null || AIDER_EXIT=$?
        
        if [ $AIDER_EXIT -ne 0 ] && [ $AIDER_EXIT -ne 1 ]; then
            echo "  ⚠️  Aider error (exit $AIDER_EXIT) — trying next model"
            ERROR_CONTEXT="Aider crashed with exit code $AIDER_EXIT"
            log_usage "$PROVIDER" "$MODEL" "$TASK_TYPE" false
            break  # Skip retries, go to next model
        fi
        
        # ─── NOWE: Linter pre-validation ───
        if [ -n "$LINT_CMD" ]; then
            echo "  🧹 Running linter..."
            eval "$LINT_CMD" 2>/dev/null || true
            
            # Jeśli linter zmienił pliki — commitnij
            if [ "$BASELINE" != "no-git" ] && ! git diff --quiet 2>/dev/null; then
                git add -A 2>/dev/null
                git commit -m "style: auto-lint fixes" --no-verify 2>/dev/null || true
                echo "  📝 Linter fixes committed"
            fi
        fi
        
        # ─── Testy ───
        if [ -n "$TEST_CMD" ]; then
            echo "  🧪 Running tests: $TEST_CMD"
            TEST_OUTPUT=$($TEST_CMD 2>&1) && TEST_EXIT=0 || TEST_EXIT=$?
            
            if [ $TEST_EXIT -eq 0 ]; then
                echo ""
                echo "╔═══════════════════════════════════════════╗"
                echo "║  ✅ SUCCESS                                ║"
                echo "╠═══════════════════════════════════════════╣"
                echo "║  Model:    $MODEL"
                echo "║  Type:     $TASK_TYPE"
                echo "║  Attempts: $TOTAL_ATTEMPTS"
                echo "╚═══════════════════════════════════════════╝"
                
                # Zapisz sukces do learnings
                echo "{\"date\":\"$TODAY\",\"task\":\"$(echo "$TASK" | head -c 120 | tr '"' "'")\",\"model\":\"$MODEL\",\"task_type\":\"$TASK_TYPE\",\"tier\":$((tier_idx+1)),\"attempts\":$TOTAL_ATTEMPTS,\"success\":true,\"ts\":$(date +%s)}" \
                    >> "$LEARNINGS"
                
                log_usage "$PROVIDER" "$MODEL" "$TASK_TYPE" true
                exit 0
            else
                echo "  ❌ Tests failed"
                ERROR_CONTEXT=$(echo "$TEST_OUTPUT" | tail -20)
                log_usage "$PROVIDER" "$MODEL" "$TASK_TYPE" false
            fi
        else
            # Brak testów — sprawdź czy Aider cokolwiek zmienił
            if [ "$BASELINE" != "no-git" ]; then
                local changes=$(git diff --stat "$BASELINE" 2>/dev/null | tail -1)
                if [ -n "$changes" ]; then
                    echo "  ✅ Changes applied (no tests to verify)"
                    echo "{\"date\":\"$TODAY\",\"task\":\"$(echo "$TASK" | head -c 120 | tr '"' "'")\",\"model\":\"$MODEL\",\"task_type\":\"$TASK_TYPE\",\"tier\":$((tier_idx+1)),\"attempts\":$TOTAL_ATTEMPTS,\"success\":true,\"no_tests\":true,\"ts\":$(date +%s)}" \
                        >> "$LEARNINGS"
                    log_usage "$PROVIDER" "$MODEL" "$TASK_TYPE" true
                    exit 0
                else
                    echo "  ⚠️  No changes made — retrying"
                    ERROR_CONTEXT="AI did not make any changes to the code"
                fi
            else
                echo "  ⚠️  No git — assuming success"
                exit 0
            fi
        fi
    done
    
    echo "  ⬆️  Escalating..."
    echo ""
done

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  🚨 ALL TIERS EXHAUSTED                               ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║  Tried $TOTAL_ATTEMPTS attempts across ${#TIER_LIST[@]} models"
echo "║  Task requires manual intervention.                   ║"
echo "║                                                       ║"
echo "║  Last error:                                          ║"
echo "║  $(echo "$ERROR_CONTEXT" | head -5)"
echo "╚═══════════════════════════════════════════════════════╝"

# Rollback
if [ "$BASELINE" != "no-git" ]; then
    git reset --hard "$BASELINE" 2>/dev/null
    echo "↩️  Git reset to baseline"
fi

echo "{\"date\":\"$TODAY\",\"task\":\"$(echo "$TASK" | head -c 120 | tr '"' "'")\",\"model\":\"all_failed\",\"task_type\":\"$TASK_TYPE\",\"tier\":0,\"attempts\":$TOTAL_ATTEMPTS,\"success\":false,\"ts\":$(date +%s)}" \
    >> "$LEARNINGS"

exit 1
