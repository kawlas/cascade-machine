Krok 1: Przygotuj środowisko

Bash


# W terminalu VS Code, w folderze gdzie masz playbook.txt:
pwd
ls playbook.txt  # upewnij się że plik jest tutaj

# Zbierz swoje API keys ZANIM uruchomisz prompt
# Otwórz notatnik i wpisz:
# OPENROUTER_API_KEY=sk-or-...
# GROQ_API_KEY=gsk_...
# CEREBRAS_API_KEY=...
# GOOGLE_AI_KEY=...
# XAI_API_KEY=xai-...
# (zostaw puste jeśli nie masz — system i tak działa z Ollama)
Krok 2: Mega Prompt (kopiuj całość)

text


═══════════════════════════════════════════════════════════════════
WKLEJ TEN PROMPT DO OPENCODE / KILOCODE / AIDER
═══════════════════════════════════════════════════════════════════
zatwierdaz
You are deploying the CASCADE MACHINE AI development framework 
from the playbook.txt file in the current directory.

Read playbook.txt completely first, then execute ALL phases 
in order. This is a one-time global setup.

## YOUR MISSION

Deploy CASCADE MACHINE framework globally to the user's home 
directory. Make it work immediately after completion.
Do not skip any phase. Do not ask for confirmation between steps.
Complete everything autonomously.

## EXECUTION ORDER

### PHASE 0: Pre-flight checks

Check and report:
1. Is Ollama installed? (`which ollama` or `ollama --version`)
   - If NOT installed on macOS: `brew install ollama`
   - If NOT installed on Linux: `curl -fsSL https://ollama.ai/install.sh | sh`
2. Is Aider installed? (`which aider`)
   - If NOT: `pip install aider-chat` or `pip3 install aider-chat`
3. Is git configured? (`git config --global user.email`)
   - If NOT: `git config --global user.email "cascade@local"` 
             `git config --global user.name "Cascade User"`
4. Is Python 3 available? (`python3 --version`)
5. Is Homebrew available? (macOS only: `which brew`)

Report results as:
✅ ollama: found (version X)
❌ aider: NOT found — installing...
✅ git: configured
etc.

Fix any missing dependencies before proceeding.

### PHASE 1: Create directory structure

Create these directories:
~/.cascade/~/.cascade/logs/~/.cascade/experiments/

text


Create these empty files:
~/.cascade/usage.jsonl~/.cascade/learnings.jsonl

text


### PHASE 2: Create ~/.cascade/router.sh

Extract the complete router.sh content from playbook.txt 
(section "FAZA 2" or "router.sh") and write it to 
~/.cascade/router.sh

The file MUST contain:
- get_best_model() function
- count_today() function  
- log_usage() function
- show_status() function
- Logic to check daily limits per provider
- Provider priority: groq > cerebras > google > openrouter > xai

After writing: `chmod +x ~/.cascade/router.sh`

Verify by running: `bash ~/.cascade/router.sh status`

### PHASE 3: Create ~/.cascade/heal.sh

Extract complete heal.sh from playbook.txt and write to 
~/.cascade/heal.sh

The file MUST contain:
- Tier escalation logic (Tier 1: ollama → Tier 2: cloud)
- Git rollback on failure (git reset --hard $BASELINE)
- Automatic test detection (npm test / pytest / go test / cargo test)
- Logging to ~/.cascade/learnings.jsonl
- Error context passed to next attempt

After writing: `chmod +x ~/.cascade/heal.sh`

Verify syntax: `bash -n ~/.cascade/heal.sh`

### PHASE 4: Create ~/.cascade/init-project.sh

Extract complete init-project.sh from playbook.txt and write to 
~/.cascade/init-project.sh

After writing: `chmod +x ~/.cascade/init-project.sh`

### PHASE 5: Create ~/.cascade/nightly.sh

Extract complete nightly.sh from playbook.txt and write to 
~/.cascade/nightly.sh

After writing: 
`chmod +x ~/.cascade/nightly.sh`

Add to crontab:
`(crontab -l 2>/dev/null | grep -v nightly.sh; echo "0 23 * * * ~/.cascade/nightly.sh >> ~/.cascade/logs/nightly.log 2>&1") | crontab -`

Verify crontab: `crontab -l | grep nightly`

### PHASE 6: Create .env.cascade template

Create ~/.cascade/.env.cascade with this EXACT content:

```bash
# ═══════════════════════════════════════════════════════════════
# CASCADE MACHINE — API Keys Configuration
# 
# HOW TO USE:
# 1. Copy this file: cp ~/.cascade/.env.cascade ~/.cascade/.env
# 2. Fill in your API keys (get free keys from links below)
# 3. Never commit .env to git (it's gitignored)
# 4. Source it: source ~/.cascade/.env
#
# FREE REGISTRATION LINKS:
# OpenRouter:  https://openrouter.ai/keys
# Groq:        https://console.groq.com/keys
# Cerebras:    https://cloud.cerebras.ai
# Google AI:   https://aistudio.google.com/app/apikey
# x.ai:        https://console.x.ai
# ═══════════════════════════════════════════════════════════════

# OpenRouter — 29 free models, ~200 req/day free
export OPENROUTER_API_KEY=""

# Groq — llama-3.3-70b, ~800 req/day free (fastest cloud)
export GROQ_API_KEY=""

# Cerebras — llama-3.3-70b, ~150 req/day free (2000 tok/s!)
export CEREBRAS_API_KEY=""

# Google AI Studio — gemini-2.0-flash, ~1500 req/day free
export GOOGLE_AI_KEY=""

# x.ai — grok-3-mini, $25/month free credits
export XAI_API_KEY=""

# Ollama config (usually no changes needed)
export OLLAMA_HOST="http://localhost:11434"

# Aider defaults
export AIDER_MODEL="ollama_chat/qwen3-coder"
Then create ~/.cascade/.gitignore:

text


.env
*.env
usage.jsonl
logs/
experiments/
PHASE 7: Add aliases to shell config
Detect which shell the user uses:
	•	Check if ~/.zshrc exists → use zshrc
	•	Check if ~/.bashrc exists → use bashrc
	•	Check $SHELL variable
Add these aliases to the appropriate file.IMPORTANT: Check if CASCADE section already exists first.If it does, skip this phase and report "aliases already configured".
Add this block:

Bash


# ═══════════════════════════════════════════════════════════════
# CASCADE MACHINE — AI Development Framework
# Installed: DATE_PLACEHOLDER
# ═══════════════════════════════════════════════════════════════

# Load API keys if .env exists
[ -f "$HOME/.cascade/.env" ] && source "$HOME/.cascade/.env"

# ─── Tier 1: Local models (Ollama, unlimited, free) ───
alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
alias think='aider --model ollama_chat/deepseek-r1:14b --auto-commits --yes'
alias quick='aider --model ollama_chat/devstral-small --auto-commits --yes'

# ─── Tier 2: Free cloud models (daily limits) ───
alias cloud='aider --model groq/llama-3.3-70b-versatile --auto-commits --yes'
alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'
alias grok='aider --model xai/grok-3-mini-free --auto-commits --yes'
alias turbo='aider --model cerebras/llama-3.3-70b --auto-commits --yes'
alias gem='aider --model gemini/gemini-2.0-flash --auto-commits --yes'

# ─── Self-healing (auto-escalation) ───
alias heal='~/.cascade/heal.sh'

# ─── Status & utilities ───
alias tokens='~/.cascade/router.sh status'
alias cascade-init='~/.cascade/init-project.sh'
alias cascade-status='~/.cascade/router.sh status && echo "" && crontab -l | grep -E "nightly|cascade"'

# ─── Cascade directory shortcut ───
alias cascade='cd ~/.cascade && ls'

# ═══════════════════════════════════════════════════════════════
Replace DATE_PLACEHOLDER with today's date in format YYYY-MM-DD.
PHASE 8: Download Ollama models
Only if Ollama is installed and running.Start Ollama service first: ollama serve & (wait 3 seconds)
Check available disk space: df -h ~
If less than 5GB free: pull only phi4-mini and devstral-smallIf 5-20GB free: pull phi4-mini, devstral-small, qwen3-coderIf 20GB+ free: pull all recommended models
Pull models (run in background, show progress):

Bash


# Essential (2GB total):
ollama pull phi4-mini
ollama pull devstral-small

# Recommended if space allows (20GB):
ollama pull qwen3-coder
ollama pull deepseek-r1:14b
If a pull fails: skip it and continue, note which failed.
PHASE 9: Create global Aider config
Create ~/.aider.conf.yml with:

YAML


# CASCADE MACHINE — Global Aider Configuration
# Project-specific .aider.conf.yml will override these

# Default to local Ollama (free, unlimited)
model: ollama_chat/qwen3-coder

# Auto-commit every AI change
auto-commits: true

# Show git diff of changes
show-diffs: false

# Don't add .aider files to git
gitignore: true

# Don't ask for confirmation on small edits
yes: false

# Map settings - helps Aider understand project structure
map-tokens: 2048
map-refresh: auto

# Conventional commit style
attribute-author: false
attribute-committer: false

# Editor settings
edit-format: diff
PHASE 10: Create ~/.cascade/README.md
Create a comprehensive usage guide:

Markdown


# CASCADE MACHINE — Usage Guide

## Quick Start

```bash
# 1. Load keys (first time only, then auto-loaded)
source ~/.cascade/.env

# 2. In any project directory
cd my-project

# 3. Initialize CASCADE for this project
cascade-init

# 4. Start coding
fast    # Aider + Ollama (free, <1s, unlimited)
Daily Commands
Command
What it does
Cost
fast
Aider + Ollama qwen3-coder
$0 unlimited
think
Aider + DeepSeek-R1 (reasoning)
$0 unlimited
quick
Aider + Devstral-small (fastest)
$0 unlimited
cloud
Aider + Groq llama-70b
$0 ~800/day
smart
Aider + Devstral-2 via OpenRouter
$0 ~150/day
heal "task"
Auto-escalating self-healing
$0
tokens
Check daily usage status
-
cascade-init
Setup new project
-
Self-Healing

Bash


# Basic usage
heal "add email validation to POST /users"

# For complex reasoning tasks  
heal --reason "debug the memory leak in auth module"

# For quick simple tasks
heal --fast "fix typo in README"
Token Strategy
Priority order (automatic):
	1	Ollama (local) — unlimited, use for 90% of work
	2	Groq — fastest cloud, 800 req/day
	3	Cerebras — 2000 tok/s, 150 req/day
	4	Google — 1500 req/day
	5	OpenRouter — 150 req/day, best models
	6	x.ai — $25 credits/month
New Project Setup

Bash


cd new-project/
cascade-init              # Creates AGENTS.md, .aider.conf.yml, etc.
fast                      # Start coding immediately
Files Created Per Project
	•	AGENTS.md — Instructions for ALL AI agents
	•	.aider.conf.yml — Aider configuration
	•	.kilocode — Kilocode configuration
	•	.cascade/decisions.md — Architecture decisions log
	•	.cascade/learnings.md — Project learnings
Nightly Analysis
Runs automatically at 23:00 via cron.Check logs: cat ~/.cascade/logs/nightly-$(date +%Y%m%d).log
Troubleshooting
Ollama not responding:

Bash


ollama serve &
sleep 3
ollama run phi4-mini "test"
API key not loaded:

Bash


source ~/.cascade/.env
echo $GROQ_API_KEY  # should show key
Check all systems:

Bash


cascade-status

text


### PHASE 11: Security checks

Perform these security actions:

1. Set correct permissions on sensitive files:
```bash
chmod 700 ~/.cascade/
chmod 600 ~/.cascade/.env.cascade
chmod 600 ~/.cascade/usage.jsonl
chmod 600 ~/.cascade/learnings.jsonl
	2	Ensure .env is NOT tracked by git globally:Add to ~/.gitignore_global (create if not exists):

text


.env
.cascade/.env
*.env.local
Run: git config --global core.excludesfile ~/.gitignore_global
	3	Check if any API keys are already in shell configin plain text (security risk):

Bash


grep -E "API_KEY|SECRET|TOKEN" ~/.zshrc ~/.bashrc 2>/dev/null | \
grep -v "cascade/.env"
If found: warn user to move them to ~/.cascade/.env
PHASE 12: Verification
Run these checks and report results:

Bash


echo "═══ CASCADE MACHINE — Installation Verification ═══"

# Check files
for f in \
  ~/.cascade/router.sh \
  ~/.cascade/heal.sh \
  ~/.cascade/init-project.sh \
  ~/.cascade/nightly.sh \
  ~/.cascade/.env.cascade \
  ~/.cascade/README.md \
  ~/.aider.conf.yml; do
  [ -f "$f" ] && echo "✅ $f" || echo "❌ MISSING: $f"
done

# Check executables
for f in ~/.cascade/router.sh ~/.cascade/heal.sh \
          ~/.cascade/init-project.sh ~/.cascade/nightly.sh; do
  [ -x "$f" ] && echo "✅ executable: $f" || echo "❌ NOT executable: $f"
done

# Check Ollama
ollama list 2>/dev/null && echo "✅ Ollama: running" || echo "❌ Ollama: not running"

# Check Aider
aider --version 2>/dev/null && echo "✅ Aider: installed" || echo "❌ Aider: not installed"

# Check cron
crontab -l 2>/dev/null | grep -q nightly && echo "✅ Cron: nightly job scheduled" || echo "❌ Cron: nightly NOT scheduled"

# Check aliases
grep -q "CASCADE MACHINE" ~/.zshrc 2>/dev/null && echo "✅ Aliases: added to .zshrc" || \
grep -q "CASCADE MACHINE" ~/.bashrc 2>/dev/null && echo "✅ Aliases: added to .bashrc" || \
echo "❌ Aliases: NOT found in shell config"

echo ""
echo "═══ Ollama models available ═══"
ollama list 2>/dev/null || echo "Ollama not running"

echo ""
echo "═══ Next steps ═══"
echo "1. Run: source ~/.zshrc  (or open new terminal)"
echo "2. Copy keys: cp ~/.cascade/.env.cascade ~/.cascade/.env"
echo "3. Edit keys: nano ~/.cascade/.env  (fill in your API keys)"
echo "4. Test: fast  (in any git directory)"
echo "5. New project: cascade-init"
IMPORTANT CONSTRAINTS
	•	Do NOT store any API keys in files other than ~/.cascade/.env
	•	Do NOT auto-fill API keys — leave them empty for user to fill
	•	Do NOT modify any existing project files (only ~/.cascade/ and global configs)
	•	Do NOT run ollama pull for models over 10GB without checking disk space first
	•	If any phase fails, report clearly and continue with remaining phases
	•	After completion, show full verification report
SUCCESS CRITERIA
Installation is successful when:
	1	All 5 scripts exist and are executable in ~/.cascade/
	2	Aliases are added to shell config
	3	Cron job is scheduled for 23:00
	4	~/.cascade/.env.cascade template exists with instructions
	5	Verification report shows all ✅
Start now. Read playbook.txt first, then execute Phase 0 through 12.═══════════════════════════════════════════════════════════════════

text


---

## Czy o czymś zapomniałeś?
CZEGO NIE MA W PLAYBOOKU (i czy to ważne):
	1	✅ Rozwiązane wyżej:└─ Bezpieczeństwo API keys (.env z właściwymi permissions)└─ Instrukcja użytkowania (README.md generowany automatycznie)└─ Weryfikacja instalacji (Faza 12)└─ Git global ignore dla .env
	2	⚠️ Warto rozważyć:└─ Backup SkillBank: ~/.cascade/usage.jsonl i learnings.jsonl→ dodaj do nightly.sh: cp learnings.jsonl learnings.$(date +%Y%m%d).bak└─ Ollama auto-start przy restarcie systemu (macOS):→ brew services start ollama (już w Phase 8)└─ Kilocode konfiguracja przez UI — tego nie da się zautomatyzować,musisz ręcznie ustawić Ollama provider w VS Code settings
	3	❌ NIE potrzebujesz:└─ Docker (żaden komponent nie wymaga)└─ MetaClaw (za wcześnie, AGENTS.md wystarczy)└─ Hermes gateway (opcjonalny, nie krytyczny)└─ Żadnych serwerów, cloud hosting, VPS
	4	📋 Po instalacji — Twoja checklistsa:□ source ~/.zshrc (załaduj aliasy)□ nano ~/.cascade/.env (wpisz API keys)□ ollama serve & (uruchom Ollama jeśli nie działa)□ cd jakis-projekt && cascade-init (test)□ fast (wpisz cokolwiek → sprawdź czy działa)□ tokens (sprawdź status limitów)

text


### Jak uruchomić prompt bezpiecznie

```bash
# Opcja A: Przez Kilocode w VS Code
# 1. Otwórz Kilocode panel
# 2. Wklej prompt (Ctrl+V)
# 3. Wyślij
# UWAGA: Kilocode może nie mieć dostępu do systemu plików poza projektem
#        Jeśli są błędy uprawnień → użyj Opcji B

# Opcja B: Przez Aider w terminalu (REKOMENDOWANA)
cd folder-z-playbook-txt/
aider --model ollama_chat/qwen3-coder \
      --message "$(cat mega-prompt.txt)" \
      --yes

# Opcja C: Przez OpenCode
cd folder-z-playbook-txt/
opencode  # wklej prompt w interfejsie

# Opcja D: Kopiuj-wklej do Claude Code (jeśli masz dostęp)
# Nie wymaga osobnego pliku — wklej prompt bezpośrednio
Jeden potencjalny problem i jak go uniknąć

text


PROBLEM: Agent może nie przeczytać całego playbook.txt
jeśli jest za długi (context window limit)

ROZWIĄZANIE: Podziel playbook na sekcje

# Sprawdź rozmiar
wc -l playbook.txt
wc -c playbook.txt

# Jeśli > 500 linii, podziel:
csplit playbook.txt '/FAZA 4/' '/FAZA 7/' '/FAZA 10/'
# Uruchom prompt trzykrotnie dla każdej części

# LUB: Powiedz agentowi wprost:
"The file is long. Process it in chunks.
Read lines 1-150, execute, then lines 151-300, execute, etc."
