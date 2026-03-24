#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# CASCADE HELP — Wszystkie komendy
# ═══════════════════════════════════════════════════════════════

# Load CASCADE environment if available
shopt -s expand_aliases
[ -f "$HOME/.cascade/.env" ] && source "$HOME/.cascade/.env" 2>/dev/null
[ -f "$HOME/.cascade/aliases.sh" ] && source "$HOME/.cascade/aliases.sh" --load >/dev/null 2>&1 || true

case "${1:-}" in

# ─────────────────────────────────────────────────────────────
models|model)
# ─────────────────────────────────────────────────────────────
cat << 'MODELS'

╔═══════════════════════════════════════════════════════════════╗
║  CASCADE — Modele                                            ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  LOKALNE (offline, $0, bez limitu):                          ║
║  ─────────────────────────────────                           ║
║  devstral         14 GB  najlepszy do planowania kodu        ║
║  qwen3-coder      18 GB  najlepszy do pisania kodu           ║
║  qwen3.5           7 GB  dobry ogólny                        ║
║  deepseek-r1:8b    5 GB  myślenie, debug, wyjaśnienia        ║
║  qwen3:4b          2.5 GB szybki, do prostych zadań          ║
║  phi4-mini         2.5 GB ultra szybki                       ║
║                                                               ║
║  CLOUD przez Ollama ($0, wymaga internet):                   ║
║  ─────────────────────────────────────────                   ║
║  qwen3.5:397b-cloud    ogromny, najlepszy ogólny             ║
║  gpt-oss:120b-cloud    GPT klasy                             ║
║  kimi-k2.5:cloud       dobry do kodu                         ║
║  nemotron-3:cloud      NVIDIA                                ║
║  minimax-m2.7:cloud    multimodal                            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Pokaż pobrane modele:   ollama list
Pobierz model:          ollama pull NAZWA
Usuń model:             ollama rm NAZWA
Test modelu:            ollama run NAZWA "napisz hello world"

MODELS
;;

# ─────────────────────────────────────────────────────────────
doctor)
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  CASCADE DOCTOR — Sprawdzam system...                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

OK="✅"
FAIL="❌"
WARN="⚠️ "
ERRORS=0

# Ollama
if command -v ollama > /dev/null 2>&1; then
    echo "$OK ollama zainstalowany ($(ollama --version 2>/dev/null | head -1))"
    if curl -s --connect-timeout 2 http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "$OK ollama działa (localhost:11434)"
        MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        echo "$OK modele: $MODEL_COUNT pobranych"
    else
        echo "$FAIL ollama NIE DZIAŁA"
        echo "   → Napraw: ollama serve"
        ERRORS=$((ERRORS+1))
    fi
else
    echo "$FAIL ollama nie zainstalowany"
    echo "   → Napraw: brew install ollama"
    ERRORS=$((ERRORS+1))
fi

echo ""

# Aider
if command -v aider > /dev/null 2>&1; then
    AIDER_VER=$(aider --version 2>/dev/null | head -1)
    echo "$OK aider zainstalowany ($AIDER_VER)"
else
    echo "$FAIL aider nie zainstalowany"
    echo "   → Napraw: pip3 install aider-chat"
    ERRORS=$((ERRORS+1))
fi

echo ""

# API Keys
if [ -n "$OPENROUTER_API_KEY" ]; then
    KEY_PREVIEW="${OPENROUTER_API_KEY:0:12}..."
    echo "$OK OPENROUTER_API_KEY ustawiony ($KEY_PREVIEW)"
    # Test połączenia
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        "https://openrouter.ai/api/v1/models" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "$OK OpenRouter: połączenie OK"
    else
        echo "$WARN OpenRouter: błąd połączenia (HTTP $STATUS)"
    fi
else
    echo "$WARN OPENROUTER_API_KEY nie ustawiony"
    echo "   → Info: quick, fast i think działają bez tego klucza"
    echo "   → Opcja: zarejestruj na openrouter.ai (darmowe)"
fi

echo ""

if [ -n "$GEMINI_API_KEY" ]; then
    echo "$OK GEMINI_API_KEY ustawiony"
else
    echo "$WARN GEMINI_API_KEY nie ustawiony (opcjonalny)"
fi

echo ""

if [ -n "$GROQ_API_KEY" ]; then
    echo "$OK GROQ_API_KEY ustawiony"
else
    echo "$WARN GROQ_API_KEY nie ustawiony (opcjonalny)"
fi

echo ""

# Pliki CASCADE
echo "Pliki CASCADE:"
for f in \
    ~/.cascade/heal.sh \
    ~/.cascade/router.sh \
    ~/.cascade/nightly.sh \
    ~/.cascade/init-project.sh \
    ~/.cascade/.env; do
    if [ -f "$f" ]; then
        if [ "$f" = "$HOME/.cascade/.env" ] || [ -x "$f" ]; then
            echo "$OK $f"
        else
            echo "$WARN $f (nie jest wykonywalny)"
            echo "   → Napraw: chmod +x $f"
        fi
    else
        echo "$FAIL $f (brak pliku)"
    fi
done

echo ""

# Aliasy
echo "Aliasy:"
for alias_name in quick fast think cloud smart turbo gem grok heal cascade-init tokens; do
    if type "$alias_name" > /dev/null 2>&1; then
        echo "$OK $alias_name"
    else
        echo "$FAIL $alias_name (brak) → uruchom: source ~/.zshrc"
    fi
done

echo ""

# Git
if command -v git > /dev/null 2>&1; then
    echo "$OK git zainstalowany"
    if git config --global user.email > /dev/null 2>&1; then
        EMAIL=$(git config --global user.email)
        echo "$OK git skonfigurowany ($EMAIL)"
    else
        echo "$WARN git nie skonfigurowany"
        echo "   → Napraw: git config --global user.email 'twoj@email.com'"
    fi
else
    echo "$FAIL git nie zainstalowany"
    echo "   → Napraw: brew install git"
    ERRORS=$((ERRORS+1))
fi

echo ""

# Cron
if crontab -l 2>/dev/null | grep -q nightly; then
    echo "$OK nightly cron zaplanowany (23:00)"
else
    echo "$WARN nightly cron nie zaplanowany"
    echo "   → Napraw: cascade config"
fi

echo ""
echo "─────────────────────────────────────────────────────"
if [ $ERRORS -eq 0 ]; then
    echo "✅ System OK — możesz zacząć: fast lub heal \"zadanie\""
else
    echo "❌ $ERRORS błędów do naprawienia (zobacz → powyżej)"
fi
echo ""
;;

# ─────────────────────────────────────────────────────────────
config)
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  CASCADE CONFIG                                           ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Co chcesz skonfigurować?                                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  1) Dodaj klucz API"
echo "  2) Zmień domyślny model"
echo "  3) Ustaw harmonogram nocny (cron)"
echo "  4) Pokaż aktualną konfigurację"
echo "  5) Wyjdź"
echo ""
read -p "Wybierz (1-5): " CHOICE

case "$CHOICE" in
    1)
        echo ""
        echo "Który klucz dodać?"
        echo "  1) OpenRouter (openrouter.ai — darmowe, 29 modeli)"
        echo "  2) Google Gemini (aistudio.google.com — darmowe)"
        echo "  3) Groq (console.groq.com — darmowe, najszybszy)"
        echo ""
        read -p "Wybierz (1-3): " KEY_CHOICE
        case "$KEY_CHOICE" in
            1) read -p "Wklej klucz OpenRouter (sk-or-...): " KEY
               VAR="OPENROUTER_API_KEY" ;;
            2) read -p "Wklej klucz Google Gemini: " KEY
               VAR="GEMINI_API_KEY" ;;
            3) read -p "Wklej klucz Groq (gsk_...): " KEY
               VAR="GROQ_API_KEY" ;;
            *) echo "Anulowano"; exit 1 ;;
        esac
        if [ -n "$KEY" ]; then
            touch ~/.cascade/.env
            # Usuń stary klucz jeśli istnieje
            sed -i '' "/export $VAR=/d" ~/.cascade/.env 2>/dev/null || true
            echo "export $VAR=\"$KEY\"" >> ~/.cascade/.env
            source ~/.cascade/.env
            echo ""
            echo "✅ Klucz zapisany w ~/.cascade/.env"
            echo "   Załaduj: source ~/.zshrc"
        else
            echo "❌ Anulowano — nie podano klucza"
        fi
        ;;
    2)
        echo ""
        echo "Wybierz domyślny model Aider:"
        echo "  1) ollama_chat/qwen3-coder (polecany do kodu)"
        echo "  2) ollama_chat/qwen3:4b (najszybszy lokalny)"
        echo "  3) ollama_chat/deepseek-r1:8b (debug i reasoning)"
        echo "  4) groq/llama-3.3-70b-versatile (cloud)"
        echo ""
        read -p "Wybierz (1-4): " MODEL_CHOICE
        case "$MODEL_CHOICE" in
            1) NEW_MODEL="ollama_chat/qwen3-coder" ;;
            2) NEW_MODEL="ollama_chat/qwen3:4b" ;;
            3) NEW_MODEL="ollama_chat/deepseek-r1:8b" ;;
            4) NEW_MODEL="groq/llama-3.3-70b-versatile" ;;
            *) echo "Anulowano"; exit 1 ;;
        esac
        touch ~/.cascade/.env
        sed -i '' '/export AIDER_MODEL=/d' ~/.cascade/.env 2>/dev/null || true
        echo "export AIDER_MODEL=\"$NEW_MODEL\"" >> ~/.cascade/.env
        echo "✅ Zmieniono domyślny AIDER_MODEL na: $NEW_MODEL"
        echo "   Załaduj: source ~/.cascade/.env"
        ;;
    3)
        if crontab -l 2>/dev/null | grep -q nightly; then
            echo "✅ Cron już zaplanowany:"
            crontab -l | grep nightly
        else
            (crontab -l 2>/dev/null; \
             echo "0 23 * * * ~/.cascade/nightly.sh >> ~/.cascade/logs/nightly.log 2>&1") \
             | crontab -
            echo "✅ Nightly analiza zaplanowana na 23:00 codziennie"
        fi
        ;;
    4)
        echo ""
        echo "═══ Aktualna konfiguracja ═══"
        echo ""
        echo "Klucze API:"
        [ -n "$OPENROUTER_API_KEY" ] && \
            echo "  OPENROUTER: ${OPENROUTER_API_KEY:0:16}..." || \
            echo "  OPENROUTER: nie ustawiony"
        [ -n "$GEMINI_API_KEY" ] && \
            echo "  GEMINI:     ${GEMINI_API_KEY:0:16}..." || \
            echo "  GEMINI:     nie ustawiony"
        [ -n "$GROQ_API_KEY" ] && \
            echo "  GROQ:       ${GROQ_API_KEY:0:16}..." || \
            echo "  GROQ:       nie ustawiony"
        [ -n "$AIDER_MODEL" ] && \
            echo "  AIDER_MODEL:${AIDER_MODEL}" || \
            echo "  AIDER_MODEL: nie ustawiony"
        echo ""
        echo "Aliasy:"
        type quick 2>/dev/null | head -1
        type fast 2>/dev/null | head -1
        type think 2>/dev/null | head -1
        type heal 2>/dev/null | head -1
        echo ""
        echo "Plik .env: ~/.cascade/.env"
        cat ~/.cascade/.env 2>/dev/null | \
            sed 's/=.*/=***/' || echo "  (pusty lub nie istnieje)"
        ;;
    5) exit 0 ;;
esac
;;

# ─────────────────────────────────────────────────────────────
status|tokens)
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  CASCADE STATUS                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Ollama
if curl -s --connect-timeout 1 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "🟢 Ollama: DZIAŁA"
    echo ""
    echo "Pobrane modele:"
    ollama list 2>/dev/null | tail -n +2 | \
        awk '{printf "   %-35s %s\n", $1, $4}' | head -10
else
    echo "🔴 Ollama: NIE DZIAŁA → uruchom: ollama serve"
fi

echo ""

# Klucze
echo "Klucze API:"
[ -n "$OPENROUTER_API_KEY" ] && \
    echo "  🟢 OpenRouter (devstral-2512, 150 req/dzień)" || \
    echo "  🔴 OpenRouter (nie ustawiony)"
[ -n "$GEMINI_API_KEY" ] && \
    echo "  🟢 Google Gemini (1500 req/dzień)" || \
    echo "  ⚪ Google Gemini (nie ustawiony, opcjonalny)"
[ -n "$GROQ_API_KEY" ] && \
    echo "  🟢 Groq (800 req/dzień)" || \
    echo "  ⚪ Groq (nie ustawiony, opcjonalny)"

echo ""

# Dzisiejsze użycie
LEARNINGS=~/.cascade/learnings.jsonl
TODAY=$(date +%Y-%m-%d)
if [ -f "$LEARNINGS" ]; then
    TOTAL=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | wc -l | tr -d ' ')
    SUCCESS=$(grep "\"date\":\"$TODAY\"" "$LEARNINGS" 2>/dev/null | \
        grep '"success":true' | wc -l | tr -d ' ')
    echo "Dzisiaj: $SUCCESS/$TOTAL zadań z sukcesem"
fi
;;

# ─────────────────────────────────────────────────────────────
logs|log)
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  CASCADE LOGS                                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
TODAY=$(date +%Y-%m-%d)
LOGFILE=~/.cascade/logs/nightly-$(date +%Y%m%d).log
if [ -f "$LOGFILE" ]; then
    cat "$LOGFILE"
else
    echo "Brak raportu na dziś ($TODAY)"
    echo ""
    echo "Ostatnie raporty:"
    ls -lt ~/.cascade/logs/*.log 2>/dev/null | head -5 | \
        awk '{print "  " $NF}'
    echo ""
    LEARN=~/.cascade/learnings.jsonl
    if [ -f "$LEARN" ]; then
        echo "Ostatnie 5 zadań:"
        tail -5 "$LEARN" 2>/dev/null | \
            python3 -c "
import sys, json
for line in sys.stdin:
    try:
        r = json.loads(line.strip())
        ok = '✅' if r.get('success') else '❌'
        task = r.get('task','?')[:50]
        model = r.get('model','?').split('/')[-1]
        print(f'  {ok} [{model}] {task}')
    except: pass
" 2>/dev/null
    fi
fi
;;

# ─────────────────────────────────────────────────────────────
update)
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  CASCADE UPDATE                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Aktualizuję komponenty..."
echo ""

echo "1/3 Aktualizuję Aider..."
pip3 install --upgrade aider-chat 2>/dev/null && \
    echo "  ✅ Aider: $(aider --version 2>/dev/null | head -1)" || \
    echo "  ❌ Błąd aktualizacji Aider"

echo ""
echo "2/3 Aktualizuję Ollama..."
brew upgrade ollama 2>/dev/null && \
    echo "  ✅ Ollama zaktualizowana" || \
    echo "  ⚪ Ollama — brak aktualizacji lub błąd"

echo ""
echo "3/3 Sprawdzam modele Ollama..."
OUTDATED=$(ollama list 2>/dev/null | tail -n +2 | \
    awk '{print $1}' | grep -v ':cloud' | head -5)
if [ -n "$OUTDATED" ]; then
    echo "  Modele lokalne (sprawdź czy aktualne):"
    echo "$OUTDATED" | while read m; do
        echo "    • $m"
    done
    echo ""
    echo "  Aby zaktualizować model: ollama pull NAZWA"
fi

echo ""
echo "✅ Update zakończony"
;;

# ─────────────────────────────────────────────────────────────
keys|key)
# ─────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  CASCADE — Konfiguracja kluczy API                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  Gdzie zdobyć darmowe klucze (2 minuty każdy):"
echo ""
echo "  OpenRouter  → https://openrouter.ai/keys"
echo "  Google      → https://aistudio.google.com/app/apikey"
echo "  Groq        → https://console.groq.com/keys"
echo ""
echo "  Jak dodać klucz:"
echo "  cascade config  → opcja 1"
echo ""
echo "  Aktualny stan:"
echo ""
for VAR in OPENROUTER_API_KEY GEMINI_API_KEY GROQ_API_KEY; do
    VAL=$(eval echo "\$$VAR")
    if [ -n "$VAL" ]; then
        echo "  ✅ $VAR = ${VAL:0:16}..."
    else
        echo "  ❌ $VAR = nie ustawiony"
    fi
done
echo ""
echo "  Plik z kluczami: ~/.cascade/.env"
echo "  Edytuj:          nano ~/.cascade/.env"
;;

# ─────────────────────────────────────────────────────────────
*|help|-h|--help)
# ─────────────────────────────────────────────────────────────
cat << 'HELP'

╔═══════════════════════════════════════════════════════════════════╗
║                   CASCADE MACHINE — POMOOC                       ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  KODOWANIE (główne komendy):                                     ║
║  ─────────────────────────────────────────────────────────────   ║
║  quick          qwen3:4b — szybkie proste zadania                ║
║                 Najszybszy stabilny lokalny alias                ║
║                                                                   ║
║  fast           qwen3-coder — główny lokalny model do kodu       ║
║                 Domyślny wybór do implementacji                  ║
║                                                                   ║
║  think          deepseek-r1:8b — wyjaśnienia i debug             ║
║                 Dla: analiza, troubleshooting, reasoning         ║
║                                                                   ║
║  cloud          Groq llama-70b — szybki cloud coding             ║
║                 Wymaga klucza API i internetu                    ║
║                                                                   ║
║  smart          OpenRouter Devstral-2 — cloud do trudnego kodu   ║
║                 Dobre do bardziej złożonych zmian                ║
║                                                                   ║
║  heal "zadanie" Automatyczne naprawianie z retry                 ║
║                 Klasyfikuje zadanie i eskaluje modele            ║
║                                                                   ║
║  ─────────────────────────────────────────────────────────────   ║
║  NARZĘDZIA:                                                      ║
║  ─────────────────────────────────────────────────────────────   ║
║  cascade help           Ten ekran                               ║
║  cascade doctor         Sprawdź czy wszystko działa             ║
║  cascade status         Modele, klucze, statystyki              ║
║  cascade config         Zmień ustawienia (klucze, model)        ║
║  cascade models         Lista wszystkich modeli                 ║
║  cascade keys           Skonfiguruj klucze API                  ║
║  cascade logs           Pokaż raporty                           ║
║  cascade update         Zaktualizuj Aider i Ollama              ║
║                                                                   ║
║  ─────────────────────────────────────────────────────────────   ║
║  W TRAKCIE PRACY z Aider:                                       ║
║  ─────────────────────────────────────────────────────────────   ║
║  /help          Pomoc Aider                                      ║
║  /undo          Cofnij ostatnią zmianę AI                       ║
║  /exit          Wyjdź z Aider                                   ║
║  /add plik.js   Dodaj plik do kontekstu                         ║
║  /drop plik.js  Usuń plik z kontekstu                           ║
║  /diff          Pokaż co AI zmienił                             ║
║  /run komenda   Uruchom komendę w terminalu                     ║
║                                                                   ║
║  ─────────────────────────────────────────────────────────────   ║
║  NOWY PROJEKT:                                                   ║
║  ─────────────────────────────────────────────────────────────   ║
║  cascade-init                  auto-detect typ projektu         ║
║  cascade-init folder --react   projekt React                    ║
║  cascade-init folder --python  projekt Python                   ║
║  cascade-init folder --node    projekt Node.js/API              ║
║  cascade-init folder --ml      projekt ML/Data Science          ║
║                                                                   ║
║  ─────────────────────────────────────────────────────────────   ║
║  SZYBKIE WSKAZÓWKI:                                             ║
║  ─────────────────────────────────────────────────────────────   ║
║  • Zacznij najczęściej od: fast                                 ║
║  • Problemy? Sprawdź: cascade doctor                            ║
║  • Brak internetu? quick, fast i think działają offline         ║
║  • AI popsuł kod? Wpisz: /undo                                  ║
║  • Jedno zadanie naraz! Nie pisz 5 rzeczy jednocześnie          ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

HELP
;;
esac
