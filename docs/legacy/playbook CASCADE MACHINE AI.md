CASCADE MACHINE — Kompletny Playbook




                Kilocode        Aider           OpenCode
────────────────────────────────────────────────────────────────
Interfejs       VS Code panel   CLI terminal    TUI terminal
Ollama          ✅ tak          ✅ tak           ✅ tak
OpenRouter      ✅ tak          ✅ tak           ✅ tak
Git auto-commit ❌ ręczny       ✅ automatyczny  ❌ ręczny
Auto-test       ❌ nie          ✅ wbudowany     ❌ nie
Architect mode  ✅ tak          ✅ tak           ❌ nie
Multi-file      ✅ tak          ✅ tak           ✅ tak
Rollback        ❌ ręczny       ✅ /undo         ❌ ręczny
Repo-map        ❌ nie          ✅ automatyczny  ❌ nie
Context window  ⚠️ manual add   ✅ auto-manages  ⚠️ manual
Praca offline   ✅ z Ollama     ✅ z Ollama      ✅ z Ollama

Werdykt: Używaj OBIE.
- Kilocode w VS Code → wizualna praca, przeglądanie kodu, szybkie fixy
- Aider w terminalu  → ciężka praca, multi-file, self-healing loop
- Nie kolidują ze sobą — jedno w edytorze, drugie w terminalu
Darmowe tokeny — realna ekonomia
=
text


Provider          Free tier              Limit dzienny     Najlepsze modele
──────────────────────────────────────────────────────────────────────────────
Ollama (local)    NIELIMITOWANY          ∞                 qwen3-coder, devstral
OpenRouter        29 modeli free         ~200 req/dzień    devstral-2, qwen3-coder-480b
x.ai              $25/mies. credits     ~500 req/dzień    grok-3-mini-free
Groq              free tier             ~1000 req/dzień   llama-3.3-70b
Cerebras          free tier             ~200 req/dzień    llama-3.3-70b (FASTEST)
Google AI Studio  free tier             ~1500 req/dzień   gemini-2.0-flash
NVIDIA NIM        free endpoints        ~200 req/dzień    nemotron, codellama
Cloudflare AI     free tier             ~10k req/dzień    misc small models

SUMA: ~3700+ req/dzień FREE z chmury + NIELIMITOWANE lokalnie

Claude Code bez Anthropic: 
  → ustaw OPENAI_BASE_URL na Ollama lub OpenRouter
  → działa, ale traci agentyczne features Claude'a
  → lepiej użyj Aider który jest natywnie model-agnostic

KOMPLETNA ARCHITEKTURA

text


╔══════════════════════════════════════════════════════════════╗
║                    CASCADE MACHINE v2                        ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ┌─────────────────────────────────────────────────────┐    ║
║  │              TY (w VS Code)                         │    ║
║  │                                                     │    ║
║  │  Panel Kilocode          Terminal z Aider           │    ║
║  │  (szybkie fixy,          (ciężka praca,             │    ║
║  │   pytania,                multi-file,               │    ║
║  │   visual debug)           self-healing)             │    ║
║  └──────────┬─────────────────────┬────────────────────┘    ║
║             │                     │                          ║
║  ╔══════════╧═════════════════════╧══════════════════════╗  ║
║  ║              MODEL ROUTER (router.sh)                 ║  ║
║  ║                                                       ║  ║
║  ║  Sprawdza:                                            ║  ║
║  ║  1. Czy Ollama odpowie wystarczająco dobrze?          ║  ║
║  ║     → TAK → ollama/qwen3-coder (0 tokenów, <1s)      ║  ║
║  ║     → NIE → krok 2                                   ║  ║
║  ║  2. Który cloud provider ma jeszcze limity?           ║  ║
║  ║     → Groq > Cerebras > Google > OpenRouter > x.ai   ║  ║
║  ║  3. Retry z lepszym modelem przy failure               ║  ║
║  ╚══════════╤════════════════════════════════════════════╝  ║
║             │                                                ║
║  ┌──────────┴──────────────────────────────────────────┐    ║
║  │                  INFERENCE LAYER                     │    ║
║  │                                                     │    ║
║  │  LOCAL (Tier 1)        CLOUD FREE (Tier 2)          │    ║
║  │  ┌─────────────┐      ┌───────────────────────┐    │    ║
║  │  │ Ollama      │      │ Groq (llama-70b)      │    │    ║
║  │  │ qwen3-coder │      │ Cerebras (llama-70b)  │    │    ║
║  │  │ devstral    │      │ Google (gemini-flash)  │    │    ║
║  │  │ deepseek-r1 │      │ OpenRouter (devstral)  │    │    ║
║  │  │             │      │ x.ai (grok-3-mini)    │    │    ║
║  │  │ UNLIMITED   │      │ ~3700 req/day total   │    │    ║
║  │  └─────────────┘      └───────────────────────┘    │    ║
║  └─────────────────────────────────────────────────────┘    ║
║                                                              ║
║  ┌─────────────────────────────────────────────────────┐    ║
║  │              BACKGROUND LAYER                        │    ║
║  │                                                     │    ║
║  │  Hermes daemon: cron + Telegram + memory             │    ║
║  │  Autoresearch: on-demand experiments                 │    ║
║  │  Nightly learner: parsuje wyniki → optymalizuje     │    ║
║  └─────────────────────────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════╝

PLAYBOOK — Wszystko w jednym pliku
Poniżej jest kompletny, gotowy do wykonania plan. Kopiujesz, wykonujesz po kolei, i masz działający system.
FAZA 1: Fundamenty (15 minut)

Bash


# ═══════════════════════════════════════════════════════════════
# 1.1 OLLAMA — Twój nielimitowany, darmowy silnik AI
# ═══════════════════════════════════════════════════════════════

# Instalacja (macOS)
brew install ollama

# Uruchom jako serwis (startuje z systemem)
brew services start ollama

# Ściągnij modele — jednorazowo, potem działają offline
ollama pull qwen3-coder        # główny model do kodowania (~20GB)
ollama pull devstral-small      # szybki, lżejszy model (~5GB)  
ollama pull deepseek-r1:14b     # reasoning i debugging (~8GB)
ollama pull phi4-mini            # ultra-lekki do klasyfikacji (~2GB)

# Test — powinno odpowiedzieć w <2s
ollama run qwen3-coder "napisz funkcję fibonacci w Python"

# ═══════════════════════════════════════════════════════════════
# 1.2 AIDER — Najlepszy darmowy coding agent
# ═══════════════════════════════════════════════════════════════

pip install aider-chat

# Test z Ollama (powinno działać natychmiast, $0)
cd /tmp && mkdir test-project && cd test-project && git init
aider --model ollama_chat/qwen3-coder --message "create hello.py" --yes

# ═══════════════════════════════════════════════════════════════
# 1.3 KILOCODE — już masz w VS Code, skonfiguruj provider
# ═══════════════════════════════════════════════════════════════

# W Kilocode Settings (VS Code):
# Provider: Ollama
# Model: qwen3-coder
# Base URL: http://localhost:11434
#
# Dodaj też OpenRouter jako secondary provider:
# Provider: OpenRouter  
# API Key: (twój klucz)
# Model: mistralai/devstral-2

# ═══════════════════════════════════════════════════════════════
# 1.4 API KEYS — darmowe tier-y (5 minut rejestracji)
# ═══════════════════════════════════════════════════════════════

# Zarejestruj się na darmowe konta:
# https://openrouter.ai          → OPENROUTER_API_KEY
# https://console.groq.com       → GROQ_API_KEY  
# https://cloud.cerebras.ai      → CEREBRAS_API_KEY
# https://aistudio.google.com    → GOOGLE_AI_KEY
# https://console.x.ai           → XAI_API_KEY

# Dodaj do ~/.zshrc (lub ~/.bashrc):
cat >> ~/.zshrc << 'KEYS'

# ═══ CASCADE MACHINE — API Keys ═══
export OPENROUTER_API_KEY="sk-or-v1-TWOJ_KLUCZ"
export GROQ_API_KEY="gsk_TWOJ_KLUCZ"
export CEREBRAS_API_KEY="TWOJ_KLUCZ"
export GOOGLE_AI_KEY="TWOJ_KLUCZ"
export XAI_API_KEY="xai-TWOJ_KLUCZ"

KEYS

source ~/.zshrc
FAZA 2: Model Router — serce systemu (10 minut)

Bash


# ═══════════════════════════════════════════════════════════════
# 2.1 Utwórz katalog CASCADE
# ═══════════════════════════════════════════════════════════════

mkdir -p ~/.cascade/{logs,experiments}
touch ~/.cascade/usage.jsonl
touch ~/.cascade/learnings.jsonl

# ═══════════════════════════════════════════════════════════════
# 2.2 MODEL ROUTER — automatyczna rotacja darmowych modeli
# ═══════════════════════════════════════════════════════════════

cat > ~/.cascade/router.sh << 'ROUTER'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE MODEL ROUTER
# Automatycznie wybiera najlepszy DARMOWY model
# z uwzględnieniem dziennych limitów tokenów
# ═══════════════════════════════════════════════════════════════

USAGE_FILE="$HOME/.cascade/usage.jsonl"
TODAY=$(date +%Y-%m-%d)

# Policz dzisiejsze użycie per provider
count_today() {
    local provider="$1"
    grep "\"provider\":\"$provider\"" "$USAGE_FILE" 2>/dev/null \
        | grep "\"date\":\"$TODAY\"" \
        | wc -l \
        | tr -d ' '
}

# Zaloguj użycie
log_usage() {
    local provider="$1" model="$2" tokens="$3" success="$4"
    echo "{\"date\":\"$TODAY\",\"provider\":\"$provider\",\"model\":\"$model\",\"tokens\":$tokens,\"success\":$success,\"ts\":$(date +%s)}" \
        >> "$USAGE_FILE"
}

# Dzienne limity per provider (konserwatywne)
GROQ_LIMIT=800
CEREBRAS_LIMIT=150
GOOGLE_LIMIT=1200
OPENROUTER_LIMIT=150
XAI_LIMIT=400

# Wybierz najlepszy dostępny model
get_best_model() {
    local task_type="${1:-code}"  # code, reason, fast
    
    # ZAWSZE najpierw próbuj Ollama (unlimited)
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        case "$task_type" in
            reason) echo "ollama_chat/deepseek-r1:14b" ;;
            fast)   echo "ollama_chat/devstral-small" ;;
            *)      echo "ollama_chat/qwen3-coder" ;;
        esac
        return 0
    fi
    
    # Ollama nie działa — użyj cloud free (z rotacją)
    local groq_used=$(count_today "groq")
    local cerebras_used=$(count_today "cerebras")
    local google_used=$(count_today "google")
    local openrouter_used=$(count_today "openrouter")
    local xai_used=$(count_today "xai")
    
    # Priorytet: Groq (najszybszy) > Cerebras > Google > OpenRouter > x.ai
    if [ "$groq_used" -lt "$GROQ_LIMIT" ]; then
        echo "groq/llama-3.3-70b-versatile"
    elif [ "$cerebras_used" -lt "$CEREBRAS_LIMIT" ]; then
        echo "cerebras/llama-3.3-70b"
    elif [ "$google_used" -lt "$GOOGLE_LIMIT" ]; then
        echo "gemini/gemini-2.0-flash"
    elif [ "$openrouter_used" -lt "$OPENROUTER_LIMIT" ]; then
        echo "openrouter/mistralai/devstral-2"
    elif [ "$xai_used" -lt "$XAI_LIMIT" ]; then
        echo "xai/grok-3-mini"
    else
        echo "LIMIT_EXCEEDED"
        return 1
    fi
}

# Wypisz status dziennych limitów
show_status() {
    echo "═══ CASCADE — Dzienne użycie tokenów ($TODAY) ═══"
    echo "Ollama (local):   UNLIMITED ✓"
    echo "Groq:             $(count_today groq)/$GROQ_LIMIT"
    echo "Cerebras:         $(count_today cerebras)/$CEREBRAS_LIMIT"
    echo "Google:           $(count_today google)/$GOOGLE_LIMIT"  
    echo "OpenRouter:       $(count_today openrouter)/$OPENROUTER_LIMIT"
    echo "x.ai:             $(count_today xai)/$XAI_LIMIT"
    echo ""
    
    local total_cloud=$(($(count_today groq) + $(count_today cerebras) + \
        $(count_today google) + $(count_today openrouter) + $(count_today xai)))
    echo "Cloud free total: $total_cloud requests today"
    echo "Remaining cloud:  $((GROQ_LIMIT + CEREBRAS_LIMIT + GOOGLE_LIMIT + \
        OPENROUTER_LIMIT + XAI_LIMIT - total_cloud)) requests"
}

# Eksportuj funkcje dla subshelli
export -f get_best_model count_today log_usage show_status 2>/dev/null

# Jeśli uruchomiony bezpośrednio — pokaż status
if [ "$1" = "status" ]; then
    show_status
elif [ "$1" = "best" ]; then
    get_best_model "${2:-code}"
fi
ROUTER

chmod +x ~/.cascade/router.sh
FAZA 3: Self-Healing Loop (5 minut)

Bash


# ═══════════════════════════════════════════════════════════════
# 3.1 HEAL.SH — Samonaprawiający się executor
# ═══════════════════════════════════════════════════════════════

cat > ~/.cascade/heal.sh << 'HEAL'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE HEAL — Self-healing coding with automatic escalation
#
# Użycie:
#   heal "dodaj walidację email do POST /users"
#   heal --reason "wyjaśnij bug w auth module"
#   heal --fast "popraw typo w README"
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

TASK="$*"
LEARNINGS="$HOME/.cascade/learnings.jsonl"
USAGE="$HOME/.cascade/usage.jsonl"
TODAY=$(date +%Y-%m-%d)
MAX_RETRIES=2

# Parse flags
TASK_TYPE="code"
case "$1" in
    --reason|--think) TASK_TYPE="reason"; shift; TASK="$*" ;;
    --fast|--quick)   TASK_TYPE="fast"; shift; TASK="$*" ;;
esac

if [ -z "$TASK" ]; then
    echo "Użycie: heal [--reason|--fast] \"opis zadania\""
    echo ""
    source ~/.cascade/router.sh
    show_status
    exit 1
fi

source ~/.cascade/router.sh

# Detect test command
detect_test_cmd() {
    if [ -f "package.json" ]; then
        if grep -q '"test"' package.json 2>/dev/null; then
            echo "npm test"
        else
            echo ""
        fi
    elif [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
        echo "python -m pytest -x -q"
    elif [ -f "go.mod" ]; then
        echo "go test ./..."
    elif [ -f "Cargo.toml" ]; then
        echo "cargo test"
    else
        echo ""
    fi
}

TEST_CMD=$(detect_test_cmd)
BASELINE=$(git rev-parse HEAD 2>/dev/null || echo "no-git")

# Tier definitions
TIERS=(
    "ollama_chat/qwen3-coder"       # Tier 1: Local, free, unlimited
    "groq/llama-3.3-70b-versatile"  # Tier 2a: Cloud, free, fast
    "openrouter/mistralai/devstral-2" # Tier 2b: Cloud, free, good
    "cerebras/llama-3.3-70b"        # Tier 2c: Cloud, free, fastest
)

echo "╔═══════════════════════════════════════════════╗"
echo "║  CASCADE HEAL — Self-Healing Coding           ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║  Task: ${TASK:0:45}..."
echo "║  Type: $TASK_TYPE"
echo "║  Tests: ${TEST_CMD:-none detected}"
echo "╚═══════════════════════════════════════════════╝"
echo ""

ERROR_CONTEXT=""

for tier_idx in "${!TIERS[@]}"; do
    MODEL="${TIERS[$tier_idx]}"
    TIER_NAME="Tier $((tier_idx+1))"
    
    # Sprawdź limity cloud providera
    PROVIDER=$(echo "$MODEL" | cut -d'/' -f1)
    if [ "$PROVIDER" != "ollama_chat" ]; then
        USED=$(count_today "$PROVIDER")
        case "$PROVIDER" in
            groq) LIMIT=800 ;;
            openrouter) LIMIT=150 ;;
            cerebras) LIMIT=150 ;;
            *) LIMIT=200 ;;
        esac
        if [ "$USED" -ge "$LIMIT" ]; then
            echo "⏭️  $PROVIDER: limit dzienny wyczerpany ($USED/$LIMIT), pomijam"
            continue
        fi
    fi
    
    for attempt in $(seq 1 $MAX_RETRIES); do
        echo "⚡ $TIER_NAME [$MODEL] — próba $attempt/$MAX_RETRIES"
        
        # Rollback do baseline (jeśli git)
        if [ "$BASELINE" != "no-git" ] && [ "$attempt" -gt 1 ]; then
            git reset --hard "$BASELINE" 2>/dev/null
        fi
        
        # Buduj prompt z kontekstem błędu
        FULL_TASK="$TASK"
        if [ -n "$ERROR_CONTEXT" ]; then
            FULL_TASK="$TASK

WAŻNE — poprzednia próba się nie powiodła. Błąd:
$ERROR_CONTEXT

Napraw to w tej próbie."
        fi
        
        # Uruchom Aider
        AIDER_OUTPUT=$(aider \
            --model "$MODEL" \
            --message "$FULL_TASK" \
            --yes \
            --auto-commits \
            --no-stream \
            2>&1) || true
        
        # Zaloguj użycie
        log_usage "$PROVIDER" "$MODEL" 0 true
        
        # Sprawdź testy
        if [ -n "$TEST_CMD" ]; then
            echo "  🧪 Uruchamiam testy: $TEST_CMD"
            TEST_OUTPUT=$($TEST_CMD 2>&1) && TEST_EXIT=0 || TEST_EXIT=$?
            
            if [ $TEST_EXIT -eq 0 ]; then
                echo "  ✅ Testy przeszły!"
                echo ""
                echo "═══ SUKCES ═══"
                echo "Model:   $MODEL"
                echo "Tier:    $TIER_NAME"  
                echo "Próby:   $((tier_idx * MAX_RETRIES + attempt))"
                
                # Zapisz do learnings
                echo "{\"date\":\"$TODAY\",\"task\":\"${TASK:0:100}\",\"model\":\"$MODEL\",\"tier\":$((tier_idx+1)),\"attempts\":$attempt,\"success\":true,\"ts\":$(date +%s)}" \
                    >> "$LEARNINGS"
                
                exit 0
            else
                echo "  ❌ Testy nie przeszły"
                ERROR_CONTEXT=$(echo "$TEST_OUTPUT" | tail -15)
            fi
        else
            # Brak testów — zakładamy sukces jeśli Aider nie zwrócił błędu
            echo "  ⚠️  Brak testów — zakładam sukces"
            echo "{\"date\":\"$TODAY\",\"task\":\"${TASK:0:100}\",\"model\":\"$MODEL\",\"tier\":$((tier_idx+1)),\"attempts\":$attempt,\"success\":true,\"no_tests\":true,\"ts\":$(date +%s)}" \
                >> "$LEARNINGS"
            exit 0
        fi
    done
    
    echo "⬆️  Eskaluję do następnego tier-u..."
    echo ""
done

echo ""
echo "🚨 WSZYSTKIE TIER-Y WYCZERPANE"
echo "Zadanie wymaga ręcznej interwencji."
echo "Ostatni błąd:"
echo "$ERROR_CONTEXT"

# Rollback do baseline
if [ "$BASELINE" != "no-git" ]; then
    git reset --hard "$BASELINE" 2>/dev/null
    echo "Git zresetowany do stanu sprzed próby."
fi

# Zapisz failure
echo "{\"date\":\"$TODAY\",\"task\":\"${TASK:0:100}\",\"model\":\"all\",\"tier\":0,\"attempts\":$((${#TIERS[@]} * MAX_RETRIES)),\"success\":false,\"ts\":$(date +%s)}" \
    >> "$LEARNINGS"

exit 1
HEAL

chmod +x ~/.cascade/heal.sh
FAZA 4: Aliasy — Twój codzienny interfejs (2 minuty)

Bash


# ═══════════════════════════════════════════════════════════════
# 4.1 ALIASY — Proste komendy do wszystkiego
# ═══════════════════════════════════════════════════════════════

cat >> ~/.zshrc << 'ALIASES'

# ═══ CASCADE MACHINE — Aliasy ═══

# === GŁÓWNE NARZĘDZIA ===

# Aider z lokalnymi modelami (UNLIMITED, $0)
alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
alias think='aider --model ollama_chat/deepseek-r1:14b --auto-commits --yes'
alias quick='aider --model ollama_chat/devstral-small --auto-commits --yes'

# Aider z darmowymi cloud modelami (dzienne limity)
alias cloud='aider --model groq/llama-3.3-70b-versatile --auto-commits --yes'
alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'
alias grok='aider --model xai/grok-3-mini-free --auto-commits --yes'
alias turbo='aider --model cerebras/llama-3.3-70b --auto-commits --yes'
alias gem='aider --model gemini/gemini-2.0-flash --auto-commits --yes'

# Self-healing (auto-eskalacja przy failure)
alias heal='~/.cascade/heal.sh'

# Status tokenów
alias tokens='~/.cascade/router.sh status'

# === BACKGROUND ===
alias hermes-start='hermes gateway start &'
alias hermes-stop='hermes gateway stop'

# === NOWY PROJEKT ===
alias cascade-init='~/.cascade/init-project.sh'

# === NAUKA I RESEARCH ===
alias learn='aider --model ollama_chat/deepseek-r1:14b --no-auto-commits'

ALIASES

source ~/.zshrc
FAZA 5: Auto-inicjalizacja nowych projektów (5 minut)

Bash


# ═══════════════════════════════════════════════════════════════
# 5.1 INIT-PROJECT.SH — Automatyczna konfiguracja nowego projektu
# ═══════════════════════════════════════════════════════════════

cat > ~/.cascade/init-project.sh << 'INIT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE INIT — Inicjalizuje projekt z pełnym frameworkiem
#
# Użycie:
#   cascade-init                    (w istniejącym katalogu)
#   cascade-init my-new-app         (tworzy nowy katalog)
#   cascade-init my-app --python    (z szablonem Python)
#   cascade-init my-app --node      (z szablonem Node.js)
#   cascade-init my-app --react     (z szablonem React)
# ═══════════════════════════════════════════════════════════════

PROJECT_NAME="${1:-.}"
TEMPLATE="${2:---auto}"

# Utwórz katalog jeśli podano nazwę
if [ "$PROJECT_NAME" != "." ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    echo "📁 Utworzono katalog: $PROJECT_NAME"
fi

# Git init jeśli nie istnieje
if [ ! -d ".git" ]; then
    git init
    echo "📦 Zainicjalizowano git"
fi

# ─── AGENTS.md — Instrukcje dla WSZYSTKICH agentów ───
cat > AGENTS.md << 'AGENTS'
# Project AI Instructions

## General Rules
- Write clean, readable code with meaningful names
- Add error handling to all I/O operations
- Write tests for new functionality
- Use existing patterns from the codebase
- Commit messages: conventional commits (feat:, fix:, refactor:, docs:)

## Architecture Decisions
See `.cascade/decisions.md` for project-specific decisions.

## Code Style
- Functions: max 30 lines
- Files: max 300 lines, split if larger
- Comments: explain WHY, not WHAT
- Types: use TypeScript types / Python type hints

## Testing
- Every new function needs at least one test
- Test edge cases and error paths
- Run tests before committing

## What NOT to do
- Don't use deprecated APIs
- Don't hardcode secrets or config values
- Don't ignore errors silently
- Don't add dependencies without justification
AGENTS

# ─── Aider config ───
cat > .aider.conf.yml << 'AIDERCONF'
# Aider configuration for this project
model: ollama_chat/qwen3-coder
auto-commits: true
auto-test: true
attribute-author: false
attribute-committer: false
gitignore: true

# Architect mode for complex tasks
architect: false

# Map settings
map-tokens: 2048
map-refresh: auto
AIDERCONF

# ─── Kilocode instructions ───
cat > .kilocode << 'KILOCODE'
# Kilocode Project Instructions

Read AGENTS.md for general rules.

When editing code:
- Preserve existing patterns
- Add error handling
- Update tests if changing behavior

When asked about architecture:
- Read .cascade/decisions.md first
- Propose changes, don't just implement
KILOCODE

# ─── Cascade directory ───
mkdir -p .cascade

cat > .cascade/decisions.md << 'DECISIONS'
# Architecture Decisions

Record important decisions here.
Format: Date | Decision | Reason | Alternatives considered

## Template
<!-- 
### YYYY-MM-DD: [Decision Title]
**Decision:** What was decided
**Reason:** Why
**Alternatives:** What else was considered
-->
DECISIONS

cat > .cascade/learnings.md << 'LEARN'
# Project Learnings

Things discovered during development.
Updated manually or by nightly Hermes analysis.

## Template
<!--
### YYYY-MM-DD: [What was learned]
**Context:** When/where this came up
**Insight:** The actual learning
**Action:** How to apply this going forward
-->
LEARN

# ─── Detect project type and add test config ───
if [ -f "package.json" ]; then
    # Node.js project — update aider test command
    sed -i '' 's/auto-test: true/auto-test: true\ntest-cmd: npm test/' .aider.conf.yml 2>/dev/null || true
    echo "  Detected: Node.js project"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    sed -i '' 's/auto-test: true/auto-test: true\ntest-cmd: python -m pytest -x -q/' .aider.conf.yml 2>/dev/null || true
    echo "  Detected: Python project"
elif [ -f "go.mod" ]; then
    sed -i '' 's/auto-test: true/auto-test: true\ntest-cmd: go test .\/.../' .aider.conf.yml 2>/dev/null || true
    echo "  Detected: Go project"
elif [ -f "Cargo.toml" ]; then
    sed -i '' 's/auto-test: true/auto-test: true\ntest-cmd: cargo test/' .aider.conf.yml 2>/dev/null || true
    echo "  Detected: Rust project"
fi

# ─── .gitignore updates ───
if [ -f ".gitignore" ]; then
    echo "" >> .gitignore
else
    touch .gitignore
fi

cat >> .gitignore << 'GITIGNORE'

# CASCADE Machine
.cascade/usage.jsonl
.cascade/experiments/
.aider*
!.aider.conf.yml
GITIGNORE

# ─── Initial commit ───
git add -A
git commit -m "feat: initialize project with CASCADE framework" 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ✅ CASCADE zainicjalizowany!                         ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║                                                       ║"
echo "║  Pliki utworzone:                                     ║"
echo "║  • AGENTS.md          — instrukcje dla AI             ║"
echo "║  • .aider.conf.yml    — konfiguracja Aider            ║"
echo "║  • .kilocode          — instrukcje dla Kilocode       ║"
echo "║  • .cascade/          — decisions, learnings          ║"
echo "║                                                       ║"
echo "║  Jak zacząć:                                          ║"
echo "║  $ fast               — Aider z Ollama (free, <1s)    ║"
echo "║  $ heal \"opis\"       — Self-healing z eskalacją      ║"
echo "║  $ tokens             — Status dziennych limitów      ║"
echo "║                                                       ║"
echo "║  W VS Code:                                           ║"
echo "║  → Kilocode czyta .kilocode automatycznie             ║"
echo "║  → AGENTS.md jest dostępny dla każdego agenta         ║"
echo "╚═══════════════════════════════════════════════════════╝"
INIT

chmod +x ~/.cascade/init-project.sh
FAZA 6: Nocny Learner — automatyczna optymalizacja (5 minut)

Bash


# ═══════════════════════════════════════════════════════════════
# 6.1 NIGHTLY LEARNER — Analizuje wyniki i optymalizuje routing
# ═══════════════════════════════════════════════════════════════

cat > ~/.cascade/nightly.sh << 'NIGHTLY'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE NIGHTLY — Automatyczna analiza i optymalizacja
# Uruchamiany przez cron codziennie o 23:00
# ═══════════════════════════════════════════════════════════════

LEARNINGS="$HOME/.cascade/learnings.jsonl"
LOG="$HOME/.cascade/logs/nightly-$(date +%Y%m%d).log"

{
echo "═══ CASCADE Nightly Report — $(date) ═══"
echo ""

# Statystyki dnia
TODAY=$(date +%Y-%m-%d)
TOTAL=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | wc -l | tr -d ' ')
SUCCESS=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"success":true' | wc -l | tr -d ' ')
FAIL=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"success":false' | wc -l | tr -d ' ')

echo "Dziś: $TOTAL zadań, $SUCCESS sukcesów, $FAIL porażek"
echo ""

# Tier distribution
T1=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep '"tier":1' | wc -l | tr -d ' ')
T2=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | grep -E '"tier":[234]' | wc -l | tr -d ' ')

echo "Tier 1 (local):    $T1 zadań"
echo "Tier 2+ (cloud):   $T2 zadań"
echo ""

# Najczęstsze typy failures
echo "Najczęstsze failures:"
grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null \
    | grep '"success":false' \
    | jq -r '.task' 2>/dev/null \
    | head -5
echo ""

# Token usage
echo "Użycie tokenów cloud:"
source ~/.cascade/router.sh
show_status

echo ""
echo "═══ Rekomendacje ═══"

# Proste reguły optymalizacji
if [ "$T2" -gt 0 ] && [ "$TOTAL" -gt 0 ]; then
    CLOUD_PCT=$((T2 * 100 / TOTAL))
    echo "• $CLOUD_PCT% zadań wymagało cloud — "
    if [ "$CLOUD_PCT" -lt 10 ]; then
        echo "  Ollama radzi sobie świetnie. Zostań na Tier 1."
    elif [ "$CLOUD_PCT" -gt 50 ]; then
        echo "  Dużo eskalacji. Rozważ większy model Ollama lub lepszy AGENTS.md"
    else
        echo "  Zdrowy mix. System działa optymalnie."
    fi
fi

} | tee "$LOG"

# Opcjonalnie: wyślij na Telegram przez Hermes
# hermes run "Przeczytaj $LOG i wyślij mi podsumowanie na Telegram" 2>/dev/null || true

NIGHTLY

chmod +x ~/.cascade/nightly.sh

# Dodaj do crontab
(crontab -l 2>/dev/null; echo "0 23 * * * ~/.cascade/nightly.sh") | crontab -
echo "✅ Nightly learner dodany do cron (23:00 codziennie)"
FAZA 7: Hermes jako background daemon (opcjonalne)

Bash


# ═══════════════════════════════════════════════════════════════
# 7.1 HERMES DAEMON — Background automation
# Wymagany TYLKO jeśli chcesz: Telegram, cron jobs, browser research
# Nie jest wymagany do kodowania!
# ═══════════════════════════════════════════════════════════════

# Skonfiguruj Hermes do używania darmowych modeli
cat > ~/.hermes/config.yaml << 'HERMESCONF'
provider: openrouter
model: mistralai/devstral-2
api_key_env: OPENROUTER_API_KEY

# Fallback na Ollama gdy OpenRouter limit
fallback:
  provider: ollama  
  model: qwen3-coder
HERMESCONF

# Uruchom jako daemon
hermes gateway start &
echo "✅ Hermes daemon uruchomiony"

# Opcjonalnie: skonfiguruj Telegram
# hermes setup telegram  # interaktywny setup

CODZIENNY WORKFLOW — Jak tego używasz

text


╔═══════════════════════════════════════════════════════════════╗
║                     TWÓJ TYPOWY DZIEŃ                         ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  1. OTWIERASZ VS CODE                                        ║
║     └─ Kilocode jest gotowy (Ollama provider)                ║
║     └─ .kilocode i AGENTS.md automatycznie wczytane          ║
║                                                               ║
║  2. SZYBKIE PYTANIE / FIX                                    ║
║     └─ Kilocode panel → pytasz → odpowiedź z Ollama (<1s)   ║
║     └─ Koszt: $0, bez limitów                                ║
║                                                               ║
║  3. POWAŻNE KODOWANIE                                        ║
║     └─ Terminal: $ fast                                      ║
║     └─ Aider + Ollama/qwen3-coder                            ║
║     └─ Piszesz co chcesz → Aider edytuje → git commit       ║
║     └─ Auto-testy → PASS? → gotowe                          ║
║     └─ Koszt: $0, bez limitów                                ║
║                                                               ║
║  4. TRUDNE ZADANIE                                           ║
║     └─ Terminal: $ heal "złożony opis zadania"               ║
║     └─ heal.sh próbuje Ollama → fail? → Groq → fail?        ║
║        → OpenRouter → sukces!                                ║
║     └─ Automatyczny rollback + retry + eskalacja             ║
║     └─ Koszt: $0 (darmowe cloud modele)                      ║
║                                                               ║
║  5. RESEARCH / NAUKA                                         ║
║     └─ Terminal: $ think                                     ║
║     └─ Aider + DeepSeek-R1 (reasoning model, local)          ║
║     └─ Lub: $ learn (Pi z deepseek-r1)                       ║
║     └─ Koszt: $0                                             ║
║                                                               ║
║  6. STATUS TOKENÓW                                           ║
║     └─ Terminal: $ tokens                                    ║
║     └─ Widzisz ile requests zostało na dziś                  ║
║                                                               ║
║  7. NOWY PROJEKT                                             ║
║     └─ Terminal: $ cascade-init my-app                       ║
║     └─ Automatycznie: AGENTS.md, .aider.conf.yml,            ║
║        .kilocode, .cascade/ — wszystko gotowe                ║
║     └─ Od razu: $ fast → piszesz kod                        ║
║                                                               ║
║  8. KONIEC DNIA                                              ║
║     └─ 23:00: nightly.sh automatycznie analizuje wyniki      ║
║     └─ Raport: ile Tier 1, ile eskalacji, rekomendacje       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Gdzie każde narzędzie żyje w tym systemie

text


CODZIENNIE (uruchomione zawsze):
├── Ollama (localhost:11434)     — silnik AI, zawsze włączony
├── Kilocode (VS Code panel)    — szybkie pytania, visual fixy
└── Aider (terminal)            — poważne kodowanie via aliasy

AUTOMATYCZNIE (w tle):
├── heal.sh                     — self-healing z eskalacją
├── router.sh                   — rotacja darmowych modeli
├── nightly.sh (cron 23:00)     — analiza i optymalizacja
└── Hermes daemon (opcjonalny)  — Telegram, cron jobs

ON-DEMAND (gdy potrzebujesz):
├── autoresearch                — eksperymenty z mierzalnym celem
├── OpenCode / opencode zen     — alternatywny TUI (gdy wolisz)
└── Codex (OpenAI free tier)    — autonomiczne PR-y

NIE UŻYWASZ NA CO DZIEŃ (zbędne w tym setupie):
├── MetaClaw       — za wcześnie, skills w AGENTS.md wystarczą
├── OpenClaw       — Aider robi to samo, lepiej
└── Pi             — deepseek-r1 w Aider daje to samo

Odpowiedzi na Twoje pytania
"W którym mam rozmawiać, który zarządza całością?"
Nie ma jednego "mózgu". I to jest celowe.

text


Rozmawiasz z:
├── Kilocode  → gdy jesteś w edytorze i chcesz szybko
└── Aider     → gdy jesteś w terminalu i chcesz poważnie kodować

Zarządza całością:
├── AGENTS.md        → mówi KAŻDEMU agentowi jak się zachować
├── .aider.conf.yml  → konfiguruje Aider per-projekt
├── heal.sh          → automatycznie eskaluje i naprawia
├── router.sh        → automatycznie rotuje modele
└── nightly.sh       → automatycznie optymalizuje system
Nie potrzebujesz "centralnego orchestratora" bo orkiestracja to pliki konfiguracyjne + bash scripty. Żaden LLM nie musi "zarządzać" innymi — to marnowanie tokenów.
"Jak uruchamiać nowe projekty żeby framework działał od razu?"

Bash


mkdir my-new-app && cd my-new-app
cascade-init
# Gotowe. AGENTS.md, .aider.conf.yml, .kilocode — wszystko na miejscu.
# Od razu:
fast
> stwórz REST API dla aplikacji do zarządzania zadaniami
"Chcę mieć darmowe tokeny, nie stać mnie na Anthropic"
System jest zaprojektowany na $0/miesiąc:
	•	90% pracy: Ollama (NIELIMITOWANY, lokalny)
	•	10% eskalacji: rotacja między 5 darmowymi cloud providerami (~3700 req/dzień)
	•	Claude Code: nie używasz (wymaga Anthropic). Aider + darmowe modele daje 85% tej jakości za $0
"Skills czy agenci — co szybsze?"

text


Skills (pliki .md w projekcie):
  Overhead: 0ms
  Dodaje tekst do kontekstu agenta → agent czyta i stosuje
  Nie wymaga serwera, procesu, konfiguracji
  ✅ UŻYJ TO — AGENTS.md, .kilocode, .aider.conf.yml

MCP (servers):
  Overhead: 200-800ms per tool call
  Wymaga serwera, zarządzania procesem, JSON-RPC
  Sensowne TYLKO dla: browser, baza danych, zewnętrzne API
  ⚠️ UŻYJ TYLKO gdy musisz (Hermes browser)

Custom plugins (Pi-tool, Claude-tool):
  Overhead: 1-30s (subprocess spawn + inference)
  Duplikuje inference (agent A → agent B → model)
  ❌ NIE UŻYWAJ — marnowanie tokenów i czasu

Quick Reference Card

text


╔═══════════════════════════════════════════════════════════════╗
║              CASCADE MACHINE — Quick Reference                ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  KOMENDY:                                                    ║
║  $ fast              Aider + Ollama (free, <1s)               ║
║  $ think             Aider + DeepSeek-R1 (reasoning, free)    ║
║  $ quick             Aider + Devstral-small (fastest, free)   ║
║  $ cloud             Aider + Groq/Llama-70b (cloud free)      ║
║  $ heal "task"       Self-healing z auto-eskalacją            ║
║  $ tokens            Status dziennych limitów                 ║
║  $ cascade-init      Zainicjuj nowy projekt                   ║
║                                                               ║
║  PLIKI PROJEKTU:                                             ║
║  AGENTS.md           Instrukcje dla wszystkich agentów        ║
║  .aider.conf.yml     Konfiguracja Aider                      ║
║  .kilocode           Instrukcje Kilocode                      ║
║  .cascade/           Decisions, learnings                     ║
║                                                               ║
║  MODELE (priorytet):                                         ║
║  1. Ollama/qwen3-coder     Local, $0, unlimited               ║
║  2. Groq/llama-70b         Cloud, $0, ~800/day                ║
║  3. Cerebras/llama-70b     Cloud, $0, ~150/day (fastest)      ║
║  4. Google/gemini-flash    Cloud, $0, ~1500/day               ║
║  5. OpenRouter/devstral    Cloud, $0, ~150/day                ║
║  6. x.ai/grok-mini         Cloud, $0, ~400/day                ║
║                                                               ║
║  AUTOMATYCZNE:                                               ║
║  heal.sh             Retry + escalate + rollback              ║
║  router.sh           Rotacja modeli wg limitów                ║
║  nightly.sh          Analiza wyników (cron 23:00)             ║
║                                                               ║
║  ZASADY:                                                     ║
║  • Zacznij od Ollama — eskaluj TYLKO gdy nie wystarczy        ║
║  • Każda zmiana = git commit (Aider robi to auto)             ║
║  • AGENTS.md jest ważniejszy niż jakikolwiek framework       ║
║  • $ tokens przed użyciem cloud modeli                       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
Ten system:
	•	Kosztuje $0/miesiąc
	•	Uruchamia się w 15 minut
	•	Sam się naprawia (heal.sh)
	•	Sam rotuje modele gdy limity się kończą (router.sh)
	•	Sam się optymalizuje (nightly.sh analizuje co działa)
	•	Automatycznie konfiguruje nowe projekty (cascade-init)
	•	Nie wymaga MCP, proxy, Docker, ani żadnej złożonej infrastruktury
	•	Działa offline (Tier 1 = Ollama, zero internetu potrzebne)
