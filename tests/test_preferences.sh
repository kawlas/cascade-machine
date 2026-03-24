#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ENV_FILE="$TMP_DIR/.env"
cat > "$ENV_FILE" <<'EOF'
export OPENROUTER_API_KEY="test"
EOF

MODEL_SET=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh model openrouter/mistralai/devstral-2)
PROVIDER_SET=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh provider gemini)
PIN_SET=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh pin quick gemini/gemini-2.0-flash)
PIN_PROVIDER_SET=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh pin-provider cloud openrouter)
CURRENT=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh current)
UNPIN=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh unpin quick)
AUTO_RESET=$(CASCADE_HOME="$TMP_DIR" bash scripts/help.sh auto)

[[ "$MODEL_SET" == *"Preferred model set: openrouter/mistralai/devstral-2"* ]]
[[ "$PROVIDER_SET" == *"Preferred provider set: gemini"* ]]
[[ "$PIN_SET" == *"Pinned quick mode to model: gemini/gemini-2.0-flash"* ]]
[[ "$PIN_PROVIDER_SET" == *"Pinned cloud mode to provider: openrouter"* ]]
[[ "$CURRENT" == *"preferred model: openrouter/mistralai/devstral-2"* ]]
[[ "$CURRENT" == *"preferred provider: gemini"* ]]
[[ "$CURRENT" == *"quick preferred model: gemini/gemini-2.0-flash"* ]]
[[ "$CURRENT" == *"cloud preferred provider: openrouter"* ]]
[[ "$CURRENT" == *"fallback: always enabled"* ]]
[[ "$UNPIN" == *"Cleared quick mode preference."* ]]
[[ "$AUTO_RESET" == *"Routing preferences cleared."* ]]
