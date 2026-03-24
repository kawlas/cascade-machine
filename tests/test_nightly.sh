#!/bin/bash
set -euo pipefail

TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.cascade"
cat > "$TEST_HOME/.cascade/learnings.jsonl" <<'JSON'
{"date":"2026-03-24","task":"fix typo","model":"ollama_chat/devstral-small","task_type":"quick","tier":1,"attempts":1,"success":true,"ts":1}
{"date":"2026-03-24","task":"debug auth","model":"groq/llama-3.3-70b-versatile","task_type":"reason","tier":2,"attempts":2,"success":false,"ts":2}
JSON

HOME="$TEST_HOME" CASCADE_HOME="$TEST_HOME/.cascade" bash scripts/nightly.sh >/tmp/cascade-nightly-test.out

grep -q "CASCADE NIGHTLY REPORT" /tmp/cascade-nightly-test.out
grep -q "Zadania:" /tmp/cascade-nightly-test.out
grep -q "PODSUMOWANIE" /tmp/cascade-nightly-test.out
test -f "$TEST_HOME/.cascade/logs/nightly-$(date +%Y%m%d).log"
