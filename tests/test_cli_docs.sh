#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

alias_output="$(bash "$ROOT_DIR/scripts/aliases.sh" --show)"
help_output="$(bash "$ROOT_DIR/scripts/help.sh" help)"
dashboard_output="$(bash "$ROOT_DIR/scripts/help.sh" dashboard)"
slash_doctor_output="$(bash "$ROOT_DIR/scripts/help.sh" /doctor)"

echo "$alias_output" | grep -q "alias quick="
echo "$alias_output" | grep -q "alias fast="
echo "$alias_output" | grep -q "alias smart="
echo "$alias_output" | grep -q "alias heal="

echo "$help_output" | grep -q "quick"
echo "$help_output" | grep -q "fast"
echo "$help_output" | grep -q "smart"
echo "$help_output" | grep -q 'cascade "zadanie"'
echo "$help_output" | grep -q 'heal "zadanie"'
echo "$dashboard_output" | grep -q "default model:"
echo "$slash_doctor_output" | grep -q "CASCADE doctor"

grep -q '`quick`' "$ROOT_DIR/docs/COMMANDS.md"
grep -q '`fast`' "$ROOT_DIR/docs/COMMANDS.md"
grep -q '`smart`' "$ROOT_DIR/docs/COMMANDS.md"
grep -q '`cascade "task"`' "$ROOT_DIR/docs/COMMANDS.md"
grep -q 'Use CASCADE in four layers' "$ROOT_DIR/docs/COMMANDS.md"
grep -q 'How To Use It Day To Day' "$ROOT_DIR/README.md"
grep -q '`cascade` | Open the interactive CASCADE chat' "$ROOT_DIR/docs/COMMANDS.md"
grep -q '`cascade dashboard` | Show the welcome dashboard' "$ROOT_DIR/docs/COMMANDS.md"
grep -q 'cascade /doctor' "$ROOT_DIR/docs/COMMANDS.md"

echo "test_cli_docs.sh: OK"
