#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PLAN=$(env \
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" \
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" \
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" \
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false \
    CASCADE_MODEL_HEALTH_ENABLED=false \
    OPENROUTER_API_KEY=test \
    GROQ_API_KEY=test \
    GEMINI_API_KEY=test \
    CEREBRAS_API_KEY=test \
    XAI_API_KEY=test \
    OLLAMA_HOST=http://127.0.0.1:9 \
    bash scripts/router.sh plan --cloud "czesc")

[[ "$PLAN" == *"openrouter/mistralai/devstral-2"* ]]
[[ "$PLAN" == *"gemini/gemini-2.0-flash"* ]]
[[ "$PLAN" == *"groq/llama-3.3-70b-versatile"* ]]
