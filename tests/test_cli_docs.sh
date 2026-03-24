#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

alias_output="$(bash "$ROOT_DIR/scripts/aliases.sh" --show)"
help_output="$(bash "$ROOT_DIR/scripts/help.sh" help)"

echo "$alias_output" | grep -q "alias quick="
echo "$alias_output" | grep -q "alias fast="
echo "$alias_output" | grep -q "alias smart="
echo "$alias_output" | grep -q "alias heal="

echo "$help_output" | grep -q "quick"
echo "$help_output" | grep -q "fast"
echo "$help_output" | grep -q "smart"
echo "$help_output" | grep -q 'heal "zadanie"'

grep -q '`quick`' "$ROOT_DIR/docs/COMMANDS.md"
grep -q '`fast`' "$ROOT_DIR/docs/COMMANDS.md"
grep -q '`smart`' "$ROOT_DIR/docs/COMMANDS.md"

echo "test_cli_docs.sh: OK"
