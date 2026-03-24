#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/catalog.tsv" <<'EOF'
openrouter	openrouter/nvidia/nemotron-3-super-120b-a12b:free	openrouter/nvidia/nemotron-3-super-120b-a12b:free	free	262144		OPENROUTER_API_KEY
openrouter	openrouter/qwen/qwen3-coder-next	openrouter/qwen/qwen3-coder-next	free	262144		OPENROUTER_API_KEY
groq	groq/llama-3.3-70b-versatile	groq/llama-3.3-70b-versatile	free	131072		GROQ_API_KEY
xai	xai/grok-3-mini	xai/grok-3-mini	prepaid	131072		XAI_API_KEY
EOF

BEST=$(env \
    CASCADE_HOME="$TMP_DIR" \
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" \
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" \
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" \
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false \
    CASCADE_MODEL_HEALTH_ENABLED=false \
    CASCADE_CLOUD_FREE_ONLY=true \
    OPENROUTER_API_KEY=test \
    GROQ_API_KEY=test \
    XAI_API_KEY=test \
    OLLAMA_HOST=http://127.0.0.1:9 \
    bash scripts/router.sh best --cloud "review the code")

PLAN=$(env \
    CASCADE_HOME="$TMP_DIR" \
    CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" \
    CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" \
    CASCADE_MODEL_CATALOG_FILE="$TMP_DIR/catalog.tsv" \
    CASCADE_MODEL_CATALOG_AUTO_REFRESH=false \
    CASCADE_MODEL_HEALTH_ENABLED=false \
    CASCADE_CLOUD_FREE_ONLY=true \
    OPENROUTER_API_KEY=test \
    GROQ_API_KEY=test \
    XAI_API_KEY=test \
    OLLAMA_HOST=http://127.0.0.1:9 \
    bash scripts/router.sh plan --cloud "review the code")

[[ "$BEST" == "openrouter/nvidia/nemotron-3-super-120b-a12b:free" ]]
[[ "$PLAN" == *"xai/grok-3-mini"* ]]
[[ "$PLAN" == *"filtered by routing policy"* ]]
