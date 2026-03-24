#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/init_core.sh"

PROJECT_NAME="${1:-.}"
TEMPLATE="${2:---auto}"
INITIALIZED_NOW="false"
TEST_CMD=""
LINT_CMD=""

if [ "$PROJECT_NAME" != "." ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
fi

if [ ! -d ".git" ]; then
    git init -q
    INITIALIZED_NOW="true"
fi

[ "$TEMPLATE" = "--auto" ] && TEMPLATE="$(detect_template)"

case "$TEMPLATE" in
    --python) TEST_CMD="python -m pytest -x -q"; LINT_CMD="ruff check --fix . && ruff format ." ;;
    --node|--react) TEST_CMD="npm test"; LINT_CMD="npx eslint --fix src/" ;;
    --ml) TEST_CMD="python -m pytest -x -q"; LINT_CMD="ruff check --fix . && ruff format ." ;;
    --go) TEST_CMD="go test ./..."; LINT_CMD="gofmt -w . && go vet ./..." ;;
esac

write_agents_template "$TEMPLATE"
write_project_files "$TEST_CMD" "$LINT_CMD"
copy_commands_template
update_gitignore
bootstrap_commit "$INITIALIZED_NOW"

echo "CASCADE initialized ($TEMPLATE)"
