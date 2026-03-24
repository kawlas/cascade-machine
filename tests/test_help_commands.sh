#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/model-a	openrouter/model-a	free	200000		OPENROUTER_API_KEY
gemini	gemini/gemini-2.0-flash	gemini/gemini-2.0-flash	free	100000		GEMINI_API_KEY
EOF

MODELS_OUTPUT=$(env CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false bash scripts/help.sh models openrouter)
RECOMMEND_OUTPUT=$(env CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false CASCADE_MODEL_HEALTH_ENABLED=false OPENROUTER_API_KEY=test GEMINI_API_KEY=test bash scripts/help.sh recommend "implement auth")

[[ "$MODELS_OUTPUT" == *"provider: openrouter"* ]]
[[ "$MODELS_OUTPUT" == *"openrouter/model-a"* ]]
[[ "$RECOMMEND_OUTPUT" == *"CASCADE recommend"* ]]
[[ "$RECOMMEND_OUTPUT" == *"type: code"* ]]
[[ "$RECOMMEND_OUTPUT" == *"best:"* ]]
