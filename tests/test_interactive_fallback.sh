#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/curl" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$TMP_DIR/curl"

cat > "$TMP_DIR/ollama" <<'EOF'
#!/bin/bash
if [ "$1" = "list" ]; then
    echo "devstral-small 1GB"
    exit 0
fi
exit 0
EOF
chmod +x "$TMP_DIR/ollama"

OUTPUT=$(CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false PATH="$TMP_DIR:$PATH" OLLAMA_HOST=http://127.0.0.1:9 bash -c 'source scripts/lib/heal_core.sh && resolve_interactive_record code true')

[[ "$OUTPUT" == *"ollama_chat/devstral-small"* ]]
