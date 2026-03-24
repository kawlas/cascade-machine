#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CASCADE INIT v3 — Z szablonami AGENTS.md per typ projektu
#
# Użycie:
#   cascade-init                     # auto-detect
#   cascade-init my-app              # nowy katalog
#   cascade-init my-app --react      # React template
#   cascade-init my-app --python     # Python template
#   cascade-init my-app --node       # Node.js API template
#   cascade-init my-app --ml         # ML/Data Science template
#   cascade-init my-app --cli        # CLI tool template
#   cascade-init my-app --go         # Go template
# ═══════════════════════════════════════════════════════════════

PROJECT_NAME="${1:-.}"
TEMPLATE="${2:---auto}"

# Utwórz katalog jeśli podano nazwę
if [ "$PROJECT_NAME" != "." ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    echo "📁 Utworzono: $PROJECT_NAME"
fi

# Git init
if [ ! -d ".git" ]; then
    git init -q
    echo "📦 Git zainicjalizowany"
fi

# Auto-detect template
if [ "$TEMPLATE" = "--auto" ]; then
    if [ -f "package.json" ] && grep -q "react\|next\|vue\|svelte" package.json 2>/dev/null; then
        TEMPLATE="--react"
    elif [ -f "package.json" ]; then
        TEMPLATE="--node"
    elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if grep -qE "torch|tensorflow|sklearn|pandas" requirements.txt pyproject.toml 2>/dev/null; then
            TEMPLATE="--ml"
        else
            TEMPLATE="--python"
        fi
    elif [ -f "go.mod" ]; then
        TEMPLATE="--go"
    elif [ -f "Cargo.toml" ]; then
        TEMPLATE="--cli"
    else
        TEMPLATE="--generic"
    fi
    echo "🔍 Auto-detected template: $TEMPLATE"
fi

# ═══════════════════════════════════════════════════════════════
# AGENTS.MD — per template
# ═══════════════════════════════════════════════════════════════

# Wspólna baza
cat > AGENTS.md << 'BASE'
# Project AI Instructions

## Universal Rules
- Write clean, readable code with meaningful variable/function names
- Add error handling to ALL I/O operations (network, file, DB)
- Every new function needs at least one test
- Functions: max 30 lines. Files: max 300 lines — split if larger
- Comments explain WHY, not WHAT
- Never hardcode secrets, API keys, or environment-specific config
- Commit messages: conventional commits (feat:, fix:, refactor:, docs:, test:)
- When unsure about architecture → ask, don't assume
- Read .cascade/decisions.md before making architectural changes

BASE

# Template-specific sections
case "$TEMPLATE" in
    --react)
        cat >> AGENTS.md << 'REACT_RULES'

## React-Specific Rules
- Use functional components with hooks (no class components)
- Custom hooks for reusable logic (prefix: use*)
- State management: start with useState/useContext, add Zustand only if needed
- Always cleanup effects (return cleanup function from useEffect)
- Memoize expensive computations (useMemo) and callbacks (useCallback)
- Component structure: types → hooks → handlers → JSX
- CSS: CSS modules or Tailwind — no inline styles except dynamic values
- Forms: controlled components with validation
- Error boundaries around async content
- Accessibility: semantic HTML, ARIA labels, keyboard navigation
- Always handle loading/error/empty states in data-fetching components

## Testing
- React Testing Library (not Enzyme)
- Test user behavior, not implementation details
- Mock API calls, not internal functions
- Test: render, interaction, error state, loading state

## File Structure
- components/ — reusable UI components
- hooks/ — custom hooks
- pages/ or routes/ — page-level components  
- utils/ — pure utility functions
- types/ — TypeScript type definitions
- __tests__/ — test files mirroring src structure
REACT_RULES
        TEST_CMD="npm test"
        LINT_CMD="npx eslint --fix src/ && npx prettier --write src/"
        ;;
        
    --python)
        cat >> AGENTS.md << 'PYTHON_RULES'

## Python-Specific Rules
- Type hints on ALL function signatures
- Docstrings (Google style) on public functions and classes
- Use pathlib instead of os.path
- Use dataclasses or Pydantic models for structured data
- Context managers for resource management (with statements)
- f-strings for formatting (not .format() or %)
- Exception handling: catch specific exceptions, never bare except
- Logging: use logging module, not print()
- Imports: stdlib → third-party → local (isort handles this)
- Virtual environment: always use (venv, poetry, or uv)

## Testing
- pytest (not unittest)
- Fixtures for test data setup
- parametrize for testing multiple inputs
- Mock external services, not internal logic
- Aim for >80% coverage on new code

## File Structure
- src/package_name/ — source code
- tests/ — test files (test_*.py)
- pyproject.toml — project config
PYTHON_RULES
        TEST_CMD="python -m pytest -x -q"
        LINT_CMD="ruff check --fix . && ruff format ."
        ;;
        
    --node)
        cat >> AGENTS.md << 'NODE_RULES'

## Node.js API-Specific Rules
- Express/Fastify with TypeScript
- Input validation on ALL endpoints (zod or joi)
- Centralized error handling middleware
- Environment config via dotenv — never hardcode
- Async/await (no callbacks, no raw promises chains)
- Rate limiting on public endpoints
- Request logging with correlation IDs
- Database: use transactions for multi-step operations
- Migrations: always create, never modify DB schema directly

## Testing
- Jest or Vitest for unit tests
- Supertest for API integration tests
- Test: happy path, validation errors, auth errors, edge cases

## File Structure
- src/routes/ — route handlers
- src/middleware/ — Express middleware
- src/models/ — DB models/schemas
- src/services/ — business logic
- src/utils/ — shared utilities
- tests/ — mirroring src structure
NODE_RULES
        TEST_CMD="npm test"
        LINT_CMD="npx eslint --fix src/"
        ;;
        
    --ml)
        cat >> AGENTS.md << 'ML_RULES'

## ML/Data Science-Specific Rules
- Reproducibility: seed ALL random operations (np, torch, random)
- Config: use YAML/JSON config files, not hardcoded hyperparameters
- Data pipeline: clear separation of load → preprocess → augment → feed
- Experiment tracking: log params, metrics, artifacts
- Model checkpointing: save best model + config + preprocessing steps
- Memory: use generators/datasets for large data, not loading all to RAM
- GPU: check device availability, support CPU fallback
- Numerical stability: use log-sum-exp, avoid division by zero
- Visualization: save plots to files, don't rely on notebooks

## Testing
- Test data loading with small sample
- Test model forward pass shape
- Test preprocessing produces expected output
- Test training loop runs 1 step without error

## File Structure
- data/ — raw and processed data (gitignored)
- experiments/ — experiment configs and results
- src/models/ — model architectures
- src/data/ — data loading and preprocessing
- src/training/ — training loops
- notebooks/ — exploration only, not production code
ML_RULES
        TEST_CMD="python -m pytest -x -q"
        LINT_CMD="ruff check --fix . && ruff format ."
        ;;
        
    --go)
        cat >> AGENTS.md << 'GO_RULES'

## Go-Specific Rules
- Accept interfaces, return structs
- Error handling: check every error, wrap with context (fmt.Errorf)
- Goroutines: always have a shutdown mechanism (context, channel)
- Use table-driven tests
- Avoid init() functions — explicit initialization
- Package names: lowercase, single word
- Don't export unnecessarily — start unexported, export when needed
- Use context.Context as first parameter for cancelable operations

## Testing
- go test with table-driven subtests
- testify for assertions if needed
- httptest for HTTP handlers

## File Structure
- cmd/ — main applications
- internal/ — private application code
- pkg/ — public library code (if any)
GO_RULES
        TEST_CMD="go test ./..."
        LINT_CMD="gofmt -w . && go vet ./..."
        ;;
        
    --cli)
        cat >> AGENTS.md << 'CLI_RULES'

## CLI Tool-Specific Rules
- Clear --help output with examples
- Exit codes: 0=success, 1=error, 2=usage error
- Stderr for errors/logs, stdout for data output
- Support piping: accept stdin, produce parseable stdout
- Config file: XDG_CONFIG_HOME or ~/.config/appname/
- Progress indicators for long operations
- Color output: respect NO_COLOR env variable
- Signal handling: cleanup on SIGINT/SIGTERM

## Testing
- Test CLI argument parsing
- Test output format
- Test error cases and exit codes
- Integration test: run actual binary with subprocess
CLI_RULES
        ;;
        
    *)
        cat >> AGENTS.md << 'GENERIC_RULES'

## Additional Guidelines
- Follow the existing patterns in the codebase
- When adding new functionality, look for similar implementations first
- Keep changes focused: one feature or fix per commit
- Update documentation when changing public interfaces
GENERIC_RULES
        ;;
esac

# Aider config
cat > .aider.conf.yml << AIDERCONF
model: ollama_chat/qwen3-coder
auto-commits: true
auto-test: true
gitignore: true
map-tokens: 2048
map-refresh: auto
attribute-author: false
attribute-committer: false
$([ -n "${TEST_CMD:-}" ] && echo "test-cmd: $TEST_CMD")
$([ -n "${LINT_CMD:-}" ] && echo "lint-cmd: $LINT_CMD")
AIDERCONF

# Kilocode config
cat > .kilocode << 'KILO'
Read AGENTS.md for all coding rules.
Preserve existing patterns. Add error handling. Update tests.
When asked about architecture: read .cascade/decisions.md first.
KILO

# Cascade directory
mkdir -p .cascade

cat > .cascade/decisions.md << 'DEC'
# Architecture Decisions

Format: Date | Decision | Reason

<!-- Add decisions here as the project evolves -->
DEC

cat > .cascade/learnings.md << 'LEARN'
# Project Learnings

Updated manually or by nightly CASCADE analysis.

<!-- Add learnings here -->
LEARN

COMMANDS_TEMPLATE=""
if [ -f "$HOME/.cascade/.cascade/commands.md" ]; then
    COMMANDS_TEMPLATE="$HOME/.cascade/.cascade/commands.md"
elif [ -f "$(dirname "$0")/../.cascade/commands.md" ]; then
    COMMANDS_TEMPLATE="$(dirname "$0")/../.cascade/commands.md"
fi

if [ -n "$COMMANDS_TEMPLATE" ]; then
    cp "$COMMANDS_TEMPLATE" .cascade/commands.md
else
    cat > .cascade/commands.md << 'CMDS'
# CASCADE — Commands

Use `cascade help` for the current command list.
CMDS
fi

# Gitignore additions
touch .gitignore
grep -q ".cascade/usage" .gitignore 2>/dev/null || cat >> .gitignore << 'GI'

# CASCADE Machine
.cascade/usage.jsonl
.cascade/experiments/
.aider*
!.aider.conf.yml
.env
.env.local
GI

# Initial commit
git add -A
git commit -m "feat: init project with CASCADE ($TEMPLATE)" -q 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ✅ CASCADE initialized ($TEMPLATE)                   ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║  Created:                                            ║"
echo "║  • AGENTS.md          (${TEMPLATE#--} template)       ║"
echo "║  • .aider.conf.yml    (Aider config)                 ║"
echo "║  • .kilocode          (Kilocode config)              ║"
echo "║  • .cascade/          (decisions, learnings, commands)║"
echo "║                                                      ║"
echo "║  Start coding:                                       ║"
echo "║  $ fast               (Ollama, free, <1s)            ║"
echo "║  $ heal \"task\"       (self-healing)                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
