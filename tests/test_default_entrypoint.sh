#!/bin/bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/aider" <<'EOF'
#!/bin/bash
echo "FAKE_AIDER $*"
EOF
chmod +x "$TMP_DIR/aider"

cat > "$TMP_DIR/curl" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$TMP_DIR/curl"

cat > "$TMP_DIR/ollama" <<'EOF'
#!/bin/bash
if [ "$1" = "list" ]; then
    echo "devstral-small 1GB"
    echo "qwen3:4b 1GB"
    echo "deepseek-r1:8b 1GB"
    exit 0
fi
exit 0
EOF
chmod +x "$TMP_DIR/ollama"

HELP_OUTPUT=$(bash scripts/help.sh help)
DEFAULT_OUTPUT=$(CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false PATH="$TMP_DIR:$PATH" OLLAMA_HOST=http://127.0.0.1:9 bash scripts/help.sh || true)
TASK_OUTPUT=$(CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false PATH="$TMP_DIR:$PATH" OLLAMA_HOST=http://127.0.0.1:9 bash scripts/help.sh "analyze auth flow" || true)
SLASH_HELP_OUTPUT=$(bash scripts/help.sh /)
SLASH_DOCTOR_OUTPUT=$(bash scripts/help.sh /doctor)
DO_OUTPUT=$(bash scripts/help.sh do || true)
THINK_OUTPUT=$(CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false PATH="$TMP_DIR:$PATH" OLLAMA_HOST=http://127.0.0.1:9 bash scripts/help.sh think || true)
QUICK_OUTPUT=$(CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false PATH="$TMP_DIR:$PATH" OLLAMA_HOST=http://127.0.0.1:9 bash scripts/help.sh quick || true)
CLOUD_OUTPUT=$(CASCADE_HOME="$TMP_DIR" CASCADE_USAGE_FILE="$TMP_DIR/usage.jsonl" CASCADE_LEARNINGS_FILE="$TMP_DIR/learnings.jsonl" CASCADE_MODEL_CATALOG_AUTO_REFRESH=false PATH="$TMP_DIR:$PATH" OLLAMA_HOST=http://127.0.0.1:9 bash scripts/help.sh cloud || true)
STOP_OUTPUT=$(bash scripts/help.sh stop)

[[ "$HELP_OUTPUT" == *'cascade "zadanie"'* ]]
[[ "$HELP_OUTPUT" == *'heal "zadanie"'* ]]
[[ "$HELP_OUTPUT" == *'cascade run "zadanie"'* ]]
[[ "$DEFAULT_OUTPUT" == *'CASCADE App'* ]]
[[ "$TASK_OUTPUT" == *'first prompt: analyze auth flow'* ]]
[[ "$SLASH_HELP_OUTPUT" == *"Slash commands:"* ]]
[[ "$SLASH_DOCTOR_OUTPUT" == *"CASCADE doctor"* ]]
[[ "$SLASH_DOCTOR_OUTPUT" == *"runtime files"* ]]
[[ "$DO_OUTPUT" == *'Usage:'* ]]
[[ "$THINK_OUTPUT" == *'CASCADE App'* ]]
[[ "$THINK_OUTPUT" == *'FAKE_AIDER --model'* ]]
[[ "$QUICK_OUTPUT" == *'CASCADE App'* ]]
[[ "$QUICK_OUTPUT" == *'FAKE_AIDER --model'* ]]
[[ "$CLOUD_OUTPUT" == *'CASCADE App'* ]]
[[ "$CLOUD_OUTPUT" == *'FAKE_AIDER --model'* ]]
[[ "$STOP_OUTPUT" == *'Ctrl+C'* ]]
