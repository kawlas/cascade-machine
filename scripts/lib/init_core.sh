#!/usr/bin/env bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"

detect_template() {
    if [ -f "package.json" ] && grep -q "react\|next\|vue\|svelte" package.json 2>/dev/null; then
        printf '%s\n' "--react"
    elif [ -f "package.json" ]; then
        printf '%s\n' "--node"
    elif [ -f "go.mod" ]; then
        printf '%s\n' "--go"
    elif [ -f "Cargo.toml" ]; then
        printf '%s\n' "--cli"
    elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if { [ -f "requirements.txt" ] && grep -qE "torch|tensorflow|sklearn|pandas" requirements.txt; } \
            || { [ -f "pyproject.toml" ] && grep -qE "torch|tensorflow|sklearn|pandas" pyproject.toml; }; then
            printf '%s\n' "--ml"
        else
            printf '%s\n' "--python"
        fi
    else
        printf '%s\n' "--generic"
    fi
}

write_agents_template() {
    local template="$1"
    cat > AGENTS.md <<'BASE'
# Project AI Instructions

## Universal Rules
- Write clean, readable code with meaningful variable/function names
- Add error handling to ALL I/O operations (network, file, DB)
- Every new function needs at least one test
- Functions: max 30 lines. Files: max 300 lines — split if larger
- Comments explain WHY, not WHAT
- Never hardcode secrets, API keys, or environment-specific config
- Commit messages: conventional commits (feat:, fix:, refactor:, docs:, test:)
- When unsure about architecture -> ask, don't assume
- Read .cascade/decisions.md before making architectural changes
BASE
    case "$template" in
        --python) cat >> AGENTS.md <<'EXTRA'

## Python-Specific Rules
- Type hints on all function signatures
- Use pytest for tests
EXTRA
            ;;
        --react) cat >> AGENTS.md <<'EXTRA'

## React-Specific Rules
- Use functional components
- Handle loading, error and empty states
EXTRA
            ;;
    esac
}

write_project_files() {
    local test_cmd="${1:-}" lint_cmd="${2:-}"
    cat > .aider.conf.yml <<AIDERCONF
model: ollama_chat/qwen3-coder
auto-commits: true
auto-test: true
gitignore: true
map-tokens: 2048
map-refresh: auto
show-model-warnings: false
attribute-author: false
attribute-committer: false
$([ -n "$test_cmd" ] && echo "test-cmd: $test_cmd")
$([ -n "$lint_cmd" ] && echo "lint-cmd: $lint_cmd")
AIDERCONF
    cat > .kilocode <<'KILO'
Read AGENTS.md for all coding rules.
Preserve existing patterns. Add error handling. Update tests.
When asked about architecture: read .cascade/decisions.md first.
KILO
    mkdir -p .cascade
    cat > .cascade/decisions.md <<'DEC'
# Architecture Decisions

Format: Date | Decision | Reason
DEC
    cat > .cascade/learnings.md <<'LEARN'
# Project Learnings

Updated manually or by nightly CASCADE analysis.
LEARN
}

copy_commands_template() {
    local template_path=""
    if [ -f "$HOME/.cascade/.cascade/commands.md" ]; then
        template_path="$HOME/.cascade/.cascade/commands.md"
    elif [ -f "$(cd "$LIB_DIR/../.." && pwd)/.cascade/commands.md" ]; then
        template_path="$(cd "$LIB_DIR/../.." && pwd)/.cascade/commands.md"
    fi
    if [ -n "$template_path" ]; then
        cp "$template_path" .cascade/commands.md
    else
        printf '%s\n' "# CASCADE — Commands" > .cascade/commands.md
    fi
}

update_gitignore() {
    touch .gitignore
    grep -q ".cascade/usage" .gitignore 2>/dev/null || cat >> .gitignore <<'GI'

# CASCADE Machine
.cascade/usage.jsonl
.cascade/experiments/
.aider*
!.aider.conf.yml
.env
.env.local
GI
}

bootstrap_commit() {
    local initialized_now="$1"
    [ "$initialized_now" != "true" ] && return 0
    git add AGENTS.md .aider.conf.yml .kilocode .cascade .gitignore 2>/dev/null || true
    git commit -m "feat: init project with CASCADE" -q 2>/dev/null || true
}
