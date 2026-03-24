#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/model-a	openrouter/model-a	free	200000		OPENROUTER_API_KEY
gemini	gemini/gemini-2.0-flash	gemini/gemini-2.0-flash	free	100000		GEMINI_API_KEY
EOF

PLAN=$(env \
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" \
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" \
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" \
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false \
    CASCADE_MODEL_HEALTH_ENABLED=false \
    OPENROUTER_API_KEY=test \
    GEMINI_API_KEY=test \
    CASCADE_PREFERRED_MODEL="openrouter/model-a" \
    CASCADE_PREFERRED_PROVIDER="gemini" \
    bash scripts/router.sh plan "implement auth")

[[ "$PLAN" == *"openrouter/model-a"* ]]
[[ "$PLAN" == *"gemini/gemini-2.0-flash"* ]]
